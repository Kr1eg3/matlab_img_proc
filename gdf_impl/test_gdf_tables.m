% test_gdf_tables.m - проверка корректности загрузки GDF таблиц
%
% Этот скрипт проверяет:
% 1. Корректность загрузки таблиц
% 2. Размеры массивов
% 3. Диапазоны значений
% 4. Доступ к элементам

clear all; close all; clc;

fprintf('=== Тест GDF lookup таблиц ===\n\n');

%% Шаг 1: Загрузка таблиц
fprintf('Шаг 1: Загрузка таблиц\n');
try
    tic;
    tables = loadGdfTables();
    elapsed = toc;
    fprintf('✓ Таблицы загружены успешно за %.3f сек\n\n', elapsed);
catch ME
    fprintf('✗ ОШИБКА при загрузке: %s\n', ME.message);
    return;
end

%% Шаг 2: Проверка размеров
fprintf('Шаг 2: Проверка размеров\n');

% Inter таблица: должна быть 5 x 6 x 1000
interSize = size(tables.inter);
if isequal(interSize, [5, 6, 1000])
    fprintf('  ✓ Gdf_Inter_Error: %s (OK)\n', mat2str(interSize));
else
    fprintf('  ✗ Gdf_Inter_Error: %s (ожидалось [5 6 1000])\n', mat2str(interSize));
end

% Intra таблица: должна быть 6 x 4096
intraSize = size(tables.intra);
if isequal(intraSize, [6, 4096])
    fprintf('  ✓ Gdf_Intra_Error: %s (OK)\n', mat2str(intraSize));
else
    fprintf('  ✗ Gdf_Intra_Error: %s (ожидалось [6 4096])\n', mat2str(intraSize));
end

%% Шаг 3: Проверка диапазонов значений
fprintf('\nШаг 3: Проверка диапазонов значений\n');

% Inter таблица
interMin = min(tables.inter(:));
interMax = max(tables.inter(:));
interMean = mean(double(tables.inter(:)));
fprintf('  Gdf_Inter_Error:\n');
fprintf('    min = %d, max = %d, mean = %.2f\n', interMin, interMax, interMean);

% Intra таблица
intraMin = min(tables.intra(:));
intraMax = max(tables.intra(:));
intraMean = mean(double(tables.intra(:)));
fprintf('  Gdf_Intra_Error:\n');
fprintf('    min = %d, max = %d, mean = %.2f\n', intraMin, intraMax, intraMean);

%% Шаг 4: Тест доступа через функции
fprintf('\nШаг 4: Тест доступа через функции\n');

% Проверяем getGdfInterError
try
    % В C++ это было бы: Gdf_Inter_Error[0][0][0]
    % В MATLAB: refDstIdx=1, qpIdx=1, pos=1
    err1 = getGdfInterError(tables, 1, 1, 1);
    fprintf('  ✓ getGdfInterError(1,1,1) = %d\n', err1);

    % Еще один пример: Gdf_Inter_Error[4][5][999]
    % В MATLAB: refDstIdx=5, qpIdx=6, pos=1000
    err2 = getGdfInterError(tables, 5, 6, 1000);
    fprintf('  ✓ getGdfInterError(5,6,1000) = %d\n', err2);
catch ME
    fprintf('  ✗ ОШИБКА в getGdfInterError: %s\n', ME.message);
end

% Проверяем getGdfIntraError
try
    % В C++ это было бы: Gdf_Intra_Error[0][0]
    % В MATLAB: qpIdx=1, pos=1
    err3 = getGdfIntraError(tables, 1, 1);
    fprintf('  ✓ getGdfIntraError(1,1) = %d\n', err3);

    % Еще один пример: Gdf_Intra_Error[5][4095]
    % В MATLAB: qpIdx=6, pos=4096
    err4 = getGdfIntraError(tables, 6, 4096);
    fprintf('  ✓ getGdfIntraError(6,4096) = %d\n', err4);
catch ME
    fprintf('  ✗ ОШИБКА в getGdfIntraError: %s\n', ME.message);
end

%% Шаг 5: Проверка консистентности
fprintf('\nШаг 5: Проверка консистентности\n');

% Проверяем что функции возвращают те же значения что и прямой доступ
directAccess = tables.inter(1, 1, 1);
functionAccess = getGdfInterError(tables, 1, 1, 1);
if directAccess == functionAccess
    fprintf('  ✓ Прямой доступ == функция доступа для Inter таблицы\n');
else
    fprintf('  ✗ Несоответствие: direct=%d, function=%d\n', directAccess, functionAccess);
end

directAccess = tables.intra(1, 1);
functionAccess = getGdfIntraError(tables, 1, 1);
if directAccess == functionAccess
    fprintf('  ✓ Прямой доступ == функция доступа для Intra таблицы\n');
else
    fprintf('  ✗ Несоответствие: direct=%d, function=%d\n', directAccess, functionAccess);
end

%% Шаг 6: Визуализация распределения
fprintf('\nШаг 6: Визуализация распределения\n');

figure('Name', 'GDF Tables Distribution', 'Position', [100, 100, 1200, 500]);

% Inter таблица - показываем одну плоскость
subplot(1, 2, 1);
imagesc(squeeze(tables.inter(1, :, :)));
colorbar;
title('Gdf\_Inter\_Error [1, :, :]');
xlabel('pos (0-999)');
ylabel('qpIdx (0-5)');

% Intra таблица
subplot(1, 2, 2);
imagesc(tables.intra);
colorbar;
title('Gdf\_Intra\_Error');
xlabel('pos (0-4095)');
ylabel('qpIdx (0-5)');

fprintf('✓ Визуализация создана\n');

%% Итоговый результат
fprintf('\n========================================\n');
fprintf('Тест завершен успешно!\n');
fprintf('========================================\n');
fprintf('\nИспользование в коде:\n');
fprintf('1. tables = loadGdfTables();  %% Загрузить таблицы (один раз)\n');
fprintf('2. err = getGdfInterError(tables, refDstIdx, qpIdx, pos);\n');
fprintf('3. err = getGdfIntraError(tables, qpIdx, pos);\n');
fprintf('\nВНИМАНИЕ: Индексы в MATLAB начинаются с 1!\n');
fprintf('  C++: Gdf_Inter_Error[0][0][0]\n');
fprintf('  MATLAB: getGdfInterError(tables, 1, 1, 1)\n');
