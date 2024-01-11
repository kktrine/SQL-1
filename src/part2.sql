-- №2.1
CREATE OR REPLACE PROCEDURE s21_add_p2p_check (
    peer_nick VARCHAR(25),
    checking_peer_nick VARCHAR(25),
    task_arg VARCHAR(25),
    state_arg check_status,
    time_arg TIME(0)
  ) AS $$ --
  --
  BEGIN ASSERT state_arg IN ('Start', 'Success', 'Failure'),
  'Incorrect state';
--
IF state_arg = 'Start' THEN --
--
INSERT INTO Checks (id, peer, task, date)
VALUES (
    (
      SELECT COALESCE(MAX(id), 0) + 1
      FROM Checks
    ),
    peer_nick,
    task_arg,
    CURRENT_DATE
  );
--
INSERT INTO p2p (id, checkid, checkingpeer, state, time)
VALUES (
    (
      SELECT COALESCE(MAX(id), 0) + 1
      FROM p2p
    ),
    (
      SELECT MAX(id)
      FROM Checks
    ),
    checking_peer_nick,
    state_arg,
    time_arg
  );
--
ELSE
--
INSERT INTO p2p (id, checkid, checkingpeer, state, time)
VALUES (
    (
      SELECT COALESCE(MAX(id), 0) + 1
      FROM p2p
    ),
    (
      SELECT id
      FROM Checks c
      WHERE peer = peer_nick
        AND task = task_arg
        AND date = CURRENT_DATE
      EXCEPT
      SELECT checkid
      FROM p2p
      WHERE checkingpeer = checking_peer_nick
        AND state != 'Start'
    ),
    checking_peer_nick,
    state_arg,
    time_arg
  );
END IF;
END;
$$ LANGUAGE plpgsql;
--
-- test
-- Тест когда один и тот же пир прверяется второй раз у того
-- же пира. Тоесть пир с первой попытки не сдал и при повторной
-- проверки нарвался на того же пира кому не смог сдать
--
-- call s21_add_p2p_check(
--   'boomergo',
--   'genevaja',
--   'CPP1_s21_matrixplus',
--   'Start',
--   make_time(8, 30, 0)
-- );
-- call s21_add_p2p_check(
--   'boomergo',
--   'genevaja',
--   'CPP1_s21_matrixplus',
--   'Success',
--   make_time(9, 00, 0)
-- );
-- -- Обычная проверка
-- call s21_add_p2p_check(
--   'jacquelc',
--   'reverend',
--   'D01_Linux',
--   'Start',
--   make_time(13, 00, 0)
-- );
-- call s21_add_p2p_check(
--   'jacquelc',
--   'reverend',
--   'D01_Linux',
--   'Success',
--   make_time(13, 30, 0)
-- );
-- -- Попытка внести проверки одних и тех же пиров,
-- -- только на разные проекты в один день
-- call s21_add_p2p_check(
--   'boomergo',
--   'genevaja',
--   'C7_SmartCalc_v1.0',
--   'Start',
--   make_time(13, 30, 0)
-- );
-- call s21_add_p2p_check(
--   'boomergo',
--   'genevaja',
--   'C7_SmartCalc_v1.0',
--   'Success',
--   make_time(14, 30, 0)
-- );
--
-- #2.2
CREATE OR REPLACE PROCEDURE proc_add_checking_by_Verter (
    checked_peer VARCHAR,
    task_check VARCHAR,
    state_check check_status,
    time_check TIME(0)
  ) AS $$
BEGIN IF (
    EXISTS(
       SELECT p2p.checkid
      FROM p2p
        JOIN (
          SELECT id,
            date
          FROM Checks
          WHERE Checks.task = task_check
            AND Checks.peer = checked_peer
        ) tmp ON p2p.checkid = tmp.id
        AND p2p.state = 'Success'
      ORDER BY tmp.date DESC,
        p2p.time DESC
      LIMIT 1
    )
) THEN
INSERT INTO Verter (ID, CheckID, State, Time)
VALUES (
    (
      SELECT COALESCE(MAX(id), 0) + 1
      FROM Verter
    ),
    (
      SELECT p2p.checkid
      FROM p2p
        JOIN (
          SELECT id,
            date
          FROM Checks
          WHERE Checks.task = 'D01_Linux'
            AND Checks.peer = 'jacquelc'
        ) tmp ON p2p.checkid = tmp.id
        AND p2p.state = 'Success'
      ORDER BY tmp.date DESC,
        p2p.time DESC
      LIMIT 1
    ), state_check, time_check
  ); 
