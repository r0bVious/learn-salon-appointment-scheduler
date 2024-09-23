#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c"

echo -e "\n~~ Welcome to the Salon ~~"

MAKE_APPOINTMENT() {
  echo -e "\n~~ Choose a service. ~~"

  # Fetch services and display them
  SERVICES=$($PSQL "SELECT service_id, name FROM services")
  echo "$SERVICES" | while IFS="|" read SERVICE_ID SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  # User chooses the service by id
  read SERVICE_ID_SELECTED
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

  # If the service doesn't exist, loop user back
  if [[ -z $SERVICE_NAME ]]
  then
    MAKE_APPOINTMENT
  else
    echo -e "You selected the $SERVICE_NAME service."

    # User provides phone number
    echo -e "\nPlease enter your phone number:"
    read CUSTOMER_PHONE

    # Fetch customer ID and name
    CUSTOMER_RESULT=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE'")

    # If the customer doesn't exist, ask for name and create the customer
    if [[ -z $CUSTOMER_RESULT ]]
    then
      echo -e "\nPlease enter your name:"
      read CUSTOMER_NAME
      NEW_CUSTOMER_INSERT_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
      if [[ $NEW_CUSTOMER_INSERT_RESULT == "INSERT 0 1" ]]
      then
        echo "Welcome, $CUSTOMER_NAME!"
        CUSTOMER_RESULT=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE'")
      else
        echo "Error! New customer insert failed."
        exit 1
      fi
    fi

    # Extract customer_id and name from the result
    CUSTOMER_ID=$(echo $CUSTOMER_RESULT | cut -d '|' -f 1 | sed 's/^ *//;s/ *$//')
    CUSTOMER_NAME=$(echo $CUSTOMER_RESULT | cut -d '|' -f 2 | sed 's/^ *//;s/ *$//')

    # Schedule the appointment
    echo -e "\nAt what time would you like to schedule your appointment?"
    read SERVICE_TIME

    # Check if CUSTOMER_ID was correctly set
    if [[ -z $CUSTOMER_ID ]]
    then
      echo "Error: customer ID not found."
      exit 1
    fi

    # Insert the appointment into the database
    APPOINTMENT_INSERT_RESULT=$($PSQL "INSERT INTO appointments(time, customer_id, service_id) VALUES ('$SERVICE_TIME', $CUSTOMER_ID, $SERVICE_ID_SELECTED)")
    
    if [[ $APPOINTMENT_INSERT_RESULT == "INSERT 0 1" ]]
    then
      echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    else
      echo "Appointment reservation failed."
    fi
  fi
}

MAKE_APPOINTMENT
