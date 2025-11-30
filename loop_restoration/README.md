# Loop Restoration Implementation for AV2/AVM Codec (MATLAB)

Реализация Loop Restoration фильтра для кодека AV2/AVM на MATLAB.

## Описание

Loop Restoration - это in-loop фильтр в кодеке AV2, который применяется для улучшения качества восстановленного видео. Он запускается **после CDEF/CCSO** и **до GDF** в pipeline декодирования.

## Структура файлов

### Основные файлы

- **lr_main.m** - главная точка входа для Loop Restoration
- **lr_filter_frame.m** - фильтрация целого кадра (плоскости)
- **lr_filter_unit.m** - фильтрация одного restoration unit
- **lr_filter_stripe.m** - фильтрация одной stripe (полосы)
- **lr_unit_grid.m** - расчет сетки restoration units
- **lr_extend_frame.m** - расширение границ кадра

### Фильтры

- **lr_wiener_nonsep.m** - Non-Separable Wiener фильтр (базовая реализация)
- **lr_wiener_pc.m** - Pixel-Classified Wiener фильтр (заглушка)

### Тестирование

- **test_loop_restoration.m** - тестовый скрипт (в корне matlab_code)

## Использование

### Базовый пример

```matlab
% Добавить пути
addpath('common');
addpath('loop_restoration');

% Читаем входной кадр (после CDEF/CCSO)
[Y_in, U_in, V_in] = readYUV('input.yuv', width, height, frameNum, bitDepth, chromaFormat);

% Настраиваем параметры Loop Restoration
lrParams.bitDepth = 10;
lrParams.chromaFormat = 444;

% Параметры для Y плоскости
lrParams.Y.frame_restoration_type = 2;  % RESTORE_WIENER_NONSEP
lrParams.Y.restoration_unit_size = 64;
% ... (настройка unit_info для каждого unit)

% Применяем Loop Restoration
[Y_out, U_out, V_out] = lr_main(Y_in, U_in, V_in, lrParams);

% Сохраняем результат
writeYUV('output.yuv', Y_out, U_out, V_out, bitDepth);
```

### Запуск теста

```matlab
% Отредактируйте пути в test_loop_restoration.m
% Затем запустите:
test_loop_restoration
```

## Параметры Loop Restoration

### lrParams структура

```matlab
lrParams = struct(
    'bitDepth', 10,           % Битность: 8, 10, или 12
    'chromaFormat', 444,      % Формат: 420, 422, или 444
    'Y', struct(...),         % Параметры для Y плоскости
    'U', struct(...),         % Параметры для U плоскости
    'V', struct(...)          % Параметры для V плоскости
);
```

### Параметры для каждой плоскости

```matlab
lrParams.Y = struct(
    'frame_restoration_type', 2,        % Тип restoration:
                                        %   0 = RESTORE_NONE
                                        %   1 = RESTORE_PC_WIENER
                                        %   2 = RESTORE_WIENER_NONSEP
                                        %   3 = RESTORE_SWITCHABLE
    'restoration_unit_size', 64,        % Размер unit (обычно 64)
    'unit_info', []                     % Массив структур для каждого unit
);
```

### unit_info структура

```matlab
unit_info(i) = struct(
    'restoration_type', 2,              % Тип для этого unit
    'num_classes', 1,                   % Количество классов (1-4)
    'wiener_info', struct(              % Коэффициенты фильтра
        'num_classes', 1,
        'allfiltertaps', taps           % int16 массив [num_classes * 32]
    )
);
```

## Ключевые константы

Из спецификации AV2 и реализации декодера:

```matlab
RESTORATION_PROC_UNIT_SIZE = 64      % Размер restoration unit
RESTORATION_UNIT_OFFSET = 8          % Offset для первой stripe
RESTORATION_BORDER_HORZ = 4          % Горизонтальное расширение границ
RESTORATION_BORDER_VERT = 4          % Вертикальное расширение границ
RESTORATION_CTX_VERT = 2             % Контекстные линии для stripe
STRIPE_HEIGHT = 64                   % Высота stripe
WIENERNS_TAPS_MAX = 32              % Максимум коэффициентов
MAX_NUM_DICTIONARY_TAPS = 28        % Максимум используемых taps
NUM_PC_WIENER_TAPS_LUMA = 13        % Taps для PC Wiener (luma)
```

## Процесс Loop Restoration

### Pipeline

```
Input Frame (после CDEF/CCSO)
    ↓
1. Расширение границ (lr_extend_frame)
    ↓
2. Создание сетки restoration units (lr_unit_grid)
    ↓
3. Для каждого restoration unit:
    ↓
   3a. Разбиение на stripes (lr_filter_unit)
    ↓
   3b. Для каждой stripe:
        - Сохранение граничных линий
        - Применение фильтра (lr_filter_stripe)
          → lr_wiener_nonsep или lr_wiener_pc
        - Восстановление границ
    ↓
4. Сборка результата
    ↓
Output Frame (вход для GDF)
```

