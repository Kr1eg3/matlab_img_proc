function gdfCls = calculateClassification(grad, h, w)
% calculateClassification - определяет класс фильтра для каждого 2x2 блока
%
% Параметры:
%   grad - массив градиентов [4, height+3, width+3] из calculateGradients
%   h - высота кадра
%   w - ширина кадра
%
% Возвращает:
%   gdfCls - массив классов [h/2, w/2]
%           Классы: 0=Vertical dominant, 1=Horizontal dominant,
%                   2=Diagonal / dominant, 3=Diagonal \ dominant
%
% Соответствует спецификации AV2 Section 7.19.5 (lines 18-21)

    % Константы направлений
    GDF_VER = 1;    % +1 для MATLAB индексации
    GDF_HOR = 2;
    GDF_DIAG0 = 3;
    GDF_DIAG1 = 4;

    % Размер массива классификации (2x2 блоки)
    clsHeight = floor(h / 2);
    clsWidth = floor(w / 2);
    gdfCls = zeros(clsHeight, clsWidth, 'uint8');

    % Для каждого 2x2 блока (спека lines 1-10)
    for i = clsHeight:-1:1  % Обратный порядок как в спеке
        for j = 1:clsWidth
            % Вычисляем силу градиента в каждом направлении (спека line 4)
            % Суммируем градиенты для 4x4 области
            str = zeros(1, 4);
            for d = 1:4
                str(d) = gradSum(grad(d, :, :), (i-1)*2 + 1, (j-1)*2 + 1, 4, 4);
            end

            % Определяем класс на основе доминирующего направления (спека lines 6-8)
            % cls = str[GDF_VER] > str[GDF_HOR] ? 0 : 1
            if str(GDF_VER) > str(GDF_HOR)
                cls = 0;
            else
                cls = 1;
            end

            % cls |= str[GDF_DIAG0] > str[GDF_DIAG1] ? 0 : 2
            if str(GDF_DIAG0) > str(GDF_DIAG1)
                % Ничего не делаем (добавляем 0)
            else
                cls = bitor(cls, 2);
            end

            gdfCls(i, j) = cls;
        end
    end
end

function sum = gradSum(grad, i, j, down, across)
    % grad_sum из спеки (Section 7.19.5, lines 20-21)
    % Суммирует прямоугольник значений в массиве grad
    %
    % Параметры:
    %   grad - 2D массив градиентов (одно направление)
    %   i, j - начальная позиция (1-based)
    %   down, across - размер прямоугольника

    sum = 0;
    gradSlice = squeeze(grad);  % Убираем лишние размерности

    % Суммируем прямоугольник (спека lines 3-7)
    for i2 = 0:(down-1)
        for j2 = 0:(across-1)
            ri = i + i2;
            rj = j + j2;

            % Проверяем границы
            if ri >= 1 && ri <= size(gradSlice, 1) && ...
               rj >= 1 && rj <= size(gradSlice, 2)
                sum = sum + gradSlice(ri, rj);
            end
        end
    end
end
