-- Part 3 task 1 
CREATE OR REPLACE FUNCTION s21_readable_transferredpoints() RETURNS TABLE (
		Peer1 VARCHAR,
		Peer2 VARCHAR,
		PointsAmount integer
	) AS $$ WITH tmp AS (
		(
			SELECT t.checkingpeer AS Peer1,
				t.checkedpeer AS Peer2,
				t.pointsamount AS p
			FROM transferredpoints t
		)
		UNION ALL
		(
			SELECT t.checkedpeer AS Peer1,
				t.checkingpeer AS Peer2,
				(t.pointsamount * (-1)) AS p
			FROM transferredpoints t
		)
	)
SELECT tmp.Peer1,
	tmp.Peer2,
	SUM(p)
FROM tmp
GROUP BY tmp.Peer1,
	tmp.Peer2
ORDER BY tmp.Peer1,
	tmp.Peer2;
$$ LANGUAGE SQL;
-- test
-- SELECT *
-- FROM s21_readable_transferredpoints();
--
-- Part 3 task 2
CREATE OR REPLACE FUNCTION s21_peer_task_xp() RETURNS --
 TABLE (peer VARCHAR, task VARCHAR, xp bigint) AS $$
SELECT peer,
	task,
	XPAmount as xp
FROM p2p
	join checks ON p2p.checkid = checks.id
	JOIN xp ON xp.id = checks.id
WHERE state = 'Success';
$$ LANGUAGE SQL;
--test
-- SELECT *
-- FROM s21_peer_task_xp();
--
-- Part 3 task 3
CREATE OR REPLACE FUNCTION s21_peer_not_exiting(date_arg DATE) RETURNS --
 TABLE (peer VARCHAR) AS $$
SELECT peer
FROM timetracking
WHERE date = date_arg
	AND state != 2
EXCEPT
SELECT peer
FROM timetracking
WHERE date = date_arg
	AND state = 2 --
   $$ LANGUAGE SQL;
--tests
-- SELECT * FROM s21_peer_not_exiting('2023-02-01');
-- SELECT * FROM s21_peer_not_exiting('2022-11-30');
--
-- Part 3 task 4
CREATE OR REPLACE PROCEDURE s21_points_balance(rc refcursor) LANGUAGE plpgsql AS $$ 
BEGIN OPEN rc FOR 
	WITH tmp AS (
		(
			SELECT t.checkingpeer AS Peer1,
				t.checkedpeer AS Peer2,
				t.pointsamount AS p
			FROM transferredpoints t
		)
		UNION ALL
		(
			SELECT t.checkedpeer AS Peer1,
				t.checkingpeer AS Peer2,
				(t.pointsamount * (-1)) AS p
			FROM transferredpoints t
		)
	),
	tmp1 AS (
		SELECT tmp.Peer1,
			tmp.Peer2,
			SUM(p) AS p
		FROM tmp
		GROUP BY tmp.Peer1,
			tmp.Peer2
		ORDER BY tmp.Peer1,
			tmp.Peer2
	)
SELECT tmp1.Peer1 AS Peer,
	SUM(tmp1.p) AS PointsAmount
FROM tmp1
GROUP BY tmp1.Peer1
ORDER BY SUM(tmp1.p) DESC;
END;
$$;
-- test
-- BEGIN;
-- CALL s21_points_balance('rc');
-- FETCH ALL IN "rc";
-- COMMIT;
--
-- Part 3 task 5  
CREATE OR REPLACE PROCEDURE s21_points_balance_with_function(rc refcursor) LANGUAGE plpgsql AS $$ 
BEGIN OPEN rc FOR
SELECT tmp.Peer1 AS Peer,
	SUM(tmp.PointsAmount) AS PointsAmount
FROM s21_readable_transferredpoints() AS tmp
GROUP BY tmp.Peer1
ORDER BY SUM(tmp.PointsAmount) DESC;
END;
$$;
-- test
-- BEGIN;
-- CALL s21_points_balance_with_function('rc');
-- FETCH ALL IN "rc";
-- COMMIT;
--
-- Part 3 task 6
CREATE OR REPLACE FUNCTION s21_most_frequent_task_for_each_day() --
 RETURNS TABLE (day DATE, task VARCHAR) AS $$ BEGIN RETURN QUERY
	WITH tmp AS (
		SELECT c.date,
			c.task,
			COUNT(c.task) AS num
		FROM checks c
		GROUP BY 1,
			2
	)
