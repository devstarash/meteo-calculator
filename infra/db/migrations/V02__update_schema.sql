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

CREATE TABLE parameter_values(
    id INT PRIMARY KEY,
    batch_id INT NOT NULL,
    parameter_type_id INT NOT NULL,
    value DECIMAL NOT NULL
);

COMMENT ON TABLE parameter_values IS 'Измеренные значения параметров';
COMMENT ON COLUMN parameter_values.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN parameter_values.batch_id IS 'Пачка измерений (batches)';
COMMENT ON COLUMN parameter_values.parameter_type_id IS 'Тип измеренного параметра (parameter_types)';
COMMENT ON COLUMN parameter_values.value IS 'Измеренное значение';

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

-- Перенос данных из parameters в parameter_values
INSERT INTO parameter_values (id, batch_id, parameter_type_id, value) VALUES
    (1, 1, 1, 25.0),
    (2, 1, 2, 765),
    (3, 1, 3, 15),
    (4, 1, 4, 100),
    (5, 1, 5, 6);

INSERT INTO parameter_values (id, batch_id, parameter_type_id, value) VALUES
    (6, 2, 6, -5.0),
    (7, 2, 7, 743),
    (8, 2, 8, 30),
    (9, 2, 9, 60),
    (10, 2, 10, 85);

INSERT INTO parameter_values (id, batch_id, parameter_type_id, value) VALUES
    (11, 3, 1, 17.0),
    (12, 3, 2, 750),
    (13, 3, 3, 9),
    (14, 3, 4, 100),
    (15, 3, 5, 4);

--Удаление ненужных таблиц/колонок
ALTER TABLE batches DROP COLUMN parameter_id;
DROP TABLE parameters;

