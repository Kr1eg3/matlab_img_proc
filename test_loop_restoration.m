% test_loop_restoration.m - тест Loop Restoration реализации
%
% Этот скрипт:
% 1. Читает CDEF/CCSO frame (вход для Loop Restoration)
% 2. Применяет MATLAB реализацию Loop Restoration
% 3. Сохраняет результат во временный файл
% 4. Сравнивает с эталонным Loop Restoration выходом анализатора (если есть)
%
% Примечание: Loop Restoration запускается ПОСЛЕ CDEF/CCSO и ДО GDF

clear all; close all; clc;

fprintf('=== Loop Restoration Filter Test ===\n\n');

%% Шаг 1: Параметры видео
fprintf('Шаг 1: Настройка параметров\n');

% Путь к YUV файлам (извлеченным из анализатора)
% TODO: Заменить на реальные пути к вашим test файлам
inputFilename = 'C:/Users/kiwi1/Desktop/cdef_filter.yuv';  % Вход для Loop Restoration
outputFilename = 'C:/Users/kiwi1/Desktop/lr_matlab_output.yuv';  % Выход MATLAB LR
referenceFilename = '';  % Эталонный выход LR из анализатора (если есть)

% Параметры видео
width = 1920;
height = 1080;
bitDepth = 10;
chromaFormat = 444;
frameNum = 1;  % Номер кадра для тестирования

fprintf('  Video: %dx%d, %d-bit, YUV%d\n', width, height, bitDepth, chromaFormat);
fprintf('  Testing frame: %d\n', frameNum);

%% Шаг 2: Loop Restoration параметры
fprintf('\nШаг 2: Настройка Loop Restoration параметров\n');

% Общие параметры
lrParams.bitDepth = bitDepth;
lrParams.chromaFormat = chromaFormat;

% Параметры для Y plane
lrParams.Y.frame_restoration_type = 2;  % RESTORE_WIENER_NONSEP
lrParams.Y.restoration_unit_size = 64;  % Стандартный размер unit

% Для тестирования создадим simple unit_info
% В реальности эти параметры должны читаться из bitstream
num_units_y = ceil(height / lrParams.Y.restoration_unit_size);
num_units_x = ceil(width / lrParams.Y.restoration_unit_size);
total_units = num_units_y * num_units_x;

fprintf('  Y plane: restoration_type=%d (WIENER_NONSEP), unit_size=%d\n', ...
    lrParams.Y.frame_restoration_type, lrParams.Y.restoration_unit_size);
fprintf('  Total restoration units: %d (%dx%d)\n', total_units, num_units_x, num_units_y);

% Создаём unit_info для каждого unit
% Для простого теста используем одинаковые параметры для всех units
for i = 1:total_units
    lrParams.Y.unit_info(i).restoration_type = lrParams.Y.frame_restoration_type;
    lrParams.Y.unit_info(i).num_classes = 1;  % Single-class для начала

    % Создаём identity фильтр (коэффициенты для pass-through)
    % В реальности эти коэффициенты читаются из bitstream
    lrParams.Y.unit_info(i).wiener_info.num_classes = 1;

    % Создаём нейтральные коэффициенты (identity filter - 3x3)
    % Центральный коэффициент = 128 (после нормализации дает 1.0)
    % Остальные = 0
    taps = zeros(1, 32);  % WIENERNS_TAPS_MAX = 32
    taps(5) = 128;  % Центральный tap для 3x3 фильтра
    lrParams.Y.unit_info(i).wiener_info.allfiltertaps = int16(taps);
end

% Параметры для U и V planes
% Для простоты пока используем RESTORE_NONE (без фильтрации)
lrParams.U.frame_restoration_type = 0;  % RESTORE_NONE
lrParams.V.frame_restoration_type = 0;  % RESTORE_NONE

fprintf('  U plane: restoration_type=%d (NONE)\n', lrParams.U.frame_restoration_type);
fprintf('  V plane: restoration_type=%d (NONE)\n', lrParams.V.frame_restoration_type);

%% Шаг 3: Читаем входной кадр
fprintf('\nШаг 3: Чтение входного кадра (CDEF/CCSO output)\n');

addpath('common');
addpath('loop_restoration');

try
    [Y_input, U_input, V_input] = readYUV(inputFilename, width, height, frameNum, bitDepth, chromaFormat);
    fprintf('  ✓ Входной кадр прочитан: Y=%dx%d, U=%dx%d, V=%dx%d\n', ...
        size(Y_input, 2), size(Y_input, 1), ...
        size(U_input, 2), size(U_input, 1), ...
        size(V_input, 2), size(V_input, 1));
    fprintf('    Y range: [%d, %d], mean=%.1f\n', ...
        min(Y_input(:)), max(Y_input(:)), mean(double(Y_input(:))));
catch ME
    fprintf('  ✗ ОШИБКА при чтении входного кадра: %s\n', ME.message);
    fprintf('    Файл: %s\n', inputFilename);
    fprintf('    Проверьте что файл существует и параметры корректны\n');
    return;
end

%% Шаг 4: Применяем MATLAB реализацию Loop Restoration
fprintf('\nШаг 4: Применение MATLAB Loop Restoration фильтра\n');

