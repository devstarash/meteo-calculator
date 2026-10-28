DO $$
BEGIN
    BEGIN
        CREATE TYPE meteo_params AS (
            equipment_type_id INT,
            height INT,
            temperature NUMERIC(4, 1),
            pressure INT,
            wind_direction INT,
            wind_speed INT,
            bullet_drift INT
        );
        COMMENT ON TYPE meteo_params IS 'Список входных параметров для составления приближенного метеобюллетеня';
        COMMENT ON COLUMN meteo_params.equipment_type_id IS 'Тип оборудования (equipment_types.id): ДМК или ВР';
        COMMENT ON COLUMN meteo_params.height IS 'Высота метеопоста, м над уровнем моря';
        COMMENT ON COLUMN meteo_params.temperature IS 'Температура воздуха на высоте метеопоста, °C';
        COMMENT ON COLUMN meteo_params.pressure IS 'Давление атмосферы на высоте метеопоста, мм рт.ст.';
        COMMENT ON COLUMN meteo_params.wind_direction IS 'Направление ветра в приземном слое, дел. угл.';
        COMMENT ON COLUMN meteo_params.wind_speed IS 'Скорость ветра, м/с (заполняется только для ДМК)';
        COMMENT ON COLUMN meteo_params.bullet_drift IS 'Дальность сноса пуль, м (заполняется только для ВР)';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Тип meteo_params уже существует';
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка при создании типа meteo_params: %', SQLERRM;
            RAISE;
    END;

    RAISE NOTICE 'Миграция выполнена успешно';
END $$;