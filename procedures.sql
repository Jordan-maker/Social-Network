DELIMITER //

CREATE PROCEDURE create_account(
    IN p_username   VARCHAR(20),
    IN p_email      VARCHAR(99),
    IN p_firstname  VARCHAR(20),
    IN p_lastname   VARCHAR(20),
    IN p_birthdate  DATE,
    IN p_info       VARCHAR(64),
    IN p_password   VARCHAR(128)
)
BEGIN
    INSERT INTO users(username, email, firstname, lastname, birthdate, info, password)
    VALUES (p_username, p_email, p_firstname, p_lastname, p_birthdate, p_info, SHA2(p_password, 512));
    SELECT CONCAT('Successful! Welcome to twitter ', p_firstname, ' ', p_lastname, '!');
END //


CREATE PROCEDURE login(
    IN p_usernameORemail VARCHAR(99),
    IN p_password VARCHAR(128)
)
BEGIN
    IF EXISTS (
        SELECT *
        FROM users
        WHERE (username = p_usernameORemail OR email = p_usernameORemail) AND password = SHA2(p_password, 512)
    )
    THEN
        INSERT INTO login_record(username)
        SELECT username FROM users
        WHERE username = p_usernameORemail OR email = p_usernameORemail;
        SELECT 1 AS status;
    ELSE
        SELECT 0 AS status;
    END IF;
END//


-- find last person who logins.
CREATE PROCEDURE find_subject(
    OUT person VARCHAR(20)
)
BEGIN
    SELECT username
    INTO person
    FROM login_record
    ORDER BY timestamp_t DESC
    LIMIT 1;
end //


-- logins record
CREATE PROCEDURE user_logins()
BEGIN
    SELECT *
    FROM login_record
    ORDER BY timestamp_t DESC;
end //


DROP PROCEDURE IF EXISTS send_tweet;
-- Send a new tweet
CREATE PROCEDURE send_tweet(
    IN p_content VARCHAR(256)
)
BEGIN
    DECLARE p_username VARCHAR(20);
    CALL find_subject(p_username);
    INSERT INTO tweet(username, tweet_content)
    VALUES (p_username, p_content);
    SELECT 'Successful, new tweet was sent.' AS mess;
end //


-- get personal tweets
CREATE PROCEDURE get_own_tweets()
BEGIN
    DECLARE p_username VARCHAR(20);
    CALL find_subject(p_username);
    SELECT tweet_content, timestamp_t, likes
    FROM tweet
    WHERE username = p_username;
end //


-- get personal tweets and replies
CREATE PROCEDURE get_own_tweets_and_replies()
BEGIN
    DECLARE p_username VARCHAR(20);
    CALL find_subject(p_username);
    SELECT t1.tweet_content, t2.tweet_content AS refrence_content, t2.username AS refrence_username, t1.timestamp_t
    FROM tweet AS t1
    LEFT JOIN tweet AS t2
    ON t1.ref_id = t2.tweet_id
    WHERE t1.username = p_username
    ORDER BY t1.timestamp_t DESC;
end //


-- Start follow
DROP PROCEDURE IF EXISTS follow;

CREATE PROCEDURE follow(
    IN p_following VARCHAR(20)
)
BEGIN
    DECLARE p_username VARCHAR(20);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
	SELECT 'There is no such username.' AS message;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
	SELECT CONCAT('You are already following to ', p_following,'.') AS message;
    END;

    CALL find_subject(p_username);

    INSERT INTO follow(follower, following)
    VALUES (p_username, p_following);
    SELECT CONCAT('Successful! you are now following to ', p_following,'.') AS message;

    UPDATE users
    SET followers = followers + 1
    WHERE username = p_following;

    UPDATE users
    SET following = following + 1
    WHERE username = p_username;

END //



-- stop follow

DROP PROCEDURE IF EXISTS stop_follow;

