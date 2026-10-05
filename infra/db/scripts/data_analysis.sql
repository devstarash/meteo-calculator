-- Скрипт выполняет анализ данных, сгенерированных Алисой AI
-- Проверяет данные миграции V03__insert_test_data.sql
-- Проверки:
--   1. Одинаковое количество измерений у пользователей
--   2. Отсутствие пустых пачек
--   3. Полнота пачек (5 параметров)
--   4. Корректность значений и диапазонов
--   5. Корректность единиц измерения

-- Проверка 1. Каждый пользователь имеет одинаковое количество измерений (пачек)?
-- LEFT JOIN нужен, чтобы пользователи без пачек тоже попали в подсчёт (с нулём).
SELECT
    (CASE
        WHEN MAX(batches_per_user.number_of_measured_batches) = MIN(batches_per_user.number_of_measured_batches)
        THEN 'Да'
        ELSE 'Нет'
    END)
    AS "У всех пользователей одинаковое количество пачек?"
FROM (
    SELECT
        u.id,
        COUNT(b.id) AS number_of_measured_batches
    FROM users u
    LEFT JOIN batches b ON b.user_id = u.id
    GROUP BY u.id
) AS batches_per_user;

-- Проверка 2. У нас нет пустых пачек измерения?
-- LEFT JOIN + IS NULL оставляет только пачки, к которым не привязан ни один параметр.
SELECT
    (CASE
        WHEN empty_batches.number_of_empty_batches = 0
        THEN 'Нет'
        ELSE 'Да'
    END)
    AS "Есть ли пустые пачки?"
FROM (
    SELECT
        COUNT(b.id) AS number_of_empty_batches
    FROM batches b
    LEFT JOIN parameters p ON p.batch_id = b.id
    WHERE p.id IS NULL
) AS empty_batches;

-- Проверка 3. Каждая пачка измерений содержит полное количество параметров (5 шт)?
-- Пачка полная, если в ней ровно 5 параметров и все они разных типов.
SELECT
    (CASE
        WHEN COUNT(complete_batches.batch_id) = SUM(complete_batches.is_complete)
        THEN 'Да'
        ELSE 'Нет'
    END)
    AS "Каждая пачка измерений содержит полное количество параметров?"
FROM (
    SELECT
        b.id AS batch_id,
        (CASE
            WHEN COUNT(p.id) = 5 AND COUNT(DISTINCT p.parameter_type_id) = 5
            THEN 1
            ELSE 0
        END) AS is_complete
    FROM batches b
    LEFT JOIN parameters p ON p.batch_id = b.id
    GROUP BY b.id
) AS complete_batches;

-- Проверка 4. Все значения корректны и в рамках допустимых диапазонов?
-- Значение считается корректным, если:
--   1. оно заполнено (value IS NOT NULL);
--   2. тип параметра существует в parameter_types;
--   3. параметр относится к оборудованию пачки;
--   4. значение не меньше min_value (если минимум задан);
--   5. значение не больше max_value (если максимум задан).
SELECT
    (CASE
        WHEN COUNT(checked_values.is_value_correct) = SUM(checked_values.is_value_correct)
        THEN 'Да'
        ELSE 'Нет'
    END)
    AS "Все значения корректны и в рамках допустимых диапазонов?"
FROM (
    SELECT
        (CASE
            WHEN p.value IS NOT NULL
             AND pt.id IS NOT NULL
             AND pt.equipment_type_id = b.equipment_type_id
             AND (p.value >= pt.min_value OR pt.min_value IS NULL)
             AND (p.value <= pt.max_value OR pt.max_value IS NULL)
            THEN 1
            ELSE 0
        END) AS is_value_correct
    FROM parameters p
    LEFT JOIN batches b ON b.id = p.batch_id
    LEFT JOIN parameter_types pt ON pt.id = p.parameter_type_id
) AS checked_values;

-- Проверка 5. Все единицы измерения верны и корректны по отношению к указанным параметрам?
-- ИИ заполнял только измерения (batches и parameters), справочники единиц заполнены вручную и считаются верными.
-- Поэтому проверяем, что от каждого значения цепочка parameters → parameter_types → units → base_units доходит до конца.
SELECT
    (CASE
        WHEN COUNT(checked_units.is_unit_correct) = SUM(checked_units.is_unit_correct)
        THEN 'Да'
        ELSE 'Нет'
    END)
    AS "Все единицы измерения верны и корректны по отношению к указанным параметрам?"
FROM (
    SELECT
        (CASE
            WHEN bu.id IS NOT NULL
            THEN 1
            ELSE 0
        END) AS is_unit_correct
    FROM parameters p
    LEFT JOIN parameter_types pt ON pt.id = p.parameter_type_id
    LEFT JOIN units u ON u.id = pt.unit_id
    LEFT JOIN base_units bu ON bu.id = u.base_unit_id
) AS checked_units;