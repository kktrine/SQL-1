-- Part 1
CREATE TABLE delete(id BIGINT);
CREATE TABLE not_delete(id BIGINT);
CREATE TABLE delet2(id BIGINT);
CREATE TABLE not_delete_2(id BIGINT);
-- TEST FOR TASK 1
-- CALL drop_tables_starting_with_name('dele');
--
-- Part 2
CREATE OR REPLACE FUNCTION test_fun_without_params() RETURNS INTEGER AS $$ BEGIN RETURN 0::INTEGER;
END;
$$ LANGUAGE plpgsql;
--

CREATE OR REPLACE FUNCTION test_fun_with_params_1(i INTEGER) RETURNS INTEGER AS $$ BEGIN RETURN 0::INTEGER;
END;
$$ LANGUAGE plpgsql;
--
CREATE OR REPLACE FUNCTION test_fun_with_params_2(i INTEGER, j INTEGER) RETURNS text
AS $$ BEGIN RETURN '0123'::text;
END;
$$ LANGUAGE plpgsql;
-- TEST FOR TASK 2
-- call get_scalar_functions(1);

--Part 3
CREATE OR REPLACE FUNCTION test_trigger_fun() RETURNS TRIGGER AS $$ BEGIN NEW.last_modified = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER test_trigger
BEFORE
UPDATE ON not_delete FOR EACH ROW EXECUTE FUNCTION test_trigger_fun();
--

CREATE OR REPLACE FUNCTION test_trigger_fun_2() RETURNS TRIGGER AS $$ BEGIN NEW.last_modified = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER test_trigger_2
BEFORE
UPDATE ON not_delete_2 FOR EACH ROW EXECUTE FUNCTION test_trigger_fun_2();
-- TEST FOR TASK 3
-- call get_delete_triggers(0);


-- Delete
drop TABLE if exists delete CASCADE;
drop TABLE if exists delet2 CASCADE;
drop TABLE if exists not_delete;
drop TABLE if exists not_delete_2;
DROP PROCEDURE IF EXISTS drop_tables_starting_with_name;
-- part 4_2
DROP FUNCTION IF EXISTS test_fun_without_params;
DROP FUNCTION IF EXISTS test_fun_with_params_1;
DROP FUNCTION IF EXISTS test_fun_with_params_2;
DROP PROCEDURE IF EXISTS get_scalar_functions;
-- part 4_3
DROP TRIGGER IF exists test_trigger on not_delete CASCADE;
DROP TRIGGER IF exists test_trigger_2 on not_delete_2 CASCADE;
DROP FUNCTION IF EXISTS test_trigger_fun;
DROP FUNCTION IF EXISTS test_trigger_fun_2;
DROP PROCEDURE IF EXISTS get_delete_triggers;