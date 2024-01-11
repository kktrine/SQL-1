-- Удаление всего созданного в первом парте
drop TABLE if exists Peers CASCADE;
drop TABLE if exists Tasks CASCADE;
drop TABLE if exists XP CASCADE;
drop TABLE if exists Verter CASCADE;
drop TABLE if exists Checks CASCADE;
drop TABLE if exists P2P CASCADE;
drop TABLE if exists TransferredPoints CASCADE;
drop TABLE if exists Friends CASCADE;
drop TABLE if exists Recommendations CASCADE;
drop TABLE if exists TimeTracking CASCADE;
drop type if exists check_status CASCADE;
DROP PROCEDURE IF exists import_csv_to_db(text);
DROP PROCEDURE IF exists export_csv_from_db(text);
-- Part 2 delete
DROP PROCEDURE IF exists s21_add_p2p_check CASCADE;
DROP PROCEDURE IF exists proc_add_checking_by_Verter CASCADE;
DROP FUNCTION IF exists fnc_TransferredPoints_update CASCADE;
DROP FUNCTION IF exists s21_XP_insert_trigger_fun CASCADE;
DROP TRIGGER IF exists trg_TransferredPoints_update on p2p CASCADE;
DROP TRIGGER IF exists s21_XP_insert_trigger_fun on XP CASCADE;
-- Part 3 delete
DROP FUNCTION IF EXISTS s21_readable_transferredpoints;
DROP FUNCTION IF EXISTS s21_peer_task_xp;
DROP FUNCTION IF EXISTS s21_peer_not_exiting;
DROP PROCEDURE IF EXISTS s21_points_balance;
DROP PROCEDURE IF EXISTS s21_points_balance_with_function;
DROP FUNCTION IF EXISTS s21_most_frequent_task_for_each_day;
DROP PROCEDURE IF EXISTS my_end_block;
DROP FUNCTION IF EXISTS s21_good_peer;
DROP PROCEDURE IF exists my_begin_block(refcursor, refcursor);
DROP FUNCTION IF exists fnc_success_procent_birthday();
DROP PROCEDURE IF exists my_execute_tasks(refcursor, refcursor, refcursor);
DROP PROCEDURE IF EXISTS s21_number_of_preceding_tasks;
DROP PROCEDURE IF EXISTS s21_lucky_days;
DROP FUNCTION IF EXISTS s21_peer_with_max_xp;
DROP PROCEDURE IF EXISTS s21_frequent_visitors;
DROP PROCEDURE IF EXISTS s21_frequent_leavers;
DROP PROCEDURE IF EXISTS s21_early_bday_visitors;
-- Part 4 delete
DROP PROCEDURE IF EXISTS s21_drop_tables_starting_with_name;
DROP PROCEDURE IF EXISTS s21_get_scalar_functions;
DROP PROCEDURE IF EXISTS s21_get_delete_triggers;
-- Создание таблицы peers
create table Peers (
    Nickname varchar primary key,
    Birthday date not null
);
-- Создание таблицы tasks
create table Tasks (
    Title varchar primary key,
    ParentTask varchar null,
    MaxXP int not null,
    constraint fk_parent_tasks_title foreign key (ParentTask) references Tasks(Title) ON UPDATE CASCADE
);
-- Создание типа данных обьединение которое хранит в себе статуc проверки
create type check_status AS ENUM ('Start', 'Success', 'Failure');
-- Cоздание таблицы Checks
create table Checks (
    ID bigint primary key,
    Peer varchar not null,
    Task varchar not null,
    Date date not null,
    constraint fk_checks_peer_id foreign key (Peer) references Peers(Nickname),
    constraint fk_checks_tasks_id foreign key (Task) references Tasks(Title)
);
-- Создание таблицы P2P
create table P2P (
    ID bigint primary key,
    CheckID bigint not null,
    CheckingPeer varchar not null,
    State check_status not null,
    Time TIME(0) not null,
    constraint fk_p2p_check_id foreign key (CheckID) references Checks(ID),
    constraint fk_p2p_checkingpeer_id foreign key (CheckingPeer) references Peers(Nickname)
);
-- Cоздание таблицы Verter
create table Verter (
    ID bigint primary key,
    CheckID bigint not null,
    State check_status not null,
    Time TIME(0) not null,
    constraint fk_verter_check_id foreign key (CheckID) references Checks(ID)
);
-- Создание таблицы TransferredPoints
create table TransferredPoints (
    ID bigint primary key,
    CheckingPeer varchar not null,
    CheckedPeer varchar not null,
    PointsAmount bigint not null,
    constraint fk_transferredpoints_checkingpeer_id foreign key (CheckingPeer) references Peers(Nickname),
    constraint fk_transferredpoints_checkedpeer_id foreign key (CheckedPeer) references Peers(Nickname)
);
-- Создание таблицы Friends
create table Friends (
    ID bigint primary key,
    Peer1 varchar not null,
    Peer2 varchar not null,
    constraint fk_friends_peer1_id foreign key (Peer1) references Peers(Nickname),
    constraint fk_friends_peer2_id foreign key (Peer2) references Peers(Nickname)
);
-- Cоздание таблицы Recommendations
create table Recommendations (
    ID bigint primary key,
    Peer varchar not null,
    RecommendedPeer varchar not null,
    constraint fk_recommendations_peer_id foreign key (Peer) references Peers(Nickname),
    constraint fk_recommendations_recommendedpeer_id foreign key (RecommendedPeer) references Peers(Nickname)
);
-- Создание таблицы XP
create table XP (
    ID bigint primary key,
    CheckID bigint not null,
    XPAmount int not null,
    constraint fk_xp_check_id foreign key (CheckID) references Checks(ID)
);
-- Создание таблицы TimeTracking
create table TimeTracking (
    ID bigint primary key,
    Peer varchar not null,
    Date date not null,
    Time TIME(0) not null,
    State int not null,
    constraint ch_state check (State in (1, 2)),
    constraint fk_timetracking_peer_id foreign key (Peer) references Peers(Nickname)
);
CREATE OR REPLACE PROCEDURE import_csv_to_db(IN delim text) LANGUAGE plpgsql AS $$ BEGIN EXECUTE FORMAT(
        'COPY Peers(Nickname, Birthday) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/peers.csv'' delimiter %L CSV HEADER;
COPY Tasks(Title, ParentTask, MaxXP) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/tasks.csv'' delimiter %L CSV HEADER;
COPY checks(ID, Peer, Task, Date) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/checks.csv'' delimiter %L CSV HEADER;
COPY p2p(ID, CheckID, CheckingPeer, State, Time) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/p2p.csv'' delimiter %L CSV HEADER;
COPY verter(ID, CheckID, State, Time) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/verter.csv'' delimiter %L CSV HEADER;
COPY TransferredPoints(ID, CheckingPeer, CheckedPeer, PointsAmount) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/transferredpoints.csv'' delimiter %L CSV HEADER;
COPY friends(ID, Peer1, Peer2) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/friends.csv'' delimiter %L CSV HEADER;
COPY recommendations(ID, Peer, RecommendedPeer) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/recommendations.csv'' delimiter %L CSV HEADER;
COPY xp(ID, CheckID, XPAmount) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/xp.csv'' delimiter %L CSV HEADER;
COPY timetracking(ID, Peer, Date, Time, State) FROM ''/home/alexey/it/SQL2_Info21_v1.0-1/src/import_csv_files/timetracking.csv'' delimiter %L CSV HEADER',
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim
    );
