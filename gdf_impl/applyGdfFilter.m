function outputFrame = applyGdfFilter(sourceFrame, gdfParams)
% applyGdfFilter - применяет GDF фильтр к кадру (только luma)
%
% Параметры:
%   sourceFrame - входной кадр (Y plane, после CDEF/CCSO)
%   gdfParams - структура с параметрами:
%       .bitDepth - битность (8, 10, 12)
%       .qpIdx - индекс QP (1-6 в MATLAB, 0-5 в спеке)
%       .refDstIdx - индекс reference distance (0=intra, 1-5=inter)
%       .gdfPixScale - масштаб пикселей (1 + gdf_pic_scale_idx)
%
% Возвращает:
%   outputFrame - выходной кадр после GDF фильтрации

    tables = loadGdfTables();

    [height, width] = size(sourceFrame);
    outputFrame = sourceFrame; % Копируем входной кадр

    % Параметры из speci (7.19.5)
    bitDepth = gdfParams.bitDepth;
    qpIdx = gdfParams.qpIdx;
    refDstIdx = gdfParams.refDstIdx;
    gdfPixScale = gdfParams.gdfPixScale;

    % Масштаб для lookup (спека line 25)
    if refDstIdx == 0
        scale = 8;  % Intra
    else
        scale = 5;  % Inter
    end

    % GDF обрабатывает кадр блоками 128x128 (GDF_UNIT_SIZE из спеки)
    GDF_UNIT_SIZE = 128;

    % Вычисляем количество блоков
    numUnitsY = ceil(height / GDF_UNIT_SIZE);
    numUnitsX = ceil(width / GDF_UNIT_SIZE);

    fprintf('Frame size: %dx%d\n', width, height);
    fprintf('GDF units: %dx%d blocks of %dx%d\n', numUnitsX, numUnitsY, GDF_UNIT_SIZE, GDF_UNIT_SIZE);
    fprintf('Total units to process: %d\n', numUnitsX * numUnitsY);

    % Обрабатываем каждый GDF unit
    unitCount = 0;
    for unitY = 0:(numUnitsY-1)
        for unitX = 0:(numUnitsX-1)
            unitCount = unitCount + 1;
            fprintf('\nProcessing unit %d/%d (block %d,%d)...\n', unitCount, numUnitsX * numUnitsY, unitX, unitY);

            % Координаты блока
            x0 = unitX * GDF_UNIT_SIZE + 1;  % MATLAB 1-based
            y0 = unitY * GDF_UNIT_SIZE + 1;

            % Размер блока (может быть меньше на краях)
            w = min(GDF_UNIT_SIZE, width - x0 + 1);
            h = min(GDF_UNIT_SIZE, height - y0 + 1);

            fprintf('  Unit position: (%d, %d), size: %dx%d\n', x0-1, y0-1, w, h);

            % Вычисляем градиенты для этого блока (спека lines 13-30)
            fprintf('  Calculating gradients...\n');
            tic;
            grad = calculateGradientsForUnit(sourceFrame, x0-1, y0-1, w, h, bitDepth);
            fprintf('    Done in %.2f sec\n', toc);

            % Классификация для 2x2 блоков (спека lines 18-21)
            fprintf('  Calculating classification...\n');
            tic;
            gdfCls = calculateClassification(grad, h, w);
            fprintf('    Done in %.2f sec\n', toc);

            % Применяем фильтр к каждому пикселю в блоке (спека lines 26-63)
            fprintf('  Applying filter...\n');
            tic;
            pixelsProcessed = 0;
            for i = 1:h
                y2 = y0 + i - 1;  % Абсолютная координата в кадре

                for j = 1:w
                    x2 = x0 + j - 1;  % Абсолютная координата в кадре
                    pixelsProcessed = pixelsProcessed + 1;

            % Получаем класс для текущего пикселя (2x2 блоки)
            clsI = floor((i-1) / 2) + 1;
            clsJ = floor((j-1) / 2) + 1;

            if clsI <= size(gdfCls, 1) && clsJ <= size(gdfCls, 2)
                cls = gdfCls(clsI, clsJ);
            else
                cls = 1;  % Default
            end

            % Вычисляем 3 индекса для lookup (gdfIdx)
            gdfIdx = zeros(1, 3, 'int64');

            % Применяем 22 коэффициента (спека lines 9-43)
            for k = 1:22
                alpha = tables.alpha(refDstIdx+1, qpIdx, k, cls+1);

                if k <= 18
                    % Spatial filtering (спека lines 11-27)
                    dy = tables.coords(k, 1);
                    dx = tables.coords(k, 2);

                    x3 = x2 - dx;
                    y3 = y2 - dy;
                    x4 = x2 + dx;
                    y4 = y2 + dy;

                    sample2 = getGdfSample(sourceFrame, x2, y2, bitDepth);
                    sample3 = getGdfSample(sourceFrame, x3, y3, bitDepth);
                    sample4 = getGdfSample(sourceFrame, x4, y4, bitDepth);

                    % Clip3(-alpha, alpha, (sample3 - sample2) << shift)
                    shift = 10 - min(10, bitDepth);
                    above = clip3(-double(alpha), double(alpha), double(bitshift(int32(sample3) - int32(sample2), shift)));
                    below = clip3(-double(alpha), double(alpha), double(bitshift(int32(sample4) - int32(sample2), shift)));
                    comb = clip3(-512, 511, above + below);
                else
                    % Gradient-based filtering (спека lines 28-38)
                    d = k - 19;  % k=19..22 -> d=0..3

                    % Получаем сумму градиентов для 4x4 блока
                    gradI = floor((i-1) / 2) * 2 + 1;
                    gradJ = floor((j-1) / 2) * 2 + 1;
                    v = gradSum(grad(d+1, :, :), gradI, gradJ, 4, 4);

                    if bitDepth == 8
                        v = bitshift(v, -2);
                    else
                        v = bitshift(v, -4);
                    end

                    comb = min(double(v), double(alpha));
                    comb = clip3(-512, 511, comb);
                end

                % Накапливаем взвешенные комбинации (спека lines 39-42)
                for idx = 1:3
                    weight = tables.weight(refDstIdx+1, qpIdx, idx, k, cls+1);
                    gdfIdx(idx) = gdfIdx(idx) + int64(comb) * int64(weight);
                end
            end

            % Вычисляем позицию в lookup таблице (спека lines 44-50)
            pos = 0;
            for idx = 1:3
                bias = tables.bias(refDstIdx+1, qpIdx, idx);
                v = round2Signed((gdfIdx(idx) + int64(bias)) * int64(scale), 15);
                v = clip3(-scale, scale - 1, v) + scale;
                pos = pos * scale * 2 + v;
            end

            % Получаем коррекцию ошибки из таблицы (спека lines 51-55)
            if refDstIdx == 0
                % Intra
                if pos >= 0 && pos < 4096
                    err = tables.intra(qpIdx, pos+1);
                else
                    err = 0;
                end
            else
                % Inter (спека: Gdf_Inter_Error[ refDstIdx - 1 ][ qpIdx ][ pos ])
                if pos >= 0 && pos < 1000
                    err = tables.inter(refDstIdx, qpIdx, pos+1);  % refDstIdx уже 1-5, в таблице это индексы 1-5
                else
                    err = 0;
                end
            end

            % Применяем коррекцию (спека lines 56-57)
            correction = round2Signed(err * gdfPixScale, 12 - bitDepth);
            result = clip1(int32(sourceFrame(y2, x2)) + correction, bitDepth);

                    outputFrame(y2, x2) = uint16(result);
                end
            end
            fprintf('    Done in %.2f sec (%d pixels)\n', toc, pixelsProcessed);
        end
    end

    fprintf('\n=== GDF filter applied successfully ===\n');
