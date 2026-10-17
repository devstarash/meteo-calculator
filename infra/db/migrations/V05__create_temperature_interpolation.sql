DO $$
BEGIN
	-- Тип данных для интерполяции
	BEGIN
		CREATE TYPE public.interpolation_type AS (
			x0 numeric,
			y0 numeric,
			x1 numeric,
			y1 numeric
		);
	EXCEPTION
		WHEN duplicate_object THEN
			RAISE NOTICE 'Тип public.interpolation_type уже существует';
		WHEN OTHERS THEN
			RAISE NOTICE 'Ошибка при создании типа interpolation_type: %', SQLERRM;
			RAISE;
	END;

	-- Параметры интерполяции по температуре
	BEGIN
		CREATE OR REPLACE FUNCTION public.get_temperature_interpolation_params(
			temperature_parameter numeric
		)
		RETURNS public.interpolation_type
		LANGUAGE plpgsql
		AS $func$
		DECLARE
			var_interpolation public.interpolation_type;
		BEGIN
			-- Нижняя точка (x0, y0): ближайшая температура <= параметра,
			-- иначе минимальная температура в таблице
			SELECT sub.x0, sub.y0
			INTO var_interpolation.x0, var_interpolation.y0
			FROM (
				(
					SELECT 0 AS sort_order, tc.temperature AS x0, tc.correction AS y0
					FROM public.temperature_corrections AS tc
					WHERE tc.temperature <= temperature_parameter
					ORDER BY tc.temperature DESC
					LIMIT 1
				)
				UNION ALL
				(
					SELECT 1 AS sort_order, tc.temperature AS x0, tc.correction AS y0
					FROM public.temperature_corrections AS tc
					ORDER BY tc.temperature ASC
					LIMIT 1
				)
			) AS sub
			ORDER BY sub.sort_order
			LIMIT 1;

			-- Верхняя точка (x1, y1): ближайшая температура >= параметра,
			-- иначе максимальная температура в таблице
			SELECT sub.x1, sub.y1
			INTO var_interpolation.x1, var_interpolation.y1
			FROM (
				(
					SELECT 0 AS sort_order, tc.temperature AS x1, tc.correction AS y1
					FROM public.temperature_corrections AS tc
					WHERE tc.temperature >= temperature_parameter
					ORDER BY tc.temperature ASC
					LIMIT 1
				)
				UNION ALL
				(
					SELECT 1 AS sort_order, tc.temperature AS x1, tc.correction AS y1
					FROM public.temperature_corrections AS tc
					ORDER BY tc.temperature DESC
					LIMIT 1
				)
			) AS sub
			ORDER BY sub.sort_order
			LIMIT 1;

			RETURN var_interpolation;
		END;
		$func$;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE NOTICE 'Ошибка при создании get_temperature_interpolation_params: %', SQLERRM;
			RAISE;
	END;

	-- Расчёт линейной интерполяции
	BEGIN
		CREATE OR REPLACE FUNCTION public.calc_linear_interpolation(
			x_value numeric,
			interpolation_params public.interpolation_type
		)
		RETURNS numeric
		LANGUAGE plpgsql
		AS $func$
		DECLARE
			result numeric;
		BEGIN
			-- Точки совпадают -> можно вернуть любой из y-ков
			IF interpolation_params.x1 = interpolation_params.x0 THEN
				RETURN interpolation_params.y0;
			END IF;

			result := interpolation_params.y0
				+ (x_value - interpolation_params.x0)
				* (interpolation_params.y1 - interpolation_params.y0)
				/ (interpolation_params.x1 - interpolation_params.x0);

			RETURN result;
		END;
		$func$;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE NOTICE 'Ошибка при создании calc_linear_interpolation: %', SQLERRM;
			RAISE;
	END;

	--  Поправка по температуре. Решил добавить такую функцию. 
    -- Проверяет, что температура не меньше 0, и вызывает две предыдущие функции
	BEGIN
		CREATE OR REPLACE FUNCTION public.get_temperature_correction(
			x_value numeric
		)
		RETURNS numeric
		LANGUAGE plpgsql
		AS $func$
		DECLARE
			result numeric;
			interpolation_params public.interpolation_type;
		BEGIN
			-- Ниже 0 по ТЗ поправка равна 0
			IF x_value < 0 THEN
				RETURN 0;
			END IF;

			interpolation_params := public.get_temperature_interpolation_params(x_value);
			result := public.calc_linear_interpolation(x_value, interpolation_params);

			RETURN result;
		END;
		$func$;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE NOTICE 'Ошибка при создании get_temperature_correction: %', SQLERRM;
			RAISE;
	END;

	RAISE NOTICE 'Миграция выполнена успешно';
END $$;