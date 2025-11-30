% test_readYUV.m - тестовый скрипт для проверки функции readYUV
%
% Этот скрипт проверяет корректность чтения YUV файлов

clear all; close all; clc;

%% Добавляем путь к общим функциям
addpath('common');

fprintf('=== Тест функции readYUV ===\n\n');

%% Шаг 1: Определяем параметры видео
% Из размера файла (12MB) вычисляем параметры

filename = 'C:/Users/kiwi1/Desktop/cdef_filter.yuv';

% Получаем размер файла
fileInfo = dir(filename);
fileSizeBytes = fileInfo.bytes;

fprintf('Размер файла: %.2f MB\n', fileSizeBytes / 1024^2);

% Пробуем разные разрешения для 10-bit YUV420
% Формула: frameSize = width * height * 1.5 * 2 (2 байта на сэмпл)

possibleResolutions = [
    1920, 1080;
    1280, 720;
    3840, 2160;
    2560, 1440;
];

fprintf('\nПроверка возможных разрешений:\n');
for i = 1:size(possibleResolutions, 1)
    w = possibleResolutions(i, 1);
    h = possibleResolutions(i, 2);

    % YUV420: Y=w*h, U=V=w/2*h/2
    frameSize = w * h * 1.5 * 2; % 2 байта на сэмпл для 10-bit
    numFrames = fileSizeBytes / frameSize;

    fprintf('  %dx%d: %.2f кадров', w, h, numFrames);

    if abs(numFrames - round(numFrames)) < 0.01
        fprintf(' ✓ ПОДХОДИТ!\n');
        width = w;
        height = h;
        numFrames = round(numFrames);
    else
        fprintf('\n');
    end
end

% Если не нашли - используем по умолчанию
if ~exist('width', 'var')
    fprintf('\nИспользуем параметры по умолчанию: 1920x1080\n');
    width = 1920;
    height = 1080;
    frameSize = width * height * 1.5 * 2;
    numFrames = floor(fileSizeBytes / frameSize);
end

bitDepth = 10;
chromaFormat = 444;

switch chromaFormat
    case 420
        UVwidth = width / 2;
        UVheight = height / 2;
    case 422
        UVwidth = width / 2;
        UVheight = height;
    case 444
        UVwidth = width;
        UVheight = height;
end

fprintf('\n--- Выбранные параметры ---\n');
fprintf('Разрешение: %dx%d\n', width, height);
fprintf('Битность: %d bit\n', bitDepth);
fprintf('Формат: YUV%d\n', chromaFormat);
fprintf('Количество кадров: %d\n', numFrames);

%% Шаг 2: Читаем первый кадр
fprintf('\n=== Чтение первого кадра ===\n');

try
    tic;
    [Y, U, V] = readYUV(filename, width, height, 1, bitDepth, chromaFormat);
    elapsed = toc;

    fprintf('✓ Кадр прочитан успешно за %.3f сек\n', elapsed);

    % Проверяем размеры
    fprintf('\nПроверка размеров:\n');

    if isequal(size(Y), [height, width])
        Ycheck = 'OK';
    else
        Ycheck = 'FAIL';
    end
    fprintf('  Y: %dx%d (ожидалось %dx%d) %s\n', ...
        size(Y, 2), size(Y, 1), width, height, Ycheck);

    if isequal(size(U), [UVheight, UVwidth])
        Ucheck = 'OK';
    else
        Ucheck = 'FAIL';
    end
    fprintf('  U: %dx%d (ожидалось %dx%d) %s\n', ...
        size(U, 2), size(U, 1), UVwidth, UVheight, Ucheck);

    if isequal(size(V), [UVheight, UVwidth])
        Vcheck = 'OK';
    else
        Vcheck = 'FAIL';
    end
    fprintf('  V: %dx%d (ожидалось %dx%d) %s\n', ...
        size(V, 2), size(V, 1), UVwidth, UVheight, Vcheck);

    % Проверяем диапазон значений
    fprintf('\nПроверка диапазона значений:\n');
    fprintf('  Y: min=%d, max=%d, mean=%.1f\n', ...
        min(Y(:)), max(Y(:)), mean(Y(:)));
    fprintf('  U: min=%d, max=%d, mean=%.1f\n', ...
        min(U(:)), max(U(:)), mean(U(:)));
    fprintf('  V: min=%d, max=%d, mean=%.1f\n', ...
        min(V(:)), max(V(:)), mean(V(:)));

    maxValue = 2^bitDepth - 1;
    if max(Y(:)) <= maxValue && max(U(:)) <= maxValue && max(V(:)) <= maxValue
        fprintf('  ✓ Все значения в допустимом диапазоне [0, %d]\n', maxValue);
    else
        fprintf('  ✗ ВНИМАНИЕ: значения превышают максимум!\n');
    end

