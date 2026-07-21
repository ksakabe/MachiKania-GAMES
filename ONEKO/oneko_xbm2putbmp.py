#!/usr/bin/env python3
"""
oneko_xbm2putbmp.py

oneko系のXBMビットマップとXBMマスクを組み合わせ、
KM-BASICのPUTBMPで使用する8ビット/ピクセル形式のBINファイルを生成する。

出力BIN形式:
    offset 0-1 : 幅  (uint16 little-endian)
    offset 2-3 : 高さ(uint16 little-endian)
    offset 4-  : 1ピクセル1バイトのパレット番号（左上から行優先）

画素変換:
    mask=0              -> 0（透明）
    mask=1, bitmap=0    -> --fill で指定した色
    mask=1, bitmap=1    -> --ink で指定した色

KM-BASICでは先頭4バイトをFGETC()で読み、その後の width*height
バイトだけを配列へFGET()してPUTBMPに渡す。
"""

from __future__ import annotations

import argparse
import re
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class XbmImage:
    """展開済みXBM画像。pixelsは0または1を行優先で保持する。"""

    width: int
    height: int
    pixels: tuple[int, ...]


# キー:
#   ビットマップ側のディレクトリ名
#
# 値:
#   (
#       出力ディレクトリ名,
#       ビットマップ側の接尾辞,
#       マスク側のディレクトリ名,
#       マスク側の接尾辞,
#   )
#
# TORAだけはbitmasks/nekoのマスクを使用する。
CHARACTER_SETS = {
    "bsd": (
        "BSD",
        "_bsd",
        "bsd",
        "_bsd",
    ),
    "dog": (
        "DOG",
        "_dog",
        "dog",
        "_dog",
    ),
    "neko": (
        "ONEKO",
        "",
        "neko",
        "",
    ),
    "sakura": (
        "SAKURA",
        "_sakura",
        "sakura",
        "_sakura",
    ),
    "tomoyo": (
        "TOMOYO",
        "_tomoyo",
        "tomoyo",
        "_tomoyo",
    ),

    # TORAの画像にはNEKOのマスクを使用する
    "tora": (
        "TORA",
        "_tora",
        "neko",
        "",
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="XBMビットマップとマスクからKM-BASIC PUTBMP用BINを一括生成します。"
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=".",
        help="bitmaps、bitmasks、cursorsが存在するルートディレクトリ（既定: .）",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="output",
        help="出力ルートディレクトリ（既定: output）",
    )
    parser.add_argument(
        "--ink",
        type=int,
        default=8,
        help="XBMビットが1の画素に使うパレット番号（既定: 8）",
    )
    parser.add_argument(
        "--fill",
        type=int,
        default=7,
        help="マスク内でXBMビットが0の画素に使うパレット番号（既定: 7）",
    )
    parser.add_argument(
        "--missing-mask",
        choices=("error", "skip", "bitmap"),
        default="skip",
        help=(
            "マスクがない場合の処理。"
            "error=即時終了、skip=警告して省略、bitmap=ビットマップ自身をマスクとして使用 "
            "（既定: skip）"
        ),
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="既存のBINファイルを上書きする",
    )
    return parser.parse_args()


def validate_palette(value: int, option_name: str) -> None:
    """PUTBMPの1バイトパレット番号として妥当か確認する。"""

    if not 0 <= value <= 255:
        raise ValueError(f"{option_name} は0～255で指定してください: {value}")
    if value == 0:
        print(
            f"警告: {option_name}=0 はPUTBMPでは透明色として扱われます。",
            file=sys.stderr,
        )


def read_text_safely(path: Path) -> str:
    """XBMテキストを読み込む。想定外に巨大なファイルは拒否する。"""

    # XBM画像として異常に大きいファイルを誤って読むことを防ぐ。
    max_size = 16 * 1024 * 1024
    size = path.stat().st_size
    if size > max_size:
        raise ValueError(f"ファイルが大きすぎます（上限16MiB）: {path}")

    return path.read_text(encoding="ascii", errors="strict")


def parse_xbm(path: Path) -> XbmImage:
    """XBMから幅、高さ、ビット列を読み取り、画素単位へ展開する。"""

    text = read_text_safely(path)

    width_match = re.search(r"#define\s+\w+_width\s+(\d+)", text)
    height_match = re.search(r"#define\s+\w+_height\s+(\d+)", text)

    if width_match is None or height_match is None:
        raise ValueError(f"widthまたはheight定義が見つかりません: {path}")

    width = int(width_match.group(1))
    height = int(height_match.group(1))

    if width <= 0 or height <= 0:
        raise ValueError(f"幅または高さが不正です: {path}: {width}x{height}")
    if width > 65535 or height > 65535:
        raise ValueError(f"BINヘッダーに格納できない寸法です: {path}: {width}x{height}")

    # 配列初期化子だけを対象にし、define等に含まれる16進数を誤取得しない。
    body_match = re.search(r"\{(?P<body>.*?)\}", text, flags=re.DOTALL)
    if body_match is None:
        raise ValueError(f"XBMデータ配列が見つかりません: {path}")

    values = [
        int(token, 16)
        for token in re.findall(r"0[xX]([0-9a-fA-F]+)", body_match.group("body"))
    ]

    bytes_per_row = (width + 7) // 8
    expected_bytes = bytes_per_row * height

    if len(values) < expected_bytes:
        raise ValueError(
            f"XBMデータ不足: {path}: 必要{expected_bytes}バイト、実際{len(values)}バイト"
        )
    if any(value > 0xFF for value in values[:expected_bytes]):
        raise ValueError(
            f"8ビットXBM以外のデータが含まれています: {path}"
        )

    # XBMは各バイトのLSBが左側の画素。
    pixels: list[int] = []
    for y in range(height):
        row_base = y * bytes_per_row
        for x in range(width):
            byte_value = values[row_base + x // 8]
            pixels.append((byte_value >> (x % 8)) & 1)

    return XbmImage(width, height, tuple(pixels))


def combine_bitmap_and_mask(
    bitmap: XbmImage,
    mask: XbmImage,
    ink_color: int,
    fill_color: int,
) -> bytes:
    """ビットマップとマスクをPUTBMP用パレット番号列へ変換する。"""

    if bitmap.width != mask.width or bitmap.height != mask.height:
        raise ValueError(
            "ビットマップとマスクの寸法が一致しません: "
            f"bitmap={bitmap.width}x{bitmap.height}, "
            f"mask={mask.width}x{mask.height}"
        )

    output = bytearray(bitmap.width * bitmap.height)

    for index, (bitmap_bit, mask_bit) in enumerate(
        zip(bitmap.pixels, mask.pixels, strict=True)
    ):
        if mask_bit == 0:
            output[index] = 0
        elif bitmap_bit:
            output[index] = ink_color
        else:
            output[index] = fill_color

    return bytes(output)


def normalized_stem(path: Path, suffix: str) -> str:
    """awake_bsd.xbm等からawakeを得る。"""

    stem = path.stem
    if suffix and stem.endswith(suffix):
        stem = stem[: -len(suffix)]
    return stem


def write_bin(
    output_path: Path,
    width: int,
    height: int,
    pixel_data: bytes,
    overwrite: bool,
) -> None:
    """寸法ヘッダー付きBINを安全に書き込む。"""

    expected_size = width * height
    if len(pixel_data) != expected_size:
        raise ValueError(
            f"画素数が一致しません: expected={expected_size}, actual={len(pixel_data)}"
        )

    if output_path.exists() and not overwrite:
        raise FileExistsError(
            f"出力ファイルが既にあります。--overwriteを指定してください: {output_path}"
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)

    # 一時ファイルへ書いてから置換し、中断時の破損ファイルを残しにくくする。
    temp_path = output_path.with_suffix(output_path.suffix + ".tmp")
    try:
        with temp_path.open("wb") as file:
            file.write(struct.pack("<HH", width, height))
            file.write(pixel_data)
        temp_path.replace(output_path)
    finally:
        if temp_path.exists():
            temp_path.unlink()


def resolve_mask(
    bitmap_path: Path,
    mask_path: Path,
    missing_policy: str,
) -> XbmImage | None:
    """マスクを読み込む。未存在時は指定ポリシーに従う。"""

    if mask_path.is_file():
        return parse_xbm(mask_path)

    message = f"マスクがありません: bitmap={bitmap_path}, expected={mask_path}"

    if missing_policy == "error":
        raise FileNotFoundError(message)
    if missing_policy == "skip":
        print(f"警告: {message}（スキップ）", file=sys.stderr)
        return None

    # bitmap自身をマスクにすると、bitmap=1の画素だけが表示される。
    print(
        f"警告: {message}（ビットマップ自身をマスクとして使用）",
        file=sys.stderr,
    )
    return parse_xbm(bitmap_path)


def process_character_set(
    root: Path,
    output_root: Path,
    source_name: str,
    output_name: str,
    suffix: str,
    mask_source_name: str,
    mask_suffix: str,
    ink_color: int,
    fill_color: int,
    missing_policy: str,
    overwrite: bool,
) -> tuple[int, int]:
    """キャラクターディレクトリ1組を処理する。"""

    bitmap_dir = root / "bitmaps" / source_name
    # マスク側はビットマップ側とは独立して指定する。
    # TORAの場合、mask_source_nameは"neko"になる。
    mask_dir = root / "bitmasks" / mask_source_name
    output_dir = output_root / output_name

    output_dir.mkdir(parents=True, exist_ok=True)

    if not bitmap_dir.is_dir():
        print(f"警告: ビットマップディレクトリがありません: {bitmap_dir}", file=sys.stderr)
        return 0, 0

    converted = 0
    skipped = 0

    # 直下だけを対象にし、dog/jl4l等の別セットを混在させない。
    for bitmap_path in sorted(bitmap_dir.glob("*.xbm")):
        base_name = normalized_stem(bitmap_path, suffix)

        # ビットマップ側とマスク側で接尾辞が異なる場合に対応する。
        #
        # 例:
        #   TORA画像:
        #       awake_tora.xbm
        #
        #   base_name:
        #       awake
        #
        #   NEKOマスク:
        #       awake_mask.xbm
        mask_filename = (
            f"{base_name}{mask_suffix}_mask.xbm"
            if mask_suffix
            else f"{base_name}_mask.xbm"
        )

        mask_path = mask_dir / mask_filename

        mask = resolve_mask(bitmap_path, mask_path, missing_policy)
        if mask is None:
            skipped += 1
            continue

        bitmap = parse_xbm(bitmap_path)
        pixels = combine_bitmap_and_mask(bitmap, mask, ink_color, fill_color)
        output_path = output_dir / f"{base_name}.bin"

        write_bin(
            output_path,
            bitmap.width,
            bitmap.height,
            pixels,
            overwrite,
        )

        print(
            f"生成: {output_path} "
            f"({bitmap.width}x{bitmap.height}, {len(pixels) + 4} bytes)"
        )
        converted += 1

    return converted, skipped


def process_cursors(
    root: Path,
    output_root: Path,
    ink_color: int,
    fill_color: int,
    missing_policy: str,
    overwrite: bool,
) -> tuple[int, int]:
    """cursors配下のカーソル画像を処理する。"""

    cursor_dir = root / "cursors"
    output_dir = output_root / "CURSOR"
    output_dir.mkdir(parents=True, exist_ok=True)

    if not cursor_dir.is_dir():
        print(f"警告: カーソルディレクトリがありません: {cursor_dir}", file=sys.stderr)
        return 0, 0

    converted = 0
    skipped = 0

    # *_mask.xbmは入力ビットマップとして処理しない。
    for bitmap_path in sorted(cursor_dir.glob("*.xbm")):
        if bitmap_path.stem.endswith("_mask"):
            continue

        # "_cursor"を取り除いた名前を出力ファイル名に使用する
        base_name = bitmap_path.stem
        
        if base_name.endswith("_cursor"):
            output_name = base_name[:-7]      # "_cursor"を削除
        else:
            output_name = base_name

        # マスクファイル名は元のファイル名を使用する
        mask_path = cursor_dir / f"{base_name}_mask.xbm"
        mask = resolve_mask(bitmap_path, mask_path, missing_policy)
        if mask is None:
            skipped += 1
            continue

        bitmap = parse_xbm(bitmap_path)
        pixels = combine_bitmap_and_mask(bitmap, mask, fill_color, ink_color)
        output_path = output_dir / f"{output_name}.bin"

        write_bin(
            output_path,
            bitmap.width,
            bitmap.height,
            pixels,
            overwrite,
        )

        print(
            f"生成: {output_path} "
            f"({bitmap.width}x{bitmap.height}, {len(pixels) + 4} bytes)"
        )
        converted += 1

    return converted, skipped


def main() -> int:
    args = parse_args()

    try:
        validate_palette(args.ink, "--ink")
        validate_palette(args.fill, "--fill")

        root = Path(args.root).expanduser().resolve()
        output_root = Path(args.output).expanduser().resolve()

        if not root.is_dir():
            raise NotADirectoryError(f"入力ルートがありません: {root}")

        # 入力ディレクトリ内部への誤出力も可能だが、入力XBMを上書きする名前にはしない。
        output_root.mkdir(parents=True, exist_ok=True)

        total_converted = 0
        total_skipped = 0

        for source_name, (
                output_name,
                suffix,
                mask_source_name,
                mask_suffix,
        ) in CHARACTER_SETS.items():

            converted, skipped = process_character_set(
                root=root,
                output_root=output_root,
                source_name=source_name,
                output_name=output_name,
                suffix=suffix,
                mask_source_name=mask_source_name,
                mask_suffix=mask_suffix,
                ink_color=args.ink,
                fill_color=args.fill,
                missing_policy=args.missing_mask,
                overwrite=args.overwrite,
            )
            total_converted += converted
            total_skipped += skipped

        converted, skipped = process_cursors(
            root=root,
            output_root=output_root,
            ink_color=args.ink,
            fill_color=args.fill,
            missing_policy=args.missing_mask,
            overwrite=args.overwrite,
        )
        total_converted += converted
        total_skipped += skipped

        print(
            f"完了: 生成={total_converted}, スキップ={total_skipped}, "
            f"出力先={output_root}"
        )
        return 0

    except (OSError, ValueError) as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