CREATE PROCEDURE stop_follow(
    IN p_following VARCHAR(20)
)
BEGIN
    DECLARE p_username VARCHAR(20);

    CALL find_subject(p_username);

    IF EXISTS (
        SELECT *
        FROM follow
        WHERE follower = p_username AND following = p_following
    )
    THEN
        DELETE FROM follow
        WHERE follower = p_username AND following = p_following;
        SELECT CONCAT('Successful! you are now unfollowing to ', p_following,'.') AS message;

        UPDATE users
        SET followers = followers - 1
        WHERE username = p_following;

        UPDATE users
        SET following = following - 1
        WHERE username = p_username;

    ELSE
        IF EXISTS(
            SELECT *
            FROM users
            WHERE users.username = p_following
            ) THEN
                SELECT CONCAT('You are not now following to', p_following,'.') AS message;
            ELSE
                SELECT 'There is no such username.' AS message;
        END IF;
    END IF;
END //



DROP PROCEDURE IF EXISTS block;
-- Start Blocking
CREATE PROCEDURE block(
    IN p_blocked_user VARCHAR(20)
)
BEGIN
    DECLARE p_username VARCHAR(20);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
	SELECT 'There is no such username.' AS message;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
	SELECT CONCAT('The user ', p_blocked_user, ' is already blocked.') AS message;
    END;

    CALL find_subject(p_username);
    INSERT INTO block(username, user_blocked)
    VALUES (p_username, p_blocked_user);
    SELECT CONCAT('Successful! you are now blocking to ', p_blocked_user ,'.') AS message;
end //



-- Stop Blocking
DROP PROCEDURE IF EXISTS stop_block;

CREATE PROCEDURE stop_block(
    IN p_blocked_user VARCHAR(20)
)
BEGIN
    DECLARE p_username VARCHAR(20);

    CALL find_subject(p_username);

    IF EXISTS (
        SELECT *
        FROM block
        WHERE username = p_username AND user_blocked = p_blocked_user
    )
    THEN
        DELETE FROM block
        WHERE username = p_username AND user_blocked = p_blocked_user;
        SELECT CONCAT('Successful! you have unblocking to ', p_blocked_user ,'.') AS message;
    ELSE
        IF EXISTS(
            SELECT *
            FROM users
            WHERE users.username = p_blocked_user
            ) THEN
                SELECT CONCAT('User ', p_blocked_user, ' had not been blocked previously.') AS message;
            ELSE
                SELECT 'There is no such username.' AS message;
        END IF;
    END IF;
END //



-- following activity
CREATE PROCEDURE get_following_activity()
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    SELECT y.type, y.username, y.tweet_content , y.cc AS ref_content, y.us AS ref_username, y.timestamp_t
    FROM follow, (  SELECT tweet.tweetid, tweet.type, tweet.username, tweet.tweet_content, tweet.ref_id, tweet.timestamp_t, tweet.likes, t.tweet_content AS cc, t.username AS us
                    FROM tweet LEFT JOIN tweet AS t
                    ON tweet.ref_id = t.tweetid) as y
    WHERE follow.following = y.username AND follow.follower = person AND y.username NOT IN
                                                                                (
                                                                                    SELECT block.username
                                                                                    FROM block
                                                                                    WHERE blocked_user = person
                                                                                    )
    ORDER BY y.timestamp_t DESC ;
end //



-- get a specific user activity
CREATE PROCEDURE get_user_activity(
    IN p_username VARCHAR(20)
)
BEGIN
    DECLARE person VARCHAR(20);

    IF NOT EXISTS(
            SELECT *
            FROM users
            WHERE users.username = p_username
            ) THEN
                SELECT 'There is no such username.' AS message;
    ELSE
        CALL  find_subject(person);
        SELECT tweet.type ,tweet.tweet_content, t.tweet_content AS refrence_content,t.username AS refrence_username, tweet.timestamp_t
        FROM tweet LEFT JOIN tweet as t
        ON tweet.ref_id = t.tweetid
        WHERE  tweet.username = p_username AND NOT EXISTS(
            SELECT *
            FROM block
            WHERE block.username = p_username AND blocked_user = person
            )
        ORDER BY tweet.timestamp_t DESC ;
    END IF;
end //



