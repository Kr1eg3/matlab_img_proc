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
printComparisonStats(comparison);

%% Шаг 7: Визуализация
fprintf('\nШаг 7: Визуализация результатов\n');

[Y_ref, ~, ~] = readYUV(referenceFilename, width, height, frameNum, bitDepth, chromaFormat);

visOptions = struct();
visOptions.title = 'GDF Comparison';
visOptions.Y_reference = Y_ref;
visOptions.bitDepth = bitDepth;
visOptions.inputTitle = 'Input (CCSO)';
visOptions.outputTitle = 'MATLAB GDF';
visOptions.referenceTitle = 'Reference (Analyzer GDF)';

visualizeComparison(Y_input, Y_matlab, comparison, visOptions);
fprintf('  ✓ Визуализация создана\n');

%% Итоговая оценка
resultOptions = struct();
resultOptions.testName = 'GDF Filter';
resultOptions.recommendations = {
    'Проверьте правильность GDF параметров (qpIdx, refDstIdx, gdfPixScale)'
    'Убедитесь что файлы экстрагированы на правильной стадии пайплайна'
    'Проверьте что используется правильный source buffer (CCSO vs CDEF)'
};

printTestResult(comparison, resultOptions);
