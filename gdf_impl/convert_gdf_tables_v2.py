#!/usr/bin/env python3
"""
Convert GDF lookup tables from C++ format to MATLAB .m files
Creates function files instead of scripts to avoid naming conflicts
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

def write_matlab_3d_function(filename, data, shape):
    """Write 3D array as MATLAB function"""
    d1, d2, d3 = shape

    with open(filename, 'w') as f:
        f.write("function table = Gdf_Inter_Error()\n")
        f.write("% Gdf_Inter_Error - Returns GDF Inter Error lookup table\n")
        f.write("% Auto-generated from C++ GDF tables\n")
        f.write("% Shape: 5 x 6 x 1000\n")
        f.write("%\n")
        f.write("% Usage:\n")
        f.write("%   table = Gdf_Inter_Error();\n")
        f.write("%   err = table(refDstIdx, qpIdx+1, pos+1);\n\n")

        f.write(f"    table = zeros({d1}, {d2}, {d3}, 'int32');\n\n")

        idx = 0
        for i in range(d1):
            for j in range(d2):
                # Write compact format
                f.write(f"    table({i+1},{j+1},:) = [")
                for k in range(d3):
                    if k > 0 and k % 20 == 0:
                        f.write("...\n        ")
                    f.write(f"{data[idx]},")
                    idx += 1
                f.write("];\n")

        f.write("end\n")

def write_matlab_2d_function(filename, data, shape):
    """Write 2D array as MATLAB function"""
    d1, d2 = shape

    with open(filename, 'w') as f:
        f.write("function table = Gdf_Intra_Error()\n")
        f.write("% Gdf_Intra_Error - Returns GDF Intra Error lookup table\n")
        f.write("% Auto-generated from C++ GDF tables\n")
        f.write("% Shape: 6 x 4096\n")
        f.write("%\n")
        f.write("% Usage:\n")
        f.write("%   table = Gdf_Intra_Error();\n")
        f.write("%   err = table(qpIdx+1, pos+1);\n\n")

        f.write(f"    table = zeros({d1}, {d2}, 'int32');\n\n")

        idx = 0
        for i in range(d1):
            # Write compact format
            f.write(f"    table({i+1},:) = [")
            for j in range(d2):
                if j > 0 and j % 20 == 0:
                    f.write("...\n        ")
                f.write(f"{data[idx]},")
                idx += 1
            f.write("];\n")

        f.write("end\n")

def convert_inter_error():
    """Convert Gdf_Inter_Error[5][6][1000] table"""
    print("Converting Gdf_Inter_Error table...")

    with open('gdf_inter_error_raw.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    # Parse all numbers from the C++ initialization
    numbers = parse_cpp_array(content)

    print(f"Extracted {len(numbers)} numbers")

    # Expected: 5 * 6 * 1000 = 30000
    expected_size = 5 * 6 * 1000
    if len(numbers) != expected_size:
        print(f"WARNING: Expected {expected_size} numbers, got {len(numbers)}")
        numbers = numbers[:expected_size]  # Truncate if too long

    # Write to .m file
    write_matlab_3d_function('Gdf_Inter_Error.m', numbers, (5, 6, 1000))

    print(f"Saved Gdf_Inter_Error.m: shape (5, 6, 1000)")
    print(f"  Value range: [{min(numbers)}, {max(numbers)}]")
    print(f"  Sample values: {numbers[:5]}")

def convert_intra_error():
    """Convert Gdf_Intra_Error[6][4096] table"""
    print("\nConverting Gdf_Intra_Error table...")

    with open('gdf_intra_error_raw.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    # Parse all numbers from the C++ initialization
    numbers = parse_cpp_array(content)

    print(f"Extracted {len(numbers)} numbers")

    # Expected: 6 * 4096 = 24576
    expected_size = 6 * 4096
    if len(numbers) != expected_size:
        print(f"WARNING: Expected {expected_size} numbers, got {len(numbers)}")
        numbers = numbers[:expected_size]  # Truncate if too long

    # Write to .m file
    write_matlab_2d_function('Gdf_Intra_Error.m', numbers, (6, 4096))

    print(f"Saved Gdf_Intra_Error.m: shape (6, 4096)")
    print(f"  Value range: [{min(numbers)}, {max(numbers)}]")
    print(f"  Sample values: {numbers[:5]}")

if __name__ == '__main__':
    try:
        convert_inter_error()
        convert_intra_error()
        print("\nConversion complete!")
        print("\nUsage in MATLAB:")
        print("  tables = loadGdfTables();")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