SELECT t1.date as day,
	t1.task
FROM tmp t1
	INNER JOIN (
		SELECT date,
			MAX(num) AS max_value
		FROM tmp
		GROUP BY date
	) t2 ON t1.date = t2.date
	AND t1.num = t2.max_value;
END;
$$ LANGUAGE plpgsql;
-- test
-- SELECT *
-- FROM s21_most_frequent_task_for_each_day();
--
-- Part 3 task 7
CREATE OR REPLACE PROCEDURE my_end_block(block refcursor) AS $$ BEGIN OPEN block FOR
SELECT DISTINCT nickname,
	checks.date
FROM peers
	join checks on peers.nickname = checks.peer
	join verter on verter.checkid = checks.id
	join (
		SELECT title
		FROM tasks
		WHERE tasks.Title ~* (block || '[0-9]')
		ORDER BY Title DESC
		LIMIT 1
	) t1 on t1.title = checks.task
WHERE task ~* (block || '[0-9]')
	and verter.state = 'Success';
END;
$$ LANGUAGE plpgsql;
-- tests
-- BEGIN;
-- CALL my_end_block('C');
-- FETCH ALL IN "C";
-- COMMIT;

-- BEGIN;
-- CALL my_end_block('CPP');
-- FETCH ALL IN "CPP";
-- COMMIT;

-- BEGIN;
-- CALL my_end_block('D0');
-- FETCH ALL IN "D0";
-- COMMIT;
--
-- Part 3 Task 8
CREATE OR REPLACE FUNCTION s21_good_peer() RETURNS TABLE (peer VARCHAR, recommendedpeer VARCHAR) AS $$ BEGIN RETURN QUERY with friend_table as (
		SELECT nickname,
			peer1 as friend
		FROM peers
			JOIN friends ON nickname = peer2
		UNION
		SELECT nickname,
			peer2 as friend
		FROM peers
			JOIN friends ON nickname = peer1
		ORDER BY 1
	),
	count_of_recomendations as(
		SELECT friend_table.nickname,
			recommendations.recommendedpeer,
			count(recommendations.recommendedpeer)
		FROM friend_table
			LEFT JOIN recommendations ON friend = recommendations.peer
		WHERE friend_table.nickname != recommendations.recommendedpeer
			OR recommendations.recommendedpeer is NULL
		GROUP BY 1,
			2
		ORDER BY 1
	)
SELECT nickname as peer,
	c1.recommendedpeer
FROM count_of_recomendations c1
WHERE count = (
		SELECT max(count)
		FROM count_of_recomendations c2
		WHERE c1.nickname = c2.nickname
	)
ORDER BY 1;
END;
$$ LANGUAGE plpgsql;
-- test
-- SELECT *
-- FROM s21_good_peer();
--
-- Part 3 task 9
CREATE OR REPLACE PROCEDURE my_begin_block(block1 refcursor, block2 refcursor) AS $$ BEGIN OPEN block1 FOR -- тело процедуры
SELECT (
		(
			block1.nicknames::real - StartedBothBlock.nicknames::real
		) / COUNT(peers) * 100
	)::integer as StartedBlock1,
	(
		(
			block2.nicknames::real - StartedBothBlock.nicknames::real
		) / COUNT(peers) * 100
	)::integer as StartedBlock2,
	(
		StartedBothBlock.nicknames::real / COUNT(peers) * 100
	)::integer as StartedBothBlock,
	(
		DidntStartAnyBlock.nicknames::real / COUNT(peers) * 100
	)::integer as DidntStartAnyBlock
FROM (
		SELECT COUNT(nickname) as nicknames
		FROM (
				SELECT DISTINCT nickname
				FROM peers
					left outer join checks on peers.nickname = checks.peer
				WHERE task ~* ($1 || '[0-9]')
			) nickname
	) block1,
	(
		SELECT COUNT(nickname) as nicknames
		FROM (
				SELECT DISTINCT nickname
				FROM peers
					left outer join checks on peers.nickname = checks.peer
				WHERE task ~* ($2 || '[0-9]')
			) nickname
	) block2,
	(
		SELECT COUNT(t1.nickname) as nicknames
		FROM (
				SELECT DISTINCT nickname
				FROM peers
					left outer join checks on peers.nickname = checks.peer
				WHERE task ~* ($1 || '[0-9]')
				INTERSECT
				SELECT DISTINCT nickname
				FROM peers
					left outer join checks on peers.nickname = checks.peer
				WHERE task ~* ($2 || '[0-9]')
			) t1
	) StartedBothBlock,
	(
		SELECT COUNT(nickname) as nicknames
		FROM (
				SELECT DISTINCT nickname
				FROM peers
					left join checks on peers.nickname = checks.peer
				WHERE task is NULL
			) nickname
	) DidntStartAnyBlock,
	peers
