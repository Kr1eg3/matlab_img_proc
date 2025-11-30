function grad = calculateGradients(sourceFrame, bitDepth)
% calculateGradients - вычисляет Laplacian градиенты в 4 направлениях
%
% Параметры:
%   sourceFrame - входной кадр (Y plane)
%   bitDepth - битность (8, 10, 12)
%
% Возвращает:
%   grad - массив градиентов [4, height+3, width+3]
%         4 направления: GDF_VER=0, GDF_HOR=1, GDF_DIAG0=2, GDF_DIAG1=3
%
% Соответствует спецификации AV2 Section 7.19.5 (lines 13-30)

    [height, width] = size(sourceFrame);

    % Константы направлений (как в спеке)
    GDF_VER = 0;    % Vertical
    GDF_HOR = 1;    % Horizontal
    GDF_DIAG0 = 2;  % Diagonal /
    GDF_DIAG1 = 3;  % Diagonal \

    % Инициализируем массив градиентов
    % Размер: [4 направления][height+3][width+3]
    grad = zeros(4, height+3, width+3, 'uint16');

    % Вычисляем градиенты для каждой точки (спека lines 1-30)
    for i = 1:(height+3)
        for j = 1:(width+3)
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
                % Координаты в исходном кадре (базируются на 0)
                x = j - 1;
                y = i - 1;

                a = getGdfSample(sourceFrame, x - dx, y - dy, bitDepth);
                b = getGdfSample(sourceFrame, x, y, bitDepth);
                c = getGdfSample(sourceFrame, x + dx, y + dy, bitDepth);

                % Вычисляем Laplacian градиент (спека line 27)
                % grad[d][i][j] = Abs(b * 2 - a - c)
                grad(d+1, i, j) = abs(b * 2 - a - c);
            end
        end
    end
end

function val = getGdfSample(frame, x, y, bitDepth)
    % get_gdf_sample из спеки (Section 7.19.5, lines 15-17)
    % Получает сэмпл с клиппингом координат и downsampling для 12-bit

    [height, width] = size(frame);

    % Клиппинг координат (от 0-based к 1-based MATLAB)
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
