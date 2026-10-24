-- Пункт 2 ТЗ: "Список параметров с ошибками"
WITH
-- 1. одна строка = одна пачка, параметры развёрнуты в колонки
turned AS (
    SELECT
        b.id AS batch_id,
        b.equipment_type_id,
        MAX(CASE WHEN pt.name = 'Температура воздуха' THEN p.value END) AS temperature,
        MAX(CASE WHEN pt.name = 'Давление' THEN p.value END) AS pressure,
        MAX(CASE WHEN pt.name = 'Направление ветра' THEN p.value END) AS wind_direction,
        MAX(CASE WHEN pt.name = 'Высота метеопоста' THEN p.value END) AS height,
        MAX(CASE WHEN pt.name = 'Скорость ветра' THEN p.value END) AS wind_speed,
        MAX(CASE WHEN pt.name = 'Дальность сноса пуль' THEN p.value END) AS bullet_drift
    FROM batches b
    JOIN parameters p ON p.batch_id = b.id
    JOIN parameter_types pt ON pt.id = p.parameter_type_id
    GROUP BY b.id, b.equipment_type_id
),
-- 2. Проверка параметров через check_meteo_params
checked AS (
    SELECT
        tr.*,
        check_meteo_params(ROW(
            tr.equipment_type_id,
            tr.height::INT,
            tr.temperature,
            tr.pressure::INT,
            tr.wind_direction::INT,
            tr.wind_speed::INT,
            tr.bullet_drift::INT
        )::meteo_params) AS errors
    FROM turned tr
)
-- 3. Вывод по ТЗ
SELECT
    c.batch_id AS "№",
    et.short_name AS "Тип оборудования",
    c.height AS "Высота метеопоста",
    c.temperature AS "Температура",
    c.pressure AS "Давление",
    c.wind_direction AS "Направление ветра",
    c.wind_speed AS "Скорость ветра",
    c.bullet_drift AS "Дальность сноса пуль",
    (c.errors <> '') AS "Флаг: Есть ошибка",
    NULLIF(c.errors, '') AS "Описание ошибки"
FROM checked c
JOIN equipment_types et ON et.id = c.equipment_type_id
ORDER BY c.batch_id;