try
    tic;
    [Y_matlab, U_matlab, V_matlab] = lr_main(Y_input, U_input, V_input, lrParams);
    elapsed = toc;
    fprintf('  ✓ Loop Restoration фильтр применен за %.2f сек\n', elapsed);
    fprintf('    Y range: [%d, %d], mean=%.1f\n', ...
        min(Y_matlab(:)), max(Y_matlab(:)), mean(double(Y_matlab(:))));
catch ME
    fprintf('  ✗ ОШИБКА при применении Loop Restoration: %s\n', ME.message);
    fprintf('    %s\n', ME.getReport());
    return;
end

%% Шаг 5: Сохраняем результат MATLAB во временный YUV файл
fprintf('\nШаг 5: Сохранение MATLAB результата\n');

try
    writeYUV(outputFilename, Y_matlab, U_matlab, V_matlab, bitDepth);
    fprintf('  ✓ Результат сохранен: %s\n', outputFilename);
catch ME
    fprintf('  ✗ ОШИБКА при сохранении: %s\n', ME.message);
    return;
end

%% Шаг 6: Сравнение с эталоном (если есть)
if ~isempty(referenceFilename) && exist(referenceFilename, 'file')
    fprintf('\nШаг 6: Сравнение с эталоном\n');

    try
        comparison = compareYUV(outputFilename, referenceFilename, width, height, bitDepth, chromaFormat, frameNum);
        fprintf('  ✓ Сравнение выполнено\n');

        % Вывод статистики
        fprintf('\n=== Статистика разницы (Y plane) ===\n');
        fprintf('  Максимальная разница: %d\n', comparison.Y.maxDiff);
        fprintf('  Средняя разница: %.2f\n', comparison.Y.meanDiff);
        fprintf('  Идентичных пикселей: %.2f%% (%d/%d)\n', ...
            comparison.Y.identicalPercent, comparison.Y.identicalPixels, comparison.Y.totalPixels);

        % Оценка результата
        if comparison.Y.identicalPercent == 100
            fprintf('\n✓✓✓ ТЕСТ ПРОЙДЕН ИДЕАЛЬНО! ✓✓✓\n');
        elseif comparison.Y.identicalPercent >= 99
            fprintf('\n✓✓ ТЕСТ ПРОЙДЕН С ОТЛИЧНЫМ РЕЗУЛЬТАТОМ! ✓✓\n');
        elseif comparison.Y.identicalPercent >= 95
            fprintf('\n✓ ТЕСТ ПРОЙДЕН С ХОРОШИМ РЕЗУЛЬТАТОМ\n');
        else
            fprintf('\n⚠ ЕСТЬ РАЗЛИЧИЯ С ЭТАЛОНОМ\n');
        end
    catch ME
        fprintf('  ✗ ОШИБКА при сравнении: %s\n', ME.message);
    end
else
    fprintf('\nШаг 6: Эталонный файл не указан - пропускаем сравнение\n');
    fprintf('  Для сравнения с эталоном укажите referenceFilename\n');
end

%% Шаг 7: Визуализация результатов
fprintf('\nШаг 7: Визуализация результатов\n');

figure('Name', 'Loop Restoration Test', 'Position', [50, 50, 1600, 500]);

% Входной кадр
subplot(1, 3, 1);
imshow(Y_input, [0, 1023]);
title(sprintf('Input (CDEF/CCSO)\nRange: [%d, %d]', min(Y_input(:)), max(Y_input(:))));
colorbar;

% MATLAB выход
subplot(1, 3, 2);
imshow(Y_matlab, [0, 1023]);
title(sprintf('MATLAB Loop Restoration\nRange: [%d, %d]', min(Y_matlab(:)), max(Y_matlab(:))));
colorbar;

% Разница (если есть эталон)
if ~isempty(referenceFilename) && exist(referenceFilename, 'file')
    subplot(1, 3, 3);
    imagesc(comparison.Y.absDiff);
    colormap(gca, 'hot');
    colorbar;
    title(sprintf('Absolute Difference\nMax: %d, Mean: %.2f', ...
        comparison.Y.maxDiff, comparison.Y.meanDiff));
    axis image;
else
    % Разница между входом и выходом
    subplot(1, 3, 3);
    diff = int32(Y_matlab) - int32(Y_input);
    imagesc(abs(diff));
    colormap(gca, 'hot');
    colorbar;
    title(sprintf('|Output - Input|\nMax: %d, Mean: %.2f', ...
        max(abs(diff(:))), mean(abs(diff(:)))));
    axis image;
end

fprintf('  ✓ Визуализация создана\n');

%% Итог
fprintf('\n========================================\n');
fprintf('ТЕСТ ЗАВЕРШЕН\n');
fprintf('========================================\n');
fprintf('\nСледующие шаги:\n');
fprintf('1. Проверьте выходной файл: %s\n', outputFilename);
fprintf('2. Сравните с эталоном из анализатора (если есть)\n');
fprintf('3. Для полной функциональности добавьте:\n');
fprintf('   - Реальные коэффициенты фильтра из bitstream\n');
fprintf('   - Multi-class фильтрацию\n');
fprintf('   - PC Wiener фильтр\n');
fprintf('   - Chroma фильтрацию\n');
fprintf('========================================\n');
