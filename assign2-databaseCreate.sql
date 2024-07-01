-- Oracle database creation script for CST2355 Assignment2
--
-- Including creation of tablespace, user, role, grant, sequences, tables, views, and triggers
--
-- A friendly reminder: run this script while connected as 'sys as sysdba'
--

-- Create tablespace
CREATE TABLESPACE assign2
  DATAFILE 'assign2.dat' SIZE 50M 
  ONLINE; 

-- Create user
CREATE USER assign2User IDENTIFIED BY assign2Password ACCOUNT UNLOCK
  DEFAULT TABLESPACE assign2
  QUOTA 40M ON assign2;

-- Create role
CREATE ROLE appAdmin;

-- Grant permissions to the role appAdmin
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE TRIGGER, CREATE PROCEDURE TO appAdmin;

-- Assign appAdmin role to assign2User
GRANT appAdmin TO assign2User;

-- Connect as the appAdmin to database 
CONNECT assign2User/assign2Password;


-- Create sequences for surrogate keys(id)
CREATE SEQUENCE movies_seq
	START WITH 1
    	INCREMENT BY 1;

CREATE SEQUENCE genre_seq
    	START WITH 1
     	INCREMENT BY 1;

CREATE SEQUENCE directors_seq
    	START WITH 11001
     	INCREMENT BY 1;

CREATE SEQUENCE firstname_seq
    	START WITH 1
     	INCREMENT BY 1;

CREATE SEQUENCE weight_seq
    	START WITH 1
     	INCREMENT BY 1;

CREATE SEQUENCE screentime_seq
    	START WITH 1
     	INCREMENT BY 1;

-- Create tables
CREATE TABLE genre (
	genre_id number DEFAULT genre_seq.NEXTVAL,
	genre_name varchar(50) NOT NULL,
	CONSTRAINT pk_genre_id PRIMARY KEY (genre_id)
);

CREATE TABLE movies (
	movie_id number DEFAULT movies_seq.NEXTVAL,
	title varchar(50) NOT NULL,
	release_date date NULL,
	duration varchar(50) NULL,
	genre_id number NULL,
	CONSTRAINT pk_movie_id PRIMARY KEY (movie_id),
	CONSTRAINT fk_m_genre_id FOREIGN KEY (genre_id) REFERENCES genre (genre_id)
);

CREATE TABLE contributors (
	contributor_id number NOT NULL,
	last_name varchar(50) NOT NULL,
	nationality varchar(50) NULL,
	date_of_birth date NULL,
	date_of_death date NULL,
	isdeleted varchar(10) DEFAULT 'N',
	CONSTRAINT pk_contributor_id PRIMARY KEY (contributor_id)
);

CREATE TABLE movie_has_contributors (
	movie_id number NOT NULL,
	contributor_id number NOT NULL,
	roletype varchar(50) NOT NULL,
    	CONSTRAINT fk_mhc_movie_id FOREIGN KEY (movie_id) REFERENCES movies (movie_id),
    	CONSTRAINT fk_mhc_contributor_id FOREIGN KEY (contributor_id) REFERENCES contributors (contributor_id)
);

CREATE TABLE first_name (
	first_name_id number DEFAULT firstname_seq.NEXTVAL,
	first_name varchar(50) NOT NULL,
	CONSTRAINT pk_first_name_id PRIMARY KEY (first_name_id)
);

CREATE TABLE contributors_first_name (
	contributor_id number NOT NULL,
	first_name_id number NOT NULL,
	start_date timestamp NOT NULL,
	end_date timestamp DEFAULT NULL,
	comments varchar(200) NULL,
	CONSTRAINT fk_cfn_contributor_id FOREIGN KEY (contributor_id) REFERENCES contributors (contributor_id),
    	CONSTRAINT fk_cfn_firstname_id FOREIGN KEY (first_name_id) REFERENCES first_name (first_name_id)	
);

CREATE TABLE directors (
	director_id number DEFAULT directors_seq.NEXTVAL,
	contributor_id number NOT NULL,
	CONSTRAINT pk_director_id PRIMARY KEY (director_id),
	CONSTRAINT fk_d_contributor_id FOREIGN KEY (contributor_id) REFERENCES contributors (contributor_id)
);

CREATE TABLE actors (
	actor_id number NOT NULL,
	height number NULL,
	haircolor varchar(50) NULL,
	contributor_id number NOT NULL,
	isdeleted varchar(10) DEFAULT 'N',
	CONSTRAINT pk_actor_id PRIMARY KEY (actor_id),
	CONSTRAINT fk_ac_contributor_id FOREIGN KEY (contributor_id) REFERENCES contributors (contributor_id)
);

CREATE TABLE weight (
	weight_id number DEFAULT weight_seq.NEXTVAL,
	weight number NOT NULL,
	CONSTRAINT weight_id PRIMARY KEY (weight_id)
);

