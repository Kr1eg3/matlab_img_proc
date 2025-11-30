function tables = loadGdfTables()
    % loadGdfTables - загружает lookup таблицы для GDF фильтра
    %
    % Возвращает структуру с таблицами:
    %   tables.inter   - Gdf_Inter_Error (5 x 6 x 1000)
    %   tables.intra   - Gdf_Intra_Error (6 x 4096)
    %   tables.coords  - Gdf_Coords (18 x 2)
    %   tables.bias    - Gdf_Bias (6 x 6 x 3)
    %   tables.alpha   - Gdf_Alpha (6 x 6 x 22 x 4)
    %   tables.weight  - Gdf_Weight (6 x 6 x 3 x 22 x 4)
    %
    % Использование:
    %   tables = loadGdfTables();

    persistent cachedTables;

    % Кэшируем таблицы, чтобы не загружать каждый раз
    if isempty(cachedTables)
        fprintf('Loading GDF lookup tables...\n');

        % Загружаем Error таблицы
        cachedTables.inter = Gdf_Inter_Error();
        fprintf('  Loaded Gdf_Inter_Error: %s\n', mat2str(size(cachedTables.inter)));

        cachedTables.intra = Gdf_Intra_Error();
        fprintf('  Loaded Gdf_Intra_Error: %s\n', mat2str(size(cachedTables.intra)));

        % Загружаем дополнительные таблицы
        cachedTables.coords = Gdf_Coords();
        fprintf('  Loaded Gdf_Coords: %s\n', mat2str(size(cachedTables.coords)));

        cachedTables.bias = Gdf_Bias();
        fprintf('  Loaded Gdf_Bias: %s\n', mat2str(size(cachedTables.bias)));

        cachedTables.alpha = Gdf_Alpha();
        fprintf('  Loaded Gdf_Alpha: %s\n', mat2str(size(cachedTables.alpha)));

        cachedTables.weight = Gdf_Weight();
        fprintf('  Loaded Gdf_Weight: %s\n', mat2str(size(cachedTables.weight)));

        fprintf('All GDF tables loaded successfully.\n');
    end

    tables = cachedTables;
end
