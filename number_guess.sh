#!/bin/bash

TARGET=$(( 1 + $RANDOM % 1000 ))

GUESS_TIMES=0
# CONDITION_REG='^([1-9][0-9]{0,2}|1000)$'
CONDITION_REG='^-?[0-9]+$'

#Get and check the username for the number guessing game.
echo -e "\nEnter your username:"
read USERNAME
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
CHECK_USERNAME=$($PSQL "SELECT username FROM user_information WHERE username='$USERNAME'")


# Welcome user to the number guessing game.
if [[ -z $CHECK_USERNAME ]]
then
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here.\n"
  RECORD_NEW_USER=$($PSQL "INSERT INTO user_information(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM user_information WHERE username='$USERNAME'")
else
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM user_information WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM user_information WHERE username='$USERNAME'")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.\n"
fi


# Start of number guessing game.
echo "Guess the secret number between 1 and 1000:"

# Define guess number game function, until user get the target number.
GUESS_NUMBER () {
  read YOUR_GUESS


  if [[ $YOUR_GUESS =~ $CONDITION_REG ]]
  then
    if (( $YOUR_GUESS == $TARGET ))
    then
	    GUESS_TIMES=$(( $GUESS_TIMES + 1 ))
      echo -e "\nYou guessed it in $GUESS_TIMES tries. The secret number was $TARGET. Nice job!\n"
    elif (( $YOUR_GUESS > $TARGET ))
    then
      echo -e "\nIt's lower than that, guess again:"
      GUESS_TIMES=$(( $GUESS_TIMES + 1 ))
      GUESS_NUMBER
    else
      echo -e "\nIt's higher than that, guess again:"
      GUESS_TIMES=$(( $GUESS_TIMES + 1 ))
      GUESS_NUMBER
    fi
  else
    echo -e "\nThat is not an integer, guess again:\n"
    GUESS_TIMES=$(( $GUESS_TIMES + 1 ))
    GUESS_NUMBER
  fi
}

# Use the function to play the game
GUESS_NUMBER


# Update user_information database, after finishing the game.
if (( $GAMES_PLAYED == 0 ))
then
  GAMES_PLAYED=$(( $GAMES_PLAYED + 1 ))
  RENEW_RECORD=$($PSQL "UPDATE user_information SET games_played=$GAMES_PLAYED, best_game=$GUESS_TIMES WHERE username='$USERNAME'")
else
  GAMES_PLAYED=$(( $GAMES_PLAYED + 1 ))

  if (( $GUESS_TIMES < $BEST_GAME ))
  then
    RENEW_RECORD=$($PSQL "UPDATE user_information SET games_played=$GAMES_PLAYED, best_game=$GUESS_TIMES WHERE username='$USERNAME'")
  else
    RENEW_RECORD=$($PSQL "UPDATE user_information SET games_played=$GAMES_PLAYED WHERE username='$USERNAME'")
  fi
fi
