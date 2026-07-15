from __future__ import annotations

import csv
import hashlib
import html as html_lib
import io
import json
import re
import sys
import zipfile
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urljoin, urlsplit, urlunsplit

import cv2
import numpy as np
import requests
from PIL import Image, ImageOps

BASE = Path(__file__).resolve().parent
OUT = BASE / 'OUTPUT'
ROOT = OUT / 'Medicube_missing_products'
MANIFEST = ROOT / 'manifest_missing.csv'
QUALITY = OUT / 'source_quality_report.json'
MODEL = BASE / 'FSRCNN_x4.pb'
S = requests.Session()
S.headers.update({'User-Agent': 'Mozilla/5.0 Chrome/131 Safari/537.36', 'Accept-Language': 'en-US,en;q=0.9'})

ALT_PAGES = {
    'Medicube Rosemary PDRN Scalp Serum': 'https://niasha.ch/products/rosemary-pdrn-scalp-serum',
    'Medicube 3H Relief Cream': 'https://kbeautystudio.com/products/medicube-3h-relief-cream-50ml',
    'Medicube PDRN Caffeine Collagen Eye Patch': 'https://youngmi.mx/products/medicube-pdrn-pink-caffeine-collagen-eye-patch',
    'Medicube Red Clear Cica Body Mist': 'https://kbeautyarabia.com/products/red-clear-cica-body-mist',
    'Medicube Soymint Scaling Shampoo': 'https://hbytala.com/products/medicube-soymint-scaling-shampoo',
    'Medicube Red Moisture Real Sun Cream': 'https://shopee.sg/-medicube-Red-Moisture-Real-Sun-Cream-50ml-SPF50-PA-UV-Moisturizing-soothing-refreshing-non-greasy-facial-sunscreen-i.1317048456.55900091963',
    'Medicube PDRN Pink One Day Serum Set': 'https://saranghae.ch/products/medicube-pdrn-pink-one-day-serum-set',
    'Medicube PDRN Pink Collagen Volume Multi Balm': 'https://aubeautybazaar.com/products/medicube-pdrn-pink-collagen-volume-multi-balm-10g',
    'Medicube PDRN Pink Glow Kit': 'https://kiokii.com/products/medicube-pdrn-glow-kit-3-items',
    'Medicube Zero Foam Cleanser': 'https://bestkoreanskincare.kr/products/zero-foam-cleanser',
    'Medicube One Day Exosome Shot Pore Ampoule 25000': 'https://kiyoko.com/products/medicube-one-day-exosome-shot-pore-ampoule-25000-13ml',
    'Medicube AGE-R Glutathione Glow Toner': 'https://youglam.pk/products/medicube-age-r-glutathione-glow-toner-140ml-1',
    'Medicube PDRN Pink Exosome Shot Serum 7500': 'https://hbuty.com/en/products/medicube-pdrn-pink-collagen-exosome-shot-7500-30ml',
    'Medicube Azelaic Acid Calming Serum Mask': 'https://www.thekingofparfums.com.br/produtos/medicube-azelaic-acid-16-calming-mask-36pyz/',
}

# The five 679px deodorant gallery images are comparatively usable; use
# super-resolution on them if no multi-image high-resolution retailer page is found.
ALT_PAGES['Medicube Fresh That Lasts Vanilla Pistachio Deodorant'] = (
    'https://shop.tiktok.com/us/pdp/coming-soon-medicube-deodorant-drops-official-launch-march/1732293620479201515'
)

IMAGE_RE = re.compile(r'''(?:(?:https?:)?//|/)[^\s"'<>\\]+?\.(?:jpe?g|png|webp)(?:\?[^\s"'<>\\]*)?''', re.I)
BAD_WORDS = {'logo', 'icon', 'favicon', 'payment', 'flag', 'sprite', 'badge', 'loader', 'placeholder', 'review', 'avatar'}


def normalize_url(url: str, page: str) -> str:
    url = html_lib.unescape(url).replace('\\/', '/').strip(' "\'')
    if url.startswith('//'):
        url = 'https:' + url
    elif url.startswith('/'):
        url = urljoin(page, url)
    parts = urlsplit(url)
    query = [(k, v) for k, v in parse_qsl(parts.query, keep_blank_values=True)
             if k.lower() not in {'width', 'height', 'crop'}]
    return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), ''))


def shopify_js_url(page: str) -> str | None:
    parts = urlsplit(page)
    path = parts.path.rstrip('/')
    if '/products/' not in path:
        return None
    return urlunsplit((parts.scheme, parts.netloc, path + '.js', '', ''))


def extract_page_urls(page: str) -> list[str]:
    urls: list[str] = []
    js_url = shopify_js_url(page)
    if js_url:
        try:
            response = S.get(js_url, timeout=45)
            if response.ok and 'json' in response.headers.get('content-type', '').lower():
                data = response.json()
                for key in ('images',):
                    for value in data.get(key, []) or []:
                        if isinstance(value, str):
                            urls.append(value)
                        elif isinstance(value, dict):
                            urls.append(value.get('src') or value.get('url') or '')
                featured = data.get('featured_image')
                if isinstance(featured, str):
                    urls.append(featured)
                elif isinstance(featured, dict):
                    urls.append(featured.get('src') or featured.get('url') or '')
        except Exception as exc:
            print('SHOPIFY JS ERROR', page, exc)

    try:
        response = S.get(page, timeout=50)
        response.raise_for_status()
        text = html_lib.unescape(response.text).replace('\\/', '/')
        urls.extend(IMAGE_RE.findall(text))
    except Exception as exc:
        print('HTML ERROR', page, exc)

    cleaned = []
    for url in urls:
        if not url:
            continue
        url = normalize_url(url, page)
        lower = url.lower()
        if any(word in lower for word in BAD_WORDS):
            continue
        if url not in cleaned:
            cleaned.append(url)
    return cleaned


