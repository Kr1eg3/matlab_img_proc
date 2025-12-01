function visualizeComparison(Y_input, Y_output, comparison, options)
% visualizeComparison - визуализация результатов сравнения изображений
%
% Параметры:
%   Y_input - входное изображение (Y plane)
%   Y_output - выходное изображение MATLAB (Y plane)
%   comparison - структура от compareYUV() или [] если нет эталона
%   options - структура с опциями:
%     .title - заголовок фигуры (по умолчанию 'Comparison')
%     .Y_reference - эталонное изображение (опционально)
%     .bitDepth - битность для диапазона отображения (по умолчанию 10)
%     .inputTitle - заголовок для входного изображения
%     .outputTitle - заголовок для выходного изображения
%     .referenceTitle - заголовок для эталона
%     .showHistogram - показывать гистограмму ошибок (по умолчанию true)
%     .figurePosition - позиция фигуры [x, y, w, h]

    if nargin < 4
        options = struct();
    end

    % Значения по умолчанию
    if ~isfield(options, 'title'), options.title = 'Comparison'; end
    if ~isfield(options, 'bitDepth'), options.bitDepth = 10; end
    if ~isfield(options, 'inputTitle'), options.inputTitle = 'Input'; end
    if ~isfield(options, 'outputTitle'), options.outputTitle = 'MATLAB Output'; end
    if ~isfield(options, 'referenceTitle'), options.referenceTitle = 'Reference'; end
    if ~isfield(options, 'showHistogram'), options.showHistogram = true; end
    if ~isfield(options, 'figurePosition'), options.figurePosition = [50, 50, 1600, 900]; end

    maxVal = 2^options.bitDepth - 1;
    hasReference = isfield(options, 'Y_reference') && ~isempty(options.Y_reference);
    hasComparison = ~isempty(comparison);

    % Определяем layout
    if hasReference
        nRows = 2;
        nCols = 3;
    else
        nRows = 1;
        nCols = 3;
    end

    figure('Name', options.title, 'Position', options.figurePosition);

    % 1. Входное изображение
    subplot(nRows, nCols, 1);
    imshow(Y_input, [0, maxVal]);
    title(sprintf('%s\nRange: [%d, %d]', options.inputTitle, min(Y_input(:)), max(Y_input(:))));
    colorbar;

    % 2. Эталон (если есть) или MATLAB выход
    if hasReference
        subplot(nRows, nCols, 2);
        imshow(options.Y_reference, [0, maxVal]);
        title(sprintf('%s\nRange: [%d, %d]', options.referenceTitle, ...
            min(options.Y_reference(:)), max(options.Y_reference(:))));
        colorbar;

        % 3. MATLAB выход
        subplot(nRows, nCols, 3);
        imshow(Y_output, [0, maxVal]);
        title(sprintf('%s\nRange: [%d, %d]', options.outputTitle, min(Y_output(:)), max(Y_output(:))));
        colorbar;

        if hasComparison
            % 4. Разница (тепловая карта)
            subplot(nRows, nCols, 4);
            imagesc(comparison.Y.diff);
            colormap(gca, 'jet');
            colorbar;
            title(sprintf('Difference (MATLAB - Reference)\nMax: %d, Mean: %.2f', ...
                comparison.Y.maxDiff, comparison.Y.meanDiff));
            axis image;

            % 5. Абсолютная разница
            subplot(nRows, nCols, 5);
            imagesc(comparison.Y.absDiff);
            colormap(gca, 'hot');
            colorbar;
            title(sprintf('Absolute Difference\nMax: %d, Mean: %.2f', ...
                comparison.Y.maxDiff, comparison.Y.meanDiff));
            axis image;

            % 6. Гистограмма ошибок
            if options.showHistogram
                subplot(nRows, nCols, 6);
                histogram(comparison.Y.absDiff(:), 100);
                xlabel('Absolute Difference');
                ylabel('Pixel Count');
                title(sprintf('Error Distribution\nIdentical: %.1f%%', comparison.Y.identicalPercent));
                grid on;
            end
        end
    else
        % Без эталона - показываем вход, выход и разницу
        subplot(nRows, nCols, 2);
        imshow(Y_output, [0, maxVal]);
        title(sprintf('%s\nRange: [%d, %d]', options.outputTitle, min(Y_output(:)), max(Y_output(:))));
        colorbar;

        % 3. Разница между входом и выходом
        subplot(nRows, nCols, 3);
        diff = int32(Y_output) - int32(Y_input);
        imagesc(abs(diff));
        colormap(gca, 'hot');
        colorbar;
        title(sprintf('|Output - Input|\nMax: %d, Mean: %.2f', ...
            max(abs(diff(:))), mean(abs(double(diff(:))))));
        axis image;
    end
end
