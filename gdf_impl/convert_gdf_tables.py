#!/usr/bin/env python3
"""
Convert GDF lookup tables from C++ format to MATLAB .m files
No external dependencies required
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

def write_matlab_3d_array(filename, varname, data, shape):
    """Write 3D array to MATLAB .m file"""
    d1, d2, d3 = shape

    with open(filename, 'w') as f:
        f.write(f"% {varname}\n")
        f.write(f"% Auto-generated from C++ GDF tables\n")
        f.write(f"% Shape: {d1} x {d2} x {d3}\n\n")
        f.write(f"{varname} = zeros({d1}, {d2}, {d3}, 'int32');\n\n")

        idx = 0
        for i in range(d1):
            for j in range(d2):
                # Write 50 values per line for readability
                f.write(f"% [{i+1},{j+1},:]\n")
                f.write(f"{varname}({i+1},{j+1},:) = [")
                for k in range(d3):
                    if k > 0 and k % 50 == 0:
                        f.write("...\n    ")
                    f.write(f"{data[idx]}, ")
                    idx += 1
                f.write("];\n\n")

def write_matlab_2d_array(filename, varname, data, shape):
    """Write 2D array to MATLAB .m file"""
    d1, d2 = shape

    with open(filename, 'w') as f:
        f.write(f"% {varname}\n")
        f.write(f"% Auto-generated from C++ GDF tables\n")
        f.write(f"% Shape: {d1} x {d2}\n\n")
        f.write(f"{varname} = zeros({d1}, {d2}, 'int32');\n\n")

        idx = 0
        for i in range(d1):
            # Write 50 values per line for readability
            f.write(f"% [{i+1},:]\n")
            f.write(f"{varname}({i+1},:) = [")
            for j in range(d2):
                if j > 0 and j % 50 == 0:
                    f.write("...\n    ")
                f.write(f"{data[idx]}, ")
                idx += 1
            f.write("];\n\n")

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
    write_matlab_3d_array('Gdf_Inter_Error.m', 'Gdf_Inter_Error', numbers, (5, 6, 1000))

    print(f"Saved Gdf_Inter_Error.m: shape (5, 6, 1000)")
    print(f"  Value range: [{min(numbers)}, {max(numbers)}]")
    print(f"  Sample values at [1,1,1:5]: {numbers[:5]}")

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
    write_matlab_2d_array('Gdf_Intra_Error.m', 'Gdf_Intra_Error', numbers, (6, 4096))

    print(f"Saved Gdf_Intra_Error.m: shape (6, 4096)")
    print(f"  Value range: [{min(numbers)}, {max(numbers)}]")
    print(f"  Sample values at [1,1:5]: {numbers[:5]}")

if __name__ == '__main__':
    try:
        convert_inter_error()
        convert_intra_error()
        print("\n✓ Conversion complete!")
        print("\nUsage in MATLAB:")
        print("  run('Gdf_Inter_Error.m');  % Creates Gdf_Inter_Error variable")
        print("  run('Gdf_Intra_Error.m');  % Creates Gdf_Intra_Error variable")
        print("\nIndexing:")
        print("  % C++: Gdf_Inter_Error[refDstIdx-1][qpIdx][pos]")
        print("  % MATLAB: Gdf_Inter_Error(refDstIdx, qpIdx+1, pos+1)")
        print("  % Note: MATLAB uses 1-based indexing")
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
