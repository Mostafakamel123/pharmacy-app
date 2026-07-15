from __future__ import annotations

import io
import json
import re
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from PIL import Image, ImageOps
import medicube_cloud_download as original

SELECTED: dict[str, dict] = {}
LOW_SIZE_SUFFIX = re.compile(r"(?P<stem>.*?)(?:-|_)(?P<w>\d{2,4})x(?P<h>\d{2,4})(?P<ext>\.(?:webp|png|jpe?g))$", re.I)


def clean_query(url: str) -> str:
    parts = urlsplit(url)
    query = [(k, v) for k, v in parse_qsl(parts.query, keep_blank_values=True) if k.lower() not in {'width', 'height', 'crop'}]
    return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), parts.fragment))


def source_candidates(url: str) -> list[str]:
    url = clean_query(url)
    parts = urlsplit(url)
    out: list[str] = []
    match = LOW_SIZE_SUFFIX.match(parts.path)
    if match and max(int(match.group('w')), int(match.group('h'))) <= 800:
        master_path = match.group('stem') + match.group('ext')
        out.append(urlunsplit((parts.scheme, parts.netloc, master_path, parts.query, parts.fragment)))
    out.append(url)
    return list(dict.fromkeys(out))


def download_best(url: str) -> bytes:
    choices = []
    errors = []
    for candidate in source_candidates(url):
        try:
            response = original.S.get(candidate, timeout=60, headers={'Referer': 'https://kstyleseoul.com/'})
            response.raise_for_status()
            raw = response.content
            if len(raw) < 1200:
                raise ValueError('image too small')
            with Image.open(io.BytesIO(raw)) as im:
                im.verify()
            with Image.open(io.BytesIO(raw)) as im:
                width, height = im.size
            choices.append((width * height, len(raw), width, height, candidate, raw))
        except Exception as exc:
            errors.append(f'{candidate}: {exc}')
    if not choices:
        raise RuntimeError(' | '.join(errors))
    choices.sort(reverse=True, key=lambda x: (x[0], x[1]))
    _, byte_count, width, height, selected_url, raw = choices[0]
    SELECTED[url] = {'requested_url': url, 'selected_url': selected_url, 'source_width': width, 'source_height': height, 'source_bytes': byte_count, 'master_recovered': selected_url != clean_query(url)}
    print(f'SOURCE {width}x{height} {selected_url}')
    return raw


def to_webp_high_quality(raw: bytes, dest: Path) -> None:
    with Image.open(io.BytesIO(raw)) as im:
        im = ImageOps.exif_transpose(im)
        if im.mode == 'RGBA':
            bg = Image.new('RGB', im.size, 'white')
            bg.paste(im, mask=im.getchannel('A'))
            im = bg
        else:
            im = im.convert('RGB')
        result = ImageOps.fit(im, (1200, 1200), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
        dest.parent.mkdir(parents=True, exist_ok=True)
        result.save(dest, 'WEBP', quality=96, method=6)

original.download = download_best
original.to_webp = to_webp_high_quality

if __name__ == '__main__':
    original.main()
    (original.OUT / 'source_quality_report.json').write_text(json.dumps({'image_count': len(SELECTED), 'below_800px': [v for v in SELECTED.values() if min(v['source_width'], v['source_height']) < 800], 'sources': list(SELECTED.values())}, ensure_ascii=False, indent=2), encoding='utf-8')
