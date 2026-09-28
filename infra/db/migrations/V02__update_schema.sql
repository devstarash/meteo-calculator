--Миграция изменения существующих табилц
CREATE TABLE base_units(
    id INT PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
);

COMMENT ON TABLE base_units IS 'Базовые единицы измерения';
COMMENT ON COLUMN base_units.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN base_units.name IS 'Наименование базовой величины';

CREATE TABLE units(
    id INT PRIMARY KEY,
    base_unit_id INT NOT NULL,
    short_name  VARCHAR(20) NOT NULL,
    conversion_factor NUMERIC NOT NULL,
    UNIQUE(base_unit_id, short_name)
);

COMMENT ON TABLE units IS 'Единицы измерения, привязанные к базовой величине';
COMMENT ON COLUMN units.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN units.base_unit_id IS 'Ссылка на базовую единицу измерения (base_units)';
COMMENT ON COLUMN units.short_name IS 'Краткое обозначение единицы (C, мм рт.ст., м/с)';
COMMENT ON COLUMN units.conversion_factor IS 'Коэффициент пересчёта в базовую единицу';

CREATE TABLE parameter_types(
    id INT PRIMARY KEY,
    equipment_type_id INT NOT NULL,
    unit_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    min_value NUMERIC,
    max_value NUMERIC,
    UNIQUE(equipment_type_id, name)
);

COMMENT ON TABLE parameter_types IS 'Типы измеряемых параметров';
COMMENT ON COLUMN parameter_types.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN parameter_types.equipment_type_id IS 'Оборудование, которым измеряется параметр (equipment_types)';
COMMENT ON COLUMN parameter_types.unit_id IS 'Единица измерения параметра (units)';
COMMENT ON COLUMN parameter_types.name IS 'Наименование параметра (Температура воздуха, Давление)';
COMMENT ON COLUMN parameter_types.min_value IS 'Минимальное значение';
COMMENT ON COLUMN parameter_types.max_value IS 'Максимальное значение';

-- Заполнение тестовыми данными
INSERT INTO base_units (id, name) VALUES
    (1, 'Температура'),
    (2, 'Давление'),
    (3, 'Направление ветра'),
    (4, 'Скорость ветра'),
    (5, 'Дальность сноса пуль'),
    (6, 'Высота');

INSERT INTO units (id, base_unit_id, short_name, conversion_factor) VALUES
    (1, 1, '°C', 1),
    (2, 2, 'мм рт.ст.', 1),
    (3, 3, 'дел.угл.', 1),
    (4, 4, 'м/с', 1),
    (5, 5, 'м', 1),
    (6, 6, 'м', 1);

INSERT INTO parameter_types (id, equipment_type_id, unit_id, name, min_value, max_value) VALUES
    (1,  1, 1, 'Температура воздуха',   -58, 58),
    (2,  1, 2, 'Давление',              500, 900),
    (3,  1, 3, 'Направление ветра',     0,   59),
    (4,  1, 6, 'Высота метеопоста',     NULL, NULL),
    (5,  1, 4, 'Скорость ветра',        0,   15),
    (6,  2, 1, 'Температура воздуха',   -58, 58),
    (7,  2, 2, 'Давление',              500, 900),
    (8,  2, 3, 'Направление ветра',     0,   59),
    (9,  2, 6, 'Высота метеопоста',     NULL, NULL),
    (10, 2, 5, 'Дальность сноса пуль',  0,   150);

-- добавляем в parameters новые колонки
ALTER TABLE parameters ADD COLUMN batch_id INT;
ALTER TABLE parameters ADD COLUMN parameter_type_id INT;
ALTER TABLE parameters ADD COLUMN value NUMERIC(6, 1);

COMMENT ON TABLE parameters IS 'Измеренные значения, одна строка = один параметр одного замера';
COMMENT ON COLUMN parameters.batch_id IS 'К какой пачке относится значение (batches)';
COMMENT ON COLUMN parameters.parameter_type_id IS 'Что за параметр (parameter_types)';
COMMENT ON COLUMN parameters.value IS 'Значение параметра';

-- раньше пачка ссылалась на параметры, теперь наоборот
UPDATE parameters SET batch_id = (SELECT b.id FROM batches b WHERE b.parameter_id = parameters.id);

-- разносим значения по отдельным строкам
-- исходные строки отличаем по тому, что у них еще нет parameter_type_id
-- старые колонки копируем как есть, потому что они пока NOT NULL
-- id считаем от максимального, чтобы не было повторов

