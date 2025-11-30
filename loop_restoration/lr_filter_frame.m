function plane_out = lr_filter_frame(plane_in, planeParams, bitDepth, planeIdx)
% lr_filter_frame - применяет loop restoration к одной плоскости кадра
%
% Это главная функция фильтрации, которая координирует весь процесс
% loop restoration для одной цветовой плоскости (Y, U или V).
%
% Параметры:
%   plane_in - входная плоскость (height x width)
%   planeParams - параметры restoration для этой плоскости:
%       .frame_restoration_type - тип restoration (1=PC_WIENER, 2=WIENER_NONSEP, 3=SWITCHABLE)
%       .restoration_unit_size - размер restoration unit (обычно 64)
%       .unit_info - массив информации для каждого unit (опционально)
%   bitDepth - битность (8, 10, 12)
%   planeIdx - индекс плоскости (1=Y, 2=U, 3=V)
%
% Возвращает:
%   plane_out - выходная плоскость после loop restoration
%
% Процесс (согласно av1_loop_restoration_filter_frame):
%   1. Расширение границ кадра
%   2. Создание сетки restoration units
%   3. Для каждого unit:
%      a. Разбиение на stripes (полосы высотой 64 пикселя)
%      b. Применение фильтра к каждой stripe
%      c. Обработка границ между stripes
%   4. Копирование результата обратно в plane_out
%
% Ссылка:
%   NGAnalyzerQt/third_party/avm/av1/common/restoration.c
%   av1_loop_restoration_filter_frame() - lines 2395-2409

    [height, width] = size(plane_in);

    fprintf('  Frame size: %dx%d\n', width, height);

    % Константы из спецификации
    RESTORATION_BORDER_HORZ = 4;
    RESTORATION_BORDER_VERT = 4;
    RESTORATION_UNIT_OFFSET = 8;  % Offset для первой stripe

    % Получаем параметры
    if isfield(planeParams, 'restoration_unit_size')
        unit_size = planeParams.restoration_unit_size;
    else
        unit_size = 64; % По умолчанию
    end

    % Шаг 1: Расширяем границы кадра
    fprintf('  Extending frame borders...\n');
    extended = lr_extend_frame(plane_in, RESTORATION_BORDER_HORZ, RESTORATION_BORDER_VERT);
    fprintf('    Extended size: %dx%d\n', size(extended, 2), size(extended, 1));

    % Шаг 2: Создаём сетку restoration units
    fprintf('  Creating restoration unit grid...\n');
    grid = lr_unit_grid(width, height, unit_size);

    % Шаг 3: Инициализируем выходную плоскость
    plane_out = plane_in; % Копируем входную плоскость

    % Шаг 4: Обрабатываем каждый restoration unit
    fprintf('  Processing %d restoration units...\n', grid.total_units);

    for unitIdx = 1:grid.total_units
        unit = grid.units(unitIdx);

        % Получаем параметры restoration для этого unit
        if isfield(planeParams, 'unit_info') && length(planeParams.unit_info) >= unitIdx
            unitInfo = planeParams.unit_info(unitIdx);
        else
            % Используем параметры по умолчанию
            unitInfo.restoration_type = planeParams.frame_restoration_type;
            unitInfo.num_classes = 1; % Single-class по умолчанию
        end

        % Пропускаем unit если тип = RESTORE_NONE
        if unitInfo.restoration_type == 0
            continue;
        end

        % Фильтруем этот restoration unit
        try
            filtered_unit = lr_filter_unit(extended, unit, unitInfo, ...
                                          bitDepth, planeIdx, ...
                                          RESTORATION_BORDER_HORZ, ...
                                          RESTORATION_BORDER_VERT, ...
                                          RESTORATION_UNIT_OFFSET);

            % Копируем отфильтрованный unit обратно в выходную плоскость
            % Координаты в unit используют 0-based индексацию
            y_start = unit.y + 1; % Конвертируем в 1-based для MATLAB
            x_start = unit.x + 1;
            y_end = y_start + unit.height - 1;
            x_end = x_start + unit.width - 1;

            plane_out(y_start:y_end, x_start:x_end) = filtered_unit;

        catch ME
            fprintf('    WARNING: Error filtering unit %d: %s\n', unitIdx, ME.message);
            % Оставляем оригинальные данные для этого unit при ошибке
        end

        % Прогресс
        if mod(unitIdx, 10) == 0 || unitIdx == grid.total_units
            fprintf('    Progress: %d/%d units\n', unitIdx, grid.total_units);
        end
    end

    fprintf('  Loop restoration filtering completed.\n');
end
