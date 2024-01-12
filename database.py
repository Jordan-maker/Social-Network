from validate_email import validate_email
import mysql.connector
import datetime
import pandas as pd
import re, sys


# Establishing connection
#db_user = input('Enter database user: ')
#db_password = input('Enter database password: ')

connection = mysql.connector.connect(host='localhost', user='root', password='Jordan@95', db='twitter')
cursor = connection.cursor()

# FUNCTIONS

def is_empty(df):
    if df.empty:
        return True

def is_valid_email(email):
    return True if validate_email(email) else "Invalid characters."

def is_valid_username(username):
    return True if bool(re.match(r'^[a-zA-Z0-9_.]+$', username))\
                else "Invalid characters: " + '!@#$%^&*()-+=<>?,;:\'"[]{}/\\|`'

def check_exist(table:str='users', param='username'):

    if param=='username': validate = lambda param: is_valid_username(param)
    elif param=='email':  validate = lambda param: is_valid_email(param)
    else: sys.exit("invalid param.")

    while True:
        param_ = input(f'Enter {param}: ')
        while not validate(param_):
            print(f"Invalid characters detected. Please re-enter a valid {param}.")
            param_ = input(f'Enter {param}: ')
        cursor.execute(f"SELECT COUNT(*) FROM {table} WHERE {param} = %s", (param_,))
        result = cursor.fetchone()[0]
        if result > 0:
            print(f"'Sorry, {param} {param_} is already registered. Please try another.'")
        else:
            return param_


print("")
print("Welcome to Mini-Twitter application!")
print("In each page there will be guidlines. Please choose the desired option and enter data.")
print('-' * 90)

while True:
    print("1-Log in")
    print("2-Sign up\n")
    option = int(input("Select option: "))

    if option == 1:
        arguments = []
        usernameORemail = input('Enter username or email: ')
        arguments.append(usernameORemail)
        password = input('Enter password: ')
        arguments.append(password)
        cursor.callproc('login', arguments)
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        if result:
            print("Login succesfully!\n")
            connection.commit()
            break
        else:
            print("Invalid username or password. Please try again.\n")
            connection.rollback()

    elif option == 2:
        arguments = []
        username = check_exist(table='users', param='username')
        arguments.append(username)
        email = check_exist(table='users', param='email')
        arguments.append(email)
        firstname = input('Enter first name: ')
        arguments.append(firstname)
        lastname = input('Enter last name: ')
        arguments.append(lastname)

        while True:
            try:
                birthdate = input('Enter date of birth (YYYY-MM-DD): ')
                birthdate = datetime.datetime.strptime(birthdate, '%Y-%m-%d')
                arguments.append(birthdate)
                break
            except: print('Invalid format. Try again.')

        info = input('Tell us more about you (max. 128 words long. If not, then press Enter to skip): ')
        if not info:
            info = None
        arguments.append(info)

        while True:
            while True:
                password = input('Enter password (max. 20 characters long): ')
                if len(password) <= 20:
                    break
                else: print("Password excedes lenght. Please, try another shorter.")
            password_2 = input('re-enter password: ')
            if password == password_2:
                arguments.append(password)
                break
            else: print("Passwords are not indentical. Please try again.")

        cursor.callproc('create_account', arguments)
        connection.commit()
        break
    else:
        print('INVALID INPUT!')

print('\n**************** Welcome to Mini-twitter ****************\n')
print('What would you like to do?\n')

