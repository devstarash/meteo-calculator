-- Пункт 3 ТЗ: "Лучший стрелок"
WITH
turned AS (
    -- одна строка = одна пачка
    SELECT
        b.id AS batch_id,
        b.user_id,
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
    GROUP BY b.id, b.user_id, b.equipment_type_id
),
checked AS (
    -- Проверка каждой пачки
    SELECT
        tr.user_id,
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
),
per_user AS (
    -- Группировка по пользователю
    SELECT
        u.id,
        u.last_name || ' ' || u.name || ' ' || u.patronymic AS "Пользователь",
        COUNT(c.user_id) AS "Всего замеров",
        COUNT(*) FILTER (WHERE c.errors <> '') AS "С ошибками"
    FROM users u
    LEFT JOIN checked c ON c.user_id = u.id
    GROUP BY u.id, u.last_name, u.name, u.patronymic
)
-- Вывод + место через RANK
SELECT
    RANK() OVER (ORDER BY "С ошибками" ASC) AS "Место",
    "Пользователь",
    "Всего замеров",
    "С ошибками"
FROM per_user
ORDER BY "С ошибками" ASC, "Пользователь";