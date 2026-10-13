--Миграция создания таблиц, заполнения тестовыми данными и создания связей
DO $$
BEGIN
    -- Транзакция 1: таблицы и счётчики
    BEGIN
        DROP TABLE IF EXISTS parameters, batches, parameter_types, units, base_units,
                             users, equipment_types, positions, temperature_corrections CASCADE;

        DROP SEQUENCE IF EXISTS positions_id_seq, equipment_types_id_seq, users_id_seq,
                                base_units_id_seq, units_id_seq, parameter_types_id_seq,
                                batches_id_seq, parameters_id_seq, temperature_corrections_id_seq;

        -- счётчики
        CREATE SEQUENCE positions_id_seq;
        CREATE SEQUENCE equipment_types_id_seq;
        CREATE SEQUENCE users_id_seq;
        CREATE SEQUENCE base_units_id_seq;
        CREATE SEQUENCE units_id_seq;
        CREATE SEQUENCE parameter_types_id_seq;
        CREATE SEQUENCE batches_id_seq;
        CREATE SEQUENCE parameters_id_seq;
        CREATE SEQUENCE temperature_corrections_id_seq;

        -- таблицы
        CREATE TABLE positions(
            id INT DEFAULT nextval('positions_id_seq'),
            title VARCHAR(30)
        );
        COMMENT ON TABLE positions IS 'Должности пользователей';
        COMMENT ON COLUMN positions.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN positions.title IS 'Наименование должности';

        CREATE TABLE equipment_types(
            id INT DEFAULT nextval('equipment_types_id_seq'),
            short_name VARCHAR(15),
            full_name VARCHAR(100)
        );
        COMMENT ON TABLE equipment_types IS 'Типы оборудования';
        COMMENT ON COLUMN equipment_types.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN equipment_types.short_name IS 'Краткое наименование (ДМК, ВР)';
        COMMENT ON COLUMN equipment_types.full_name IS 'Полное наименование оборудования';

        CREATE TABLE users(
            id INT DEFAULT nextval('users_id_seq'),
            name VARCHAR(30),
            last_name VARCHAR(50),
            patronymic VARCHAR(50),
            position_id INT
        );
        COMMENT ON TABLE users IS 'Пользователи системы';
        COMMENT ON COLUMN users.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN users.name IS 'Имя';
        COMMENT ON COLUMN users.last_name IS 'Фамилия';
        COMMENT ON COLUMN users.patronymic IS 'Отчество';
        COMMENT ON COLUMN users.position_id IS 'Должность пользователя из таблицы positions';

        CREATE TABLE base_units(
            id INT DEFAULT nextval('base_units_id_seq'),
            name VARCHAR(30)
        );
        COMMENT ON TABLE base_units IS 'Базовые единицы измерения';
        COMMENT ON COLUMN base_units.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN base_units.name IS 'Наименование базовой величины';

        CREATE TABLE units(
            id INT DEFAULT nextval('units_id_seq'),
            base_unit_id INT,
            short_name VARCHAR(20),
            conversion_factor NUMERIC
        );
        COMMENT ON TABLE units IS 'Единицы измерения, привязанные к базовой величине';
        COMMENT ON COLUMN units.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN units.base_unit_id IS 'Ссылка на базовую единицу измерения (base_units)';
        COMMENT ON COLUMN units.short_name IS 'Краткое обозначение единицы (°C, мм рт.ст., м/с)';
        COMMENT ON COLUMN units.conversion_factor IS 'Коэффициент пересчёта в базовую единицу';

        CREATE TABLE parameter_types(
            id INT DEFAULT nextval('parameter_types_id_seq'),
            equipment_type_id INT,
            unit_id INT,
            name VARCHAR(100),
            min_value NUMERIC,
            max_value NUMERIC
        );
        COMMENT ON TABLE parameter_types IS 'Типы измеряемых параметров';
        COMMENT ON COLUMN parameter_types.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN parameter_types.equipment_type_id IS 'Оборудование, которым измеряется параметр (equipment_types)';
        COMMENT ON COLUMN parameter_types.unit_id IS 'Единица измерения параметра (units)';
        COMMENT ON COLUMN parameter_types.name IS 'Наименование параметра (Температура воздуха, Давление)';
        COMMENT ON COLUMN parameter_types.min_value IS 'Минимальное значение';
        COMMENT ON COLUMN parameter_types.max_value IS 'Максимальное значение';

        CREATE TABLE batches(
            id INT DEFAULT nextval('batches_id_seq'),
            user_id INT,
            equipment_type_id INT,
            measured_at TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        COMMENT ON TABLE batches IS 'Журнал измерений';
        COMMENT ON COLUMN batches.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN batches.user_id IS 'Автор измерения (users)';
        COMMENT ON COLUMN batches.equipment_type_id IS 'Использованное оборудование (equipment_types)';
        COMMENT ON COLUMN batches.measured_at IS 'Дата/время окончания измерения';
        COMMENT ON COLUMN batches.created_at IS 'Дата/время создания записи в системе';

        CREATE TABLE parameters(
            id INT DEFAULT nextval('parameters_id_seq'),
            batch_id INT,
            parameter_type_id INT,
            value NUMERIC(6, 1)
        );
        COMMENT ON TABLE parameters IS 'Измеренные значения, одна строка = один параметр одного замера';
        COMMENT ON COLUMN parameters.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN parameters.batch_id IS 'К какой пачке относится значение (batches)';
        COMMENT ON COLUMN parameters.parameter_type_id IS 'Что за параметр (parameter_types)';
        COMMENT ON COLUMN parameters.value IS 'Значение параметра';

        -- Таблица 1: поправка для расчёта температуры
        CREATE TABLE temperature_corrections(
            id INT DEFAULT nextval('temperature_corrections_id_seq'),
            temperature NUMERIC(4, 1),
            correction NUMERIC(3, 1)
        );
        COMMENT ON TABLE temperature_corrections IS 'Таблица 1: поправка ΔTv по измеренной температуре t0';
        COMMENT ON COLUMN temperature_corrections.id IS 'Уникальный идентификатор записи';
        COMMENT ON COLUMN temperature_corrections.temperature IS 'Значение температуры t0, °C';
        COMMENT ON COLUMN temperature_corrections.correction IS 'Поправка ΔTv, °C';

        RAISE NOTICE 'Транзакция 1: таблицы и счётчики созданы';
    END;
    COMMIT;


    -- Транзакция 2: тестовые данные
    BEGIN
        INSERT INTO positions (title) VALUES
            ('Оператор метеопоста'),
            ('Начальник метеопоста'),
            ('Командир взвода управления');

        INSERT INTO equipment_types (short_name, full_name) VALUES
            ('ДМК', 'Десантный метеорологический комплект'),
            ('ВР', 'Ветровое ружьё');

        INSERT INTO users (name, last_name, patronymic, position_id) VALUES
            ('Иван', 'Петров', 'Петрович', 1),
            ('Сергей', 'Кузнецов', 'Сергеевич', 2),
            ('Алексей', 'Смирнов', 'Алексеевич', 3),
            ('Сидор', 'Сидоров', 'Сидорович', 1);

        INSERT INTO base_units (name) VALUES
            ('Температура'),
            ('Давление'),
            ('Направление ветра'),
            ('Скорость ветра'),
            ('Дальность сноса пуль'),
            ('Высота');

        INSERT INTO units (base_unit_id, short_name, conversion_factor) VALUES
            (1, '°C', 1),
            (2, 'мм рт.ст.', 1),
            (3, 'дел.угл.', 1),
            (4, 'м/с', 1),
            (5, 'м', 1),
            (6, 'м', 1);

        INSERT INTO parameter_types (equipment_type_id, unit_id, name, min_value, max_value) VALUES
            (1, 1, 'Температура воздуха', -58, 58),
            (1, 2, 'Давление', 500, 900),
            (1, 3, 'Направление ветра', 0, 59),
            (1, 6, 'Высота метеопоста', NULL, NULL),
            (1, 4, 'Скорость ветра', 0, 15),
            (2, 1, 'Температура воздуха', -58, 58),
            (2, 2, 'Давление', 500, 900),
            (2, 3, 'Направление ветра', 0, 59),
            (2, 6, 'Высота метеопоста', NULL, NULL),
            (2, 5, 'Дальность сноса пуль', 0, 150);

        INSERT INTO batches (user_id, equipment_type_id, measured_at) VALUES
            (1, 1, '2026-09-21 09:30:00'),
            (2, 2, '2026-09-21 14:05:00'),
            (4, 1, '2026-09-22 07:15:00');

        INSERT INTO parameters (batch_id, parameter_type_id, value) VALUES
            (1, 4, 100), (1, 1, 25.0), (1, 2, 765), (1, 3, 15), (1, 5, 6),
            (2, 9, 60), (2, 6, -5.0), (2, 7, 743), (2, 8, 30), (2, 10, 85),
            (3, 4, 100), (3, 1, 17.0), (3, 2, 750), (3, 3, 9), (3, 5, 4);

        -- Таблица 1: поправка ΔTv
        INSERT INTO temperature_corrections (temperature, correction) VALUES
            (0, 0.5),
            (5, 0.5),
            (10, 1.0),
            (15, 1.0),
            (20, 1.5),
            (25, 2.0),
            (30, 3.5),
            (40, 4.5);

        RAISE NOTICE 'Транзакция 2: тестовые данные загружены';
    END;
    COMMIT;


    -- Транзакция 3: связи и ограничения
    BEGIN
        -- обязательные поля (NOT NULL)
        ALTER TABLE positions
            ALTER COLUMN title SET NOT NULL;
        ALTER TABLE equipment_types
            ALTER COLUMN short_name SET NOT NULL,
            ALTER COLUMN full_name SET NOT NULL;
        ALTER TABLE users
            ALTER COLUMN name SET NOT NULL,
            ALTER COLUMN last_name SET NOT NULL,
            ALTER COLUMN patronymic SET NOT NULL,
            ALTER COLUMN position_id SET NOT NULL;
        ALTER TABLE base_units
            ALTER COLUMN name SET NOT NULL;
        ALTER TABLE units
            ALTER COLUMN base_unit_id SET NOT NULL,
            ALTER COLUMN short_name SET NOT NULL,
            ALTER COLUMN conversion_factor SET NOT NULL;
        ALTER TABLE parameter_types
            ALTER COLUMN equipment_type_id SET NOT NULL,
            ALTER COLUMN unit_id SET NOT NULL,
            ALTER COLUMN name SET NOT NULL;
        ALTER TABLE batches
            ALTER COLUMN user_id SET NOT NULL,
            ALTER COLUMN equipment_type_id SET NOT NULL,
            ALTER COLUMN measured_at SET NOT NULL,
            ALTER COLUMN created_at SET NOT NULL;
        ALTER TABLE parameters
            ALTER COLUMN batch_id SET NOT NULL,
            ALTER COLUMN parameter_type_id SET NOT NULL,
            ALTER COLUMN value SET NOT NULL;
        ALTER TABLE temperature_corrections
            ALTER COLUMN temperature SET NOT NULL,
            ALTER COLUMN correction SET NOT NULL;

        -- первичные ключи
        ALTER TABLE positions ADD PRIMARY KEY (id);
        ALTER TABLE equipment_types ADD PRIMARY KEY (id);
        ALTER TABLE users ADD PRIMARY KEY (id);
        ALTER TABLE base_units ADD PRIMARY KEY (id);
        ALTER TABLE units ADD PRIMARY KEY (id);
        ALTER TABLE parameter_types ADD PRIMARY KEY (id);
        ALTER TABLE batches ADD PRIMARY KEY (id);
        ALTER TABLE parameters ADD PRIMARY KEY (id);
        ALTER TABLE temperature_corrections ADD PRIMARY KEY (id);

        -- уникальность
        ALTER TABLE positions ADD UNIQUE (title);
        ALTER TABLE equipment_types ADD UNIQUE (short_name);
        ALTER TABLE equipment_types ADD UNIQUE (full_name);
        ALTER TABLE base_units ADD UNIQUE (name);
        ALTER TABLE units ADD UNIQUE (base_unit_id, short_name);
        ALTER TABLE parameter_types ADD UNIQUE (equipment_type_id, name);
        ALTER TABLE temperature_corrections ADD UNIQUE (temperature);

        -- проверки
        ALTER TABLE temperature_corrections ADD CHECK (temperature BETWEEN -58 AND 58);
        ALTER TABLE temperature_corrections ADD CHECK (correction >= 0);

        -- внешние ключи (связи)
        ALTER TABLE users ADD FOREIGN KEY (position_id) REFERENCES positions(id);
        ALTER TABLE units ADD FOREIGN KEY (base_unit_id) REFERENCES base_units(id);
        ALTER TABLE parameter_types ADD FOREIGN KEY (equipment_type_id) REFERENCES equipment_types(id);
        ALTER TABLE parameter_types ADD FOREIGN KEY (unit_id) REFERENCES units(id);
        ALTER TABLE batches ADD FOREIGN KEY (user_id) REFERENCES users(id);
        ALTER TABLE batches ADD FOREIGN KEY (equipment_type_id) REFERENCES equipment_types(id);
        ALTER TABLE parameters ADD FOREIGN KEY (batch_id) REFERENCES batches(id);
        ALTER TABLE parameters ADD FOREIGN KEY (parameter_type_id) REFERENCES parameter_types(id);

        RAISE NOTICE 'Транзакция 3: связи и ограничения созданы';
    END;
    COMMIT;
END $$;