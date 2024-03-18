-- Задание 1
-- Сделать запрос для получения атрибутов из указанных таблиц, применив фильтры по указанным условиям:
-- Н_ТИПЫ_ВЕДОМОСТЕЙ, Н_ВЕДОМОСТИ.
-- Вывести атрибуты: Н_ТИПЫ_ВЕДОМОСТЕЙ.НАИМЕНОВАНИЕ, Н_ВЕДОМОСТИ.ИД.
-- Фильтры (AND):
-- a) Н_ТИПЫ_ВЕДОМОСТЕЙ.НАИМЕНОВАНИЕ = Ведомость.
-- b) Н_ВЕДОМОСТИ.ИД > 1250972.
-- c) Н_ВЕДОМОСТИ.ИД = 1250972.
-- Вид соединения: LEFT JOIN.

SELECT A."НАИМЕНОВАНИЕ", B."ИД"
FROM "Н_ТИПЫ_ВЕДОМОСТЕЙ" A
         LEFT JOIN "Н_ВЕДОМОСТИ" B ON
    A."НАИМЕНОВАНИЕ" = 'Ведомость' AND B."ИД" > 1250972 AND B."ИД" = 1250972;

-- Задание 2
-- Сделать запрос для получения атрибутов из указанных таблиц, применив фильтры по указанным условиям:
-- Таблицы: Н_ЛЮДИ, Н_ОБУЧЕНИЯ, Н_УЧЕНИКИ.
-- Вывести атрибуты: Н_ЛЮДИ.ИД, Н_ОБУЧЕНИЯ.ЧЛВК_ИД, Н_УЧЕНИКИ.НАЧАЛО.
-- Фильтры: (AND)
-- a) Н_ЛЮДИ.ОТЧЕСТВО > Георгиевич.
-- b) Н_ОБУЧЕНИЯ.ЧЛВК_ИД < 163276.
-- Вид соединения: INNER JOIN.
SELECT HUMANS."ИД", STUDIES."ЧЛВК_ИД", STUDS."НАЧАЛО"
FROM "Н_ЛЮДИ" HUMANS
         INNER JOIN "Н_УЧЕНИКИ" STUDS ON HUMANS."ИД" = STUDS."ЧЛВК_ИД"
         INNER JOIN "Н_ОБУЧЕНИЯ" STUDIES ON STUDIES."ЧЛВК_ИД" < 163276 AND HUMANS."ОТЧЕСТВО" > 'Георгиевич';

-- Задание 3
-- Вывести число имен без учета повторений.
-- При составлении запроса нельзя использовать DISTINCT.
SELECT COUNT(A)
FROM (SELECT COUNT(1) AS A FROM "Н_ЛЮДИ" GROUP BY "ИМЯ") B;
-- без B ругается, что у FROM должно быть имя
-- [42601] ERROR: subquery in FROM must have an alias Hint: For example, FROM (SELECT ...) [AS] foo.

-- Задание 4
-- Выдать различные фамилии преподавателей и число людей с каждой из этих фамилий,
-- ограничив список фамилиями, встречающимися более 10 раз на на заочной форме обучения.
-- Для реализации использовать подзапрос.
WITH TEACHERS_SECOND_NAMES AS (SELECT DISTINCT HUMANS."ФАМИЛИЯ"
                               FROM "Н_СЕССИЯ" SESSION
                                        INNER JOIN "Н_ЛЮДИ" HUMANS ON SESSION."ЧЛВК_ИД" = HUMANS."ИД")
SELECT HUMAN."ФАМИЛИЯ", COUNT(HUMAN."ФАМИЛИЯ")
FROM "Н_УЧЕНИКИ" STUD
         INNER JOIN "Н_ПЛАНЫ" SP ON STUD."ПЛАН_ИД" = SP."ИД"
         INNER JOIN "Н_ФОРМЫ_ОБУЧЕНИЯ" FORM ON FORM."НАИМЕНОВАНИЕ" = 'Заочная'
         INNER JOIN "Н_ЛЮДИ" HUMAN
                    ON HUMAN."ИД" = STUD."ЧЛВК_ИД" AND HUMAN."ФАМИЛИЯ" = ANY (SELECT * FROM TEACHERS_SECOND_NAMES)
GROUP BY HUMAN."ФАМИЛИЯ"
HAVING COUNT(HUMAN."ФАМИЛИЯ") > 10;

-- Задание 5
-- Выведите таблицу со средним возрастом студентов во всех группах (Группа, Средний возраст),
-- где средний возраст больше максимального возраста в группе 1101.

CREATE OR REPLACE FUNCTION AGE_IN_YEARS(day_of_birth date)
    RETURNS INTEGER
    LANGUAGE 'plpgsql' AS
$$
BEGIN
    RETURN DATE_PART('YEAR', AGE(CURRENT_DATE, day_of_birth));
END;
$$;

WITH MAX_AGE_IN_1101 AS (SELECT MAX(AGE_IN_YEARS(HUMAN."ДАТА_РОЖДЕНИЯ"::date)) as max_age
                         FROM "Н_УЧЕНИКИ" AS STUDS
                                  INNER JOIN "Н_ЛЮДИ" HUMAN ON HUMAN."ИД" = STUDS."ЧЛВК_ИД"
                         WHERE "ГРУППА" = '1101')
