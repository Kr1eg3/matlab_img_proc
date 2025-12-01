function printComparisonStats(comparison, options)
% printComparisonStats - выводит статистику сравнения YUV файлов
%
% Параметры:
%   comparison - структура от compareYUV()
%   options - структура с опциями (опционально):
%     .showY - показывать статистику Y plane (по умолчанию true)
%     .showU - показывать статистику U plane (по умолчанию true)
%     .showV - показывать статистику V plane (по умолчанию true)
%     .showErrorDistribution - показывать распределение ошибок (по умолчанию true)
%     .verbose - подробный вывод (по умолчанию true)

    if nargin < 2
        options = struct();
    end

    % Значения по умолчанию
    if ~isfield(options, 'showY'), options.showY = true; end
    if ~isfield(options, 'showU'), options.showU = true; end
    if ~isfield(options, 'showV'), options.showV = true; end
    if ~isfield(options, 'showErrorDistribution'), options.showErrorDistribution = true; end
    if ~isfield(options, 'verbose'), options.verbose = true; end

    fprintf('\n=== Статистика разницы ===\n');

    % Y plane
    if options.showY
        printPlaneStats(comparison.Y, 'Y', options);
    end

    % U plane
    if options.showU
        printPlaneStats(comparison.U, 'U', options);
    end

    % V plane
    if options.showV
        printPlaneStats(comparison.V, 'V', options);
    end
end

function printPlaneStats(planeStats, planeName, options)
    fprintf('\n%s plane:\n', planeName);

    if options.verbose
        fprintf('  Максимальная разница: %d\n', planeStats.maxDiff);
        fprintf('  Средняя разница: %.2f\n', planeStats.meanDiff);
        fprintf('  Медианная разница: %d\n', planeStats.medianDiff);
        fprintf('  Стд. откл.: %.2f\n', planeStats.stdDiff);
    end

    fprintf('  Идентичных пикселей: %.2f%% (%d/%d)\n', ...
        planeStats.identicalPercent, planeStats.identicalPixels, planeStats.totalPixels);

    % Распределение ошибок (только если есть ошибки и verbose режим)
    if options.showErrorDistribution && options.verbose && planeStats.maxDiff > 0
        fprintf('\n  Распределение ошибок:\n');
        dist = planeStats.errorDistribution;
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
    end
end