GROUP BY block1.nicknames,
	block2.nicknames,
	StartedBothBlock.nicknames,
	DidntStartAnyBlock.nicknames;
END;
$$ LANGUAGE plpgsql;
-- tests
-- BEGIN;
-- CALL my_begin_block('C', 'CPP');
-- FETCH ALL IN "C";
-- COMMIT;

-- BEGIN;
-- CALL my_begin_block('CPP', 'C');
-- FETCH ALL IN "CPP";
-- COMMIT;

-- BEGIN;
-- CALL my_begin_block('D0', 'C');
-- FETCH ALL IN "D0";
-- COMMIT;
--
-- Part 3 task 10
CREATE OR REPLACE FUNCTION fnc_success_procent_birthday() RETURNS TABLE(SuccessfulChecks integer, UnsuccessfulChecks integer) AS $$ BEGIN RETURN QUERY -- тело процедуры
SELECT (
		count_peers_success.SuccessfulCheck::real / COUNT(peers) * 100
	)::integer as SuccessfulChecks,
	(
		count_peers_failure.UnsuccessfulCheck::real / COUNT(peers) * 100
	)::integer as UnsuccessfulChecks
FROM peers,
	(
		SELECT COUNT(peers_success.unique_nicknames) as SuccessfulCheck
		FROM (
				SELECT nickname as unique_nicknames
				FROM peers
					join checks on peers.nickname = Checks.peer
					AND EXTRACT(
						month
						from peers.Birthday
					) = EXTRACT(
						month
						from checks.Date
					)
					AND EXTRACT(
						day
						from peers.Birthday
					) = EXTRACT(
						day
						from checks.Date
					)
					join verter on checks.id = verter.checkid
				WHERE verter.state = 'Success'
				GROUP by nickname
			) peers_success
	) count_peers_success,
	(
		SELECT COUNT(peers_failure.unique_nicknames) as UnsuccessfulCheck
		FROM (
				SELECT nickname as unique_nicknames
				FROM peers
					join checks on peers.nickname = Checks.peer
					AND EXTRACT(
						month
						from peers.Birthday
					) = EXTRACT(
						month
						from checks.Date
					)
					AND EXTRACT(
						day
						from peers.Birthday
					) = EXTRACT(
						day
						from checks.Date
					)
					join verter on checks.id = verter.checkid
					join p2p on checks.id = p2p.checkid
				WHERE verter.state = 'Failure'
					or p2p.state = 'Failure'
				GROUP by nickname
			) peers_failure
	) count_peers_failure
GROUP BY SuccessfulCheck,
	UnsuccessfulCheck;
END;
$$ LANGUAGE plpgsql;
-- test
-- SELECT *
-- FROM fnc_success_procent_birthday();
--
-- Part 3 task 11
CREATE OR REPLACE PROCEDURE my_execute_tasks(
		task1 refcursor,
		task2 refcursor,
		task3 refcursor
	) AS $$ BEGIN OPEN task1 FOR -- тело процедуры
SELECT *
FROM (
		SELECT peers.nickname
		FROM peers
			join checks on checks.peer = peers.nickname
			join verter on verter.checkid = checks.id
		where verter.state = 'Success'
			and checks.task = $1::TEXT
		INTERSECT
		SELECT peers.nickname
		FROM peers
			join checks on checks.peer = peers.nickname
			join verter on verter.checkid = checks.id
		where verter.state = 'Success'
			and checks.task = $2::TEXT
	) as success_first_second_task
INTERSECT
SELECT *
FROM (
		SELECT peers.nickname
		From peers
		EXCEPT
		SELECT peers.nickname
		FROM peers
			join checks on checks.peer = peers.nickname
			join verter on verter.checkid = checks.id
		where verter.state = 'Success'
			and checks.task = $3::TEXT
	) as not_success_third_tasks;
