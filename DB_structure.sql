/*
 База данных стримингового музыкального сервиса.
 
Таблицы:
- тарифов для пользователей,
- пользователи,
- исполнители,
- альбомы,
- песни,
- обложки,
- плейлисты,
- лайки,
- рекламодатели,
- реклама.
 */

DROP DATABASE IF EXISTS music;
CREATE DATABASE music;
USE music;

DROP TABLE IF EXISTS tarifs;
CREATE TABLE IF NOT EXISTS tarifs (
	id SERIAL PRIMARY KEY,
	tarif VARCHAR(255) NOT NULL COMMENT 'Наименование плана подписки',
	cost INT COMMENT 'Стоимость в месяц',
	adver TINYINT COMMENT 'Наличие рекламы',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления'
) COMMENT 'План подписки';

DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL COMMENT 'Имя пользователя',
	email VARCHAR(255) UNIQUE COMMENT 'Электронный адрес пользователя',
	tarif_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на тариф',
	FOREIGN KEY (tarif_id) REFERENCES tarifs(id),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления профиля',
	KEY index_of_users_email (email)
) COMMENT 'Пользователи';

DROP TABLE IF EXISTS artists;
CREATE TABLE IF NOT EXISTS artists (
	id SERIAL PRIMARY KEY,
	artist VARCHAR(255) NOT NULL COMMENT 'Наименование исполнителя',
	date_creation YEAR COMMENT 'Дата создания',
	date_end YEAR COMMENT 'Дата окончания',
	genre VARCHAR(255) COMMENT 'Основной жанр',
	about TEXT COMMENT 'Описание исполнителя',
	email VARCHAR(255) UNIQUE COMMENT 'Контактный электронный адрес иполнителя',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления профиля'
) COMMENT 'Исполнители';

DROP TABLE IF EXISTS covers;
CREATE TABLE IF NOT EXISTS covers (
	id SERIAL PRIMARY KEY,
	cover_url TEXT COMMENT 'Обложка',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления'
) COMMENT 'Обложки';

DROP TABLE IF EXISTS albums;
CREATE TABLE IF NOT EXISTS albums (
	id SERIAL PRIMARY KEY,
	album VARCHAR(255) NOT NULL COMMENT 'Наименование альбома',
	release_date DATE COMMENT 'Дата релиза',
	artist_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на исполнителя',
	cover_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на обложку',
	FOREIGN KEY (artist_id) REFERENCES artists(id),
    FOREIGN KEY (cover_id) REFERENCES covers(id),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления',
	KEY index_of_artist_id (artist_id)
) COMMENT 'Альбомы';

DROP TABLE IF EXISTS songs;
CREATE TABLE IF NOT EXISTS songs (
	id SERIAL PRIMARY KEY,
	song VARCHAR(255) NOT NULL COMMENT 'Наименование трэка',
	duration_ms BIGINT COMMENT 'Продожительность в милисекундах',
	album_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на альбом',
	count_plays BIGINT COMMENT 'Счетчик прослушиваний',
	FOREIGN KEY (album_id) REFERENCES albums(id),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления',
	KEY index_of_album_id (album_id)
) COMMENT 'Песни';

DROP TABLE IF EXISTS playlists;
CREATE TABLE IF NOT EXISTS playlists (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL COMMENT 'Наименование плэйлиста',
	user_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на пользователя',
	song_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на трэк',
	FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (song_id) REFERENCES songs(id),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления',
	KEY index_of_user_id (user_id),
	KEY index_of_song_id (song_id)
) COMMENT 'Плейлисты';

DROP TABLE IF EXISTS likes;
CREATE TABLE IF NOT EXISTS likes (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на пользователя',
	song_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на трэк',
	FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (song_id) REFERENCES songs(id),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления',
	KEY index_of_user_id (user_id),
	KEY index_of_song_id (song_id)
) COMMENT 'План подписки';

DROP TABLE IF EXISTS advertiser;
CREATE TABLE IF NOT EXISTS advertiser (
	id SERIAL PRIMARY KEY,
	advertiser VARCHAR(255) COMMENT 'Рекламодатель',
	month_cost INT COMMENT 'Платеж в месяц',
	count_monts INT COMMENT 'Сколько месяцев размещалась реклама',
	revenue BIGINT COMMENT 'Суммарная выручка от контрагента',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления'
) COMMENT 'Рекламодатель';

DROP TABLE IF EXISTS advertisment;
CREATE TABLE IF NOT EXISTS advertisment (
	id SERIAL PRIMARY KEY,
	adv_url VARCHAR(255) COMMENT 'Рекламная запись',
	duration_ms BIGINT COMMENT 'Длительность рекламы',
	advertiser_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на рекламодателя',
	FOREIGN KEY (advertiser_id) REFERENCES advertiser(id),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления',
	KEY index_of_advertiser_id (advertiser_id)
) COMMENT 'Реклама';