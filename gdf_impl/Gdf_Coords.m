function coords = Gdf_Coords()
% Gdf_Coords - Returns GDF coordinate offsets for 18 spatial positions
% Auto-generated from C++ GDF tables (AV2Helper.cpp:2710)
% Shape: 18 x 2 [x, y]
%
% Usage:
%   coords = Gdf_Coords();
%   x_offset = coords(i, 1);
%   y_offset = coords(i, 2);

    coords = [
         6,  0;  5,  0;  4,  0;  3,  0;
         2,  1;  2,  0;  2, -1;
         1,  2;  1,  1;  1,  0;  1, -1;  1, -2;
         0,  6;  0,  5;  0,  4;  0,  3;  0,  2;  0,  1
    ];
end
