DROP TABLE IF EXISTS batches;
DROP TABLE IF EXISTS parameters;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS equipment_types;
DROP TABLE IF EXISTS positions;

-- Должности пользователей
CREATE TABLE positions(
    id INT PRIMARY KEY,
    title VARCHAR(30) NOT NULL UNIQUE
);

COMMENT ON TABLE positions IS 'Должности пользователей';
COMMENT ON COLUMN positions.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN positions.title IS 'Наименование должности';

-- Типы оборудования (ДМК / ветровое ружьё)
CREATE TABLE equipment_types(
    id INT PRIMARY KEY,
    short_name VARCHAR(15) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL UNIQUE
);

COMMENT ON TABLE equipment_types IS 'Типы оборудования';
COMMENT ON COLUMN equipment_types.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN equipment_types.short_name IS 'Краткое наименование (ДМК, ВР)';
COMMENT ON COLUMN equipment_types.full_name IS 'Полное наименование оборудования';

-- Пользователи
CREATE TABLE users(
    id INT PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50) NOT NULL,
    position_id INT NOT NULL
);

COMMENT ON TABLE users IS 'Пользователи системы';
COMMENT ON COLUMN users.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN users.name IS 'Имя';
COMMENT ON COLUMN users.last_name IS 'Фамилия';
COMMENT ON COLUMN users.patronymic IS 'Отчество';
COMMENT ON COLUMN users.position_id IS 'Должность пользователя из таблицы positions';

-- Измеренные значения
CREATE TABLE parameters(
    id INT PRIMARY KEY,
    station_height INT NOT NULL,
    temperature NUMERIC(3, 1) NOT NULL CHECK(temperature <= 58 AND temperature >= -58),
    pressure INT NOT NULL CHECK(pressure <= 900 AND pressure >= 500),
    wind_direction INT NOT NULL CHECK(wind_direction <= 59 AND wind_direction >= 0),
    wind_speed INT CHECK(wind_speed IS NULL OR (wind_speed <= 15 AND wind_speed >= 0)),
    bullet_drift INT CHECK(bullet_drift IS NULL OR (bullet_drift <= 150 AND bullet_drift >= 0)),
    CHECK(
        (wind_speed IS NOT NULL AND bullet_drift IS NULL) OR
        (wind_speed IS NULL AND bullet_drift IS NOT NULL)
    )
);

COMMENT ON TABLE parameters IS 'Измеренные значения';
COMMENT ON COLUMN parameters.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN parameters.station_height IS 'Высота метеопоста, м';
COMMENT ON COLUMN parameters.temperature IS 'Температура воздуха, °C, диапазон [-58, 58]';
COMMENT ON COLUMN parameters.pressure IS 'Давление, мм рт.ст., диапазон [500, 900]';
COMMENT ON COLUMN parameters.wind_direction IS 'Направление ветра, дел.угл., диапазон [0, 59]';
COMMENT ON COLUMN parameters.wind_speed IS 'Скорость ветра, м/с, [0, 15] — только для ДМК';
COMMENT ON COLUMN parameters.bullet_drift IS 'Дальность сноса пуль, м, [0, 150] — только для ВР';

-- Журнал измерений(кто, чем и когда работал)
CREATE TABLE batches(
    id INT PRIMARY KEY,
    user_id INT NOT NULL,
    parameter_id INT NOT NULL,
    equipment_type_id INT NOT NULL,
    measured_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE batches IS 'Журнал измерений';
COMMENT ON COLUMN batches.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN batches.user_id IS 'Автор расчёта';
COMMENT ON COLUMN batches.parameter_id IS 'Набор измеренных значений';
COMMENT ON COLUMN batches.equipment_type_id IS 'Использованное оборудование';
COMMENT ON COLUMN batches.measured_at IS 'Дата/время окончания измерения';
COMMENT ON COLUMN batches.created_at IS 'Дата/время создания записи в системе';

-- Заполнение таблиц тестовыми данными

INSERT INTO positions (id, title) VALUES
    (1, 'Оператор метеопоста'),
    (2, 'Начальник метеопоста'),
    (3, 'Командир взвода управления');

INSERT INTO equipment_types (id, short_name, full_name) VALUES
    (1, 'ДМК', 'Десантный метеорологический комплект'),
    (2, 'ВР',  'Ветровое ружьё');

INSERT INTO users (id, name, last_name, patronymic, position_id) VALUES
    (1, 'Иван',    'Петров',   'Петрович',   1),
    (2, 'Сергей',  'Кузнецов', 'Сергеевич',  2),
    (3, 'Алексей', 'Смирнов',  'Алексеевич', 3),
    (4, 'Сидор',   'Сидоров',  'Сидорович',  1);

INSERT INTO parameters (id, station_height, temperature, pressure, wind_direction, wind_speed, bullet_drift) VALUES
    (1, 100, 25.0, 765, 15, 6,    NULL),
    (2, 60,  -5.0, 743, 30, NULL, 85),
    (3, 100, 17.0, 750, 9,  4,    NULL);

INSERT INTO batches (id, user_id, parameter_id, equipment_type_id, measured_at) VALUES
    (1, 1, 1, 1, '2026-09-21 09:30:00'),
    (2, 2, 2, 2, '2026-09-21 14:05:00'),
    (3, 4, 3, 1, '2026-09-22 07:15:00');