CREATE TABLE actors_weight (
	actor_id number NOT NULL,
	weight_id number NOT NULL,
	start_date timestamp NOT NULL,
	end_date timestamp DEFAULT NULL,
	comments varchar(200) NULL,
	CONSTRAINT fk_awe_actor_id FOREIGN KEY (actor_id) REFERENCES actors (actor_id),
    	CONSTRAINT fk_awe_weight_id FOREIGN KEY (weight_id) REFERENCES weight (weight_id)
);

CREATE TABLE role (
	movie_id number NOT NULL,
	actor_id number NOT NULL,
	character_name varchar(50) NOT NULL,
	isdeleted varchar(10) DEFAULT 'N',
    	CONSTRAINT fk_r_movie_id FOREIGN KEY (movie_id) REFERENCES movies (movie_id),	
	CONSTRAINT fk_r_actor_id FOREIGN KEY (actor_id) REFERENCES actors (actor_id)
);

CREATE TABLE screen_time (
	screen_time_id number DEFAULT screentime_seq.NEXTVAL,
	screen_time varchar(50) NOT NULL,
	CONSTRAINT pk_screen_time_id PRIMARY KEY (screen_time_id)
);

CREATE TABLE role_screen_time (
	movie_id number NOT NULL,
	actor_id number NOT NULL,
	screen_time_id number NOT NULL,
	start_date timestamp NOT NULL,
	end_date timestamp DEFAULT NULL,
	comments varchar(200) NULL,
	CONSTRAINT fk_rst_movie_id FOREIGN KEY (movie_id) REFERENCES movies (movie_id),
	CONSTRAINT fk_rst_actor_id FOREIGN KEY (actor_id) REFERENCES actors (actor_id),
    	CONSTRAINT fk_rst_screen_time_id FOREIGN KEY (screen_time_id) REFERENCES screen_time (screen_time_id)
);


-- Create views on selected tables
-- Create contributors_view
CREATE VIEW contributors_view AS
SELECT c.contributor_id, fn.first_name_id, fn.first_name, c.last_name, c.nationality, c.date_of_birth, c.date_of_death
FROM contributors c
  	LEFT JOIN contributors_first_name cfn 
   		ON c.contributor_id = cfn.contributor_id
	LEFT JOIN first_name fn
    		ON cfn.first_name_id = fn.first_name_id    
WHERE cfn.end_date is NULL;

-- Create actors_view
CREATE VIEW actors_view AS
SELECT a.actor_id, a.height, w.weight_id, w.weight, a.haircolor, a.contributor_id
FROM actors a
  	LEFT JOIN actors_weight aw 
   		ON a.actor_id = aw.actor_id
	LEFT JOIN weight w
    		ON aw.weight_id = w.weight_id    
WHERE aw.end_date is NULL;

-- Create role_view
CREATE VIEW role_view AS
SELECT r.movie_id, r.actor_id, r.character_name, st.screen_time_id, st.screen_time
FROM role r
  	LEFT JOIN role_screen_time rst
   		ON r.movie_id = rst.movie_id AND r.actor_id = rst.actor_id
	LEFT JOIN screen_time st
    		ON rst.screen_time_id = st.screen_time_id    
WHERE rst.end_date is NULL;


-- Create triggers
-- Create instead of trigger on contributors_view
CREATE OR REPLACE TRIGGER trg_contributors_view
INSTEAD OF INSERT OR UPDATE OR DELETE ON contributors_view
FOR EACH ROW
DECLARE
    v_operation_type varchar(20);
    seq number;
BEGIN
    IF INSERTING THEN
        v_operation_type := 'insert';
    ELSIF UPDATING THEN
        v_operation_type := 'update';
    ELSIF DELETING THEN
        v_operation_type := 'delete';
    END IF;

    IF v_operation_type = 'insert' THEN
        seq := firstname_seq.NEXTVAL;
        INSERT INTO contributors (contributor_id, last_name, nationality, date_of_birth, date_of_death)
        VALUES (:NEW.contributor_id, :NEW.last_name, :NEW.nationality, :NEW.date_of_birth, :NEW.date_of_death);

        INSERT INTO first_name (first_name_id, first_name) VALUES (seq, :NEW.first_name);

        INSERT INTO contributors_first_name (contributor_id, first_name_id, start_date, comments)
        VALUES (:NEW.contributor_id, seq, SYSTIMESTAMP, 'Initial first name of the contributor');

    ELSIF v_operation_type = 'update' THEN
    seq:= firstname_seq.NEXTVAL;
    UPDATE contributors
    SET last_name = :NEW.last_name,
           nationality = :NEW.nationality,
           date_of_birth = :NEW.date_of_birth,
           date_of_death = :NEW.date_of_death
    WHERE contributor_id = :OLD.contributor_id;

    UPDATE contributors_first_name
    SET end_date = SYSTIMESTAMP
    WHERE contributor_id = :OLD.contributor_id
    AND end_date IS NULL;  

    INSERT INTO first_name (first_name_id, first_name) VALUES (seq, :NEW.first_name);

    INSERT INTO contributors_first_name (contributor_id, first_name_id, start_date, comments)
    VALUES (:OLD.contributor_id, seq, SYSTIMESTAMP, 'Update first name of the contributor');
  
    ELSIF v_operation_type = 'delete' THEN
        UPDATE contributors
        SET isdeleted = 'Y'
        WHERE contributor_id = :OLD.contributor_id;

        UPDATE contributors_first_name
        SET end_date = SYSTIMESTAMP,
               comments = 'This contributor has been deleted'	
        WHERE contributor_id = :OLD.contributor_id
        AND end_date IS NULL;  

    END IF;
