use library;
-- 4.	Создать представление, через которое невозможно получить информацию о том, какая конкретно книга была выдана читателю в любой из выдач.
CREATE OR REPLACE VIEW `subscribers_with_undefined_book`
as
	select books.b_name, subscribers.s_name, sb_start
    from subscriptions
    left join books on books.b_id = subscriptions.sb_book
    left join subscribers on subscribers.s_id = subscriptions.sb_subscriber;
    
-- 1.	Создать представление, позволяющее получать список читателей с количеством находящихся у каждого читателя на руках книг, но отображающее только таких читателей, по которым имеются задолженности, т.е. на руках у читателя есть хотя бы одна книга, которую он должен был вернуть до наступления текущей даты.-- 
CREATE OR REPLACE VIEW `subscribers_with_books_dept`
as
	select subscribers.s_name, count(subscriptions.sb_is_active)
    from subscriptions
	left join subscribers on subscribers.s_id = subscriptions.sb_subscriber
	WHERE subscriptions.sb_is_active = 'Y' AND subscriptions.sb_finish < CURRENT_DATE()
    GROUP BY subscribers.s_name;
    
-- 17.	Создать триггер, меняющий дату выдачи книги на текущую, если указанная в INSERT- или UPDATE-запросе дата выдачи книги меньше текущей на полгода и более.
DROP TRIGGER IF EXISTS `change_subscription_start_date`;
DROP TRIGGER IF EXISTS `change_subscription_start_date_2`;

DELIMITER $$

CREATE TRIGGER `change_subscription_start_date`
BEFORE INSERT
ON `subscriptions`
	FOR EACH ROW    
	SET NEW.`sb_start` = if (DATEDIFF(CURRENT_DATE(), NEW.`sb_start`) > 182, current_date(), NEW.`sb_start`)
$$

CREATE TRIGGER `change_subscription_start_date_2`
BEFORE UPDATE
ON `subscriptions`
	FOR EACH ROW    
	SET NEW.`sb_start` = if (DATEDIFF(CURRENT_DATE(), NEW.`sb_start`) > 182, current_date(), NEW.`sb_start`)
$$

DELIMITER ;

--  14.	Создать триггер, не позволяющий выдать книгу читателю, у которого на руках находится пять и более книг, при условии, что суммарное время, оставшееся до возврата всех выданных ему книг, составляет менее одного месяца.
DROP TRIGGER IF EXISTS `abort_subscription`;
DELIMITER $$

CREATE TRIGGER `abort_subscription`
BEFORE INSERT
ON `subscriptions`
	FOR EACH ROW
    BEGIN
        DECLARE msg VARCHAR(255);
		if ((SELECT COUNT(`sb_is_active`)
				FROM `subscriptions`
				WHERE `sb_is_active` = 'Y' AND `sb_subscriber` = NEW.`sb_subscriber`) >= 5
			AND (select SUM(datediff(CURRENT_DATE(), `sb_finish`))
				 from `subscriptions`
				 WHERE `sb_is_active` = 'Y' AND `sb_subscriber` = NEW.`sb_subscriber`) < 31)
		THEN 
			set msg = "DIE: You broke the rules... I will now Smite you, hold still...";
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
		end if;
    END;
$$

DELIMITER ;

-- 16.	Создать триггер, корректирующий название книги таким образом, чтобы оно удовлетворяло следующим условиям:
-- a.	не допускается наличие пробелов в начале и конце названия;
-- b.	не допускается наличие повторяющихся пробелов;
-- c.	первая буква в названии всегда должна быть заглавной.
DROP TRIGGER IF EXISTS `change_book_name`;
DROP FUNCTION IF EXISTS `CAP_FIRST`;
DELIMITER $$

CREATE FUNCTION CAP_FIRST (input VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE len INT;
	DECLARE i INT;

	SET len   = CHAR_LENGTH(input);
	SET input = LOWER(input);
	SET i = 0;

	WHILE (i < len) DO
		IF (MID(input,i,1) = ' ' OR i = 0) THEN
			IF (i < len) THEN
				SET input = CONCAT(
					LEFT(input,i),
					UPPER(MID(input,i + 1,1)),
					RIGHT(input,len - i - 1)
				);
			END IF;
		END IF;
		SET i = i + 1;
	END WHILE;

	RETURN input;
END;

CREATE TRIGGER `change_book_name`
BEFORE INSERT
ON `books`
	FOR EACH ROW    
	SET NEW.`b_name` = if ((ASCII(REGEXP_REPLACE(TRIM(NEW.`b_name`), '[ ]{2,}', ' ')) >= 97 AND ASCII(REGEXP_REPLACE(TRIM(NEW.`b_name`), '[ ]{2,}', ' ')) <= 122),
							CAP_FIRST(REGEXP_REPLACE(TRIM(NEW.`b_name`), '[ ]{2,}', ' ')),
                            REGEXP_REPLACE(TRIM(NEW.`b_name`), '[ ]{2,}', ' '))
$$

DELIMITER ;