function grid = lr_unit_grid(width, height, unit_size)
% lr_unit_grid - вычисляет сетку restoration units для кадра
%
% Согласно спецификации AV2, кадр разбивается на restoration units
% фиксированного размера (обычно 64x64 пикселя). Эта функция вычисляет
% координаты и размеры всех restoration units в кадре.
%
% Параметры:
%   width - ширина кадра
%   height - высота кадра
%   unit_size - размер restoration unit (обычно 64)
%
% Возвращает:
%   grid - структура с информацией о сетке:
%       .unit_size - размер unit (входной параметр)
%       .horz_units - количество units по горизонтали
%       .vert_units - количество units по вертикали
%       .total_units - общее количество units
%       .units - массив структур для каждого unit:
%           .x - начальная x координата (0-based, как в спеке)
%           .y - начальная y координата (0-based)
%           .width - ширина unit (может быть меньше на краях)
%           .height - высота unit (может быть меньше на краях)
%           .unit_idx - линейный индекс unit (0-based)
%           .unit_row - индекс строки unit (0-based)
%           .unit_col - индекс столбца unit (0-based)
%
% Примечание:
%   Координаты в grid.units используют 0-based индексацию для соответствия
%   спецификации. При обращении к MATLAB массивам нужно добавлять +1.
%
% Ссылка:
%   NGAnalyzerQt/third_party/avm/av1/common/restoration.c:
%   av1_alloc_restoration_struct() - lines 2265-2332

    % Вычисляем количество units
    horz_units = ceil(width / unit_size);
    vert_units = ceil(height / unit_size);
    total_units = horz_units * vert_units;

    fprintf('  Unit grid: %dx%d (total %d units of size %d)\n', ...
        horz_units, vert_units, total_units, unit_size);

    % Инициализируем структуру grid
    grid.unit_size = unit_size;
    grid.horz_units = horz_units;
    grid.vert_units = vert_units;
    grid.total_units = total_units;

    % Создаём массив units
    grid.units = struct('x', {}, 'y', {}, 'width', {}, 'height', {}, ...
                        'unit_idx', {}, 'unit_row', {}, 'unit_col', {});

    % Заполняем информацию для каждого unit
    unit_idx = 0;
    for row = 0:(vert_units - 1)
        for col = 0:(horz_units - 1)
            % Начальные координаты unit (0-based)
            x = col * unit_size;
            y = row * unit_size;

            % Размер unit (может быть меньше на краях кадра)
            unit_width = min(unit_size, width - x);
            unit_height = min(unit_size, height - y);

            % Создаём структуру для этого unit
            unit.x = x;
            unit.y = y;
            unit.width = unit_width;
            unit.height = unit_height;
            unit.unit_idx = unit_idx;
            unit.unit_row = row;
            unit.unit_col = col;

            % Добавляем в массив
            grid.units = [grid.units; unit];

            unit_idx = unit_idx + 1;
        end
    end
end