END;
/


-- Create instead of trigger on actors_view
CREATE OR REPLACE TRIGGER trg_actors_view
INSTEAD OF INSERT OR UPDATE OR DELETE ON actors_view
FOR EACH ROW
DECLARE
    v_operation_type varchar(20);
    seq number;
BEGIN
    IF INSERTING THEN
        v_operation_type := 'insert';
    ELSIF UPDATING THEN
        v_operation_type := 'update';
    ELSIF DELETING THEN
        v_operation_type := 'delete';
    END IF;   

    IF v_operation_type = 'insert' THEN
        seq:= weight_seq.NEXTVAL;
        INSERT INTO actors (actor_id, height, haircolor, contributor_id)
        VALUES (:NEW.actor_id, :NEW.height, :NEW.haircolor, :NEW.contributor_id);
        
        INSERT INTO weight (weight_id, weight) VALUES (seq, :NEW.weight);
        
        INSERT INTO actors_weight (actor_id, weight_id, start_date, comments)
        VALUES (:NEW.actor_id, seq, SYSTIMESTAMP, 'Create initial weight of the actor');

    ELSIF v_operation_type = 'update' THEN
        seq:= weight_seq.NEXTVAL;
        UPDATE actors
        SET height = :NEW.height,
               haircolor = :NEW.haircolor
        WHERE actor_id = :OLD.actor_id;

        UPDATE actors_weight
        SET end_date = SYSTIMESTAMP
        WHERE actor_id = :OLD.actor_id
        AND end_date IS NULL;
    
        INSERT INTO weight (weight_id, weight) VALUES (seq , :NEW.weight);
        
        INSERT INTO actors_weight (actor_id, weight_id, start_date, comments)
        VALUES (:OLD.actor_id, seq, SYSTIMESTAMP, 'Update weight of the actor');

    ELSIF v_operation_type = 'delete' THEN
        UPDATE actors
        SET isdeleted = 'Y'
        WHERE actor_id = :OLD.actor_id;

        UPDATE actors_weight
        SET end_date = SYSTIMESTAMP,
               comments = 'Actor has been deleted'
        WHERE actor_id = :OLD.actor_id
        AND end_date IS NULL;

    END IF;
END;
/


-- Create instead of trigger on role_view
CREATE OR REPLACE TRIGGER trg_role_view
INSTEAD OF INSERT OR UPDATE OR DELETE ON role_view
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(20);
    seq number;
BEGIN
    IF INSERTING THEN
        v_operation_type := 'insert';
    ELSIF UPDATING THEN
        v_operation_type := 'update';
    ELSIF DELETING THEN
        v_operation_type := 'delete';
    END IF;

    IF v_operation_type = 'insert' THEN
        seq:= screentime_seq.NEXTVAL;
        INSERT INTO role (movie_id, actor_id, character_name)
        VALUES (:NEW.movie_id, :NEW.actor_id, :NEW.character_name);

        INSERT INTO screen_time (screen_time_id, screen_time) VALUES (seq, :NEW.screen_time);

        INSERT INTO role_screen_time (movie_id, actor_id, screen_time_id, start_date, comments)
        VALUES (:NEW.movie_id, :NEW.actor_id, seq, SYSTIMESTAMP, 'Initial screen time of the role');

    ELSIF v_operation_type = 'update' THEN
        seq:= screentime_seq.NEXTVAL;
        UPDATE role
        SET character_name = :NEW.character_name
        WHERE movie_id = :OLD.movie_id AND actor_id = :OLD.actor_id;

        UPDATE role_screen_time
        SET end_date = SYSTIMESTAMP
        WHERE movie_id = :OLD.movie_id AND actor_id = :OLD.actor_id
        AND end_date IS NULL;  

        INSERT INTO screen_time (screen_time_id, screen_time) VALUES (seq, :NEW.screen_time);

        INSERT INTO role_screen_time (movie_id, actor_id, screen_time_id, start_date, comments)
        VALUES (:OLD.movie_id, :OLD.actor_id, seq, SYSTIMESTAMP, 'Update screen time of the role');

        

    ELSIF v_operation_type = 'delete' THEN
        UPDATE role
        SET isdeleted = 'Y'
        WHERE movie_id = :OLD.movie_id AND actor_id = :OLD.actor_id;

        UPDATE role_screen_time
        SET end_date = SYSTIMESTAMP	
        WHERE movie_id = :OLD.movie_id AND actor_id = :OLD.actor_id
        AND end_date IS NULL;  

    END IF;
END;
/




