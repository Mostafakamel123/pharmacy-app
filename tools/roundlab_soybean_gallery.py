from __future__ import annotations

import csv
import io
import json
import zipfile
from pathlib import Path

import requests
from PIL import Image, ImageOps

OUT = Path('roundlab_output')
FOLDER = OUT / 'ROUND LAB Soybean Nourishing Serum 50ml'

IMAGES = [
    ('https://www.lamourlife.com/cdn/shop/files/RoundLabSoybeanSerum50mL1.png?v=1723061087&width=1500', 'Deep Nourishment'),
    ('https://www.lamourlife.com/cdn/shop/files/RoundLabSoybeanSerum50mL2.png?v=1723061087&width=1500', 'Barrier Support'),
    ('https://www.lamourlife.com/cdn/shop/files/RoundLabSoybeanSerum50mL3.png?v=1723061087&width=1500', 'Smooth Elasticity'),
    ('https://www.lamourlife.com/cdn/shop/files/RoundLabSoybeanSerum50mL4.png?v=1723061087&width=1500', 'Rich Hydration'),
]

session = requests.Session()
session.headers.update({
    'User-Agent': 'Mozilla/5.0 Chrome/131 Safari/537.36',
    'Referer': 'https://www.lamourlife.com/products/round-lab-soybean-serum-50ml',
})


def save_webp(raw: bytes, destination: Path) -> tuple[int, int]:
    with Image.open(io.BytesIO(raw)) as image:
        image = ImageOps.exif_transpose(image)
        source_size = image.size
        if image.mode == 'RGBA':
            background = Image.new('RGB', image.size, 'white')
            background.paste(image, mask=image.getchannel('A'))
            image = background
        else:
            image = image.convert('RGB')

        # Gallery sources are square 1500px. Resize proportionally without stretching.
        result = ImageOps.fit(
            image,
            (1200, 1200),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )
        destination.parent.mkdir(parents=True, exist_ok=True)
        result.save(destination, 'WEBP', quality=96, method=6)
        return source_size


def main() -> None:
    FOLDER.mkdir(parents=True, exist_ok=True)
    rows = []
    for url, benefit in IMAGES:
        response = session.get(url, timeout=60)
        response.raise_for_status()
        if len(response.content) < 10_000:
            raise RuntimeError(f'Unexpectedly small image: {url}')
        filename = f'ROUND LAB Soybean Nourishing Serum 50ml - {benefit}.webp'
        source_width, source_height = save_webp(response.content, FOLDER / filename)
        rows.append({
            'product': 'ROUND LAB Soybean Nourishing Serum 50ml',
            'benefit': benefit,
            'filename': filename,
            'source_url': url,
            'source_width': source_width,
            'source_height': source_height,
            'output_width': 1200,
            'output_height': 1200,
        })

    with (FOLDER / 'manifest.csv').open('w', newline='', encoding='utf-8-sig') as file:
        writer = csv.DictWriter(file, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    report = {
        'product': 'ROUND LAB Soybean Nourishing Serum 50ml',
        'image_count': len(rows),
        'format': 'WebP',
        'output_size': '1200x1200',
        'source_sizes': [[r['source_width'], r['source_height']] for r in rows],
    }
    (FOLDER / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')

    zip_path = OUT / 'ROUND_LAB_Soybean_Nourishing_Serum_50ml_gallery.zip'
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in FOLDER.rglob('*'):
            if path.is_file():
                archive.write(path, FOLDER.name / path.relative_to(FOLDER))

    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