def get_image(url: str, referer: str) -> tuple[bytes, int, int] | None:
    try:
        response = S.get(url, timeout=50, headers={'Referer': referer})
        response.raise_for_status()
        raw = response.content
        if len(raw) < 3000:
            return None
        with Image.open(io.BytesIO(raw)) as im:
            width, height = im.size
            im.verify()
        return raw, width, height
    except Exception:
        return None


def page_candidates(page: str) -> list[dict]:
    found = []
    seen_hashes = set()
    for url in extract_page_urls(page):
        item = get_image(url, page)
        if not item:
            continue
        raw, width, height = item
        if min(width, height) < 800:
            continue
        digest = hashlib.sha256(raw).hexdigest()
        if digest in seen_hashes:
            continue
        seen_hashes.add(digest)
        found.append({'url': url, 'raw': raw, 'width': width, 'height': height, 'area': width * height})
    found.sort(key=lambda x: (x['area'], len(x['raw'])), reverse=True)
    return found


def load_fsrcnn():
    if not MODEL.exists():
        return None
    try:
        sr = cv2.dnn_superres.DnnSuperResImpl_create()
        sr.readModel(str(MODEL))
        sr.setModel('fsrcnn', 4)
        return sr
    except Exception as exc:
        print('FSRCNN unavailable', exc)
        return None


def super_resolve(raw: bytes, sr) -> Image.Image:
    with Image.open(io.BytesIO(raw)) as source:
        source = ImageOps.exif_transpose(source).convert('RGB')
        arr = cv2.cvtColor(np.array(source), cv2.COLOR_RGB2BGR)
    if sr is not None:
        try:
            arr = sr.upsample(arr)
            return Image.fromarray(cv2.cvtColor(arr, cv2.COLOR_BGR2RGB))
        except Exception as exc:
            print('FSRCNN failed, using Lanczos', exc)
    return Image.fromarray(cv2.cvtColor(arr, cv2.COLOR_BGR2RGB)).resize(
        (arr.shape[1] * 4, arr.shape[0] * 4), Image.Resampling.LANCZOS
    )


def convert_to_square(image: Image.Image, destination: Path) -> None:
    image = image.convert('RGB')
    result = ImageOps.fit(image, (1200, 1200), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
    destination.parent.mkdir(parents=True, exist_ok=True)
    result.save(destination, 'WEBP', quality=96, method=6)


def download_original(url: str) -> bytes:
    response = S.get(url, timeout=50, headers={'Referer': 'https://kstyleseoul.com/'})
    response.raise_for_status()
    return response.content


def rebuild_zip() -> None:
    target = OUT / 'Medicube_missing_25_actual_images.zip'
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for file_path in ROOT.rglob('*'):
            if file_path.is_file():
                archive.write(file_path, Path(ROOT.name) / file_path.relative_to(ROOT))


def main() -> None:
    rows = list(csv.DictReader(MANIFEST.open(encoding='utf-8-sig')))
    quality = json.loads(QUALITY.read_text(encoding='utf-8'))
    source_info = {item['requested_url']: item for item in quality['sources']}
    low_rows = [row for row in rows if min(source_info[row['source_image']]['source_width'], source_info[row['source_image']]['source_height']) < 800]

    grouped: dict[str, list[dict]] = {}
    for row in low_rows:
        grouped.setdefault(row['product'], []).append(row)

    sr = load_fsrcnn()
    report = []
    for product, product_rows in grouped.items():
        page = ALT_PAGES.get(product)
        candidates = page_candidates(page) if page else []
        print(product, 'low=', len(product_rows), 'alternatives=', len(candidates))
        used = 0
        for row in product_rows:
            destination = ROOT / row['output_file']
            if used < len(candidates):
                candidate = candidates[used]
                with Image.open(io.BytesIO(candidate['raw'])) as image:
                    convert_to_square(ImageOps.exif_transpose(image), destination)
                report.append({
                    'product': product,
                    'file': row['output_file'],
                    'method': 'alternate_high_resolution_source',
                    'source_url': candidate['url'],
                    'source_width': candidate['width'],
                    'source_height': candidate['height'],
                })
                used += 1
            else:
                raw = download_original(row['source_image'])
                image = super_resolve(raw, sr)
                convert_to_square(image, destination)
                info = source_info[row['source_image']]
                report.append({
                    'product': product,
                    'file': row['output_file'],
                    'method': 'FSRCNN_x4_super_resolution' if sr is not None else 'Lanczos_x4_fallback',
                    'source_url': row['source_image'],
                    'source_width': info['source_width'],
                    'source_height': info['source_height'],
                })

    (OUT / 'low_resolution_replacement_report.json').write_text(
        json.dumps({
            'replaced_image_count': len(report),
            'alternate_source_count': sum(1 for item in report if item['method'] == 'alternate_high_resolution_source'),
            'super_resolution_count': sum(1 for item in report if 'super_resolution' in item['method']),
            'items': report,
        }, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    rebuild_zip()
    if len(report) != len(low_rows):
        print('replacement count mismatch', len(report), len(low_rows))
        sys.exit(2)


if __name__ == '__main__':
    main()
