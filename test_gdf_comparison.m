% test_gdf_comparison.m - сравнение GDF выхода анализатора с MATLAB реализацией
%
% Этот скрипт:
% 1. Читает CCSO frame (вход для GDF)
% 2. Применяет MATLAB имплементацию GDF
% 3. Сохраняет результат во временный файл
% 4. Сравнивает с эталонным GDF выходом анализатора

clear all; close all; clc;

fprintf('=== GDF Filter Verification Test ===\n\n');

%% Шаг 1: Параметры видео
fprintf('Шаг 1: Настройка параметров\n');

% Путь к YUV файлам (извлеченным из анализатора)
inputFilename = 'C:/Users/kiwi1/Desktop/cdef_filter.yuv';  % Вход для GDF
referenceFilename = 'C:/Users/kiwi1/Desktop/gdf_filter.yuv';  % Выход GDF из анализатора
outputFilename = 'C:/Users/kiwi1/Desktop/gdf_matlab_output.yuv';  % Выход MATLAB GDF

% Параметры видео
width = 1920;
height = 1080;
bitDepth = 10;
chromaFormat = 444;
frameNum = 1;  % Номер кадра для тестирования

fprintf('  Video: %dx%d, %d-bit, YUV%d\n', width, height, bitDepth, chromaFormat);
fprintf('  Testing frame: %d\n', frameNum);

% GDF параметры (эти значения нужно взять из анализатора или bitstream)
gdfParams.bitDepth = bitDepth;
gdfParams.qpIdx = 1;  % QP index (1-6 в MATLAB, 0-5 в спеке)
gdfParams.refDstIdx = 0;  % 0=intra, 1-5=inter
gdfParams.gdfPixScale = 1;  % 1 + gdf_pic_scale_idx

fprintf('  GDF params: qpIdx=%d, refDstIdx=%d, gdfPixScale=%d\n', ...
    gdfParams.qpIdx, gdfParams.refDstIdx, gdfParams.gdfPixScale);

%% Шаг 2: Читаем входной кадр
fprintf('\nШаг 2: Чтение входного кадра (CCSO output)\n');

addpath('common');
addpath('gdf_impl');

try
    [Y_input, U_input, V_input] = readYUV(inputFilename, width, height, frameNum, bitDepth, chromaFormat);
    fprintf('  ✓ Входной кадр прочитан: %dx%d\n', size(Y_input, 2), size(Y_input, 1));
    fprintf('    Range: [%d, %d], mean=%.1f\n', min(Y_input(:)), max(Y_input(:)), mean(double(Y_input(:))));
catch ME
    fprintf('  ✗ ОШИБКА при чтении входного кадра: %s\n', ME.message);
    return;
end

%% Шаг 3: Применяем MATLAB реализацию GDF (только к Y plane)
fprintf('\nШаг 3: Применение MATLAB GDF фильтра\n');

try
    tic;
    Y_matlab = applyGdfFilter(Y_input, gdfParams);
    elapsed = toc;
    fprintf('  ✓ GDF фильтр применен за %.2f сек\n', elapsed);
    fprintf('    Range: [%d, %d], mean=%.1f\n', min(Y_matlab(:)), max(Y_matlab(:)), mean(double(Y_matlab(:))));
catch ME
    fprintf('  ✗ ОШИБКА при применении GDF: %s\n', ME.message);
    fprintf('    %s\n', ME.getReport());
    return;
end

% U и V плоскости остаются без изменений (GDF применяется только к Y)
U_matlab = U_input;
V_matlab = V_input;

%% Шаг 4: Сохраняем результат MATLAB во временный YUV файл
fprintf('\nШаг 4: Сохранение MATLAB результата\n');

try
    writeYUV(outputFilename, Y_matlab, U_matlab, V_matlab, bitDepth);
    fprintf('  ✓ Результат сохранен: %s\n', outputFilename);
catch ME
    fprintf('  ✗ ОШИБКА при сохранении: %s\n', ME.message);
    return;
end

%% Шаг 5: Сравниваем MATLAB результат с эталоном анализатора
fprintf('\nШаг 5: Сравнение с эталоном\n');

try
    comparison = compareYUV(outputFilename, referenceFilename, width, height, bitDepth, chromaFormat, frameNum);
    fprintf('  ✓ Сравнение выполнено\n');
catch ME
    fprintf('  ✗ ОШИБКА при сравнении: %s\n', ME.message);
    fprintf('    %s\n', ME.getReport());
    return;
end

%% Шаг 6: Вывод статистики
fprintf('\n=== Статистика разницы ===\n');

% Y plane
fprintf('\nY plane:\n');
fprintf('  Максимальная разница: %d\n', comparison.Y.maxDiff);
fprintf('  Средняя разница: %.2f\n', comparison.Y.meanDiff);
fprintf('  Медианная разница: %d\n', comparison.Y.medianDiff);
fprintf('  Стд. откл.: %.2f\n', comparison.Y.stdDiff);
fprintf('  Идентичных пикселей: %.2f%% (%d/%d)\n', ...
    comparison.Y.identicalPercent, comparison.Y.identicalPixels, comparison.Y.totalPixels);

fprintf('\n  Распределение ошибок:\n');
dist = comparison.Y.errorDistribution;
for i = 1:length(dist.counts)
    if i < length(dist.bins)
        if dist.bins(i+1) == Inf
            fprintf('    >= %d: %d пикселей (%.2f%%)\n', ...
                dist.bins(i), dist.counts(i), dist.percents(i));
        else
            fprintf('    %d-%d: %d пикселей (%.2f%%)\n', ...
                dist.bins(i), dist.bins(i+1)-1, dist.counts(i), dist.percents(i));
        end
    end
