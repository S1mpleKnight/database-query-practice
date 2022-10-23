USE library;

-- 1 1.	Показать всю информацию об авторах.
SELECT *
FROM authors;

-- 2 2.	Показать всю информацию о жанрах.
SELECT *
FROM genres;

-- 5 5.	Показать, сколько всего читателей зарегистрировано в библиотеке.
SELECT COUNT(1)
FROM subscribers;

-- 16 16.	Показать в днях, сколько в среднем времени читатели уже зарегистрированы в библиотеке (временем регистрации считать диапазон от первой даты получения читателем книги до текущей даты).
SELECT AVG(times.registration_time)
FROM
(
	SELECT datediff(NOW(), MIN(sb_start)) as registration_time
	FROM subscriptions
	group by sb_subscriber
) as times;

-- 17 17.	Показать, сколько книг было возвращено и не возвращено в библиотеку (СУБД должна оперировать исходными значениями поля sb_is_active (т.е. «Y» и «N»), а после подсчёта значения «Y» и «N» должны быть преобразованы в «Returned» и «Not returned»).
SELECT COUNT(sb_is_active) as 'Not returned', yes.y as 'Returned'
FROM subscriptions, 
	(
		SELECT COUNT(sb_is_active) as y
		FROM subscriptions
		WHERE sb_is_active = 'N'
	) as yes
WHERE sb_is_active = 'Y';