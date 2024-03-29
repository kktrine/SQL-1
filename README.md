# Info21 v1.0


## Contents


1. [Введение](#введение)
2. [Logical view of database model](#logical-view-of-database-model)
3. [Chapter III](#chapter-iii) \
    3.1. [Part 1. Создание базы данных](#part-1-создание-базы-данных) \
    3.2. [Part 2. Изменение данных](#part-2-изменение-данных) \
    3.3. [Part 3. Получение данных](#part-3-получение-данных) \
    3.4. [Дополнительно. Part 4. Метаданные](#дополнительно-part-4-метаданные)

## Введение

В школе программирования N нет ни учителей, ни уроков. Студентам необходимо последовательно выполнять задания, разработанные школой. Задания разделены на блоки (язык С/С++, SQL, DevOps, frontend, backend и тд). Каждое задание становится доступным к выполнению после успешной сдачи предыдущего(-их). Чтобы успешно выполнять проекты, студенты учатся по системе "равный равному", а также самостоятельно изучают интернет и литературу для текущего проекта. Система "равный равному" подразумевает, что между студентами нет конкуренции, всегда можно обратиться с вопросом к другому студенту и он охотно поможет. \
Чтобы проект считался успешно сданным, его необходимо проверить у других студентов (р2р проверка), а затем некоторые проекты отправляются на автоматическое тестирование (Verter). \
В школе N организована "экономика". У каждого студента есть points, которые тратятся, когда студент отправляет свой проект на проверку, и зарабатываются, когда студент сам проверяет чей-то проект. Результат выполнения проекта оценивается в процентах. Каждый проект имеет количество опыта, который получит студент при выполнении его на 100%. Если проект выполнен меньше, чем на 100%, полученный опыт кратно пересчитывается. Чтобы продолжать обучение в школе N, студенту необходимо набирать определенное количество опыта к определенным датам.

## Logical view of database model

![SQL2](./Img/SQL.jpg)


#### Таблица Peers

- Ник пира
- День рождения

#### Таблица Tasks

- Название задания
- Название задания, являющегося условием входа
- Максимальное количество XP

Чтобы начать выполнение задания, необходимо успешно финишировать другое задание, называемое условием входа.

#### Статус проверки

Статус проверки (пиром или Verter'ом) имеет перечисляемый тип с полями:
- Start - начало проверки
- Success - успешное окончание проверки
- Failure - неудачное окончание проверки

#### Таблица P2P

- ID
- ID проверки
- Ник проверяющего пира
- Статус P2P проверки
- Время

Каждая P2P проверка состоит из 2-х записей в таблице: первая имеет статус "начало",  вторая - "успех" / "неудача" - означает, что проверка окончена. \
Для данного проверяющего и проверяемого может быть одновременно только одна незавершенная проверка (проверка, для которой есть запись со статусом "начало", но нет записи со статусом "успех"/ "неудача").


#### Таблица Verter

- ID
- ID проверки
- Статус проверки Verter'ом
- Время

Verter - система автоматических тестов проектов. Проверка Verter, если она вообще предусмотрена в проекте, начинается после завершения P2P проверки при условии статуса "успех".
Каждая проверка Verter'ом состоит из 2-х записей в таблице: первая имеет статус "начало", вторая - "успех" / "неудача" - означает, что проверка окончена.

#### Таблица Checks

- ID
- Ник пира
- Название задания
- Дата проверки

Описывает факт сдачи проекта без указания результата. Проверка обязательно включает в себя **один** этап P2P и, возможно, этап Verter.

Проверка считается успешной, если соответствующий P2P этап успешен, а этап Verter успешен, либо отсутствует.
Проверка считается неуспешной, если хоть один из этапов неуспешен.


#### Таблица TransferredPoints

- ID
- Ник проверяющего пира
- Ник проверяемого пира
- Количество переданных пир поинтов за всё время (только от проверяемого к проверяющему)

При каждой P2P проверке проверяемый пир передаёт один пир поинт проверяющему.
Эта таблица содержит все пары проверяемый-проверяющий и кол-во переданных пир поинтов, то есть,
другими словами, количество P2P проверок указанного проверяемого пира, данным проверяющим.

#### Таблица Friends

- ID
- Ник первого пира
- Ник второго пира

Дружба взаимная, т.е. первый пир является другом второго, а второй -- другом первого.

#### Таблица Recommendations

- ID
- Ник пира
- Ник пира, к которому рекомендуют идти на проверку

Каждому может понравиться, как проходила P2P проверка у того или иного пира.
Пир, указанный в поле Peer, рекомендует проходить P2P проверку у пира из поля RecommendedPeer.
Каждый пир может рекомендовать как ни одного, так и сразу несколько других пиров.

#### Таблица XP

- ID
- ID проверки
- Количество полученного XP

За каждый успешно сданный проект пир получает какое-то определенное количество ХР.
За каждый проект есть определенное максимально возможное количество ХР, после сдачи проекта пир получает сколько-то процентов от максимального ХР проекта. ХР начисляется только за успешно сданные проекты.

#### Таблица TimeTracking

- ID
- Ник пира
- Дата
- Время
- Состояние (1 - пришел, 2 - вышел)

Данная таблица содержит информация о посещениях пирами кампуса.
Когда пир входит в кампус, в таблицу добавляется запись с состоянием 1, когда выходит - с состоянием 2.

Под "отлучиться" подразумеваются все выходы из кампуса за день, кроме последнего.
В течение одного дня должно быть одинаковое количество записей с состоянием 1 и состоянием 2 для каждого пира.

Например:

| ID | Peer  | Date     | Time  | State |
|----|-------|----------|-------|-------|
| 1  | Ivan | 21.04.22 | 13:50 | 1     |
| 2  | Ivan | 21.04.22 | 15:30 | 2     |
| 3  | Ivan | 21.04.22 | 16:08 | 1     |
| 4  | Ivan | 21.04.22 | 20:24 | 2     |

Пир с ником Ivan отлучился из кампуса на 14 минут.


## Chapter III

## Part 1. Создание базы данных

Cкрипт *part1.sql* создает все таблицы, описанные выше, также создает процедуры для  импортирта и экспортирта данных из/в *.csv* файлы (*import_csv_to_db*, *export_csv_from_db*). В качестве параметра каждой процедуры указывается разделитель *csv* файла.


## Part 2. Изменение данных

Скрипт *part2.sql* содержит:

##### 1) Процедуру добавления P2P проверки (*add_p2p_check*)
Параметры: ник проверяемого, ник проверяющего, название задания, [статус проверки](#статус-проверки), время.

##### 2) Процедуру добавления проверки Verter'ом (*proc_add_checking_by_Verter*)
Параметры: ник проверяемого, название задания, [статус проверки Verter'ом](#статус-проверки), время.

##### 3) Триггер: после добавления записи со статутом "начало" в таблицу P2P, изменяется соответствующая запись в таблице TransferredPoints (*trg_TransferredPoints_update*)

##### 4) Триггер: перед добавлением записи в таблицу XP проверяется корректность добавляемой записи (*XP_insert_trigger*):
- Количество XP не превышает максимальное доступное для проверяемой задачи
- Поле Check ссылается на успешную проверку\
Если запись не прошла проверку, не добавлять её в таблицу.

## Part 3. Получение данных

Скрипт *part3.sql* содержит:

##### 1) Функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде (*readable_transferredpoints*)
Ник пира 1, ник пира 2, количество переданных пир поинтов. \
Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.

##### 2) Функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP (*peer_task_xp*)
В таблице помещаются только задания, успешно прошедшие проверку. \
Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.

##### 3) Функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня (*peer_not_exiting*)
Параметры функции: день, например 12.05.2022. \
Функция возвращает только список пиров.

##### 4) Подсчет изменения в количестве пир поинтов каждого пира по таблице TransferredPoints (*points_balance*)
Результат вывести отсортированным по изменению числа поинтов. \
Формат вывода: ник пира, изменение в количество пир поинтов

##### 5) Подсчет изменения в количестве пир поинтов каждого пира по таблице, возвращаемой [первой функцией из Part 3](#1-написать-функцию-возвращающую-таблицу-transferredpoints-в-более-человекочитаемом-виде) (*points_balance_with_function*)
Результат вывести отсортированным по изменению числа поинтов. \
Формат вывода: ник пира, изменение в количество пир поинтов

##### 6) Определение самого часто проверяемого задания за каждый день (*most_frequent_task_for_each_day*)
При одинаковом количестве проверок каких-то заданий в определенный день, выводятся они все. \
Формат вывода: день, название задания

##### 7) Находит всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания (*my_end_block*)
Параметры процедуры: название блока, например "CPP". \
Результат вывести отсортированным по дате завершения. \
Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)

##### 8) Определяет, к какому пиру стоит идти на проверку каждому обучающемуся (*good_peer*)
Определяет  исходя из рекомендаций друзей пира, т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей. \
Формат вывода: ник пира, ник найденного проверяющего

##### 9) Определяет процент пиров, которые (*my_begin_block*):
- Приступили только к блоку 1
- Приступили только к блоку 2
- Приступили к обоим
- Не приступили ни к одному

Пир считается приступившим к блоку, если он проходил хоть одну проверку любого задания из этого блока.

Параметры процедуры: название блока 1, например SQL, название блока 2, например A. \
Формат вывода: процент приступивших только к первому блоку, процент приступивших только ко второму блоку, процент приступивших к обоим, процент не приступивших ни к одному

##### 10) Определяет процент пиров, которые когда-либо успешно проходили проверку в свой день рождения (*fnc_success_procent_birthday*)
Также определяет процент пиров, которые хоть раз проваливали проверку в свой день рождения. \
Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения

##### 11) Определяет всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3 (*my_execute_tasks*)
Параметры процедуры: названия заданий 1, 2 и 3. \
Формат вывода: список пиров

##### 12) Для каждой задачи выводит кол-во предшествующих ей задач (*number_of_preceding_tasks*)
То есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей. \
Формат вывода: название задачи, количество предшествующих


##### 13) Находит "удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы *N* идущих подряд успешных проверки (*lucky_days*)
Параметры процедуры: количество идущих подряд успешных проверок *N*. \
Временем проверки считать время начала P2P этапа. \
Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных. \
При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального. \
Формат вывода: список дней

##### 14) Определяет пира с наибольшим количеством XP (*peer_with_max_xp*)
Формат вывода: ник пира, количество XP


##### 15) Определяет пиров, приходивших раньше заданного времени не менее *N* раз за всё время (*frequent_visitors*)
Параметры процедуры: время, количество раз *N*. \
Формат вывода: список пиров

##### 16) Определяет пиров, выходивших за последние *N* дней из кампуса больше *M* раз (*frequent_leavers*)
Параметры процедуры: количество дней *N*, количество раз *M*. \
Формат вывода: список пиров

##### 17) Определяет для каждого месяца процент ранних входов (*early_bday_visitors*)
Для каждого месяца считает, сколько раз люди, родившиеся в этот месяц, приходили в кампус за всё время. \
Для каждого месяца считает, сколько раз люди, родившиеся в этот месяц, приходили в кампус раньше 12:00 за всё время. \
Для каждого месяца считает процент ранних входов в кампус относительно общего числа входов. \
Формат вывода: месяц, процент ранних входов

## Part 4. Метаданные

Скрипт *part4.sql*.

##### 1) Создает хранимую процедуру, которая, не уничтожая базу данных, уничтожает все те таблицы текущей базы данных, имена которых начинаются с фразы 'TableName' (*drop_tables_starting_with_name*).

##### 2) Создает хранимую процедуру с выходным параметром, которая выводит список имен и параметров всех скалярных SQL функций пользователя в текущей базе данных. Имена функций без параметров не выводятся. Возвращает количество найденных функций (*get_scalar_functions*).

##### 3) Создает хранимую процедуру с выходным параметром, которая уничтожает все SQL DML триггеры в текущей базе данных. Возвращает количество уничтоженных триггеров (*get_delete_triggers*).

