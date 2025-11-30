function writeYUV(filename, Y, U, V, bitDepth)
% writeYUV - сохраняет YUV кадр в файл
%
% Параметры:
%   filename - путь к выходному файлу
%   Y - Y plane (uint16)
%   U - U plane (uint16)
%   V - V plane (uint16)
%   bitDepth - битность (8, 10, 12)
%
% Примечания:
%   - Для 8-bit данные сохраняются как uint8
%   - Для 10-bit и 12-bit данные сохраняются как uint16 (little-endian)

    % Открываем файл для записи
    fid = fopen(filename, 'wb');
    if fid == -1
        error('Не удалось открыть файл для записи: %s', filename);
    end

    try
        % Определяем формат записи
        if bitDepth == 8
            % 8-bit: преобразуем uint16 в uint8 и записываем
            Y_write = uint8(Y);
            U_write = uint8(U);
            V_write = uint8(V);

            fwrite(fid, Y_write', 'uint8');
            fwrite(fid, U_write', 'uint8');
            fwrite(fid, V_write', 'uint8');
        else
            % 10-bit или 12-bit: записываем как uint16 little-endian
            fwrite(fid, Y', 'uint16');
            fwrite(fid, U', 'uint16');
            fwrite(fid, V', 'uint16');
        end

        % Закрываем файл
        fclose(fid);

    catch ME
        fclose(fid);
        rethrow(ME);
    end
end
