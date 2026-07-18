from pathlib import Path
from collections import deque
from statistics import median

import numpy as np
from PIL import Image


BASE_DIR = Path(__file__).parent
SOURCE = BASE_DIR / "cat.png"
OUTPUT_DIR = BASE_DIR / "sprites"

NAMES = [
    "sleep_01.png",
    "sleep_02.png",
    "yawn_01.png",
    "yawn_02.png",
    "yawn_03.png",

    "stretch_01.png",
    "stretch_02.png",
    "stretch_03.png",
    "stretch_04.png",

    "walk_r_01.png",
    "walk_r_02.png",
    "walk_r_03.png",
    "walk_r_04.png",
    "walk_r_05.png",
    "walk_r_06.png",

    "walk_l_01.png",
    "walk_l_02.png",
    "walk_l_03.png",
    "walk_l_04.png",
    "walk_l_05.png",
    "walk_l_06.png",
]

FLIP_HORIZONTAL = {
    "walk_r_01.png",
    "walk_r_02.png",
    "walk_r_03.png",
    "walk_r_04.png",
    "walk_r_05.png",
    "walk_r_06.png",
}

WALK_NAMES = [name for name in NAMES if name.startswith("walk_")]


def make_mask(img: Image.Image) -> np.ndarray:
    rgba = img.convert("RGBA")
    arr = np.array(rgba)

    alpha = arr[:, :, 3]

    # 투명 배경 PNG면 alpha 기준으로 감지
    if alpha.min() < 250:
        return alpha > 10

    # 투명 배경이 아니고 체크무늬/흰 배경으로 저장된 경우용 fallback
    rgb = arr[:, :, :3].astype(np.int16)
    brightness = rgb.mean(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)

    # 고양이/검은 라벨 포함. 라벨은 나중에 크기 필터로 제외.
    return (brightness < 245) | (saturation > 18)


def connected_components(mask: np.ndarray):
    h, w = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    components = []

    for y in range(h):
        for x in range(w):
            if visited[y, x] or not mask[y, x]:
                continue

            q = deque([(x, y)])
            visited[y, x] = True

            min_x = max_x = x
            min_y = max_y = y
            count = 0

            while q:
                cx, cy = q.popleft()
                count += 1

                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)

                for nx, ny in (
                    (cx + 1, cy),
                    (cx - 1, cy),
                    (cx, cy + 1),
                    (cx, cy - 1),
                ):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if visited[ny, nx] or not mask[ny, nx]:
                        continue

                    visited[ny, nx] = True
                    q.append((nx, ny))

            components.append({
                "box": (min_x, min_y, max_x + 1, max_y + 1),
                "area": count,
                "width": max_x - min_x + 1,
                "height": max_y - min_y + 1,
            })

    return components


def pad_box(box, padding, image_size):
    left, top, right, bottom = box
    width, height = image_size

    return (
        max(0, left - padding),
        max(0, top - padding),
        min(width, right + padding),
        min(height, bottom + padding),
    )


def make_background_transparent(img: Image.Image) -> Image.Image:
    """Remove the near-white background connected to the crop edges."""
    arr = np.array(img.convert("RGBA"))
    rgb = arr[:, :, :3].astype(np.int16)
    brightness = rgb.mean(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)

    # Only near-white, nearly neutral pixels can be background. Flood-filling
    # from the edges prevents enclosed light parts of the cat from disappearing.
    candidate = (brightness >= 235) & (saturation <= 20)
    h, w = candidate.shape
    background = np.zeros_like(candidate, dtype=bool)
    q = deque()

    for x in range(w):
        for y in (0, h - 1):
            if candidate[y, x] and not background[y, x]:
                background[y, x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if candidate[y, x] and not background[y, x]:
                background[y, x] = True
                q.append((x, y))

    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                if candidate[ny, nx] and not background[ny, nx]:
                    background[ny, nx] = True
                    q.append((nx, ny))

    arr[background, 3] = 0
    return Image.fromarray(arr)


def normalize_frames(names, padding=8, match_content_height=False):
    """Normalize subject size and align frames to a shared bottom-centered canvas."""
    images = {name: Image.open(OUTPUT_DIR / name).convert("RGBA") for name in names}
    bounds = {name: image.getchannel("A").getbbox() for name, image in images.items()}
    valid_bounds = [box for box in bounds.values() if box is not None]
    if not valid_bounds:
        return

    target_height = None
    if match_content_height:
        target_height = round(median(box[3] - box[1] for box in valid_bounds))

    contents = {}
    for name, image in images.items():
        box = bounds[name]
        if box is None:
            continue

        content = image.crop(box)
        if target_height is not None and content.height != target_height:
            scale = target_height / content.height
            target_width = max(1, round(content.width * scale))
            content = content.resize(
                (target_width, target_height),
                Image.Resampling.LANCZOS,
            )
        contents[name] = content

    canvas_width = max(content.width for content in contents.values()) + padding * 2
    canvas_height = max(content.height for content in contents.values()) + padding * 2

    for name, content in contents.items():
        x = (canvas_width - content.width) // 2
        y = canvas_height - padding - content.height
        canvas = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
        canvas.alpha_composite(content, (x, y))
        canvas.save(OUTPUT_DIR / name)


def sort_boxes_reading_order(components):
    # 라벨 글자나 작은 점 제거
    cats = [
        c for c in components
        if c["area"] > 2500
        and c["width"] > 80
        and c["height"] > 70
    ]

    # 줄 단위로 묶기
    cats.sort(key=lambda c: c["box"][1])

    rows = []
    for c in cats:
        top = c["box"][1]
        placed = False

        for row in rows:
            row_top = row[0]["box"][1]
            if abs(top - row_top) < 80:
                row.append(c)
                placed = True
                break

        if not placed:
            rows.append([c])

    result = []
    for row in rows:
        row.sort(key=lambda c: c["box"][0])
        result.extend(row)

    return result


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    img = Image.open(SOURCE).convert("RGBA")
    mask = make_mask(img)
    components = connected_components(mask)
    cats = sort_boxes_reading_order(components)

    print(f"found cats: {len(cats)}")

    if len(cats) != len(NAMES):
        print("warning: expected", len(NAMES), "but found", len(cats))
        print("detected boxes:")
        for i, c in enumerate(cats, 1):
            print(i, c["box"], "area=", c["area"])

    for name, component in zip(NAMES, cats):
        box = pad_box(component["box"], padding=8, image_size=img.size)
        sprite = img.crop(box)
        sprite = make_background_transparent(sprite)
        if name in FLIP_HORIZONTAL:
            sprite = sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        sprite.save(OUTPUT_DIR / name)
        print("saved:", OUTPUT_DIR / name)

    normalize_frames(WALK_NAMES, match_content_height=True)
    print("normalized walking frames:", len(WALK_NAMES))


if __name__ == "__main__":
    main()
