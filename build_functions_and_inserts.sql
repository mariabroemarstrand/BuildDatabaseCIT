--D.2.
DROP FUNCTION IF EXISTS simple_search(username VARCHAR, user_input VARCHAR);
CREATE OR REPLACE FUNCTION simple_search(username VARCHAR, user_input VARCHAR)
RETURNS TABLE 
            (title_id VARCHAR,
	          title VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN 

IF (simple_search.username IN (SELECT search_history.username FROM search_history) AND user_input IN (SELECT search_string FROM search_history)) THEN
DELETE FROM search_history
WHERE search_history.username = simple_search.username AND search_history.search_string = simple_search.user_input;

END IF;

INSERT INTO search_history 
VALUES (username,user_input);

RETURN QUERY 
SELECT title.title_id,title.title_name
FROM title 
WHERE title.title_name ILIKE CONCAT('%',user_input,'%') OR title.title_plot ILIKE CONCAT('%',user_input,'%');

END;
$$;


--D.3.
CREATE OR REPLACE FUNCTION rating_function(username_ VARCHAR, rated_ VARCHAR, rating_ INT4)
RETURNS void
language plpgsql as
$$
BEGIN

if (rating_ not in (select scale from rating_scale)) then 
raise exception 'input unknown, please select a number from 1 to 10, where 1 is awful and 10 is brilliant';
end if;

if(username_ in (SELECT rating_history.username from rating_history) and rated_ in (SELECT title_id from rating_history)) then
UPDATE title
set nr_ratings = nr_ratings - 1;

UPDATE title
set avg_rating = avg_rating - ((select rating_ from rating_history) - title.avg_rating)/title.nr_ratings;

DELETE FROM rating_history;
end if;

INSERT INTO rating_history
VALUES(username_, rated_, rating_);

UPDATE title
set nr_ratings = nr_ratings + 1;

UPDATE title
set avg_rating = avg_rating + ((select rating_ from rating_history) - title.avg_rating)/title.nr_ratings;

END;
$$;


--D.4.
CREATE OR REPLACE FUNCTION structured_search ( title_input  varchar, plot_input varchar, characters_input varchar, name_input varchar)
RETURNS TABLE(title varchar, plot varchar, characters varchar, profname varchar)
LANGUAGE plpgsql
AS $$
BEGIN 
RETURN QUERY 
Select * 
from(
SELECT title_name,title_plot, casting.characters,prof_name
from title natural join co_actors_view natural join casting
where title_name like CONCAT('%',title_input,'%')) as foo
where title_plot ilike (CONCAT('%',(plot_input),'%')) and foo.characters ilike (CONCAT('%',(characters_input),'%')) and prof_name ilike CONCAT('%',(name_input),'%');
END;
$$;


--D.5.a
CREATE OR REPLACE FUNCTION simple_search_person(user_input VARCHAR)
RETURNS TABLE 
            (prof_id VARCHAR,
	          prof_name VARCHAR,
						characters VARCHAR,
						title_name VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN 
RETURN QUERY 
SELECT professionals.prof_id, professionals.prof_name, casting.characters, title.title_name
FROM professionals NATURAL JOIN casting NATURAL JOIN title
WHERE professionals.prof_name ILIKE CONCAT('%',user_input,'%') OR casting.characters ILIKE CONCAT('%',user_input,'%');
END;
$$;

--D.5.b
CREATE OR REPLACE FUNCTION structured_search_person(name_input VARCHAR, prof_input VARCHAR, characters_input VARCHAR)
RETURNS TABLE (name VARCHAR,
	          profession VARCHAR,
	          characters VARCHAR,
						title_name VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN 
RETURN QUERY 
SELECT * 
FROM(
SELECT prof_name, has_professions.profession, casting.characters, title.title_name
FROM has_professions NATURAL JOIN professionals NATURAL JOIN co_actors_view NATURAL JOIN casting NATURAL JOIN title
WHERE prof_name LIKE CONCAT('%',name_input,'%')) AS foo
WHERE foo.profession LIKE CONCAT('%',prof_input,'%') AND foo.characters LIKE CONCAT('%',characters_input,'%');
END;
$$;


--D.6.
create or replace function co_actors_function(actor VARCHAR)
returns table (prof_id VARCHAR,
	          prof_name VARCHAR,
	          frequency VARCHAR)
language sql as
$$
(SELECT prof_id, prof_name, "count"(*) as frequency from co_actors_view WHERE title_id in
(SELECT title_id FROM co_actors_view NATURAL JOIN casting WHERE prof_name = actor) and prof_name != actor
GROUP BY prof_id, prof_name
ORDER BY frequency desc
LIMIT 10);
$$;


--D.8.
CREATE OR REPLACE FUNCTION populer_actors(movie VARCHAR)
returns table (prof_name VARCHAR,
							 prof_rating FLOAT
							 )
language sql as
$$
SELECT prof_name, prof_rating from professionals NATURAL JOIN casted_in
WHERE title_id = movie
ORDER BY prof_rating desc
LIMIT 10 
$$;


--D.9.
drop FUNCTION if EXISTS similar_movies(movie varchar);
create or replace function similar_movies(movie varchar)
returns table (id varchar)
language plpgsql
as $$
BEGIN 

RETURN QUERY 

SELECT distinct title_id 
from
(select distinct title_id
from keyword_search
where  keyword in
(select keyword
from title natural join keyword_search
where title_id=movie
group by keyword,title_id,title_name
order by count(keyword) desc
limit 3)) as temp_title_table NATURAL JOIN has_genre
WHERE genre in (SELECT genre from has_genre where title_id =movie)
limit 10;
END;
$$;


--D.10.
create or replace function person_words(person_name varchar, lim INTEGER DEFAULT 10)
returns table (words VARCHAR,
               c_count BIGINT)
language plpgsql
as $$
BEGIN 
RETURN QUERY
select distinct keyword,count(keyword)
from(
select distinct title_id
from casted_in 
where prof_name=person_name) as tempp natural join keyword_search
group by keyword
order by count DESC
limit lim;
END;
$$;


--D.11.
CREATE or replace FUNCTION excact_search(VARIADIC w text[])
RETURNS TABLE (title_id varchar, primarytitle varchar) as $$
DECLARE
w_elem text;
endd text= ''')';
startt text=
'select title_id, title_name from title where title_id in
(select title_id from keyword_search where keyword = ''';
t text = '';
q text;
BEGIN
FOREACH w_elem IN ARRAY w
LOOP
if w_elem != w[array_upper(w, 1)] then
t := t || w_elem || endd || 'or title_id in ( select title_id from keyword_search where keyword =''';
else 
t := t || w_elem || endd;
end if;
END LOOP;
q= startt || t ;
RAISE NOTICE '%', q;
RETURN QUERY EXECUTE q;
END $$
LANGUAGE 'plpgsql';


--D.12.
drop FUNCTION if EXISTS best_match(VARIADIC w text[]);
CREATE OR REPLACE FUNCTION best_match(VARIADIC w text[])
RETURNS TABLE (
title_id VARCHAR,
title_name VARCHAR,
ranking int
)
LANGUAGE 'plpgsql'
AS $$
DECLARE
		q text;
		w_elem text;
BEGIN
    q := 'select title.title_id, title.title_name, sum(score) rank 
		       from title, (' ||
          'select distinct title_id, 1 score from keyword_search where keyword = ''' || w[1] || '''';
FOREACH w_elem IN ARRAY w[2:]
LOOP
				q := q ||
				' union all ' ||
				' select distinct title_id, 1 score from keyword_search 
				  where keyword = ''' || w_elem || '''';
END LOOP;
q := q || ') as bigunion where title.title_id = bigunion.title_id 
             GROUP BY title.title_id, title.title_name 
						 ORDER BY rank desc';
RAISE NOTICE '%', q;
RETURN QUERY EXECUTE q;
END;
$$;


--D.13.
CREATE OR REPLACE FUNCTION word_to_word(VARIADIC w text[])
RETURNS TABLE (
keyword VARCHAR,
ranking bigint
)
LANGUAGE 'plpgsql'
AS $$
DECLARE
		q text;
		w_elem text;
BEGIN
    q := ' 
select keyword, sum(score) rank 
from title natural join keyword_search natural join (' ||
'select distinct title_id, 1 score from keyword_search where keyword = ''' || w[1] || '''';
FOREACH w_elem IN ARRAY w[2:]
LOOP
				q := q ||
' union all ' ||
' select distinct title_id, 1 score from keyword_search 
where keyword = ''' || w_elem || '''';

END LOOP;
q := q || 

') as bigunion where title.title_id = bigunion.title_id 
GROUP BY keyword
ORDER BY rank desc';

RAISE NOTICE '%', q;
RETURN QUERY EXECUTE q;
END;
$$;

--update på professionals, avg_rating UDEN vægt på nr_ratings
UPDATE professionals
SET prof_rating = avg from (SELECT prof_name, avg(avg_rating) from (SELECT * from casted_in) as foo WHERE prof_name = foo.prof_name GROUP BY prof_name) as temp where temp.prof_name = professionals.prof_name;

--update på professionals, avg_rating med vægt på nr_ratings
UPDATE professionals
set prof_rating = round(weighted_avg_rating,2) 
from (select (sum(avg_sum)/nr_sum) as weighted_avg_rating, prof_id
FROM
(SELECT * from
(select sum (nr_ratings) as nr_sum, prof_id
from casted_in natural join title
where prof_id = 'nm3690621' or prof_id = 'nm3696551' or prof_id = 'nm7322330'

GROUP BY prof_id) as num_sum_table NATURAL JOIN
 
(select title_id, sum (avg_rating*nr_ratings) as avg_sum, prof_id
from (select title_id, avg_rating, nr_ratings, prof_id 
from title natural join casted_in  
where prof_id = 'nm3690621' or prof_id = 'nm3696551' or prof_id = 'nm7322330'
) as titles_table 
GROUP BY title_id, prof_id) as titles_avg_sum_table) as resultat GROUP BY nr_sum, prof_id) as foo
WHERE foo.prof_id = professionals.prof_id;