while True:
    print('0-Quit')
    print('1-Write a new tweet')
    print('2-Get personal tweets')
    print('3-Get personal tweets and replies')
    print('4-Follow')
    print('5-Unfollow')
    print('6-Block')
    print('7-Unblock')
    print('8-Get following activities')
    print('9-Get a specific user activities')
    print('10-Add a new comment')
    print('11-Get comments of specific tweet')
    print('12-Gets tweets consist of specific hashtag')
    print('13-Like')
    print('14-Get like numbers of specific tweet')
    print('15-List of liking of specific tweet')
    print('16-Popular tweets')
    print('17-Send a text message in direct')
    print('18-Send a tweet in direct')
    print('19-Receive a list of messages received from the specific user')
    print('20-Get a list of message senders')
    print('21-get login records')

    option = int(input("\nPlease, write option: "))

    if option == 0:
        break

    elif option == 1:
        arguments = []
        tweet_content = input('Enter tweet content (max. 256 characters long):\n')
        arguments.append(tweet_content)
        cursor.callproc('send_tweet', arguments)
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input("Press Enter to continue...\n")

    elif option == 2:
        cursor.callproc('get_own_tweets')
        for i in cursor.stored_results():
            result = i.fetchall()
        df = pd.DataFrame(result)
        if is_empty(df):
            print("Empty table.")
        else:
            df.columns = ["Tweet", "Date", "Likes"]
            print()
            print(df.to_markdown(), "\n")
        input("Press Enter to continue...\n")

    elif option == 3:
        cursor.callproc('get_own_tweets_and_replies')
        for i in cursor.stored_results():
            result = i.fetchall()
        df = pd.DataFrame(result)
        if is_empty(df):
            print("Empty table.")
        else:
            df.columns = ["Tweet", "reply", "user", "Date"]
            print()
            print(df.to_markdown(), "\n")
        input("Press Enter to continue...\n")

    elif option == 4:
        arguments = []
        username = input('Enter the username of the person you want to follow: ')
        arguments.append(username)
        cursor.callproc('follow', arguments)
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input("Press Enter to continue...\n")

    elif option == 5:
        arguments = []
        username = input('Enter the username of the person you want to unfollow: ')
        arguments.append(username)
        cursor.callproc('stop_follow', arguments)
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input("Press Enter to continue...\n")

    elif option == 6:
        arguments = []
        username = input('Enter the username of the person you want to block: ')
        arguments.append(username)
        cursor.callproc('block', arguments)
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input("Press Enter to continue...\n")

    elif option == 7:
        arguments = []
        username = input('Enter the username of the person you want to unblock: ')
        arguments.append(username)
        cursor.callproc('stop_block', arguments)
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input("Press Enter to continue...\n")

    elif option == 8:
        cursor.callproc('get_following_activity')
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 9:
        arguments = []
        print('Enter the username of the person whose activities you want to see:')
        username = input()
        arguments.append(username)
        cursor.callproc('get_user_activity', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 10:
        arguments = []
        tweet_id = int(input('Enter the tweet ID you want to comment on: '))
        arguments.append(tweet_id)
        comment_content = input('Enter your comment content: ')
        arguments.append(comment_content)
        cursor.callproc('comment', arguments)
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print()
        connection.commit()
        input("Press Enter to continue...\n")

    elif option == 11:
        arguments = []
        print('Enter the tweet ID you want to see it\'s comments:')
        tweet_id = int(input())
        arguments.append(tweet_id)
        cursor.callproc('get_comments_of_tweet', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 12:
        arguments = []
        print('Enter the hashtag you want to see its tweets')
        hashtag = input()
        arguments.append(hashtag)
        cursor.callproc('hashtag_tweets', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 13:
        arguments = []
        print('Enter the tweet ID you want to like it:')
        tweet_id = int(input())
        arguments.append(tweet_id)
        cursor.callproc('liking', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input()

    elif option == 14:
        arguments = []
        print('Enter the tweet ID you want to see it\'s number of likes:')
        tweet_id = int(input())
        arguments.append(tweet_id)
        cursor.callproc('number_of_likes', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 15:
        arguments = []
        print('Enter the tweet ID you want to see it\'s List of likings :')
        tweet_id = int(input())
        arguments.append(tweet_id)
        cursor.callproc('list_of_liking', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 16:
        cursor.callproc('get_popular_tweets')
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 17:
        arguments = []
        print('Enter the username to which you want to send a text message:')
        username = input()
        arguments.append(username)
        print('Enter your text message:')
        message = input()
        arguments.append(message)

        cursor.callproc('direct_text_message', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input()

    elif option == 18:
        arguments = []
        print('Enter the username to which you want to send a tweet:')
        username = input()
        arguments.append(username)
        print('Enter the tweet ID you want to send it:')
        tweet_id = int(input())
        arguments.append(tweet_id)

        cursor.callproc('direct_tweet_message', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        print(result)
        connection.commit()
        input()

    elif option == 19:
        arguments = []
        print('Enter the username whose messages you want to view:')
        username = input()
        arguments.append(username)
        cursor.callproc('get_a_user_messages', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 20:
        cursor.callproc('list_of_message_sender')
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    elif option == 21:
        cursor.callproc('user_logins')
        result = ''
        for i in cursor.stored_results():
            result = i.fetchall()
            df = pd.DataFrame(result)
            is_empty(df)
            print(df.to_markdown())
        input()

    else:
        print('INVALID INPUT!')

cursor.close()
connection.close()
