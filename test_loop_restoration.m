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
comparison = [];
if ~isempty(referenceFilename) && exist(referenceFilename, 'file')
    fprintf('\nШаг 6: Сравнение с эталоном\n');

    try
        comparison = compareYUV(outputFilename, referenceFilename, width, height, bitDepth, chromaFormat, frameNum);
        fprintf('  ✓ Сравнение выполнено\n');

        % Вывод статистики
        printComparisonStats(comparison);
    catch ME
        fprintf('  ✗ ОШИБКА при сравнении: %s\n', ME.message);
    end
else
    fprintf('\nШаг 6: Эталонный файл не указан - пропускаем сравнение\n');
    fprintf('  Для сравнения с эталоном укажите referenceFilename\n');
end

%% Шаг 7: Визуализация результатов
fprintf('\nШаг 7: Визуализация результатов\n');

visOptions = struct();
visOptions.title = 'Loop Restoration Test';
visOptions.bitDepth = bitDepth;
visOptions.inputTitle = 'Input (CDEF/CCSO)';
visOptions.outputTitle = 'MATLAB Loop Restoration';
visOptions.figurePosition = [50, 50, 1600, 500];

if ~isempty(referenceFilename) && exist(referenceFilename, 'file')
    [Y_ref, ~, ~] = readYUV(referenceFilename, width, height, frameNum, bitDepth, chromaFormat);
    visOptions.Y_reference = Y_ref;
    visOptions.referenceTitle = 'Reference (Analyzer LR)';
end

visualizeComparison(Y_input, Y_matlab, comparison, visOptions);
fprintf('  ✓ Визуализация создана\n');

%% Итоговая оценка
if ~isempty(comparison)
    resultOptions = struct();
    resultOptions.testName = 'Loop Restoration';
    resultOptions.recommendations = {
        'Проверьте правильность коэффициентов фильтра из bitstream'
        'Убедитесь что файлы экстрагированы на правильной стадии пайплайна'
        'Проверьте что используется правильный restoration_type'
    };
    printTestResult(comparison, resultOptions);
else
    fprintf('\n========================================\n');
    fprintf('ТЕСТ ЗАВЕРШЕН (без сравнения с эталоном)\n');
    fprintf('========================================\n');
    fprintf('\nДля полного теста укажите referenceFilename\n');
end
