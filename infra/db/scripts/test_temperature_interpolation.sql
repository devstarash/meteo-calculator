DO $$
DECLARE 
	test_cases numeric[][] := ARRAY[
		[23, 1.8],
		[25, 2],
		[35, 4],
		[50, 4.5],
		[-10, 0]
	];
	temperature_value numeric;
	expected_value numeric;
	actual_value numeric;
	i integer;
BEGIN
	FOR i IN 1 .. array_length(test_cases, 1) LOOP
	temperature_value := test_cases[i][1];
	expected_value := test_cases[i][2];
	actual_value := round(public.get_temperature_correction(temperature_value), 1);
	IF actual_value = expected_value THEN
			RAISE NOTICE 'OK: t = %, ожидалось %, получено %',
				temperature_value, expected_value, actual_value;
		ELSE
			RAISE NOTICE 'ОШИБКА: t = %, ожидалось %, получено %',
				temperature_value, expected_value, actual_value;
		END IF;
	END LOOP;
END $$;