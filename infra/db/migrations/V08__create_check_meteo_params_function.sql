DO $$
BEGIN
    CREATE OR REPLACE FUNCTION error_message(
        error_code parameter_error_code,
        val NUMERIC DEFAULT NULL,
        min_val NUMERIC DEFAULT NULL,
        max_val NUMERIC DEFAULT NULL
    )
    RETURNS TEXT
    LANGUAGE sql
    AS $func$
        SELECT format(message, val, min_val, max_val)
        FROM parameter_error_types
        WHERE code = error_code;
    $func$;

    COMMENT ON FUNCTION error_message(parameter_error_code, NUMERIC, NUMERIC, NUMERIC) IS
        'Возвращает текст ошибки по коду, подставляя значение, минимум и максимум';

    CREATE OR REPLACE FUNCTION check_meteo_params(
        params meteo_params
    )
    RETURNS TEXT
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        result TEXT := '';
        r RECORD;
        v_val NUMERIC;
        msg TEXT;
    BEGIN
        -- 1. Тип оборудования указан?
        IF params.equipment_type_id IS NULL THEN
            RETURN error_message('EQUIPMENT_EMPTY');
        END IF;

        -- 2. Тип оборудования существует?
        IF NOT EXISTS (
            SELECT 1 FROM equipment_types WHERE id = params.equipment_type_id
        ) THEN
            RETURN error_message('EQUIPMENT_UNKNOWN', params.equipment_type_id);
        END IF;

        -- 3. Идём только по тем параметрам, которые относятся к этому оборудованию
        FOR r IN
            SELECT pt.name, pt.min_value, pt.max_value
            FROM parameter_types pt
            WHERE pt.equipment_type_id = params.equipment_type_id
            ORDER BY pt.id
        LOOP
            -- Значение параметра из переданной структуры
            v_val := CASE r.name
                WHEN 'Высота метеопоста' THEN params.height
                WHEN 'Температура воздуха' THEN params.temperature
                WHEN 'Давление' THEN params.pressure
                WHEN 'Направление ветра' THEN params.wind_direction
                WHEN 'Скорость ветра' THEN params.wind_speed
                WHEN 'Дальность сноса пуль' THEN params.bullet_drift
            END;

            -- Проверка значения
            IF v_val IS NULL THEN
                msg := error_message('REQUIRED');
            ELSIF r.min_value IS NOT NULL AND v_val < r.min_value THEN
                msg := error_message('BELOW_MIN', v_val, r.min_value, r.max_value);
            ELSIF r.max_value IS NOT NULL AND v_val > r.max_value THEN
                msg := error_message('ABOVE_MAX', v_val, r.min_value, r.max_value);
            ELSE
                msg := NULL;
            END IF;

            IF msg IS NOT NULL THEN
                result := result || r.name || ': ' || msg || '; ';
            END IF;
        END LOOP;

        RETURN rtrim(result, '; ');
    END;
    $func$;

    COMMENT ON FUNCTION check_meteo_params(meteo_params) IS
        'Принимает структуру параметров, проверяет только те параметры, '
        'которые применимы к выбранному оборудованию. '
        'Возвращает строку с ошибками через "; ". Пустая строка = ошибок нет';

    RAISE NOTICE 'Миграция выполнена успешно';
END $$;