-- высота метеопоста
INSERT INTO parameters (id, station_height, temperature, pressure,
                        wind_direction, wind_speed, bullet_drift, batch_id,
                        parameter_type_id, value)
SELECT p.id + (SELECT MAX(id) FROM parameters),
       p.station_height, p.temperature, p.pressure,
       p.wind_direction, p.wind_speed, p.bullet_drift, p.batch_id,
       (SELECT pt.id FROM parameter_types pt WHERE pt.name = 'Высота метеопоста'
       AND pt.equipment_type_id = b.equipment_type_id),
       p.station_height
FROM parameters p
JOIN batches b ON p.batch_id = b.id
WHERE p.parameter_type_id IS NULL;

-- давление
INSERT INTO parameters (id, station_height, temperature, pressure,
                        wind_direction, wind_speed, bullet_drift, batch_id,
                        parameter_type_id, value)
SELECT p.id + (SELECT MAX(id) FROM parameters),
       p.station_height, p.temperature, p.pressure,
       p.wind_direction, p.wind_speed, p.bullet_drift, p.batch_id,
       (SELECT pt.id FROM parameter_types pt WHERE pt.name = 'Давление'
        AND pt.equipment_type_id = b.equipment_type_id),
       p.pressure
FROM parameters p
JOIN batches b ON p.batch_id = b.id
WHERE p.parameter_type_id IS NULL;

-- направление ветра
INSERT INTO parameters (id, station_height, temperature, pressure,
                        wind_direction, wind_speed, bullet_drift, batch_id,
                        parameter_type_id, value)
SELECT p.id + (SELECT MAX(id) FROM parameters),
       p.station_height, p.temperature, p.pressure,
       p.wind_direction, p.wind_speed, p.bullet_drift, p.batch_id,
       (SELECT pt.id FROM parameter_types pt WHERE pt.name = 'Направление ветра'
        AND pt.equipment_type_id = b.equipment_type_id),
       p.wind_direction
FROM parameters p
JOIN batches b ON p.batch_id = b.id
WHERE p.parameter_type_id IS NULL;

-- скорость ветра, есть только у ДМК
INSERT INTO parameters (id, station_height, temperature, pressure,
                        wind_direction, wind_speed, bullet_drift, batch_id,
                        parameter_type_id, value)
SELECT p.id + (SELECT MAX(id) FROM parameters),
       p.station_height, p.temperature, p.pressure,
       p.wind_direction, p.wind_speed, p.bullet_drift, p.batch_id,
       (SELECT pt.id FROM parameter_types pt WHERE pt.name = 'Скорость ветра'
        AND pt.equipment_type_id = b.equipment_type_id),
       p.wind_speed
FROM parameters p
JOIN batches b ON p.batch_id = b.id
WHERE p.parameter_type_id IS NULL AND p.wind_speed IS NOT NULL;

-- снос пуль, есть только у ВР
INSERT INTO parameters (id, station_height, temperature, pressure,
                        wind_direction, wind_speed, bullet_drift, batch_id,
                        parameter_type_id, value)
SELECT p.id + (SELECT MAX(id) FROM parameters),
       p.station_height, p.temperature, p.pressure,
       p.wind_direction, p.wind_speed, p.bullet_drift, p.batch_id,
       (SELECT pt.id FROM parameter_types pt WHERE pt.name = 'Дальность сноса пуль'
        AND pt.equipment_type_id = b.equipment_type_id),
       p.bullet_drift
FROM parameters p
JOIN batches b ON p.batch_id = b.id
WHERE p.parameter_type_id IS NULL AND p.bullet_drift IS NOT NULL;

-- исходную строку не удаляем, а делаем из нее температуру
UPDATE parameters SET value = temperature, parameter_type_id = (
    SELECT pt.id FROM batches b
    JOIN parameter_types pt ON b.equipment_type_id = pt.equipment_type_id
    WHERE b.id = parameters.batch_id AND pt.name = 'Температура воздуха'
    )
WHERE parameter_type_id IS NULL;

-- старые колонки больше не нужны, все уже лежит в value
ALTER TABLE parameters DROP COLUMN station_height CASCADE;
ALTER TABLE parameters DROP COLUMN temperature    CASCADE;
ALTER TABLE parameters DROP COLUMN pressure       CASCADE;
ALTER TABLE parameters DROP COLUMN wind_direction CASCADE;
ALTER TABLE parameters DROP COLUMN wind_speed     CASCADE;
ALTER TABLE parameters DROP COLUMN bullet_drift   CASCADE;

-- пачка больше не ссылается на параметры, связь теперь через parameters.batch_id
ALTER TABLE batches DROP COLUMN parameter_id CASCADE;