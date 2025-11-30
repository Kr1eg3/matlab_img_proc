function filtered = lr_filter_stripe(stripe_with_ctx, unitInfo, bitDepth, ...
                                                    planeIdx, stripe_height, stripe_width, ...
                                                    ctx_above, ctx_below, ...
                                                    border_left, border_right)
% lr_filter_stripe - применяет loop restoration фильтр к одной stripe
%
% Stripe - это горизонтальная полоса пикселей высотой 64. Эта функция
% применяет соответствующий restoration фильтр (PC Wiener или Non-Sep Wiener)
% к stripe с учётом контекстных линий выше и ниже.
%
% Параметры:
%   stripe_with_ctx - stripe с контекстом:
%       Размер: (ctx_above + stripe_height + ctx_below) x (border_left + stripe_width + border_right)
%   unitInfo - параметры restoration:
%       .restoration_type - 1=PC_WIENER, 2=WIENER_NONSEP, 3=SWITCHABLE
%       .num_classes - количество классов фильтров
%       .wiener_info - коэффициенты фильтра (если заданы)
%   bitDepth - битность (8, 10, 12)
%   planeIdx - индекс плоскости (1=Y, 2=U, 3=V)
%   stripe_height - высота полезной части stripe (без контекста)
%   stripe_width - ширина полезной части stripe (без borders)
%   ctx_above, ctx_below - размеры контекста выше/ниже
%   border_left, border_right - размеры границ слева/справа
%
% Возвращает:
%   filtered - отфильтрованная stripe (stripe_height x stripe_width)
%
% Ссылка:
%   NGAnalyzerQt/third_party/avm/av1/common/restoration.c
%   wiener_nsfilter_stripe_highbd() - линии 1333+
%   wiener_filter_stripe() для PC Wiener

    % Координаты полезной части stripe в stripe_with_ctx (1-based)
    y_start = ctx_above + 1;
    y_end = ctx_above + stripe_height;
    x_start = border_left + 1;
    x_end = border_left + stripe_width;

    % Определяем тип фильтра
    restoration_type = unitInfo.restoration_type;

    switch restoration_type
        case 1
            % RESTORE_PC_WIENER (Pixel-Classified Wiener)
            filtered = lr_wiener_pc(stripe_with_ctx, unitInfo, bitDepth, planeIdx, ...
                                   y_start, y_end, x_start, x_end);

        case 2
            % RESTORE_WIENER_NONSEP (Non-Separable Wiener)
            filtered = lr_wiener_nonsep(stripe_with_ctx, unitInfo, bitDepth, planeIdx, ...
                                       y_start, y_end, x_start, x_end);

        case 3
            % RESTORE_SWITCHABLE - выбор зависит от unit info
            % TODO: реализовать логику выбора
            % Пока используем WIENER_NONSEP по умолчанию
            filtered = lr_wiener_nonsep(stripe_with_ctx, unitInfo, bitDepth, planeIdx, ...
                                       y_start, y_end, x_start, x_end);

        otherwise
            % Неизвестный тип - возвращаем оригинальные данные
            fprintf('      WARNING: Unknown restoration type %d, passing through\n', restoration_type);
            filtered = stripe_with_ctx(y_start:y_end, x_start:x_end);
    end

    % Проверка размеров выходных данных
    if size(filtered, 1) ~= stripe_height || size(filtered, 2) ~= stripe_width
        error('Filtered stripe size mismatch: expected %dx%d, got %dx%d', ...
              stripe_width, stripe_height, size(filtered, 2), size(filtered, 1));
    end
end
