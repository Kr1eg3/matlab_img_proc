function filtered = lr_wiener_nonsep(stripe_with_ctx, unitInfo, bitDepth, ...
                                                    planeIdx, y_start, y_end, x_start, x_end)
% lr_wiener_nonsep - применяет Non-Separable Wiener фильтр к stripe
%
% Non-Separable Wiener фильтр использует до 28 коэффициентов (taps)
% в несепарабельной конфигурации для восстановления качества изображения.
% Поддерживает multi-class фильтрацию (до 4 классов).
%
% Параметры:
%   stripe_with_ctx - stripe с контекстными линиями
%   unitInfo - информация о unit:
%       .num_classes - количество классов фильтров (обычно 1-4)
%       .wiener_info - структура с коэффициентами фильтра:
%           .allfiltertaps - массив коэффициентов [num_classes x WIENERNS_TAPS_MAX]
%           .bank_ref_for_class - reference для каждого класса
%   bitDepth - битность (8, 10, 12)
%   planeIdx - индекс плоскости (1=Y, 2=U, 3=V)
%   y_start, y_end - диапазон строк для фильтрации (в stripe_with_ctx)
%   x_start, x_end - диапазон столбцов для фильтрации (в stripe_with_ctx)
%
% Возвращает:
%   filtered - отфильтрованная область (stripe_height x stripe_width)
%
% Ссылка:
%   NGAnalyzerQt/third_party/avm/av1/common/restoration.c
%   wiener_nsfilter_stripe_highbd() - lines 1333+
%   NGAnalyzerQt/third_party/avm/av1/common/blockd.h
%   WienerNonsepInfo structure - lines 1756-1779

    % Константы
    WIENERNS_TAPS_MAX = 32;
    WIENERNS_MAX_CLASSES = 4;

    % Размеры stripe
    stripe_height = y_end - y_start + 1;
    stripe_width = x_end - x_start + 1;

    % Получаем количество классов
    if isfield(unitInfo, 'num_classes')
        num_classes = unitInfo.num_classes;
    else
        num_classes = 1; % По умолчанию single-class
    end

    % Проверка num_classes
    if num_classes < 1 || num_classes > WIENERNS_MAX_CLASSES
        error('Invalid num_classes: %d (must be 1-%d)', num_classes, WIENERNS_MAX_CLASSES);
    end

    % Инициализируем выходной массив
    filtered = zeros(stripe_height, stripe_width, 'like', stripe_with_ctx);

    % Если нет filter info, используем identity (копируем вход)
    if ~isfield(unitInfo, 'wiener_info') || isempty(unitInfo.wiener_info)
        fprintf('        No Wiener filter info - using identity filter\n');
        filtered = stripe_with_ctx(y_start:y_end, x_start:x_end);
        return;
    end

    wiener_info = unitInfo.wiener_info;

    % Получаем коэффициенты фильтра
    if isfield(wiener_info, 'allfiltertaps')
        % allfiltertaps - это линейный массив [num_classes * WIENERNS_TAPS_MAX]
        % Нужно преобразовать в [num_classes x WIENERNS_TAPS_MAX]
        if numel(wiener_info.allfiltertaps) >= num_classes * WIENERNS_TAPS_MAX
            filter_taps = reshape(wiener_info.allfiltertaps(1:num_classes * WIENERNS_TAPS_MAX), ...
                                 [WIENERNS_TAPS_MAX, num_classes])';
        else
            fprintf('        WARNING: Insufficient filter taps, using identity\n');
            filtered = stripe_with_ctx(y_start:y_end, x_start:x_end);
            return;
        end
    else
        % Используем нейтральные коэффициенты (identity filter)
        fprintf('        No filter taps - using identity filter\n');
        filtered = stripe_with_ctx(y_start:y_end, x_start:x_end);
        return;
    end

    % Для простоты пока реализуем single-class фильтрацию
    % TODO: добавить классификацию для multi-class
    class_id = 1; % Используем первый класс

    % Получаем коэффициенты для этого класса
    taps = filter_taps(class_id, :);

    % Определяем конфигурацию фильтра
    % Стандартные конфигурации из спецификации AV2
    % Для упрощения используем 5x5 конфигурацию (13 taps)
    % TODO: расширить до 28 taps для полной поддержки

    % Применяем фильтр к каждому пикселю
    for i = 1:stripe_height
        for j = 1:stripe_width
            % Абсолютные координаты в stripe_with_ctx
            y = y_start + i - 1;
            x = x_start + j - 1;

            % Применяем Non-Separable Wiener фильтр
            % Для начала используем простую 3x3 конфигурацию
            filtered_val = apply_wiener_filter_3x3(stripe_with_ctx, y, x, taps, bitDepth);

            % Сохраняем результат
            filtered(i, j) = filtered_val;
        end
    end
end

function filtered_val = apply_wiener_filter_3x3(img, y, x, taps, bitDepth)
    % Простая 3x3 реализация Non-Separable Wiener фильтра
    % Использует 9 коэффициентов из taps

    % Получаем размер изображения
    [height, width] = size(img);

    % Инициализируем аккумулятор
    acc = int64(0);

    % 3x3 окрестность (центр в 0,0)
    offsets = [-1, -1; -1, 0; -1, 1; ...
                0, -1;  0, 0;  0, 1; ...
                1, -1;  1, 0;  1, 1];

    % Применяем 9 коэффициентов
    for k = 1:9
        dy = offsets(k, 1);
        dx = offsets(k, 2);

        % Координаты соседнего пикселя
        ny = y + dy;
        nx = x + dx;

        % Clipping координат (edge replication)
        ny = max(1, min(height, ny));
        nx = max(1, min(width, nx));

        % Получаем значение пикселя
        pixel = int64(img(ny, nx));

        % Коэффициент фильтра
        coef = int64(taps(k));

        % Накапливаем
        acc = acc + pixel * coef;
    end

    % Нормализация и округление
    % Wiener фильтры используют fixed-point arithmetic
    % Коэффициенты обычно в формате с 7-битной точностью
    WIENER_ROUND_BITS = 7;

    % Округление со сдвигом
    if acc >= 0
        result = bitshift(acc + bitshift(int64(1), WIENER_ROUND_BITS - 1), -WIENER_ROUND_BITS);
    else
        result = -bitshift(-acc + bitshift(int64(1), WIENER_ROUND_BITS - 1), -WIENER_ROUND_BITS);
    end

    % Clipping к диапазону битности
    max_val = bitshift(1, bitDepth) - 1;
    filtered_val = uint16(max(0, min(max_val, result)));
end
