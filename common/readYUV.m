function [Y, U, V] = readYUV(filename, width, height, frameNum, bitDepth, chromaFormat)
    % readYUV - читает один кадр из YUV файла
    %
    % Параметры:
    %   filename - путь к .yuv файлу
    %   width, height - размеры кадра
    %   frameNum - номер кадра (начиная с 1)
    %   bitDepth - битность (8, 10, 12)
    %   chromaFormat - формат цветности (420, 422, 444)
    
    % Рассчитываем размеры компонент
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
    
    % Размеры в сэмплах
    Ysize = width * height;
    UVsize = UVwidth * UVheight;
    frameSize = Ysize + 2 * UVsize;
    
    % Открываем файл
    fid = fopen(filename, 'rb');
    if fid == -1
        error('Не могу открыть файл: %s', filename);
    end
    
    % Переходим к нужному кадру (frameNum начинается с 1)
    bytesPerSample = 2; % для 10/12 bit всегда используется 2 байта
    fseek(fid, (frameNum - 1) * frameSize * bytesPerSample, 'bof');
    
    % Читаем Y компоненту
    Y = fread(fid, [width, height], 'uint16=>uint16')';
    
    % Читаем U компоненту
    U = fread(fid, [UVwidth, UVheight], 'uint16=>uint16')';
    
    % Читаем V компоненту
    V = fread(fid, [UVwidth, UVheight], 'uint16=>uint16')';
    
    fclose(fid);
    
    % Для 12-bit даунсэмплим до 10-bit если нужно (как в спецификации)
    if bitDepth == 12
        Y = bitshift(Y, -2);
        U = bitshift(U, -2);
        V = bitshift(V, -2);
    end
end