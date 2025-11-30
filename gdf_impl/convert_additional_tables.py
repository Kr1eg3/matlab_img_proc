#!/usr/bin/env python3
"""
Convert additional GDF lookup tables from C++ format to MATLAB functions
"""

import re

def parse_cpp_array(text):
    """Parse C++ array initialization and extract numbers"""
    # Remove comments
    text = re.sub(r'//.*?\n', ' ', text)
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.DOTALL)
    # Remove all whitespace and newlines
    text = re.sub(r'\s+', ' ', text)
    # Extract all numbers (including negative)
    numbers = re.findall(r'-?\d+', text)
    return [int(n) for n in numbers]

def convert_gdf_bias():
    """Convert Gdf_Bias[6][6][3] table"""
    print("Converting Gdf_Bias table...")

    with open('gdf_bias_raw.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    numbers = parse_cpp_array(content)
    expected_size = 6 * 6 * 3
    print(f"Extracted {len(numbers)} numbers (expected {expected_size})")

    if len(numbers) != expected_size:
        numbers = numbers[:expected_size]

    with open('Gdf_Bias.m', 'w') as f:
        f.write("function bias = Gdf_Bias()\n")
        f.write("% Gdf_Bias - Returns GDF Bias lookup table\n")
        f.write("% Shape: 6 x 6 x 3\n\n")
        f.write("    bias = zeros(6, 6, 3, 'int32');\n\n")

        idx = 0
        for i in range(6):
            for j in range(6):
                f.write(f"    bias({i+1},{j+1},:) = [{numbers[idx]}, {numbers[idx+1]}, {numbers[idx+2]}];\n")
                idx += 3

        f.write("end\n")

    print(f"Saved Gdf_Bias.m")

def convert_gdf_alpha():
    """Convert Gdf_Alpha[6][6][22][4] table"""
    print("\nConverting Gdf_Alpha table...")

    with open('gdf_alpha_raw.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    numbers = parse_cpp_array(content)
    expected_size = 6 * 6 * 22 * 4
    print(f"Extracted {len(numbers)} numbers (expected {expected_size})")

    if len(numbers) != expected_size:
        numbers = numbers[:expected_size]

    with open('Gdf_Alpha.m', 'w') as f:
        f.write("function alpha = Gdf_Alpha()\n")
        f.write("% Gdf_Alpha - Returns GDF Alpha lookup table\n")
        f.write("% Shape: 6 x 6 x 22 x 4\n\n")
        f.write("    alpha = zeros(6, 6, 22, 4, 'int32');\n\n")

        idx = 0
        for i in range(6):
            for j in range(6):
                for k in range(22):
                    f.write(f"    alpha({i+1},{j+1},{k+1},:) = [")
                    f.write(f"{numbers[idx]}, {numbers[idx+1]}, {numbers[idx+2]}, {numbers[idx+3]}];\n")
                    idx += 4

        f.write("end\n")

    print(f"Saved Gdf_Alpha.m")

def convert_gdf_weight():
    """Convert Gdf_Weight[6][6][3][22][4] table"""
    print("\nConverting Gdf_Weight table...")

    with open('gdf_weight_raw.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    numbers = parse_cpp_array(content)
    expected_size = 6 * 6 * 3 * 22 * 4
    print(f"Extracted {len(numbers)} numbers (expected {expected_size})")

    if len(numbers) != expected_size:
        numbers = numbers[:expected_size]

    with open('Gdf_Weight.m', 'w') as f:
        f.write("function weight = Gdf_Weight()\n")
        f.write("% Gdf_Weight - Returns GDF Weight lookup table\n")
        f.write("% Shape: 6 x 6 x 3 x 22 x 4\n\n")
        f.write("    weight = zeros(6, 6, 3, 22, 4, 'int32');\n\n")

        idx = 0
        for i in range(6):
            for j in range(6):
                for k in range(3):
                    for m in range(22):
                        f.write(f"    weight({i+1},{j+1},{k+1},{m+1},:) = [")
                        f.write(f"{numbers[idx]}, {numbers[idx+1]}, {numbers[idx+2]}, {numbers[idx+3]}];\n")
                        idx += 4

        f.write("end\n")

    print(f"Saved Gdf_Weight.m")

if __name__ == '__main__':
    try:
        convert_gdf_bias()
        convert_gdf_alpha()
        convert_gdf_weight()
        print("\nConversion complete!")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
