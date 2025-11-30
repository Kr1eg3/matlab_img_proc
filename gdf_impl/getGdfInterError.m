function err = getGdfInterError(tables, refDstIdx, qpIdx, pos)
    % getGdfInterError - получает значение ошибки из Inter таблицы
    %
    % Параметры:
    %   tables - структура с таблицами из loadGdfTables()
    %   refDstIdx - индекс reference distance (1-5 в C++: 1,2,3,4,5)
    %   qpIdx - индекс QP (0-5 в C++)
    %   pos - позиция (0-999 в C++)
    %
    % Возвращает:
    %   err - значение коррекции ошибки
    %
    % Соответствие C++ коду:
    %   C++: err = Gdf_Inter_Error[refDstIdx - 1][qpIdx][pos];
    %   MATLAB: err = getGdfInterError(tables, refDstIdx, qpIdx + 1, pos + 1);
    %
    % Пример:
    %   tables = loadGdfTables();
    %   % Для refDstIdx=1, qpIdx=0, pos=0 в C++:
    %   err = getGdfInterError(tables, 1, 1, 1);

    % В MATLAB индексы начинаются с 1, поэтому:
    % C++ [refDstIdx-1][qpIdx][pos] -> MATLAB (refDstIdx, qpIdx+1, pos+1)
    err = tables.inter(refDstIdx, qpIdx, pos);
end
