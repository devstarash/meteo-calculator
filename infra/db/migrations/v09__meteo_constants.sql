DO $$
BEGIN
    -- Таблица констант
    BEGIN
        CREATE TABLE IF NOT EXISTS meteo_constants (
            code VARCHAR(50) PRIMARY KEY,
            value NUMERIC NOT NULL,
            note TEXT
        );
        COMMENT ON TABLE meteo_constants IS 'Константы для расчёта метеобюллетеня';
        COMMENT ON COLUMN meteo_constants.code IS 'Код константы';
        COMMENT ON COLUMN meteo_constants.value IS 'Значение';
        COMMENT ON COLUMN meteo_constants.note IS 'Описание';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при создании meteo_constants: %', SQLERRM;
            RAISE;
    END;

    -- Значения констант
    BEGIN
        INSERT INTO meteo_constants (code, value, note) VALUES
            ('TABLE_PRESSURE', 750, 'Табличное наземное давление, мм рт.ст.'),
            ('TABLE_TEMPERATURE', 15.9, 'Табличная приземная виртуальная температура, °C')
        ON CONFLICT (code) DO NOTHING;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при заполнении meteo_constants: %', SQLERRM;
            RAISE;
    END;

    -- Получение константы по коду
    BEGIN
        CREATE OR REPLACE FUNCTION get_constant(p_code TEXT)
        RETURNS NUMERIC
        LANGUAGE sql
        AS $func$
            SELECT value FROM meteo_constants WHERE code = p_code;
        $func$;
        COMMENT ON FUNCTION get_constant(TEXT) IS 'Возвращает значение константы по коду';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при создании get_constant: %', SQLERRM;
            RAISE;
    END;

    RAISE NOTICE 'Миграция выполнена успешно';
END $$;