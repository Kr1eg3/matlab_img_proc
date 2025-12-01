function passed = printTestResult(comparison, options)
% printTestResult - выводит итоговую оценку результата теста
%
% Параметры:
%   comparison - структура от compareYUV()
%   options - структура с опциями (опционально):
%     .testName - название теста (по умолчанию 'Test')
%     .thresholds - пороги для оценок (структура):
%       .perfect - порог для идеального результата (по умолчанию 100)
%       .excellent - порог для отличного результата (по умолчанию 99.9)
%       .good - порог для хорошего результата (по умолчанию 95)
%       .warning - порог для предупреждения (по умолчанию 80)
%     .showRecommendations - показывать рекомендации (по умолчанию true)
%     .recommendations - cell array с рекомендациями (опционально)
%
% Возвращает:
%   passed - true если тест пройден (>= warning threshold)

    if nargin < 2
        options = struct();
    end

    % Значения по умолчанию
    if ~isfield(options, 'testName'), options.testName = 'Test'; end
    if ~isfield(options, 'showRecommendations'), options.showRecommendations = true; end

    % Пороги по умолчанию
    if ~isfield(options, 'thresholds')
        options.thresholds = struct();
    end
    th = options.thresholds;
    if ~isfield(th, 'perfect'), th.perfect = 100; end
    if ~isfield(th, 'excellent'), th.excellent = 99.9; end
    if ~isfield(th, 'good'), th.good = 95; end
    if ~isfield(th, 'warning'), th.warning = 80; end

    fprintf('\n========================================\n');

    % Определяем результат
    yPercent = comparison.Y.identicalPercent;
    uPercent = comparison.U.identicalPercent;
    vPercent = comparison.V.identicalPercent;

    if comparison.identical || (yPercent == 100 && uPercent == 100 && vPercent == 100)
        fprintf('ТЕСТ ПРОЙДЕН ИДЕАЛЬНО!\n');
        fprintf('Все плоскости идентичны эталону.\n');
        passed = true;
        resultLevel = 'perfect';
    elseif yPercent >= th.excellent
        fprintf('ТЕСТ ПРОЙДЕН С ОТЛИЧНЫМ РЕЗУЛЬТАТОМ!\n');
        fprintf('%.2f%% пикселей Y идентичны (очень близко к эталону).\n', yPercent);
        passed = true;
        resultLevel = 'excellent';
    elseif yPercent >= th.good
        fprintf('ТЕСТ ПРОЙДЕН С ХОРОШИМ РЕЗУЛЬТАТОМ\n');
        fprintf('%.2f%% пикселей Y идентичны. Возможны небольшие различия в округлении.\n', yPercent);
        passed = true;
        resultLevel = 'good';
    elseif yPercent >= th.warning
        fprintf('ТЕСТ ПРОЙДЕН С ПРЕДУПРЕЖДЕНИЯМИ\n');
        fprintf('%.2f%% пикселей Y идентичны. Есть заметные различия.\n', yPercent);
        passed = true;
        resultLevel = 'warning';
    else
        fprintf('ТЕСТ НЕ ПРОЙДЕН\n');
        fprintf('Только %.2f%% пикселей Y идентичны. Проверьте реализацию.\n', yPercent);
        passed = false;
        resultLevel = 'failed';
    end

    fprintf('========================================\n');

    % Рекомендации
    if options.showRecommendations && yPercent < 100
        fprintf('\nРекомендации:\n');

        % Пользовательские рекомендации
        if isfield(options, 'recommendations') && ~isempty(options.recommendations)
            for i = 1:length(options.recommendations)
                fprintf('%d. %s\n', i, options.recommendations{i});
            end
        else
            % Стандартные рекомендации
            fprintf('1. Проверьте правильность параметров фильтра\n');
            fprintf('2. Убедитесь что файлы экстрагированы на правильной стадии пайплайна\n');
            fprintf('3. Проверьте что используется правильный source buffer\n');
            if comparison.Y.maxDiff > 10
                fprintf('4. Большая максимальная ошибка (%d) может указывать на проблему в алгоритме\n', ...
                    comparison.Y.maxDiff);
            end
        end
    end
end