### Stripe Processing

Restoration unit разбивается на полосы (stripes) высотой 64 пикселя:

- **Первая stripe**: высота = 64 - 8 = 56 пикселей (из-за RESTORATION_UNIT_OFFSET)
- **Остальные stripes**: высота = 64 пикселя
- Между stripes сохраняются 2 контекстные линии выше/ниже

## Текущая реализация

### Что реализовано ✓

1. **Базовая инфраструктура**
   - Главная точка входа (lr_main)
   - Обработка по restoration units
   - Разбиение на stripes
   - Расширение границ кадра

2. **Non-Separable Wiener фильтр**
   - Базовая 3x3 реализация
   - Single-class фильтрация
   - Fixed-point arithmetic с 7-bit precision

3. **Тестирование**
   - Тестовый скрипт
   - Сравнение с эталоном
   - Визуализация результатов

### Что нужно добавить TODO

1. **Расширенная фильтрация**
   - [ ] Полная 5x5, 7x7 конфигурации для Non-Sep Wiener
   - [ ] До 28 коэффициентов для полной поддержки
   - [ ] Multi-class classification и фильтрация

2. **PC Wiener фильтр**
   - [ ] Алгоритм классификации пикселей
   - [ ] 13-tap фильтр для luma
   - [ ] Cross-component фильтрация для chroma
   - [ ] Pre-trained коэффициенты

3. **Chroma обработка**
   - [ ] 5x5 или 7x7 фильтры для chroma
   - [ ] Cross-component с luma
   - [ ] Поддержка 420/422 форматов

4. **Оптимизации**
   - [ ] Vectorized операции
   - [ ] Кэширование коэффициентов
   - [ ] Параллельная обработка units

5. **Bitstream интеграция**
   - [ ] Парсинг restoration параметров из bitstream
   - [ ] Frame-level фильтры
   - [ ] Temporal prediction
   - [ ] SWITCHABLE mode

## Сравнение с декодером

Эта реализация основана на:

- **Спецификация**: `C:\Work\CodecSpecs\20251105_d6078400_AV2_Spec_Draft\index.html`
- **Референсный декодер**: `NGAnalyzerQt/third_party/avm/av1/common/restoration.c`

### Ключевые файлы декодера

- `restoration.h` - определения структур и констант
- `restoration.c` - основная реализация
  - `av1_loop_restoration_filter_frame()` - главная функция (lines 2395+)
  - `av1_loop_restoration_filter_unit()` - обработка unit (lines 2068+)
  - `wiener_nsfilter_stripe_highbd()` - Non-Sep Wiener (lines 1333+)
- `blockd.h` - WienerNonsepInfo структура (lines 1756+)

## Тестирование

### Подготовка тестовых данных

1. Извлеките кадр из анализатора на стадии **после CDEF/CCSO**
2. Сохраните как YUV файл
3. (Опционально) Извлеките выход Loop Restoration для сравнения

### Запуск теста

1. Отредактируйте `test_loop_restoration.m`:
   ```matlab
   inputFilename = 'path/to/your/input.yuv';
   referenceFilename = 'path/to/reference.yuv';  % опционально
   ```

2. Настройте параметры видео:
   ```matlab
   width = 1920;
   height = 1080;
   bitDepth = 10;
   chromaFormat = 444;
   ```

3. Запустите:
   ```matlab
   test_loop_restoration
   ```

### Интерпретация результатов

- **100% идентичных пикселей** - отлично! ✓✓✓
- **≥99% идентичных** - очень хорошо ✓✓
- **≥95% идентичных** - хорошо, возможны различия в округлении ✓
- **<95% идентичных** - проверьте параметры и реализацию ⚠

## Примечания

### Координаты

- В спецификации и C коде используется **0-based индексация**
- В MATLAB используется **1-based индексация**
- При обращении к MATLAB массивам добавляйте +1 к координатам из grid

### Битность

- Поддерживается 8, 10, 12 bit
- Внутренние вычисления используют int64 для точности
- Результат clipping к диапазону [0, 2^bitDepth - 1]

### Производительность

Текущая реализация не оптимизирована. Для больших кадров обработка может занять время.

## Ссылки

- [AV2 Specification](https://aomediacodec.github.io/av2-spec/)
- [AVM Decoder (GitLab)](https://gitlab.com/AOMediaCodec/avm)
- [Loop Restoration in AV1](https://patents.google.com/patent/US10623774B2)

## Автор

Создано для разработки и тестирования Loop Restoration фильтра AV2/AVM.

Дата: 2025-01-20