SELECT GROUP_INFO.NAME, GROUP_INFO.AGE
FROM (SELECT "ГРУППА" AS NAME, AVG(AGE_IN_YEARS(HUMAN."ДАТА_РОЖДЕНИЯ"::date)) AS AGE
      FROM "Н_УЧЕНИКИ" AS STUD
               INNER JOIN "Н_ЛЮДИ" HUMAN ON HUMAN."ИД" = STUD."ЧЛВК_ИД"
      WHERE STUD."ГРУППА" != '1101'
      GROUP BY "ГРУППА") GROUP_INFO
WHERE GROUP_INFO.AGE > (SELECT * FROM MAX_AGE_IN_1101);

-- WITH MAX_AGE_IN_1101 AS (SELECT MAX(DATE_PART('YEAR', AGE(CURRENT_DATE, HUMAN."ДАТА_РОЖДЕНИЯ"))) as max_age
--                          FROM "Н_УЧЕНИКИ" AS STUDS
--                                   INNER JOIN "Н_ЛЮДИ" HUMAN ON HUMAN."ИД" = STUDS."ЧЛВК_ИД"
--                          WHERE "ГРУППА" = '1101')
-- SELECT GROUP_INFO.NAME, GROUP_INFO.AGE
-- FROM (SELECT "ГРУППА" AS NAME, AVG(DATE_PART('YEAR', AGE(CURRENT_DATE, HUMAN."ДАТА_РОЖДЕНИЯ"))) AS AGE
--       FROM "Н_УЧЕНИКИ" AS STUD
--                INNER JOIN "Н_ЛЮДИ" HUMAN ON HUMAN."ИД" = STUD."ЧЛВК_ИД"
--       WHERE STUD."ГРУППА" != '1101'
--       GROUP BY "ГРУППА") GROUP_INFO
-- WHERE GROUP_INFO.AGE > (SELECT * FROM MAX_AGE_IN_1101);

-- Задание 6
-- Получить список студентов, отчисленных ровно первого сентября 2012 года с заочной формы обучения (специальность: Программная инженерия). В результат включить:
-- номер группы;
-- номер, фамилию, имя и отчество студента;
-- номер пункта приказа;

-- Н_НАПР_СПЕЦ хранит в себе Программная инженерия
-- Н_ФОРМЫ_ОБУЧЕНЯ хранит в себе заочную форму с кодом 3
-- Н_ПЛАНЫ обращаться через Н_УЧЕНИКИ, через планы можно найти форму обучения

-- STUDS."КОНЕЦ_ПО_ПРИКАЗУ" = '2012-08-31'::date
SELECT STUD."ГРУППА", HUMAN."ИД", HUMAN."ФАМИЛИЯ", HUMAN."ИМЯ", HUMAN."ОТЧЕСТВО", SP."ПЛАН_ИД"
FROM "Н_УЧЕНИКИ" STUD
         INNER JOIN "Н_ПЛАНЫ" SP ON STUD."ПЛАН_ИД" = SP."ИД" AND STUD."КОНЕЦ_ПО_ПРИКАЗУ" = '2012-08-31'::date
         INNER JOIN "Н_ФОРМЫ_ОБУЧЕНИЯ" FORM ON FORM."НАИМЕНОВАНИЕ" = 'Заочная'
         INNER JOIN "Н_НАПР_СПЕЦ" PROG ON PROG."НАИМЕНОВАНИЕ" = 'Программная инженерия'
         INNER JOIN "Н_ЛЮДИ" HUMAN ON HUMAN."ИД" = STUD."ЧЛВК_ИД";


-- Задание 7
-- Сформировать запрос для получения числа в группе No 3100 отличников.

CREATE FUNCTION IS_A_GOOD_MARK(mark VARCHAR(8))
    RETURNS INTEGER
    LANGUAGE 'plpgsql' AS
$$
BEGIN
    IF mark in ('5', 'зачет', 'осв') THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;

-- Чтобы убрать функцию можно ее заинлайнить при помощи WHEN
WITH IS_STAR_OR_NOT AS (SELECT DISTINCT MIN(IS_A_GOOD_MARK("ОЦЕНКА")) AS IS_STAR, "ЧЛВК_ИД" AS ID
                        FROM "Н_ВЕДОМОСТИ"
                        GROUP BY "ЧЛВК_ИД")
SELECT DISTINCT COUNT(STUDS."ИД")
FROM "Н_УЧЕНИКИ" AS STUDS
WHERE STUDS."ЧЛВК_ИД" = ANY (SELECT ID FROM IS_STAR_OR_NOT WHERE IS_STAR_OR_NOT.IS_STAR = 1)
  AND STUDS."ГРУППА" = '3100';

-- WITH IS_STAR_OR_NOT AS (SELECT DISTINCT MIN(CASE WHEN "ОЦЕНКА" IN ('5', 'зачет', 'осв') THEN 1 ELSE 0 END) AS IS_STAR,
--                                         "ЧЛВК_ИД"                                                          AS ID
--                         FROM "Н_ВЕДОМОСТИ"
--                         GROUP BY "ЧЛВК_ИД")
-- SELECT DISTINCT COUNT(STUDS."ИД")
-- FROM "Н_УЧЕНИКИ" AS STUDS
-- WHERE STUDS."ЧЛВК_ИД" = ANY (SELECT ID FROM IS_STAR_OR_NOT WHERE IS_STAR_OR_NOT.IS_STAR = 1)
--   AND STUDS."ГРУППА" = '3100';

-- можно написать при помощи ALL
