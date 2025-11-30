function [Y_out, U_out, V_out] = lr_main(Y_in, U_in, V_in, lrParams)
% lr_main - применяет Loop Restoration фильтр к кадру
%
% Это главная точка входа для Loop Restoration процесса согласно AV2 спецификации.
% Loop Restoration применяется ПОСЛЕ CDEF/CCSO и ДО GDF.
%
% Параметры:
%   Y_in, U_in, V_in - входные плоскости (после CDEF/CCSO)
%   lrParams - структура с параметрами loop restoration:
%       .bitDepth - битность (8, 10, 12)
%       .chromaFormat - формат цветности (420, 422, 444)
%
%       Для каждой плоскости (Y, U, V):
%       .frame_restoration_type - тип для всего кадра:
%           0 = RESTORE_NONE
%           1 = RESTORE_PC_WIENER (Pixel-Classified Wiener)
%           2 = RESTORE_WIENER_NONSEP (Non-Separable Wiener)
%           3 = RESTORE_SWITCHABLE
%
%       .restoration_unit_size - размер restoration unit (обычно 64)
%
%       .unit_info - массив информации для каждого restoration unit
%           Каждый элемент содержит:
%           .restoration_type - тип для этого unit (если SWITCHABLE)
%           .wiener_info - коэффициенты фильтра для этого unit
%           .num_classes - количество классов (для multi-class filtering)
%           .frame_filters - коэффициенты на уровне кадра
%
% Возвращает:
%   Y_out, U_out, V_out - выходные плоскости после loop restoration
%
% Примечание:
%   Функция следует процессу из спецификации AV2 и реализации в
%   NGAnalyzerQt/third_party/avm/av1/common/restoration.c
%
% Автор: Generated for AV2 Loop Restoration implementation
% Дата: 2025-01-20

    fprintf('\n=== Loop Restoration Filter ===\n');

    % Проверка входных параметров
    if nargin < 4
        error('Недостаточно параметров. Использование: lr_main(Y, U, V, lrParams)');
    end

    % Размеры входных плоскостей
    [height_y, width_y] = size(Y_in);
    [height_u, width_u] = size(U_in);
    [height_v, width_v] = size(V_in);

    fprintf('Input frame size: Y=%dx%d, U=%dx%d, V=%dx%d\n', ...
        width_y, height_y, width_u, height_u, width_v, height_v);
    fprintf('Bit depth: %d, Chroma format: %d\n', ...
        lrParams.bitDepth, lrParams.chromaFormat);

    % Инициализируем выходные плоскости (копируем входные)
    Y_out = Y_in;
    U_out = U_in;
    V_out = V_in;

    % Обрабатываем каждую плоскость
    planes = {'Y', 'U', 'V'};

    for planeIdx = 1:3
        planeName = planes{planeIdx};
        fprintf('\n--- Processing %s plane ---\n', planeName);

        % Получаем входную и выходную плоскость
        switch planeIdx
            case 1
                plane_in = Y_in;
                plane_height = height_y;
                plane_width = width_y;
            case 2
                plane_in = U_in;
                plane_height = height_u;
                plane_width = width_u;
            case 3
                plane_in = V_in;
                plane_height = height_v;
                plane_width = width_v;
        end

        % Получаем тип restoration для этой плоскости
        if isfield(lrParams, planeName)
            planeParams = lrParams.(planeName);
            restorationType = planeParams.frame_restoration_type;
        else
            restorationType = 0; % RESTORE_NONE по умолчанию
        end

        fprintf('Restoration type: %d ', restorationType);
        switch restorationType
            case 0
                fprintf('(RESTORE_NONE)\n');
                % Пропускаем обработку
                continue;
            case 1
                fprintf('(RESTORE_PC_WIENER)\n');
            case 2
                fprintf('(RESTORE_WIENER_NONSEP)\n');
            case 3
                fprintf('(RESTORE_SWITCHABLE)\n');
            otherwise
                fprintf('(UNKNOWN)\n');
                warning('Неизвестный тип restoration: %d', restorationType);
                continue;
        end

        % Применяем loop restoration к этой плоскости
        try
            tic;
            plane_out = lr_filter_frame(plane_in, planeParams, lrParams.bitDepth, planeIdx);
            elapsed = toc;
            fprintf('Plane %s filtered in %.2f sec\n', planeName, elapsed);

            % Сохраняем результат
            switch planeIdx
                case 1
                    Y_out = plane_out;
                case 2
                    U_out = plane_out;
                case 3
                    V_out = plane_out;
            end

        catch ME
            fprintf('ERROR filtering %s plane: %s\n', planeName, ME.message);
            fprintf('%s\n', ME.getReport());
            % Оставляем оригинальную плоскость при ошибке
        end
    end

    fprintf('\n=== Loop Restoration completed ===\n');
end
