#!/usr/bin/env python3
"""
将大型建筑图切割成16×16 tiles
"""

import os

def split_building_to_tiles(input_file, output_dir, building_name, width, height):
    """
    切割大图成多个16×16 tiles

    Args:
        input_file: 输入文件路径 (e.g., eceb.txt)
        output_dir: 输出目录
        building_name: 建筑名称前缀 (e.g., "eceb")
        width: 建筑宽度（pixels）
        height: 建筑高度（pixels）

    Returns:
        生成的tile文件列表 [(tile_x, tile_y, filepath), ...]
    """

    # 读取所有pixels
    print(f"读取 {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        pixels = [line.strip() for line in f if line.strip()]

    if len(pixels) != width * height:
        print(f"错误：期望 {width*height} 个pixels，实际 {len(pixels)}")
        return []

    # 计算tile数量
    tiles_x = width // 16
    tiles_y = height // 16
    print(f"  尺寸：{width}×{height} pixels")
    print(f"  切割为：{tiles_x}×{tiles_y} = {tiles_x * tiles_y} 个tiles")

    os.makedirs(output_dir, exist_ok=True)

    tile_files = []

    # 遍历每个tile
    for tile_y in range(tiles_y):
        for tile_x in range(tiles_x):
            # 提取这个tile的256个pixels
            tile_pixels = []

            for pixel_y in range(16):
                for pixel_x in range(16):
                    # 计算在大图中的坐标
                    big_x = tile_x * 16 + pixel_x
                    big_y = tile_y * 16 + pixel_y

                    # 大图是按行存储的
                    pixel_index = big_y * width + big_x

                    tile_pixels.append(pixels[pixel_index])

            # 写入tile文件
            tile_filename = f"{building_name}_tile_{tile_x}_{tile_y}.txt"
            tile_path = os.path.join(output_dir, tile_filename)

            with open(tile_path, 'w', encoding='utf-8') as f:
                for pixel in tile_pixels:
                    f.write(pixel + '\n')

            tile_files.append((tile_x, tile_y, tile_path))
            print(f"  生成：{tile_filename}")

    return tile_files

def main():
    assets_dir = r"c:\Users\Ziheng Qi\Desktop\385 Final Project\assets\tiles"
    output_dir = os.path.join(assets_dir, "building_tiles")

    print("=" * 60)
    print("开始切割大型建筑...")
    print("=" * 60)

    # ECEB: 128×64
    eceb_tiles = split_building_to_tiles(
        os.path.join(assets_dir, "eceb.txt"),
        output_dir,
        "eceb",
        128, 64
    )

    print()

    # Alma Mater: 64×64
    alma_tiles = split_building_to_tiles(
        os.path.join(assets_dir, "alma_mater.txt"),
        output_dir,
        "alma",
        64, 64
    )

    print()

    # Main Quad: 128×64
    quad_tiles = split_building_to_tiles(
        os.path.join(assets_dir, "main_quad.txt"),
        output_dir,
        "quad",
        128, 64
    )

    print()
    print("=" * 60)
    print("切割完成！")
    print(f"  ECEB: {len(eceb_tiles)} tiles")
    print(f"  Alma Mater: {len(alma_tiles)} tiles")
    print(f"  Main Quad: {len(quad_tiles)} tiles")
    print(f"  总计: {len(eceb_tiles) + len(alma_tiles) + len(quad_tiles)} tiles")
    print(f"  输出目录: {output_dir}")
    print("=" * 60)

    # 计算BRAM需求
    total_tiles = 12 + len(eceb_tiles) + len(alma_tiles) + len(quad_tiles)
    words_needed = total_tiles * 64
    address_bits = (words_needed - 1).bit_length()

    print()
    print("⚠️  BRAM容量需求：")
    print(f"  小tiles: 12")
    print(f"  建筑tiles: {len(eceb_tiles) + len(alma_tiles) + len(quad_tiles)}")
    print(f"  总tiles: {total_tiles}")
    print(f"  需要BRAM: {words_needed} words ({address_bits}-bit地址)")
    print(f"  当前BRAM: 2048 words (11-bit地址)")

    if words_needed > 2048:
        print(f"  ❌ 不够！需要扩展到至少 {2**address_bits} words")
    else:
        print(f"  ✓ 足够！")

if __name__ == "__main__":
    main()