end

% U plane
fprintf('\nU plane:\n');
fprintf('  Идентичных пикселей: %.2f%% (%d/%d)\n', ...
    comparison.U.identicalPercent, comparison.U.identicalPixels, comparison.U.totalPixels);
if comparison.U.maxDiff > 0
    fprintf('  Максимальная разница: %d\n', comparison.U.maxDiff);
end

% V plane
fprintf('\nV plane:\n');
fprintf('  Идентичных пикселей: %.2f%% (%d/%d)\n', ...
    comparison.V.identicalPercent, comparison.V.identicalPixels, comparison.V.totalPixels);
if comparison.V.maxDiff > 0
    fprintf('  Максимальная разница: %d\n', comparison.V.maxDiff);
end

%% Шаг 7: Визуализация
fprintf('\nШаг 7: Визуализация результатов\n');

figure('Name', 'GDF Comparison', 'Position', [50, 50, 1600, 900]);

% Входной кадр
subplot(2, 3, 1);
imshow(Y_input, [0, 1023]);
title(sprintf('Input (CCSO)\nRange: [%d, %d]', min(Y_input(:)), max(Y_input(:))));
colorbar;

% Эталонный выход
subplot(2, 3, 2);
[Y_ref, ~, ~] = readYUV(referenceFilename, width, height, frameNum, bitDepth, chromaFormat);
imshow(Y_ref, [0, 1023]);
title(sprintf('Reference (Analyzer GDF)\nRange: [%d, %d]', min(Y_ref(:)), max(Y_ref(:))));
colorbar;

% MATLAB выход
subplot(2, 3, 3);
imshow(Y_matlab, [0, 1023]);
title(sprintf('MATLAB GDF\nRange: [%d, %d]', min(Y_matlab(:)), max(Y_matlab(:))));
colorbar;

% Разница (тепловая карта)
subplot(2, 3, 4);
imagesc(comparison.Y.diff);
colormap(gca, 'jet');
colorbar;
title(sprintf('Difference (MATLAB - Reference)\nMax: %d, Mean: %.2f', ...
    comparison.Y.maxDiff, comparison.Y.meanDiff));
axis image;

% Абсолютная разница
subplot(2, 3, 5);
imagesc(comparison.Y.absDiff);
colormap(gca, 'hot');
colorbar;
title(sprintf('Absolute Difference\nMax: %d, Mean: %.2f', ...
    comparison.Y.maxDiff, comparison.Y.meanDiff));
axis image;

% Гистограмма ошибок
subplot(2, 3, 6);
histogram(comparison.Y.absDiff(:), 100);
xlabel('Absolute Difference');
ylabel('Pixel Count');
title(sprintf('Error Distribution\nIdentical: %.1f%%', comparison.Y.identicalPercent));
grid on;

fprintf('  ✓ Визуализация создана\n');

%% Итоговая оценка
fprintf('\n========================================\n');
if comparison.identical
    fprintf('✓✓✓ ТЕСТ ПРОЙДЕН ИДЕАЛЬНО! ✓✓✓\n');
    fprintf('Все плоскости идентичны эталону.\n');
elseif comparison.Y.identicalPercent == 100 && ...
       comparison.U.identicalPercent == 100 && ...
       comparison.V.identicalPercent == 100
    fprintf('✓✓✓ ТЕСТ ПРОЙДЕН ИДЕАЛЬНО! ✓✓✓\n');
    fprintf('Все пиксели идентичны эталону.\n');
elseif comparison.Y.identicalPercent >= 99.9
    fprintf('✓✓ ТЕСТ ПРОЙДЕН С ОТЛИЧНЫМ РЕЗУЛЬТАТОМ! ✓✓\n');
    fprintf('%.2f%% пикселей Y идентичны (очень близко к эталону).\n', comparison.Y.identicalPercent);
elseif comparison.Y.identicalPercent >= 95
    fprintf('✓ ТЕСТ ПРОЙДЕН С ХОРОШИМ РЕЗУЛЬТАТОМ\n');
    fprintf('%.2f%% пикселей Y идентичны. Возможны небольшие различия в округлении.\n', comparison.Y.identicalPercent);
elseif comparison.Y.identicalPercent >= 80
    fprintf('⚠ ТЕСТ ПРОЙДЕН С ПРЕДУПРЕЖДЕНИЯМИ\n');
    fprintf('%.2f%% пикселей Y идентичны. Есть заметные различия.\n', comparison.Y.identicalPercent);
else
    fprintf('✗ ТЕСТ НЕ ПРОЙДЕН\n');
    fprintf('Только %.2f%% пикселей Y идентичны. Проверьте реализацию.\n', comparison.Y.identicalPercent);
end
fprintf('========================================\n');

fprintf('\nРекомендации:\n');
if comparison.Y.identicalPercent < 100
    fprintf('1. Проверьте правильность GDF параметров (qpIdx, refDstIdx, gdfPixScale)\n');
    fprintf('2. Убедитесь что файлы экстрагированы на правильной стадии пайплайна\n');
    fprintf('3. Проверьте что используется правильный source buffer (CCSO vs CDEF)\n');
    if comparison.Y.maxDiff > 10
        fprintf('4. Большая максимальная ошибка (%d) может указывать на проблему в алгоритме\n', comparison.Y.maxDiff);
    end
end