END;
$$;
CREATE OR REPLACE PROCEDURE export_csv_from_db(IN delim text) LANGUAGE plpgsql AS $$ BEGIN EXECUTE FORMAT(
        'COPY Peers(Nickname, Birthday) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/peers.csv'' delimiter %L CSV HEADER;
COPY Tasks(Title, ParentTask, MaxXP) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/tasks.csv'' delimiter %L CSV HEADER;
COPY checks(ID, Peer, Task, Date) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/checks.csv'' delimiter %L CSV HEADER;
COPY p2p(ID, CheckID, CheckingPeer, State, Time) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/p2p.csv'' delimiter %L CSV HEADER;
COPY verter(ID, CheckID, State, Time) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/verter.csv'' delimiter %L CSV HEADER;
COPY TransferredPoints(ID, CheckingPeer, CheckedPeer, PointsAmount) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/transferredpoints.csv'' delimiter %L CSV HEADER;
COPY friends(ID, Peer1, Peer2) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/friends.csv'' delimiter %L CSV HEADER;
COPY recommendations(ID, Peer, RecommendedPeer) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/recommendations.csv'' delimiter %L CSV HEADER;
COPY xp(ID, CheckID, XPAmount) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/xp.csv'' delimiter %L CSV HEADER;
COPY timetracking(ID, Peer, Date, Time, State) TO ''/home/alexey/it/SQL2_Info21_v1.0-1/src/export_csv_files/timetracking.csv'' delimiter %L CSV HEADER',
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim,
        delim
    );
END;
$$;
-- Вызов функции импорта
call import_csv_to_db(',');
-- Вызов функции эскпорта
call export_csv_from_db(',');