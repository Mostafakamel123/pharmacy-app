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

REPLACEMENTS = [
    {
        'file': ROOT / 'Medicube Red Moisture Real Sun Cream' / 'Medicube Red Moisture Real Sun Cream - Product Hero.webp',
        'urls': [
            'https://coscorea.com/cdn/shop/products/MedicubeRedMoistureRealSunCream50ml_1800x1800.jpg?v=1665156093',
            'https://coscorea.com/cdn/shop/products/MEDICUBERedMoistureRealSunCream50ml_1_1800x1800.jpg?v=1665156094',
        ],
        'referer': 'https://coscorea.com/products/medicube-red-moisture-real-sun-cream-50ml-spf50-pa',
    },
    {
        'file': ROOT / 'Medicube PDRN Pink One Day Serum Set' / 'Medicube PDRN Pink One Day Serum Set - Product Hero.webp',
        'urls': [
            'https://saranghae.ch/cdn/shop/files/pdrnpinkonedayset.webp?v=1768383321&width=1500',
            'https://saranghae.ch/cdn/shop/files/PDRNPinkOneDaySerumSet_50g_2.webp?v=1768383321&width=1500',
        ],
        'referer': 'https://saranghae.ch/products/medicube-pdrn-pink-one-day-serum-set',
    },
    {
        'file': ROOT / 'Medicube AGE-R Glutathione Glow Toner' / 'Medicube AGE-R Glutathione Glow Toner - Product Hero.webp',
        'urls': [
            'https://future.com.kw/cdn/shop/files/SC-00015203-2.jpg?crop=center&height=1200&v=1766215001&width=1200',
            'https://future.com.kw/cdn/shop/files/SC-00015203-1_1.jpg?v=1766215001&width=1200',
        ],
        'referer': 'https://future.com.kw/products/medicube-age-r-glutathione-glow-toner-140ml',
    },
    {
        'file': ROOT / 'Medicube Azelaic Acid Calming Serum Mask' / 'Medicube Azelaic Acid Calming Serum Mask - Product Hero.webp',
        'urls': [
            'https://www.plazastyle.com/img/goods/L/p02msk0205_l.jpg',
        ],
        'referer': 'https://www.plazastyle.com/shop/g/g8800289478949/',
    },
]


def fetch_best(item):
    choices = []
    errors = []
    for url in item['urls']:
        try:
            response = S.get(url, timeout=50, headers={'Referer': item['referer']})
            response.raise_for_status()
            raw = response.content
            if len(raw) < 5000:
                raise ValueError('response too small')
            with Image.open(io.BytesIO(raw)) as image:
                width, height = image.size
                image.verify()
            if min(width, height) < 700:
                raise ValueError(f'not high resolution: {width}x{height}')
            choices.append((width * height, len(raw), width, height, url, raw))
        except Exception as exc:
            errors.append(f'{url}: {exc}')
    if not choices:
        raise RuntimeError(' | '.join(errors))
    choices.sort(reverse=True)
    return choices[0]


def save(raw, destination):
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
    with zipfile.ZipFile(OUT / 'Medicube_missing_25_actual_images.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in ROOT.rglob('*'):
            if path.is_file():
                archive.write(path, Path(ROOT.name) / path.relative_to(ROOT))


def main():
    report = []
    for item in REPLACEMENTS:
        _, byte_count, width, height, url, raw = fetch_best(item)
        save(raw, item['file'])
        report.append({
            'file': str(item['file'].relative_to(ROOT)),
            'source_url': url,
            'source_width': width,
            'source_height': height,
            'source_bytes': byte_count,
        })
        print('REPLACED 300PX', item['file'].name, width, height, url)
    (OUT / 'replaced_300px_report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    rebuild_zip()


if __name__ == '__main__':
    main()
