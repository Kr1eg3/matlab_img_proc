function err = getGdfIntraError(tables, qpIdx, pos)
    % getGdfIntraError - получает значение ошибки из Intra таблицы
    %
    % Параметры:
    %   tables - структура с таблицами из loadGdfTables()
    %   qpIdx - индекс QP (0-5 в C++)
    %   pos - позиция (0-4095 в C++)
    %
    % Возвращает:
    %   err - значение коррекции ошибки
    %
    % Соответствие C++ коду:
    %   C++: err = Gdf_Intra_Error[qpIdx][pos];
    %   MATLAB: err = getGdfIntraError(tables, qpIdx + 1, pos + 1);
    %
    % Пример:
    %   tables = loadGdfTables();
    %   % Для qpIdx=0, pos=0 в C++:
    %   err = getGdfIntraError(tables, 1, 1);

    % В MATLAB индексы начинаются с 1, поэтому:
    % C++ [qpIdx][pos] -> MATLAB (qpIdx+1, pos+1)
    err = tables.intra(qpIdx, pos);
end
