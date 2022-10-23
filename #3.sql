USE library;

SELECT *
FROM m2m_books_authors
ORDER BY b_id;

-- 1 1.	Показать список книг, у которых более одного автора.
SELECT m2m_books_authors.b_id, COUNT(a_id) as count, books.b_name, books.b_quantity, books.b_year
FROM m2m_books_authors
LEFT JOIN books on books.b_id = m2m_books_authors.b_id
GROUP BY b_id
HAVING count >= 2;

-- 2 2.	Показать список книг, относящихся ровно к одному жанру.
SELECT m2m_books_genres.b_id, COUNT(g_id) as count, books.b_name, books.b_quantity, books.b_year
FROM m2m_books_genres
LEFT JOIN books on books.b_id = m2m_books_genres.b_id
group by b_id
having count = 1;

-- 5 5.	Показать список книг, которые когда-либо были взяты читателями.
SELECT books.b_id, books.b_name, books.b_year, books.b_quantity
FROM books
WHERE books.b_id IN 
	(
		SELECT distinct sb_book
        FROM subscriptions
    )
;

-- 23 23.	Показать читателя, последним взявшего в библиотеке книгу.
SELECT s.s_id, s.s_name
FROM subscriptions as sub
LEFT JOIN subscribers as s
ON sub.sb_subscriber = s.s_id
order by sb_start DESC
LIMIT 1;

-- 24 24.	Показать читателя (или читателей, если их окажется несколько), дольше всего держащего у себя книгу (учитывать только случаи, когда книга не возвращена).
select s_id, s_name, MIN(sb_start)
from subscriptions sub
left join subscribers s
ON sub.sb_subscriber = s.s_id
WHERE sb_is_active = 'Y'