-- Add a new comment
CREATE PROCEDURE comment(
    IN p_tweetid INT,
    IN p_comment_content VARCHAR(256)
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status VARCHAR(5);

    CALL find_subject(person);

    SET status = (SELECT CASE WHEN EXISTS (
    SELECT *
    FROM tweet
    WHERE tweet.tweetid = p_tweetid AND tweet.username NOT IN (
            SELECT block.username
            FROM block
            WHERE blocked_user = person
        )
    )
    THEN 'True'
    ELSE 'False'
    END AS status);

    IF status = 'True' THEN
        INSERT INTO tweet(type, username, tweet_content, ref_id)
        VALUES ('C', person, p_comment_content, p_tweetid);
        SELECT 'New comment added.' as message;
    ELSE
        IF NOT EXISTS(
            SELECT *
            FROM tweet as tt
            WHERE tt.tweetid = p_tweetid
            ) THEN
                SELECT 'There is no such tweet.' AS message;
        ELSE
            SELECT 'Sorry, you cant add comment because the tweet sender is blocking you.' AS message;
        end if ;
    end if;
end //



drop procedure if exists get_comments_of_tweet;
-- Get comments of specific tweet
CREATE PROCEDURE get_comments_of_tweet(
    IN p_tweetid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    IF NOT EXISTS(
            SELECT *
            FROM tweet as tt
            WHERE tt.tweetid = p_tweetid
            ) THEN
                SELECT 'There is no such tweet.' AS message;
    ELSE
        SELECT tweet.username , tweet.tweet_content
        FROM tweet
        WHERE NOT EXISTS(
            SELECT *
            FROM block, tweet AS t
            WHERE t.tweetid = p_tweetid AND t.username = block.username AND block.blocked_user = person
            ) AND tweet.type = 'C' AND tweet.ref_id = p_tweetid AND tweet.username NOT IN (
                SELECT block.username
                FROM block
                WHERE blocked_user = person
                )
        ORDER BY tweet.timestamp_t DESC ;
    end if ;
end //


-- Gets tweets consist of specific hashtag
CREATE PROCEDURE hashtag_tweets(
    IN p_hashtag VARCHAR(6)
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);
    SELECT tweet.tweetid, type, username, tweet_content, ref_id
    FROM hashtag INNER JOIN tweet ON hashtag.tweetid = tweet.tweetid
    WHERE hashtag = p_hashtag AND tweet.username NOT IN (
                SELECT block.username
                FROM block
                WHERE blocked_user = person
            )
    ORDER BY timestamp_t DESC ;
end //


drop procedure if exists liking;
-- Like
CREATE PROCEDURE liking(
    IN p_tweetid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status VARCHAR(5);
    DECLARE status2 VARCHAR(6);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
	SELECT 'There is no such tweet.' AS message;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
	SELECT CONCAT('You are already liking tweet with tweetID = ',p_tweetid,'') AS message;
    END;

    SET status2 = (SELECT CASE WHEN EXISTS (
    SELECT *
    FROM tweet as tt
    WHERE tt.tweetid = p_tweetid
    )
    THEN 'True'
    ELSE 'False'
    END AS status);

    CALL  find_subject(person);
    SET status = (
        SELECT CASE WHEN EXISTS (
        SELECT *
        FROM tweet
        WHERE tweet.tweetid = p_tweetid AND  tweet.username NOT IN (
                SELECT block.username
                FROM block
                WHERE blocked_user = person
            )
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF status = 'True' AND status2 = 'True' THEN
        INSERT INTO likes(username, tweetid)
        VALUES (person, p_tweetid);
        SELECT 'Successful!' as mess;
    ELSEIF status2 = 'False' THEN
        SELECT 'There is no such tweet.' AS mess;
    ELSE
        SELECT 'You cant like this tweet because sender is blocking you.' as mess;
    end if;
end //




-- Get #like of specific tweet
CREATE PROCEDURE number_of_likes(
    IN p_tweetid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    IF NOT EXISTS(
            SELECT *
            FROM tweet as tt
            WHERE tt.tweetid = p_tweetid
            ) THEN
                SELECT 'There is no such tweet.' AS mess;
    ELSE

        SELECT CASE WHEN EXISTS (
        SELECT *
        FROM tweet
        WHERE tweet.tweetid = p_tweetid AND  tweet.username  IN (
                SELECT block.username
                FROM block
                WHERE blocked_user = person
            )
        )
        THEN 0
        ELSE (SELECT COUNT(*)
              FROM likes
              WHERE tweetid = p_tweetid)
        END AS number_of_like;
    end if;
end //



-- List of liking of specific tweet
CREATE PROCEDURE list_of_liking(
    IN p_tweetid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    IF NOT EXISTS(
            SELECT *
            FROM tweet as tt
            WHERE tt.tweetid = p_tweetid
            ) THEN
                SELECT 'There is no such tweet.' AS mess;
    ELSE

        SELECT likes.username
        FROM likes
        WHERE NOT EXISTS(
            SELECT *
            FROM block, tweet AS t
            WHERE t.tweetid = p_tweetid AND t.username = block.username
            ) AND likes.tweetid = p_tweetid AND likes.username NOT IN (
                SELECT block.username
                FROM block
                WHERE blocked_user = person
                );
    end if ;
end //



-- Popular tweets
CREATE PROCEDURE get_popular_tweets()
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);
    SELECT *
    FROM tweet
    WHERE username NOT IN (
            SELECT block.username
            FROM block
            WHERE blocked_user = person
        )
    ORDER BY likes DESC ;
end //


drop procedure if exists direct_text_message;
-- Send text message
CREATE PROCEDURE direct_text_message(
    IN  p_username VARCHAR(20),
    IN  p_text  VARCHAR(256)
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status VARCHAR(5);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
	SELECT 'There is no such username.' AS message;
    END;

    CALL  find_subject(person);
    SET status = (
        SELECT CASE WHEN NOT EXISTS(
        SELECT *
        FROM block
        WHERE block.username = p_username AND block.blocked_user = person
    )
    THEN 'True'
    ELSE 'False'
    END AS status);

    IF status = 'True' THEN
        INSERT INTO message(type, s_id, r_id, content)
        VALUES ('M', person, p_username, p_text);
        SELECT 'Successful!' AS mess;
    ELSE
        SELECT CONCAT('Sorry, you cant send message because ',p_username,' is blocking you.') AS mess;
    end if;
end //



drop procedure if exists direct_tweet_message;
-- Send a tweet in direct
CREATE PROCEDURE direct_tweet_message(
    IN  p_username VARCHAR(20),
    IN  p_tweetid  INT
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status1 VARCHAR(5);
    DECLARE status2 VARCHAR(5);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
	SELECT 'Either there is no such tweet or such a user' AS mess;
    END;

    CALL  find_subject(person);

    SET status1 = (
        SELECT CASE WHEN NOT EXISTS(
        SELECT *
        FROM block
        WHERE block.username = p_username AND block.blocked_user = person
    )
    THEN 'True'
    ELSE 'False'
    END AS status);

    SET status2 = (
        SELECT CASE WHEN NOT EXISTS(
        SELECT *
        FROM  tweet
        WHERE tweet.tweetid = p_tweetid AND tweet.username IN (
            SELECT block.username
            FROM block
            WHERE blocked_user = person
            )
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF (status1 = 'True' and status2 = 'True') THEN
        INSERT INTO message(type, s_id, r_id, ref_id)
        VALUES ('T', person, p_username, p_tweetid);
        SELECT 'Successful!' AS mess;
    ELSEIF status1 = 'True' THEN
        SELECT CONCAT('Sorry, you cant send message because ',p_username,' is blocking you.') AS mess;
    ELSE
        SELECT CONCAT('Sorry, you cant send message because tweet sender is blocking you.') AS mess;
    end if;

end //


drop procedure if exists get_a_user_messages;
-- Receive a list of messages received from the specific user
CREATE PROCEDURE get_a_user_messages(
    IN p_username VARCHAR(20)
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    IF NOT EXISTS(
            SELECT *
            FROM users
            WHERE users.username = p_username
            ) THEN
                SELECT 'There is no such username.' AS message;
    ELSE

        SELECT message.type, message.content, tweet.tweet_content
        FROM message LEFT JOIN tweet ON message.ref_id = tweet.tweetid
        WHERE r_id = person AND s_id = p_username AND (NOT message.type = 'T' OR
            tweet.username NOT IN (
            SELECT block.username
            FROM block
            WHERE blocked_user = person
            ))
        ORDER BY message.timestamp_t DESC ;
    end if;
end //


-- Get a list of message senders
CREATE PROCEDURE list_of_message_sender()
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    SELECT message.type, message.s_id, message.content, tweet.tweet_content
    FROM message LEFT JOIN tweet ON message.ref_id = tweet.tweetid
    WHERE r_id = person AND (NOT message.type = 'T' OR
        tweet.username NOT IN (
        SELECT block.username
        FROM block
        WHERE blocked_user = person
        ))
    ORDER BY message.timestamp_t DESC ;
end //