end

% Вспомогательные функции

function val = getGdfSample(frame, x, y, bitDepth)
    % get_gdf_sample из спеки (lines 15-17)
    [height, width] = size(frame);
    x = max(1, min(width, x));
    y = max(1, min(height, y));

    sample = frame(y, x);

    % Downsample 12-bit to 10-bit
    if bitDepth == 12
        shift = 2;
    else
        shift = 0;
    end

    val = bitshift(sample, -shift);
end

function val = clip3(minVal, maxVal, x)
    % Clip3 из спеки
    val = max(minVal, min(maxVal, x));
end

function val = clip1(x, bitDepth)
    % Clip1 - клиппинг к диапазону битности
    maxVal = bitshift(1, bitDepth) - 1;
    val = max(0, min(maxVal, x));
end

function val = round2Signed(x, n)
    % Round2Signed из спеки
    % Округление со сдвигом вправо на n бит
    if x >= 0
        val = bitshift(x + bitshift(1, n-1), -n);
    else
        val = -bitshift(-x + bitshift(1, n-1), -n);
    end
end

function sum = gradSum(grad, i, j, down, across)
    % grad_sum из спеки (lines 20-21)
    % Суммирует прямоугольник значений в массиве grad
    sum = 0;
    gradSlice = squeeze(grad);  % Убираем первую размерность

    for i2 = 0:(down-1)
        for j2 = 0:(across-1)
            ri = i + i2;
            rj = j + j2;
            if ri >= 1 && ri <= size(gradSlice, 1) && rj >= 1 && rj <= size(gradSlice, 2)
                sum = sum + gradSlice(ri, rj);
            end
        end
    end
end
