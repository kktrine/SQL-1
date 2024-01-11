-- Part 4 Task 1
CREATE OR REPLACE PROCEDURE s21_drop_tables_starting_with_name(p_table_name text) LANGUAGE plpgsql AS $$
DECLARE table_rec record;
BEGIN FOR table_rec IN (
  SELECT tablename
  FROM pg_tables
  WHERE schemaname = current_schema()
    AND tablename LIKE p_table_name || '%'
) LOOP EXECUTE 'DROP TABLE IF EXISTS ' || table_rec.tablename || ' CASCADE';
RAISE NOTICE 'Table % dropped',
table_rec.tablename;
END LOOP;
END;
$$;
--
-- Этот код создает хранимую процедуру на языке PL / pgSQL,
-- которая выполняет удаление всех таблиц в текущей схеме базы данных PostgreSQL,
-- чьи имена начинаются с заданной строки p_table_name.
--
-- Конкретнее,
-- процедура выполняет следующие шаги:
-- 1) Объявляет переменную table_rec типа record.
-- 2)Используя цикл FOR..LOOP,
-- выбирает все таблицы из pg_tables,
-- где schemaname равна текущей схеме,
-- и имя таблицы начинается с p_table_name.
-- 3)Для каждой таблицы в цикле выполняет команду DROP TABLE IF EXISTS,
-- с параметром CASCADE,
-- чтобы удалить таблицу и все связанные с ней объекты (например, индексы, ограничения и т.д.).
-- 4)Выводит сообщение RAISE NOTICE с именем удаленной таблицы.
--
-- Общая идея процедуры - упрощение процесса удаления нескольких таблиц с помощью одной команды.
-- Part 4 Task 2
CREATE OR REPLACE PROCEDURE s21_get_scalar_functions(OUT function_count integer) AS $$
DECLARE function_details text := ' ';
frec record;
BEGIN function_count := 0;
FOR frec IN
SELECT routine_name AS name,
  string_agg(parameter_name || ' ' || pr.data_type, ', ') AS parameters
FROM information_schema.parameters pr
  JOIN information_schema.routines rt ON rt.specific_name = pr.specific_name
  JOIN pg_proc pg ON pg.proname = rt.routine_name
WHERE pr.specific_schema = current_schema() -- пространство имен - текущая схема
  AND pr.parameter_mode = 'IN' -- рассматриваем только функции с входными аргументами
  AND rt.routine_type = 'FUNCTION' -- функция, а не процедура
  AND pg.prorettype::regtype IN -- return type скалярный
  (
    'boolean',
    'integer',
    'bigint',
    'real',
    'numeric',
    'varchar',
    'text',
    'date',
    'time',
    'timestamp',
    'uuid'
  )
GROUP BY routine_name LOOP function_details := function_details || frec.name || '(' || frec.parameters || ')' || CHR(10);
function_count := function_count + 1;
END LOOP;
RAISE NOTICE 'Найдено % скалярных функций:',
function_count;
RAISE NOTICE '%',
function_details;
END;
$$ LANGUAGE plpgsql;
-- test
-- call s21_get_scalar_functions(1);
-- Part 4 Task 3
CREATE OR REPLACE PROCEDURE s21_get_delete_triggers(OUT trigger_count integer) AS $$
DECLARE trigger_rec record;
BEGIN trigger_count := 0;
FOR trigger_rec IN (
  SELECT trigger_name,
    event_object_table,
    event_manipulation
  FROM information_schema.triggers
  WHERE trigger_schema = current_schema()
    AND (
      event_manipulation LIKE 'INSERT%'
      OR event_manipulation LIKE 'UPDATE%'
      OR event_manipulation LIKE 'DELETE%'
      OR event_manipulation LIKE 'SELECT%'
    )
) LOOP EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_rec.trigger_name || ' ON ' || trigger_rec.event_object_table;
trigger_count := trigger_count + 1;
END LOOP;
END;
$$ LANGUAGE plpgsql;
-- test
-- call s21_get_delete_triggers(0);