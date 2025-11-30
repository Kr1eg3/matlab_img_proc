function extended = lr_extend_frame(frame, border_horz, border_vert)
% lr_extend_frame - расширяет границы кадра для loop restoration
%
% Для корректной фильтрации на границах кадра, нужно расширить frame
% путём репликации граничных пикселей. Это соответствует функции
% extend_frame в декодере AV2.
%
% Параметры:
%   frame - входной кадр (height x width)
%   border_horz - размер горизонтального расширения (обычно 4)
%   border_vert - размер вертикального расширения (обычно 4)
%
% Возвращает:
%   extended - расширенный кадр размером:
%              (height + 2*border_vert) x (width + 2*border_horz)
%
% Метод расширения:
%   Граничные пиксели реплицируются (edge replication)
%
% Ссылка:
%   NGAnalyzerQt/third_party/avm/av1/common/restoration.c
%   RESTORATION_BORDER_HORZ = 4
%   RESTORATION_BORDER_VERT = 4

    [height, width] = size(frame);

    % Новые размеры
    new_height = height + 2 * border_vert;
    new_width = width + 2 * border_horz;

    % Инициализируем расширенный кадр
    extended = zeros(new_height, new_width, 'like', frame);

    % Копируем основную часть кадра в центр
    extended(border_vert+1 : border_vert+height, ...
             border_horz+1 : border_horz+width) = frame;

    % Расширяем верхнюю границу (реплицируем первую строку)
    for i = 1:border_vert
        extended(i, border_horz+1:border_horz+width) = frame(1, :);
    end

    % Расширяем нижнюю границу (реплицируем последнюю строку)
    for i = 1:border_vert
        extended(border_vert+height+i, border_horz+1:border_horz+width) = frame(end, :);
    end

    % Расширяем левую границу (реплицируем первый столбец)
    for j = 1:border_horz
        extended(border_vert+1:border_vert+height, j) = frame(:, 1);
    end

    % Расширяем правую границу (реплицируем последний столбец)
    for j = 1:border_horz
        extended(border_vert+1:border_vert+height, border_horz+width+j) = frame(:, end);
    end

    % Заполняем углы (реплицируем угловые пиксели)
    % Верхний левый угол
    extended(1:border_vert, 1:border_horz) = frame(1, 1);

    % Верхний правый угол
    extended(1:border_vert, border_horz+width+1:end) = frame(1, end);

    % Нижний левый угол
    extended(border_vert+height+1:end, 1:border_horz) = frame(end, 1);

    % Нижний правый угол
    extended(border_vert+height+1:end, border_horz+width+1:end) = frame(end, end);
end
