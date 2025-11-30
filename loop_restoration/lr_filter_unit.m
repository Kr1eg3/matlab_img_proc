function filtered_unit = lr_filter_unit(extended, unit, unitInfo, bitDepth, ...
                                                       planeIdx, border_horz, border_vert, ...
                                                       unit_offset)
% lr_filter_unit - фильтрует один restoration unit
%
% Restoration unit обрабатывается по полосам (stripes) высотой 64 пикселя.
% Это соответствует функции av1_loop_restoration_filter_unit в декодере.
%
% Параметры:
%   extended - расширенный кадр (с границами)
%   unit - структура с информацией о unit:
%       .x, .y - координаты (0-based)
%       .width, .height - размеры unit
%   unitInfo - параметры restoration для этого unit:
%       .restoration_type - тип фильтра
%       .num_classes - количество классов (для multi-class)
%       .wiener_info - коэффициенты фильтра (опционально)
%   bitDepth - битность
%   planeIdx - индекс плоскости (1=Y, 2=U, 3=V)
%   border_horz, border_vert - размеры расширения границ
%   unit_offset - offset для первой stripe (обычно 8)
%
% Возвращает:
%   filtered_unit - отфильтрованный unit (unit.height x unit.width)
%
% Процесс:
%   1. Разбиение unit на stripes высотой 64
%   2. Для каждой stripe:
%      a. Сохранение граничных линий
%      b. Применение фильтра
%      c. Восстановление границ
%   3. Сборка результата
%
% Ссылка:
%   NGAnalyzerQt/third_party/avm/av1/common/restoration.c
%   av1_loop_restoration_filter_unit() - lines 2068-2221

    STRIPE_HEIGHT = 64; % Высота stripe
    RESTORATION_CTX_VERT = 2; % Количество контекстных линий

    % Инициализируем выходной unit
    filtered_unit = zeros(unit.height, unit.width, 'like', extended);

    % Вычисляем количество stripes в этом unit
    % Первая stripe имеет offset, остальные - полная высота
    first_stripe_height = STRIPE_HEIGHT - unit_offset;
    remaining_height = unit.height - first_stripe_height;

    if remaining_height > 0
        num_stripes = 1 + ceil(remaining_height / STRIPE_HEIGHT);
    else
        num_stripes = 1;
    end

    % Обрабатываем каждую stripe
    stripe_y = 0; % Позиция stripe относительно начала unit (0-based)

    for stripeIdx = 1:num_stripes
        % Определяем высоту текущей stripe
        if stripeIdx == 1
            stripe_height = min(first_stripe_height, unit.height);
        else
            remaining = unit.height - stripe_y;
            stripe_height = min(STRIPE_HEIGHT, remaining);
        end

        % Координаты stripe в расширенном кадре (1-based для MATLAB)
        % unit.x и unit.y в 0-based, нужно добавить border и конвертировать в 1-based
        stripe_x_in_extended = unit.x + border_horz + 1;
        stripe_y_in_extended = unit.y + stripe_y + border_vert + 1;

        % Определяем контекстную область для stripe
        % Нужны дополнительные линии выше и ниже для фильтрации
        ctx_above = RESTORATION_CTX_VERT;
        ctx_below = RESTORATION_CTX_VERT;

        % Для первой stripe нет контекста выше внутри unit
        if stripeIdx == 1
            ctx_above = border_vert; % Используем расширенные границы кадра
        end

        % Для последней stripe нет контекста ниже внутри unit
        if stripeIdx == num_stripes
            ctx_below = border_vert; % Используем расширенные границы кадра
        end

        % Извлекаем stripe с контекстом из расширенного кадра
        y_start = stripe_y_in_extended - ctx_above;
        y_end = stripe_y_in_extended + stripe_height - 1 + ctx_below;
        x_start = stripe_x_in_extended - border_horz;
        x_end = stripe_x_in_extended + unit.width - 1 + border_horz;

        % Проверка границ
        [ext_height, ext_width] = size(extended);
        y_start = max(1, min(ext_height, y_start));
        y_end = max(1, min(ext_height, y_end));
        x_start = max(1, min(ext_width, x_start));
        x_end = max(1, min(ext_width, x_end));

        stripe_with_ctx = extended(y_start:y_end, x_start:x_end);

        % Применяем фильтр к stripe
        try
            filtered_stripe = lr_filter_stripe(stripe_with_ctx, unitInfo, ...
                                              bitDepth, planeIdx, ...
                                              stripe_height, unit.width, ...
                                              ctx_above, ctx_below, ...
                                              border_horz, border_horz);

            % Копируем отфильтрованную stripe в результат
            y_out_start = stripe_y + 1; % 1-based для MATLAB
            y_out_end = stripe_y + stripe_height;

            filtered_unit(y_out_start:y_out_end, :) = filtered_stripe;

        catch ME
            fprintf('      WARNING: Error filtering stripe %d: %s\n', stripeIdx, ME.message);
            % При ошибке копируем оригинальные данные
            % Извлекаем оригинальную stripe из extended (без контекста)
            orig_y_start = stripe_y_in_extended;
            orig_y_end = stripe_y_in_extended + stripe_height - 1;
            orig_x_start = stripe_x_in_extended;
            orig_x_end = stripe_x_in_extended + unit.width - 1;

            orig_stripe = extended(orig_y_start:orig_y_end, orig_x_start:orig_x_end);
            filtered_unit(y_out_start:y_out_end, :) = orig_stripe;
        end

        % Переходим к следующей stripe
        stripe_y = stripe_y + stripe_height;
    end
end
