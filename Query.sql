-- выбор всех трэков 
SELECT * FROM songs;

-- выбор всех трэков с указанием наименования альбома и исполнителя
SELECT s.id, a.artist, al.album, s.song, al.release_date, s.duration_ms
FROM songs AS s
JOIN albums AS al ON al.id = s.album_id
JOIN artists AS a ON a.id = al.artist_id;

-- выбор всех трэков с указанием наименования альбома и исполнителя (при помощи подзапросов)
SELECT s.id, 
	   (SELECT artist FROM artists WHERE id = 
	   		(SELECT artist_id FROM albums WHERE albums.id = s.album_id)) AS artist, 
	   (SELECT album FROM albums WHERE albums.id = s.album_id) AS album, 
	   s.song, 
	   (SELECT release_date FROM albums WHERE albums.id = s.album_id) AS release_date, 
	   s.duration_ms,
	   s.count_plays
FROM songs AS s;

-- выбор наиболее популярных трэков (топ-100) с указанием наименования альбома и исполнителя 
SELECT s.id, a.artist, al.album, s.song, al.release_date, s.duration_ms, s.count_plays
FROM songs AS s
JOIN albums AS al ON al.id = s.album_id
JOIN artists AS a ON a.id = al.artist_id
ORDER BY s.count_plays DESC
LIMIT 100;

-- выбор наиболее популярных альбомов (топ-10) (при помощи группировки)
SELECT a.artist, al.album, SUM(s.count_plays) AS count_plays
FROM songs AS s
JOIN albums AS al ON al.id = s.album_id
JOIN artists AS a ON a.id = al.artist_id
GROUP BY al.album, a.artist
ORDER BY count_plays DESC
LIMIT 10;

-- рейтинг исполнителей (при помощи конструкции with (именнованые подзапросы + join))
WITH
	top_albums AS (SELECT al.artist_id, al.album, SUM(s.count_plays) AS count_plays
					FROM songs AS s
					JOIN albums AS al ON al.id = s.album_id
					GROUP BY al.album, al.artist_id),
	
	list_artists AS (SELECT a.artist, a.id FROM artists AS a)

SELECT la.artist, SUM(tp.count_plays) AS count_plays
FROM top_albums AS tp
JOIN list_artists AS la ON la.id = tp.artist_id
GROUP BY artist
ORDER BY count_plays DESC;


-- создаем представление с рейтингом альбомов
CREATE OR REPLACE VIEW album_rating (artist, album, count_plays)
AS SELECT a.artist, al.album, SUM(s.count_plays) AS count_plays
FROM songs AS s
JOIN albums AS al ON al.id = s.album_id
JOIN artists AS a ON a.id = al.artist_id
GROUP BY al.album, a.artist
ORDER BY count_plays DESC;

-- выборка из представления c рейтингом альбомов
SELECT * FROM album_rating ORDER BY count_plays DESC;

-- создаем представление с пользователями без платной подписки
CREATE OR REPLACE VIEW users_without_subs (id, name, email)
AS SELECT u.id, u.name, u.email
FROM users AS u
WHERE u.tarif_id = 1;

-- выборка из представления c рейтингом альбомов
SELECT * FROM users_without_subs;

-- добавим колонку duration с длительностью трека в формате mm-ss (с помощью транзакций)
START TRANSACTION;
ALTER TABLE songs ADD duration TIME DEFAULT NULL;
UPDATE songs SET duration = SEC_TO_TIME(duration_ms/1000);
COMMIT;

SELECT song, duration FROM songs;

-- функция расчета индекса популярности трэка (среднее количество прослушиваний в день с даты релиза по текущую дату)
DROP FUNCTION IF EXISTS index_popularity;

DELIMITER //
CREATE FUNCTION index_popularity(check_song_id BIGINT)
RETURNS FLOAT READS SQL DATA
BEGIN
	DECLARE since_release INT;
	DECLARE count_play BIGINT;
	
	SET since_release = (TIMESTAMPDIFF(DAY, (SELECT release_date 
											   FROM albums AS al 
											   JOIN songs AS s ON s.album_id = al.id 
											   WHERE s.id = check_song_id), DATE(NOW())));
											  
	SET count_play = (SELECT count_plays FROM songs WHERE songs.id = check_song_id);

	RETURN count_play / since_release;
END

-- проверка функции
DELIMITER ;
SELECT index_popularity(1);


-- Далее создается процедура назначения рекламы для пользователя без подписки (несколько шагов):
-- 1. Добавляем новое поле в таблицу users, в котором будет указываться id назначенной рекламы
ALTER TABLE users ADD adv_id BIGINT DEFAULT NULL;
ALTER TABLE users ADD CONSTRAINT adv_id_cons FOREIGN KEY (adv_id) REFERENCES advertisment(id);

-- 2. создаем процедуру назначения рекламы для пользователя (случайно выбирается значение между максимальным и минимальным id из таблицы рекламы)
DELIMITER //
DROP PROCEDURE IF EXISTS pull_adv;
CREATE PROCEDURE pull_adv(IN for_user_id BIGINT)
BEGIN
	IF ((SELECT tarif_id FROM users WHERE id = for_user_id) = 2) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The User got subscription';
	ELSEIF ((SELECT tarif_id FROM users WHERE id = for_user_id) = 1) THEN
		UPDATE users SET adv_id = (SELECT FLOOR(RAND()*((SELECT MAX(id) FROM advertisment)-(SELECT MIN(id) FROM advertisment)+1)+(SELECT MIN(id) FROM advertisment))) WHERE id = for_user_id;
	END IF;
END//

-- 3. Проверка процедуры
CALL pull_adv(2);
SELECT * from users;