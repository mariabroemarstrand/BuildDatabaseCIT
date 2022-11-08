--INDEX
CREATE INDEX best_known_for_index
ON best_known_for(prof_id,title_id);

CREATE INDEX keyword_search_index
ON keyword_search(keyword);

CREATE INDEX characters_index
ON casting(job_category,characters);

CREATE INDEX professional_index
ON professionals(prof_name);


CREATE INDEX title_index
ON title(title_name);

--users table
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
username CHAR(20) UNIQUE,
picture VARCHAR,
user_bio VARCHAR,
email VARCHAR,
user_password CHAR(30),
PRIMARY KEY (username)
);

--search_history TABLE
DROP TABLE IF EXISTS search_history;
CREATE TABLE search_history
(
username CHAR(20),
search_string VARCHAR,
PRIMARY KEY (username, search_string),
FOREIGN KEY (username) REFERENCES users(username)
);

--bookmark TABLE
DROP TABLE IF EXISTS bookmark;
CREATE TABLE bookmark
(
username CHAR(20),
title_id VARCHAR,
PRIMARY KEY (username, title_id),
FOREIGN KEY (username) REFERENCES users(username),
FOREIGN KEY (title_id) REFERENCES title(title_id)
);

--rating_history TABLE
DROP TABLE IF EXISTS rating_history;
CREATE TABLE rating_history
(
username CHAR(20),
title_id VARCHAR,
rating INT4,
PRIMARY KEY (username, title_id),
FOREIGN KEY (username) REFERENCES users(username),
FOREIGN KEY (title_id) REFERENCES title(title_id)
);

--create table rating_scale
DROP TABLE IF EXISTS rating_scale;
CREATE TABLE rating_scale
(
SCALE INTEGER NOT NULL CHECK (scale between 1 and 10),
description VARCHAR,
PRIMARY KEY (scale)
);

--create table rating_scale
DROP TABLE IF EXISTS rating_scale;
CREATE TABLE rating_scale
(
SCALE INTEGER NOT NULL CHECK (scale between 1 and 10),
description VARCHAR,
PRIMARY KEY (scale)
);

--insert into users, Troels
INSERT INTO users 
VALUES ('Troels', 'https://forskning.ruc.dk/files-asset/34400990/_Troels_Andreasen_MG_2279_120x120px.jpg?w=160&f=webp', 'Jeg er underviser på CS 2022', 'troels@ruc.dk','1234');

--INSERT INTO search_history
INSERT INTO search_history
VALUES ('Troels', 'what is a for-loop?');

--insert into bookmark, Troels
INSERT INTO bookmark
VALUES ('Troels', 'tt8111272');    

--insert into rating_history, Troels
INSERT INTO rating_history
VALUES ('Troels', 'tt8111272', 4.6);

--insert into rating_scale
INSERT INTO rating_scale
VALUES(1, 'Ridiculous (Burn)');
INSERT INTO rating_scale
VALUES(2, 'Awful (Don/'' even borrow it)');
INSERT INTO rating_scale
VALUES(3, 'Bad (No but you can borrow it)');
INSERT INTO rating_scale
VALUES(4, 'ehh (No desire to watch again)');
INSERT INTO rating_scale
VALUES(5, 'Average (Probably not going to watch again)');
INSERT INTO rating_scale
VALUES(6, 'Good (Maybe I will watch again)');
INSERT INTO rating_scale
VALUES(7, 'Good (Probably going to watch again)');
INSERT INTO rating_scale
VALUES(8, 'Very Good (Will watch again)');
INSERT INTO rating_scale
VALUES(9,'Excellent (Will watch again and Again..)');
INSERT INTO rating_scale
VALUES(10, 'Amazing (Indefinitely will watch again. And again and again..)');

