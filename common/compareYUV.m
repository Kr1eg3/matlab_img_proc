function result = compareYUV(file1, file2, width, height, bitDepth, chromaFormat, frameNum)
% compareYUV - сравнивает два YUV файла и возвращает детальную статистику
%
% Параметры:
%   file1, file2 - пути к YUV файлам для сравнения
%   width, height - размер кадра
%   bitDepth - битность (8, 10, 12)
%   chromaFormat - формат цветности (420, 422, 444)
%   frameNum - номер кадра для сравнения (опционально, по умолчанию 1)
%
% Возвращает:
%   result - структура с полями:
%     .identical - true если файлы полностью идентичны
%     .Y, .U, .V - структуры для каждого плейна с полями:
%       .diff - знаковая разница (int32): file1 - file2
%       .absDiff - абсолютная разница (uint32)
%       .maxDiff - максимальная абсолютная разница
%       .meanDiff - средняя абсолютная разница
%       .medianDiff - медианная абсолютная разница
%       .stdDiff - стандартное отклонение абсолютной разницы
%       .identicalPixels - количество идентичных пикселей
%       .totalPixels - общее количество пикселей
%       .identicalPercent - процент идентичных пикселей
%       .errorDistribution - распределение ошибок по бинам

    if nargin < 7
        frameNum = 1;
    end

    % Читаем первый файл
    [Y1, U1, V1] = readYUV(file1, width, height, frameNum, bitDepth, chromaFormat);

    % Читаем второй файл
    [Y2, U2, V2] = readYUV(file2, width, height, frameNum, bitDepth, chromaFormat);

    % Инициализируем результат
    result = struct();

    % Сравниваем Y plane
    result.Y = comparePlane(Y1, Y2, 'Y');

    % Сравниваем U plane
    result.U = comparePlane(U1, U2, 'U');

    % Сравниваем V plane
    result.V = comparePlane(V1, V2, 'V');

    % Проверяем полную идентичность
    result.identical = (result.Y.identicalPixels == result.Y.totalPixels) && ...
                       (result.U.identicalPixels == result.U.totalPixels) && ...
                       (result.V.identicalPixels == result.V.totalPixels);

    % Общая статистика
    result.totalIdenticalPixels = result.Y.identicalPixels + ...
                                  result.U.identicalPixels + ...
                                  result.V.identicalPixels;
    result.totalPixels = result.Y.totalPixels + ...
                         result.U.totalPixels + ...
                         result.V.totalPixels;
    result.totalIdenticalPercent = 100 * result.totalIdenticalPixels / result.totalPixels;
end

function planeResult = comparePlane(plane1, plane2, planeName)
    % Вычисляем разницу
    diff = int32(plane1) - int32(plane2);
    absDiff = abs(diff);

    % Статистика
    maxDiff = max(absDiff(:));
    meanDiff = mean(double(absDiff(:)));
    medianDiff = median(absDiff(:));
    stdDiff = std(double(absDiff(:)));

    % Процент идентичных пикселей
    identicalPixels = sum(absDiff(:) == 0);
    totalPixels = numel(absDiff);
    identicalPercent = 100 * identicalPixels / totalPixels;

    % Распределение ошибок
    errorBins = [0, 1, 2, 5, 10, 20, 50, 100, Inf];
    errorCounts = histcounts(absDiff(:), errorBins);

    % Формируем структуру распределения
    errorDistribution = struct();
    errorDistribution.bins = errorBins;
    errorDistribution.counts = errorCounts;
    errorDistribution.percents = 100 * errorCounts / totalPixels;

    % Собираем результат
    planeResult = struct();
    planeResult.name = planeName;
    planeResult.diff = diff;
    planeResult.absDiff = absDiff;
    planeResult.maxDiff = maxDiff;
    planeResult.meanDiff = meanDiff;
    planeResult.medianDiff = medianDiff;
    planeResult.stdDiff = stdDiff;
    planeResult.identicalPixels = identicalPixels;
    planeResult.totalPixels = totalPixels;
    planeResult.identicalPercent = identicalPercent;
    planeResult.errorDistribution = errorDistribution;
end
