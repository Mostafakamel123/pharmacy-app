from __future__ import annotations

import csv, hashlib, html as html_lib, io, json, sys, zipfile
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

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

# Exact product pages. The script uses the lightweight Shopify .js endpoint only;
# blocked/dynamic pages immediately fall back to local neural super-resolution.
ALT_PAGES = {
    'Medicube Rosemary PDRN Scalp Serum': 'https://niasha.ch/products/rosemary-pdrn-scalp-serum',
    'Medicube 3H Relief Cream': 'https://kbeautystudio.com/products/medicube-3h-relief-cream-50ml',
    'Medicube PDRN Caffeine Collagen Eye Patch': 'https://youngmi.mx/products/medicube-pdrn-pink-caffeine-collagen-eye-patch',
    'Medicube Red Clear Cica Body Mist': 'https://kbeautyarabia.com/products/red-clear-cica-body-mist',
    'Medicube Soymint Scaling Shampoo': 'https://hbytala.com/products/medicube-soymint-scaling-shampoo',
    'Medicube PDRN Pink One Day Serum Set': 'https://saranghae.ch/products/medicube-pdrn-pink-one-day-serum-set',
    'Medicube PDRN Pink Collagen Volume Multi Balm': 'https://aubeautybazaar.com/products/medicube-pdrn-pink-collagen-volume-multi-balm-10g',
    'Medicube PDRN Pink Glow Kit': 'https://kiokii.com/products/medicube-pdrn-glow-kit-3-items',
    'Medicube Zero Foam Cleanser': 'https://bestkoreanskincare.kr/products/zero-foam-cleanser',
    'Medicube One Day Exosome Shot Pore Ampoule 25000': 'https://kiyoko.com/products/medicube-one-day-exosome-shot-pore-ampoule-25000-13ml',
    'Medicube AGE-R Glutathione Glow Toner': 'https://youglam.pk/products/medicube-age-r-glutathione-glow-toner-140ml-1',
    'Medicube PDRN Pink Exosome Shot Serum 7500': 'https://hbuty.com/en/products/medicube-pdrn-pink-collagen-exosome-shot-7500-30ml',
}


def clean_url(url: str) -> str:
    url = html_lib.unescape(url).replace('\\/', '/')
    if url.startswith('//'):
        url = 'https:' + url
    parts = urlsplit(url)
    query = [(k, v) for k, v in parse_qsl(parts.query, keep_blank_values=True)
             if k.lower() not in {'width', 'height', 'crop'}]
    return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), ''))


def shopify_urls(page: str) -> list[str]:
    parts = urlsplit(page)
    path = parts.path.rstrip('/')
    if '/products/' not in path:
        return []
    endpoint = urlunsplit((parts.scheme, parts.netloc, path + '.js', '', ''))
    try:
        response = S.get(endpoint, timeout=15)
        response.raise_for_status()
        data = response.json()
    except Exception as exc:
        print('NO SHOPIFY JSON', page, exc)
        return []
    urls = []
    for value in data.get('images', []) or []:
        if isinstance(value, str):
            urls.append(value)
        elif isinstance(value, dict):
            urls.append(value.get('src') or value.get('url') or '')
    featured = data.get('featured_image')
    if isinstance(featured, str):
        urls.append(featured)
    elif isinstance(featured, dict):
        urls.append(featured.get('src') or featured.get('url') or '')
    return list(dict.fromkeys(clean_url(url) for url in urls if url))


def get_image(url: str, referer: str):
    try:
        response = S.get(url, timeout=20, headers={'Referer': referer})
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


def page_candidates(page: str, need: int) -> list[dict]:
    found, seen = [], set()
    for url in shopify_urls(page)[:30]:
        item = get_image(url, page)
        if not item:
            continue
        raw, width, height = item
        if min(width, height) < 800:
            continue
        digest = hashlib.sha256(raw).hexdigest()
        if digest in seen:
            continue
        seen.add(digest)
        found.append({'url': url, 'raw': raw, 'width': width, 'height': height, 'area': width * height})
        if len(found) >= need + 3:
            break
    found.sort(key=lambda x: (x['area'], len(x['raw'])), reverse=True)
    return found


def load_sr():
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
            up = sr.upsample(arr)
            return Image.fromarray(cv2.cvtColor(up, cv2.COLOR_BGR2RGB))
        except Exception as exc:
            print('FSRCNN failed', exc)
    source = Image.fromarray(cv2.cvtColor(arr, cv2.COLOR_BGR2RGB))
    return source.resize((source.width * 4, source.height * 4), Image.Resampling.LANCZOS)


def save_square(image: Image.Image, destination: Path) -> None:
    result = ImageOps.fit(ImageOps.exif_transpose(image).convert('RGB'), (1200, 1200), Image.Resampling.LANCZOS, centering=(0.5, 0.5))
    destination.parent.mkdir(parents=True, exist_ok=True)
    result.save(destination, 'WEBP', quality=96, method=6)


def original_raw(url: str) -> bytes:
    response = S.get(url, timeout=30, headers={'Referer': 'https://kstyleseoul.com/'})
    response.raise_for_status()
    return response.content


def rebuild_zip() -> None:
    with zipfile.ZipFile(OUT / 'Medicube_missing_25_actual_images.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for file_path in ROOT.rglob('*'):
            if file_path.is_file():
                archive.write(file_path, Path(ROOT.name) / file_path.relative_to(ROOT))


def main() -> None:
    rows = list(csv.DictReader(MANIFEST.open(encoding='utf-8-sig')))
    quality = json.loads(QUALITY.read_text(encoding='utf-8'))
    source_info = {item['requested_url']: item for item in quality['sources']}
    low_rows = [row for row in rows if min(source_info[row['source_image']]['source_width'], source_info[row['source_image']]['source_height']) < 800]
    grouped = {}
    for row in low_rows:
        grouped.setdefault(row['product'], []).append(row)

    sr = load_sr()
    report = []
    for product, product_rows in grouped.items():
        page = ALT_PAGES.get(product)
        candidates = page_candidates(page, len(product_rows)) if page else []
        print(product, 'low=', len(product_rows), 'high-res alternatives=', len(candidates))
        for index, row in enumerate(product_rows):
            destination = ROOT / row['output_file']
            if index < len(candidates):
                candidate = candidates[index]
                with Image.open(io.BytesIO(candidate['raw'])) as image:
                    save_square(image, destination)
                method = 'alternate_high_resolution_source'
                source_url = candidate['url']
                sw, sh = candidate['width'], candidate['height']
            else:
                info = source_info[row['source_image']]
                save_square(super_resolve(original_raw(row['source_image']), sr), destination)
                method = 'FSRCNN_x4_super_resolution' if sr is not None else 'Lanczos_x4_fallback'
                source_url = row['source_image']
                sw, sh = info['source_width'], info['source_height']
            report.append({'product': product, 'file': row['output_file'], 'method': method, 'source_url': source_url, 'source_width': sw, 'source_height': sh})

    summary = {
        'replaced_image_count': len(report),
        'alternate_source_count': sum(x['method'] == 'alternate_high_resolution_source' for x in report),
        'super_resolution_count': sum('super_resolution' in x['method'] for x in report),
        'items': report,
    }
    (OUT / 'low_resolution_replacement_report.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    rebuild_zip()
    print(json.dumps({k: v for k, v in summary.items() if k != 'items'}, indent=2))
    if len(report) != len(low_rows):
        sys.exit(2)


if __name__ == '__main__':
    main()
