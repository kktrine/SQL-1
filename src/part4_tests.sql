-- Part 1
CREATE TABLE s21_delete(id BIGINT);
CREATE TABLE s21_not_delete(id BIGINT);
CREATE TABLE s21_delet2(id BIGINT);
CREATE TABLE s21_not_delete_2(id BIGINT);
-- TEST FOR TASK 1
-- CALL s21_drop_tables_starting_with_name('s21_dele');
--
-- Part 2
CREATE OR REPLACE FUNCTION s21_test_fun_without_params() RETURNS INTEGER AS $$ BEGIN RETURN 0::INTEGER;
END;
$$ LANGUAGE plpgsql;
--

CREATE OR REPLACE FUNCTION s21_test_fun_with_params_1(i INTEGER) RETURNS INTEGER AS $$ BEGIN RETURN 0::INTEGER;
END;
$$ LANGUAGE plpgsql;
--
CREATE OR REPLACE FUNCTION s21_test_fun_with_params_2(i INTEGER, j INTEGER) RETURNS text
AS $$ BEGIN RETURN '0123'::text;
END;
$$ LANGUAGE plpgsql;
-- TEST FOR TASK 2
-- call s21_get_scalar_functions(1);

--Part 3
CREATE OR REPLACE FUNCTION s21_test_trigger_fun() RETURNS TRIGGER AS $$ BEGIN NEW.last_modified = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER s21_test_trigger
BEFORE
UPDATE ON s21_not_delete FOR EACH ROW EXECUTE FUNCTION s21_test_trigger_fun();
--

CREATE OR REPLACE FUNCTION s21_test_trigger_fun_2() RETURNS TRIGGER AS $$ BEGIN NEW.last_modified = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER s21_test_trigger_2
BEFORE
UPDATE ON s21_not_delete_2 FOR EACH ROW EXECUTE FUNCTION s21_test_trigger_fun_2();
-- TEST FOR TASK 3
-- call s21_get_delete_triggers(0);


-- Delete
drop TABLE if exists s21_delete CASCADE;
drop TABLE if exists s21_delet2 CASCADE;
drop TABLE if exists s21_not_delete;
drop TABLE if exists s21_not_delete_2;
DROP PROCEDURE IF EXISTS s21_drop_tables_starting_with_name;
-- part 4_2
DROP FUNCTION IF EXISTS s21_test_fun_without_params;
DROP FUNCTION IF EXISTS s21_test_fun_with_params_1;
DROP FUNCTION IF EXISTS s21_test_fun_with_params_2;
DROP PROCEDURE IF EXISTS s21_get_scalar_functions;
-- part 4_3
DROP TRIGGER IF exists s21_test_trigger on s21_not_delete CASCADE;
DROP TRIGGER IF exists s21_test_trigger_2 on s21_not_delete_2 CASCADE;
DROP FUNCTION IF EXISTS s21_test_trigger_fun;
DROP FUNCTION IF EXISTS s21_test_trigger_fun_2;
DROP PROCEDURE IF EXISTS s21_get_delete_triggers;