END;
$$ LANGUAGE plpgsql;
-- test
-- BEGIN;
-- CALL my_execute_tasks(
-- 	'C3_SimpleBashUtils',
-- 	'C4_s21_math',
-- 	'C7_SmartCalc_v1.0'
-- );
-- FETCH ALL IN "C3_SimpleBashUtils";
-- COMMIT;
--
-- Part 3 task 12
CREATE OR REPLACE PROCEDURE s21_number_of_preceding_tasks(rc refcursor) LANGUAGE plpgsql AS $$ 
BEGIN OPEN rc FOR 
	WITH RECURSIVE r (title, parenttask, PrevCount) AS (
		(
			SELECT title,
				parenttask,
				0 AS PrevCount
			FROM tasks
			WHERE parenttask IS NULL
		)
		UNION
		(
			SELECT t.title,
				t.parenttask,
				PrevCount + 1 AS PrevCount
			FROM tasks t
				JOIN r ON r.title = t.parenttask
		)
	)
SELECT title as Task,
	PrevCount
FROM r;
END;
$$;
-- test
-- BEGIN;
-- CALL s21_number_of_preceding_tasks('rc');
-- FETCH ALL IN "rc";
-- COMMIT;
--
-- Part 3 Task 13
CREATE OR REPLACE PROCEDURE s21_lucky_days(lucky_data refcursor, N int) AS $$ 
BEGIN OPEN lucky_data FOR 
	WITH cte_date AS(
		SELECT c1.date,
			c1.time,
			status_check,
			LEAD(status_check) OVER (
				ORDER BY date,
					time
			) AS next_status_check
		FROM (
				SELECT checks.date,
					time,
					state AS status_check
				FROM checks
					JOIN p2p ON checks.id = p2p.checkid
					AND p2p.state in('Success', 'Failure')
			) c1
	),
	cte_date_prev_checks AS (
		SELECT d1.date,
			d1.time,
			d1.status_check,
			d1.next_status_check,
			COUNT (d2.date)
		FROM cte_date d1
			JOIN cte_date d2 on d1.date = d2.date
			AND d1.time <= d2.time
			AND d1.status_check = d2.next_status_check
		GROUP BY d1.date,
			d1.time,
			d1.status_check,
			d1.next_status_check
	)
SELECT m1.date
FROM (
		SELECT success_checks.date,
			MAX(success_count) AS max_success_count
		FROM (
				SELECT cte_date_prev_checks.date,
					count as success_count
				FROM cte_date_prev_checks
				WHERE status_check::text = 'Success'
			) success_checks
		GROUP BY success_checks.date
	) m1
WHERE max_success_count >= N;
END;
$$ LANGUAGE plpgsql;
-- test
-- CALL s21_lucky_days('tmp', 1);
-- FETCH ALL
-- FROM "tmp";
-- CLOSE "tmp";
--
-- Part 3 Task 14
CREATE OR REPLACE FUNCTION s21_peer_with_max_xp() --
RETURNS TABLE (peer VARCHAR, xpamount bigint) AS $$
	BEGIN RETURN QUERY with latest_attempts as(
		SELECT max(x1.id) as id,
			c.peer,
			task
		FROM checks c
			JOIN xp x1 on x1.checkid = c.id
		GROUP BY 2,
			3
	),
	sum_xp_of_all_peers AS (
		SELECT l.peer,
			sum(xp.xpamount)
		FROM latest_attempts l
			JOIN xp ON l.id = xp.id
		GROUP BY 1
	)
SELECT *
FROM sum_xp_of_all_peers
WHERE sum = (
		SELECT max(sum)
		FROM sum_xp_of_all_peers
	);
END;
$$ LANGUAGE plpgsql;
-- test
-- SELECT *
-- FROM s21_peer_with_max_xp();
--
-- Part 3 task 15 
CREATE OR REPLACE PROCEDURE s21_frequent_visitors(
		visit_time time,
		visit_count integer,
		rc refcursor
	) LANGUAGE plpgsql AS $$ 
BEGIN OPEN rc FOR 
	WITH tmp AS (
		SELECT peer,
			count(*) AS C
		FROM (
				SELECT *
				FROM TimeTracking AS tt
				WHERE tt.state = 1
					AND tt.time < visit_time
			) AS tt1
		GROUP BY peer
	)