catch ME
    fprintf('✗ ОШИБКА при чтении: %s\n', ME.message);
    return;
end

%% Шаг 3: Визуализация
fprintf('\n=== Визуализация ===\n');

figure('Name', 'Test readYUV', 'Position', [100, 100, 1400, 500]);

% Y компонента
subplot(1, 3, 1);
imshow(Y, [0, 1023]);
title(sprintf('Y plane (%dx%d)', width, height));
colorbar;

% U компонента
subplot(1, 3, 2);
imshow(U, [0, 1023]);
title(sprintf('U plane (%dx%d)', UVwidth, UVheight));
colorbar;

% V компонента
subplot(1, 3, 3);
imshow(V, [0, 1023]);
title(sprintf('V plane (%dx%d)', UVwidth, UVheight));
colorbar;

fprintf('✓ Визуализация создана\n');

%% Шаг 4: Проверка на черное/белое изображение
fprintf('\n=== Проверка содержимого ===\n');

if std(double(Y(:))) < 1
    fprintf('  ⚠ ВНИМАНИЕ: Y plane почти константа (возможно черное изображение)\n');
else
    fprintf('  ✓ Y plane содержит изменяющиеся значения\n');
end

% Проверяем есть ли детали
% Нормализуем для edge detection
Y_normalized = double(Y) / double(max(Y(:)));
edges = edge(Y_normalized, 'canny');
edgePercent = 100 * sum(edges(:)) / numel(edges);
fprintf('  Процент границ: %.2f%%\n', edgePercent);

if edgePercent < 0.1
    fprintf('  ⚠ ВНИМАНИЕ: Очень мало границ (возможно некорректное чтение)\n');
elseif edgePercent > 0.5
    fprintf('  ✓ Изображение содержит детали\n');
end

%% Шаг 5: Сравнение с другим кадром (если есть несколько кадров)
if numFrames > 1
    fprintf('\n=== Сравнение кадров ===\n');

    frameToCompare = min(2, numFrames);
    [Y2, ~, ~] = readYUV(filename, width, height, frameToCompare, bitDepth, chromaFormat);

    diff = abs(double(Y2) - double(Y));
    maxDiff = max(diff(:));
    avgDiff = mean(diff(:));

    fprintf('Сравнение кадра 1 и кадра %d:\n', frameToCompare);
    fprintf('  Максимальная разница: %d\n', maxDiff);
    fprintf('  Средняя разница: %.2f\n', avgDiff);

    if maxDiff == 0
        fprintf('  ⚠ ВНИМАНИЕ: Кадры идентичны (возможно статическое изображение)\n');
    else
        fprintf('  ✓ Кадры отличаются\n');
    end
end

%% Шаг 6: Дополнительные тесты
fprintf('\n=== Дополнительные тесты ===\n');

% Тест чтения последнего кадра
try
    [Ylast, ~, ~] = readYUV(filename, width, height, numFrames, bitDepth, chromaFormat);
    fprintf('  ✓ Последний кадр (%d) читается корректно\n', numFrames);
catch
    fprintf('  ✗ Не удалось прочитать последний кадр\n');
end

% Тест на выход за границы
try
    [~, ~, ~] = readYUV(filename, width, height, numFrames + 1, bitDepth, chromaFormat);
    fprintf('  ⚠ Чтение за границами файла не вызвало ошибку\n');
catch
    fprintf('  ✓ Чтение за границами корректно обрабатывается\n');
end

%% Итоговый результат
fprintf('\n========================================\n');
fprintf('Тест завершен!\n');
fprintf('========================================\n');
fprintf('\nРекомендации:\n');
fprintf('1. Проверьте визуализацию - должны быть видны детали\n');
fprintf('2. Если изображение черное/белое - проверьте параметры\n');
fprintf('3. Для GDF тестов используйте оба файла:\n');
fprintf('   - cdef_filter.yuv (input для GDF)\n');
fprintf('   - gdf_filter.yuv (output после GDF)\n');

%% Сохраняем параметры для других скриптов
save('video_params.mat', 'width', 'height', 'bitDepth', 'chromaFormat', 'numFrames');
fprintf('\nПараметры сохранены в video_params.mat\n');
