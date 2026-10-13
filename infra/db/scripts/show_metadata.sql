select
    row_number() over (order by sort) as "№",
    "Наименование",
    "Тип"
from (
    select 1 as sort, table_name as "Наименование", 'Таблица' as "Тип"
    from information_schema.tables
    where table_catalog = current_database()
      and table_schema = 'public'
      and table_type = 'BASE TABLE'
    union all
    select 2, sequence_name, 'Счётчик'
    from information_schema.sequences
    where sequence_catalog = current_database()
      and sequence_schema = 'public'
) t;