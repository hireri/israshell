#!/usr/bin/env python3.14
"""
finds the least busy wallpaper region for the clock widget

Usage:
leastbusy.py <image> --monitor NAME:WxH [--monitor NAME:WxH ...] [--clock-w N] [--clock-h N] [--visualize]

Output (stdout, one line per monitor):
DP-2=1847,112
HDMI-A-1=920,56

Coordinates are the **center** of the clock widget in screen space.
"""

import argparse
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, laplace

_SCALE = 0.25


def busyness_map(gray_f: np.ndarray, sigma: float = 2.0) -> np.ndarray:
    edges = np.abs(laplace(gaussian_filter(gray_f, sigma)))
    mean = gaussian_filter(gray_f,    sigma * 4)
    mean2 = gaussian_filter(gray_f**2, sigma * 4)
    var = np.clip(mean2 - mean**2, 0, None)
    raw = edges + np.sqrt(var)
    s = gaussian_filter(raw, sigma * 3)
    return (s - s.min()) / (s.max() - s.min() + 1e-8)


def penalty_mask(h: int, w: int, edge_margin: float = 0.13, center_radius: float = 0.18) -> np.ndarray:
    ys = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    xs = np.linspace(0, 1, w, dtype=np.float32)[None, :]
    edge = np.minimum(np.minimum(xs, 1-xs), np.minimum(ys, 1-ys))
    dist_c = np.sqrt((ys-0.5)**2 + (xs-0.5)**2)
    p = np.where(edge < edge_margin, (edge_margin - edge) /
                 edge_margin * 3, 0.0).astype(np.float32)
    p += np.exp(-0.5 * (dist_c / (center_radius * 0.5))
                ** 2).astype(np.float32) * 1.5
    return p


def score_image(image_path, brightness_weight: float = 0.5, mode: str = "dark"):
    img = Image.open(image_path).convert("L")
    orig_w, orig_h = img.size
    small_w = max(1, int(orig_w * _SCALE))
    small_h = max(1, int(orig_h * _SCALE))
    small = img.resize((small_w, small_h), Image.BOX)

    gray_f = np.array(small, dtype=np.float32)
    norm_gray = gray_f / 255.0

    busyness = busyness_map(gray_f)
    geometry = penalty_mask(small_h, small_w)

    if mode == "dark":
        brightness_penalty = norm_gray * brightness_weight
    else:
        brightness_penalty = (1.0 - norm_gray) * brightness_weight

    scores = busyness + geometry + brightness_penalty

    integ = scores.cumsum(axis=0).cumsum(axis=1)
    pad = np.zeros((small_h + 1, small_w + 1), dtype=np.float32)
    pad[1:, 1:] = integ

    return small_w, small_h, scores, pad


def best_center(pad, small_w, small_h, screen_w, screen_h, clock_w, clock_h):
    box_w = max(1, int(clock_w * small_w / screen_w))
    box_h = max(1, int(clock_h * small_h / screen_h))
    r_end = small_h - box_h + 1
    c_end = small_w - box_w + 1
    wins = (pad[box_h:box_h+r_end, box_w:box_w+c_end]
            - pad[0:r_end,           box_w:box_w+c_end]
            - pad[box_h:box_h+r_end, 0:c_end]
            + pad[0:r_end,           0:c_end])
    br, bc = np.unravel_index(wins.argmin(), wins.shape)
    cx = int((bc + box_w / 2) / small_w * screen_w)
    cy = int((br + box_h / 2) / small_h * screen_h)
    return cx, cy


