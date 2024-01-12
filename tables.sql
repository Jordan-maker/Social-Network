CREATE TABLE users (
user_id            INT AUTO_INCREMENT,
username           VARCHAR(20) NOT NULL, -- UNIQUE
email              VARCHAR(99) NOT NULL, -- UNIQUE
firstname          VARCHAR(20) NOT NULL,
lastname           VARCHAR(20) NOT NULL,
birthdate          DATE NOT NULL,
creation_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
info               VARCHAR(128) DEFAULT '',
followers          INT NOT NULL DEFAULT 0,
following          INT NOT NULL DEFAULT 0,
password           VARCHAR(128) NOT NULL,

PRIMARY KEY (user_id),
UNIQUE KEY (username, email)
);


DROP TABLE IF EXISTS tweet;
CREATE TABLE tweet(
tweet_id          INT AUTO_INCREMENT,
username          VARCHAR(20)  NOT NULL,
tweet_content     VARCHAR(256) NOT NULL,
ref_id            INT,
timestamp_t       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
likes             INT NOT NULL DEFAULT 0,

PRIMARY KEY (tweet_id),
FOREIGN KEY (username) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (ref_id) REFERENCES tweet(tweet_id)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE message(
 mess_id            INT AUTO_INCREMENT,
 type               CHAR(1) NOT NULL CHECK ( type in ('M', 'T')) ,
 s_id               VARCHAR(20) NOT NULL ,
 r_id               VARCHAR(20) NOT NULL ,
 content            VARCHAR(256),
 ref_id             INT,
 timestamp_t        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

PRIMARY KEY (mess_id),
FOREIGN KEY (s_id) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (r_id) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (ref_id) REFERENCES tweet(tweetid)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE login_record(
login_id      INT AUTO_INCREMENT,
username      VARCHAR(20) NOT NULL,
timestamp_t   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

PRIMARY KEY (login_id),
FOREIGN KEY (username) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE follow(
follower      VARCHAR(20) NOT NULL,
following     VARCHAR(20) NOT NULL,
timestamp_t   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

PRIMARY KEY (follower, following),
FOREIGN KEY (following) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE hashtag
(
  hashtag char(6) CHECK ( 1 = REGEXP_LIKE(UPPER(hashtag), '#[A-Z][A-Z][A-Z][A-Z][A-Z]')),
  tweetid INT,

  PRIMARY KEY (hashtag, tweetid),
  FOREIGN KEY (tweetid) REFERENCES tweet(tweetid)
  ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE likes (
username        VARCHAR(20),
tweetid         INT,
timeStamp_l     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

PRIMARY KEY     (tweetid, username),
FOREIGN KEY     (tweetid) REFERENCES tweet(tweetid)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY     (username) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE
);


DROP TABLE IF EXISTS block;
CREATE TABLE block(
username         VARCHAR(20),
user_blocked     VARCHAR(20),

PRIMARY KEY (username, user_blocked),
FOREIGN KEY (username) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (user_blocked) REFERENCES users(username)
ON DELETE CASCADE ON UPDATE CASCADE
);


