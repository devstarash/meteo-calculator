DO $$
BEGIN
    -- Проверка параметров
    CREATE OR REPLACE FUNCTION check_meteo_params(
        params meteo_params
    )
    RETURNS TEXT
    LANGUAGE sql STABLE
    AS $func$
        SELECT CASE
            -- 1. Тип оборудования указан?
            WHEN params.equipment_type_id IS NULL
                THEN error_message('EQUIPMENT_EMPTY')

            -- 2. Тип оборудования существует?
            WHEN NOT EXISTS (
                SELECT 1 FROM equipment_types WHERE id = params.equipment_type_id
            )
                THEN error_message('EQUIPMENT_UNKNOWN', params.equipment_type_id)

            -- 3. Проверяем параметры
            ELSE COALESCE((
                SELECT string_agg(
                    v.name || ': ' || format(e.message, v.val, pt.min_value, pt.max_value),
                    '; ' ORDER BY v.ord
                )
                -- превращаем в строки: порядковый номер, название, значение
                FROM (VALUES
                    (1, 'Высота метеопоста', params.height::NUMERIC),
                    (2, 'Температура воздуха', params.temperature::NUMERIC),
                    (3, 'Давление', params.pressure::NUMERIC),
                    (4, 'Направление ветра', params.wind_direction::NUMERIC),
                    (5, 'Скорость ветра', params.wind_speed::NUMERIC),
                    (6, 'Дальность сноса пуль', params.bullet_drift::NUMERIC)
                ) AS v(ord, name, val)
                -- Добавляем min/max из справочника. left join, чтобы увидеть лишние параметры -> pt.id IS NULL
                LEFT JOIN parameter_types pt
                    ON pt.name = v.name
                    AND pt.equipment_type_id = params.equipment_type_id
                -- Определяем код ошибки и оставляем только строки, где ошибка есть
                JOIN parameter_error_types e
                    ON e.code = CASE
                        -- параметр не нужен для оборудования, но передан
                        WHEN pt.id IS NULL AND v.val IS NOT NULL THEN 'NOT_APPLICABLE'
                        -- параметр не нужен и не передан: ошибки нет
                        WHEN pt.id IS NULL THEN NULL
                        -- параметр нужен, но не заполнен
                        WHEN v.val IS NULL THEN 'REQUIRED'
                        WHEN v.val < pt.min_value THEN 'BELOW_MIN'
                        WHEN v.val > pt.max_value THEN 'ABOVE_MAX'
                    END::parameter_error_code
            ), '') -- если string_agg вернул null -> заменяем на пустую строку
        END;
    $func$;

    COMMENT ON FUNCTION check_meteo_params(meteo_params) IS
        'Принимает структуру параметров и проверяет их для выбранного оборудования: '
        'заполненность, границы min/max, наличие лишних параметров. '
        'Возвращает строку с ошибками через "; ". Пустая строка = ошибок нет';

    RAISE NOTICE 'Миграция выполнена успешно';
END $$;