def _debug(image_path, scores, small_w, small_h, results, clock_w, clock_h):
    try:
        import matplotlib.pyplot as plt
        import matplotlib.patches as patches
    except ImportError:
        print("# visualize requires matplotlib", file=sys.stderr)
        return
    img = Image.open(image_path).convert(
        "RGB").resize((small_w, small_h), Image.BOX)
    box_w = max(1, int(clock_w * small_w / results[0][2]))
    box_h = max(1, int(clock_h * small_h / results[0][3]))
    fig, ax = plt.subplots(1, 2, figsize=(14, 5))
    fig.suptitle("Clock placement thing chart")
    ax[0].imshow(img)
    ax[0].set_title("Original")
    ax[0].axis("off")
    ax[1].imshow(img, alpha=0.55)
    ax[1].imshow(scores, cmap="hot", alpha=0.45)
    for name, cx_s, sw, sh in results:
        cx_s2 = int(cx_s / sw * small_w)
        cy_s2 = int(results[0][1] / sh * small_h)
        ax[1].add_patch(patches.Rectangle((cx_s2 - box_w//2, cy_s2 - box_h//2),
                        box_w, box_h, lw=2, edgecolor="cyan", facecolor="none"))
        ax[1].annotate(name, (cx_s2, cy_s2), color="cyan",
                       fontsize=8, ha="center")
    ax[1].set_title("Score + spots")
    ax[1].axis("off")
    out = Path(image_path).with_suffix(".clock_debug.png")
    plt.tight_layout()
    plt.savefig(out, dpi=120, bbox_inches="tight")
    plt.close(fig)
    print(f"# debug 👉 {out}", file=sys.stderr)


def get_monitors():
    """Returns [(name, width, height), ...] from hyprctl monitors"""
    import subprocess
    import re
    try:
        out = subprocess.check_output(["hyprctl", "monitors"], text=True)
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        print(f"error: hyprctl failed: {e}", file=sys.stderr)
        sys.exit(1)
    monitors = []
    current_name = None
    for line in out.splitlines():
        m = re.match(r"^Monitor (\S+) \(ID \d+\):", line)
        if m:
            current_name = m.group(1)
            continue
        if current_name:
            m = re.search(r"(\d+)x(\d+)(?:@[\d.]+)?\s+at\s+", line)
            if m:
                monitors.append(
                    (current_name, int(m.group(1)), int(m.group(2))))
                current_name = None
    if not monitors:
        print("error: no monitors found via hyprctl", file=sys.stderr)
        sys.exit(1)
    return monitors


def main():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("image")
    p.add_argument("--monitor", metavar="NAME:WxH", action="append",
                   help="Override monitor list (NAME:WxH). Defaults to hyprctl monitors.")
    p.add_argument("--clock-w", type=int, default=200)
    p.add_argument("--clock-h", type=int, default=80)
    p.add_argument("--visualize", action="store_true")
    p.add_argument("--mode", choices=["dark", "light"], default="dark",
                   help="Mode: 'dark' avoids bright spots, 'light' avoids dark spots.")
    p.add_argument("--brightness-weight", type=float, default=0.5,
                   help="Intensity of the brightness penalty (default 0.5)")

    a = p.parse_args()

    if not Path(a.image).exists():
        print(f"error: file not found: {a.image}", file=sys.stderr)
        sys.exit(1)

    if a.monitor:
        monitors = []
        for mon in a.monitor:
            try:
                name, res = mon.split(":")
                sw, sh = map(int, res.lower().split("x"))
                monitors.append((name, sw, sh))
            except ValueError:
                print(
                    f"error: bad monitor spec '{mon}', expected NAME:WxH", file=sys.stderr)
                sys.exit(1)
    else:
        monitors = get_monitors()

    small_w, small_h, scores, pad = score_image(
        a.image, a.brightness_weight, a.mode)

    debug_results = []
    for name, sw, sh in monitors:
        cx, cy = best_center(pad, small_w, small_h, sw,
                             sh, a.clock_w, a.clock_h)
        print(f"{name}={cx},{cy}")
        debug_results.append((name, cx, sw, sh))

    if a.visualize:
        _debug(a.image, scores, small_w, small_h,
               debug_results, a.clock_w, a.clock_h)


if __name__ == "__main__":
    main()
