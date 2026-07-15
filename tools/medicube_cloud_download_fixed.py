from __future__ import annotations
import io
from pathlib import Path
from PIL import Image, ImageOps
import medicube_cloud_download as original


def to_webp_fill(raw: bytes, dest: Path) -> None:
    """Resize the real source image to fill 1200x1200 without distortion."""
    with Image.open(io.BytesIO(raw)) as im:
        im = ImageOps.exif_transpose(im)
        if im.mode == 'RGBA':
            bg = Image.new('RGB', im.size, 'white')
            bg.paste(im, mask=im.getchannel('A'))
            im = bg
        else:
            im = im.convert('RGB')

        # Scale proportionally and crop only the overflow. This prevents a
        # 300x300 source from being pasted as a tiny square on a 1200 canvas.
        result = ImageOps.fit(
            im,
            (1200, 1200),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        result.save(dest, 'WEBP', quality=90, method=6)


original.to_webp = to_webp_fill

if __name__ == '__main__':
    original.main()
