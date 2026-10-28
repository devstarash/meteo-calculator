DO $$
BEGIN
    -- ДДЧЧМ: день месяца + часы + десятки минут
    BEGIN
        CREATE OR REPLACE FUNCTION meteo_ddchchm(measured_at TIMESTAMP)
        RETURNS TEXT
        LANGUAGE sql
        AS $func$
            SELECT to_char(measured_at, 'DDHH24') || (EXTRACT(MINUTE FROM measured_at) / 10)::INT;
        $func$;
        COMMENT ON FUNCTION meteo_ddchchm(TIMESTAMP) IS
            'ДДЧЧМ: день месяца, часы, десятки минут';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при создании meteo_ddchchm: %', SQLERRM;
            RAISE;
    END;

    -- ВВВВ: высота метеопоста в 4 разряда
    BEGIN
        CREATE OR REPLACE FUNCTION meteo_vvvv(height INT)
        RETURNS TEXT
        LANGUAGE sql
        AS $func$
            SELECT lpad(height::TEXT, 4, '0');
        $func$;
        COMMENT ON FUNCTION meteo_vvvv(INT) IS
            'ВВВВ: высота метеопоста в 4 разряда';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при создании meteo_vvvv: %', SQLERRM;
            RAISE;
    END;

    -- БББТТ: отклонение давления (БББ) + отклонение температуры (ТТ)
    BEGIN
        CREATE OR REPLACE FUNCTION meteo_bbbtt(params meteo_params)
        RETURNS TEXT
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            d_pressure NUMERIC;
            t_virtual NUMERIC;
            d_temp NUMERIC;
            bbb TEXT;
            tt TEXT;
        BEGIN
            -- БББ: давление - 750
            d_pressure := params.pressure - get_constant('TABLE_PRESSURE');
            IF d_pressure >= 0 THEN
                bbb := lpad(d_pressure::INT::TEXT, 3, '0');
            ELSE
                bbb := '5' || lpad(abs(d_pressure)::INT::TEXT, 2, '0');
            END IF;

            -- ТТ: виртуальная температура - 15.9, округление
            t_virtual := params.temperature + get_temperature_correction(params.temperature);
            d_temp := round(t_virtual - get_constant('TABLE_TEMPERATURE'));
            IF d_temp >= 0 THEN
                tt := lpad(d_temp::INT::TEXT, 2, '0');
            ELSE
                tt := '-' || lpad(abs(d_temp)::INT::TEXT, 2, '0');
            END IF;

            RETURN bbb || tt;
        END;
        $func$;
        COMMENT ON FUNCTION meteo_bbbtt(meteo_params) IS
            'БББТТ: отклонение давления (БББ) + отклонение температуры (ТТ)';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при создании meteo_bbbtt: %', SQLERRM;
            RAISE;
    END;

    RAISE NOTICE 'Миграция выполнена успешно';
END $$;