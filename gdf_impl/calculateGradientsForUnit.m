function grad = calculateGradientsForUnit(sourceFrame, x, y, w, h, bitDepth)
% calculateGradientsForUnit - вычисляет градиенты для GDF unit
%
% Параметры:
%   sourceFrame - входной кадр (Y plane)
%   x, y - позиция блока (0-based coordinates)
%   w, h - размер блока
%   bitDepth - битность (8, 10, 12)
%
% Возвращает:
%   grad - массив градиентов [4, h+3, w+3]
%
% Соответствует спецификации AV2 Section 7.19.5 (lines 1-30)

    % Константы направлений
    GDF_VER = 0;    % Vertical
    GDF_HOR = 1;    % Horizontal
    GDF_DIAG0 = 2;  % Diagonal /
    GDF_DIAG1 = 3;  % Diagonal \

    % Инициализируем массив градиентов
    % Размер: [4 направления][h+3][w+3]
    grad = zeros(4, h+3, w+3, 'uint16');

    % Вычисляем градиенты для каждой точки в блоке + границы
    % Спека: for(i=0; i<h+3; i++) for(j=0; j<w+3; j++)
    for i = 0:(h+2)
        for j = 0:(w+2)
            % Для каждого из 4 направлений
            for d = 0:3
                % Определяем смещение для направления (спека lines 4-16)
                if d == GDF_VER
                    dx = 0;
                    dy = 1;
                elseif d == GDF_HOR
                    dx = 1;
                    dy = 0;
                elseif d == GDF_DIAG0
                    dx = 1;
                    dy = 1;
                else  % GDF_DIAG1
                    dx = 1;
                    dy = -1;
                end

                % Получаем 3 сэмпла вдоль направления (спека lines 23-25)
                % Координаты в исходном кадре (x, y - это координаты unit'а)
                px = x + j;
                py = y + i;

                a = getSample(sourceFrame, px - dx, py - dy, bitDepth);
                b = getSample(sourceFrame, px, py, bitDepth);
                c = getSample(sourceFrame, px + dx, py + dy, bitDepth);

                % Вычисляем Laplacian градиент (спека line 27)
                % grad[d][i][j] = Abs(b * 2 - a - c)
                grad(d+1, i+1, j+1) = abs(b * 2 - a - c);
            end
        end
    end
end

function val = getSample(frame, x, y, bitDepth)
    % get_gdf_sample из спеки (Section 7.19.5, lines 15-17)
    % Получает сэмпл с клиппингом координат и downsampling для 12-bit

    [height, width] = size(frame);

    % Клиппинг координат (0-based → 1-based MATLAB)
    x = max(0, min(width-1, x)) + 1;
    y = max(0, min(height-1, y)) + 1;

    sample = frame(y, x);

    % Downsample 12-bit to 10-bit (спека line 2)
    if bitDepth == 12
        shift = 2;
    else
        shift = 0;
    end

    val = bitshift(sample, -shift);
end