END IF;
END;
$$ LANGUAGE plpgsql;
-- -- test
-- call proc_add_checking_by_Verter(
--   'boomergo',
--   'CPP1_s21_matrixplus',
--   'Start',
--   make_time(11, 00, 0)
-- );
-- call proc_add_checking_by_Verter(
--   'genevaja',
--   'C7_SmartCalc_v1.0',
--   'Start',
--   make_time(11, 00, 0)
-- );
-- call proc_add_checking_by_Verter(
--   'genevaja',
--   'C7_SmartCalc_v1.0',
--   'Success',
--   make_time(11, 02, 0)
-- );
--
-- #2.3
CREATE OR REPLACE FUNCTION fnc_TransferredPoints_update() RETURNS TRIGGER AS $$ 
BEGIN IF (NEW.state = 'Start') THEN 
IF (
    EXISTS(
      SELECT *
      FROM Transferredpoints t
        JOIN (
          SELECT DISTINCT p2p.checkingpeer,
            Checks.peer
          FROM p2p
            JOIN Checks ON new.checkid = Checks.id
            AND new.checkingpeer = p2p.checkingpeer
        ) tmp ON t.checkingpeer = tmp.checkingpeer
        AND t.checkedpeer = tmp.peer
    )
  ) THEN
UPDATE Transferredpoints
SET PointsAmount = PointsAmount + 1
WHERE checkingpeer = NEW.checkingpeer
  AND Transferredpoints.checkedpeer = (
    SELECT DISTINCT Checks.peer
    FROM p2p
      JOIN Checks ON new.checkid = Checks.id
      AND new.checkingpeer = p2p.checkingpeer);
RETURN NEW;
ELSE
INSERT INTO Transferredpoints
VALUES (
    (
      SELECT COALESCE(MAX(id), 0) + 1
      FROM Transferredpoints
    ),
    NEW.checkingpeer,
    (
      SELECT DISTINCT Checks.peer
      FROM p2p
        JOIN Checks ON new.checkid = Checks.id
        AND new.checkingpeer = p2p.checkingpeer
    ),
    1);
RETURN NEW;
END IF;
ELSE RETURN NULL;
END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_TransferredPoints_update
AFTER
INSERT ON p2p FOR EACH ROW EXECUTE PROCEDURE fnc_TransferredPoints_update();

--tests
-- call s21_add_p2p_check(
--   'reverend',
--   'boomergo',
--   'CPP1_s21_matrixplus',
--   'Start',
--   make_time(8, 30, 0)
-- );
-- call s21_add_p2p_check(
--   'reverend',
--   'boomergo',
--   'CPP1_s21_matrixplus',
--   'Success',
--   make_time(9, 00, 0)
-- );
-- call s21_add_p2p_check(
--   'hankmagg',
--   'boomergo',
--   'D01_Linux',
--   'Start',
--   make_time(13, 00, 0)
-- );
--
-- #2.4
CREATE OR REPLACE FUNCTION s21_XP_insert_trigger_fun() RETURNS TRIGGER AS $$ BEGIN --
IF NEW.XPAmount > (
SELECT MaxXP
FROM checks c
  JOIN tasks t ON c.task = t.title
WHERE c.id = NEW.checkid
) THEN RAISE EXCEPTION 'Invalid XP amount';
END IF;
IF (
  SELECT count(state) <> 1
  FROM checks c
    JOIN verter v on v.checkid = c.id
  WHERE state = 'Success'
    AND c.id = NEW.checkid
) THEN RAISE EXCEPTION 'Project status is failure';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
--
CREATE OR REPLACE TRIGGER s21_XP_insert_trigger BEFORE
INSERT ON XP FOR EACH ROW EXECUTE FUNCTION s21_XP_insert_trigger_fun();
--
--
-- tests
-- INSERT INTO XP (id, CheckID, XPAmount)
-- VALUES (
--     (
--       SELECT COALESCE(MAX(id), 0) + 1
--       FROM XP
--     ),
--     1,
--     740
--   );
-- INSERT INTO XP (id, CheckID, XPAmount)
-- VALUES (
--     (
--       SELECT COALESCE(MAX(id), 0) + 1
--       FROM XP
--     ),
--     4,
--     1000
--   );
-- INSERT INTO XP (id, CheckID, XPAmount)
-- VALUES (
--     (
--       SELECT COALESCE(MAX(id), 0) + 1
--       FROM XP
--     ),
--     5,
--     1000
--   );
-- INSERT INTO XP (id, CheckID, XPAmount)
-- VALUES (
--     (
--       SELECT COALESCE(MAX(id), 0) + 1
--       FROM XP
--     ),
--     7,
--     300
--   );
-- SELECT *
-- FROM xp;