SELECT peer
FROM tmp
WHERE C >= visit_count;
END;
$$;
-- test
-- BEGIN;
-- CALL s21_frequent_visitors('18:00:00', 2, 'rc');
-- FETCH ALL IN "rc";
-- COMMIT;

-- BEGIN;
-- CALL s21_frequent_visitors('15:00:00', 1, 'rc');
-- FETCH ALL IN "rc";
-- COMMIT;

-- BEGIN;
-- CALL s21_frequent_visitors('11:00:00', 1, 'rc');
-- FETCH ALL IN "rc";
-- COMMIT;
--
-- Part 3 task 16 
CREATE OR REPLACE PROCEDURE s21_frequent_leavers(
		days_count integer,
		visit_count integer,
		rc refcursor
	) LANGUAGE plpgsql AS $$ 
BEGIN OPEN rc FOR 
	WITH tmp AS (
		SELECT peer,
			count(*) AS C
		FROM (
				SELECT *
				FROM TimeTracking AS tt
				WHERE tt.state = 2
					AND tt.date >= current_date - days_count * interval '1 day'
					AND tt.date <= current_date
			) AS tt1
		GROUP BY peer
	)
SELECT peer
FROM tmp
WHERE C > visit_count;
END;
$$;
-- tests
-- BEGIN;
-- CALL s21_frequent_leavers(100, 1, 'rc');
-- FETCH ALL IN "rc";
-- COMMIT;

-- BEGIN;
-- CALL s21_frequent_leavers(365, 1, 'rc');
-- FETCH ALL IN "rc";
-- COMMIT;

-- BEGIN;
-- CALL s21_frequent_leavers(365, 4, 'rc');
-- FETCH ALL IN "rc";
-- COMMIT;
--
-- Part 3 task 17 
CREATE OR REPLACE PROCEDURE s21_early_bday_visitors(rc refcursor) LANGUAGE plpgsql AS $$ 
BEGIN OPEN rc FOR 
	WITH tmp AS (
		SELECT m.month_id,
			tt.peer,
			tt.time
		FROM (
				SELECT month_id
				FROM generate_series(1, 12) AS month_id
			) AS m
			LEFT JOIN (
				SELECT *
				FROM TimeTracking
					JOIN Peers AS p ON TimeTracking.peer = p.nickname
					AND extract(
						month
						from TimeTracking.date
					) = extract(
						month
						from p.birthday
					)
				WHERE TimeTracking.state = 1
			) AS tt ON m.month_id = extract(
				month
				from tt.date
			)
	),
	t1 AS (
		SELECT DISTINCT tmp1.month_id,
			tmp1.TEntries
		FROM (
				SELECT *,
					count(*) FILTER (
						WHERE tmp.time <= '24:00:00'
					) OVER (PARTITION BY month_id) AS TEntries
				FROM tmp
			) AS tmp1
	),
	t2 AS (
		SELECT DISTINCT tmp2.month_id,
			tmp2.EEntries
		FROM (
				SELECT *,
					count(*) FILTER (
						WHERE tmp.time <= '12:00:00'
					) OVER (PARTITION BY month_id) AS EEntries
				FROM tmp
			) AS tmp2
	)
SELECT (
		CASE
			WHEN t1.month_id = 1 THEN 'January'
			WHEN t1.month_id = 2 THEN 'February'
			WHEN t1.month_id = 3 THEN 'March'
			WHEN t1.month_id = 4 THEN 'April'
			WHEN t1.month_id = 5 THEN 'May'
			WHEN t1.month_id = 6 THEN 'June'
			WHEN t1.month_id = 7 THEN 'July'
			WHEN t1.month_id = 8 THEN 'August'
			WHEN t1.month_id = 9 THEN 'September'
			WHEN t1.month_id = 10 THEN 'October'
			WHEN t1.month_id = 11 THEN 'November'
			ELSE 'December'
		END
	) AS Month,
	(
		CASE
			WHEN TEntries = 0 THEN 0
			ELSE (EEntries::real / TEntries * 100)::integer
		END
	) AS EarlyEntries
FROM t1
	JOIN t2 ON t1.month_id = t2.month_id
ORDER BY t1.month_id;
END;
$$;
-- test
-- BEGIN;
-- CALL s21_early_bday_visitors('rc');
-- FETCH ALL IN "rc";
-- COMMIT;
