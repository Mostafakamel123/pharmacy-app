from __future__ import annotations

import io
import json
import zipfile
from pathlib import Path

import requests
from PIL import Image, ImageOps

BASE = Path(__file__).resolve().parent
OUT = BASE / 'OUTPUT'
ROOT = OUT / 'Medicube_missing_products'
S = requests.Session()
S.headers.update({'User-Agent': 'Mozilla/5.0 Chrome/131 Safari/537.36'})

FIXES = [
    {
        'file': ROOT / 'Medicube Rosemary PDRN Scalp Serum' / 'Medicube Rosemary PDRN Scalp Serum - How To Use.webp',
        'candidates': [
            'https://niasha.ch/cdn/shop/files/MEDICUBERosemaryPDRNScalpSerum-02.png?v=1781025114',
            'https://niasha.ch/cdn/shop/files/MEDICUBERosemaryPDRNScalpSerum-03.png?v=1781025115',
            'https://niasha.ch/cdn/shop/files/MEDICUBERosemaryPDRNScalpSerum-00.png?v=1781025113',
            'https://niasha.ch/cdn/shop/files/MEDICUBERosemaryPDRNScalpSerum-02_490x510_crop_center.png?v=1781025114',
        ],
        'referer': 'https://niasha.ch/products/rosemary-pdrn-scalp-serum',
    },
    {
        'file': ROOT / 'Medicube Zero Foam Cleanser' / 'Medicube Zero Foam Cleanser - Gentle Cleansing.webp',
        'candidates': [
            'https://pharmazone.com/cdn/shop/files/55553-MedicubeZeroFoamCleanser120g_8_1800x1800.webp?v=1770755779',
            'https://pharmazone.com/cdn/shop/files/55553-MedicubeZeroFoamCleanser120g_6_1800x1800.webp?v=1770755783',
            'https://pharmazone.com/cdn/shop/files/55553-MedicubeZeroFoamCleanser120g_5_1800x1800.webp?v=1770755788',
        ],
        'referer': 'https://pharmazone.com/products/medicube-zero-foam-cleanser-120g',
    },
]


def fetch_best(item: dict):
    choices = []
    errors = []
    for url in item['candidates']:
        try:
            response = S.get(url, timeout=45, headers={'Referer': item['referer']})
            response.raise_for_status()
            raw = response.content
            with Image.open(io.BytesIO(raw)) as image:
                width, height = image.size
                image.verify()
            if min(width, height) < 450:
                raise ValueError(f'too small: {width}x{height}')
            choices.append((width * height, len(raw), width, height, url, raw))
        except Exception as exc:
            errors.append(f'{url}: {exc}')
    if not choices:
        raise RuntimeError(' | '.join(errors))
    choices.sort(reverse=True)
    return choices[0]


def save_square(raw: bytes, destination: Path):
    with Image.open(io.BytesIO(raw)) as image:
        image = ImageOps.exif_transpose(image)
        if image.mode == 'RGBA':
            bg = Image.new('RGB', image.size, 'white')
            bg.paste(image, mask=image.getchannel('A'))
            image = bg
        else:
            image = image.convert('RGB')
        result = ImageOps.fit(image, (1200, 1200), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
        result.save(destination, 'WEBP', quality=96, method=6)


def rebuild_zip():
    target = OUT / 'Medicube_missing_25_actual_images.zip'
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for file_path in ROOT.rglob('*'):
            if file_path.is_file():
                archive.write(file_path, Path(ROOT.name) / file_path.relative_to(ROOT))


def main():
    report = []
    for item in FIXES:
        area, byte_count, width, height, url, raw = fetch_best(item)
        save_square(raw, item['file'])
        report.append({
            'file': str(item['file'].relative_to(ROOT)),
            'source_url': url,
            'source_width': width,
            'source_height': height,
            'source_bytes': byte_count,
        })
        print('FIXED', item['file'].name, width, height, url)
    (OUT / 'two_wrong_images_fix_report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    rebuild_zip()


if __name__ == '__main__':
    main()
