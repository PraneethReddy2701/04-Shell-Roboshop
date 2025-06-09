#!/bin/bash

START_TIME=$(date +%s)
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started running at : $(date)"   | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]
then
    echo -e "$R ERROR $N: Please run the script with root user"  | tee -a $LOG_FILE
    exit 1
else
    echo "Running the script with root user"  | tee -a $LOG_FILE
fi

echo "Enter rabbitmq password" | tee -a $LOG_FILE
read -s RABBITMQ_PASSWORD

VALIDATE()
{
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N"  | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N"  | tee -a $LOG_FILE
        exit 1
    fi
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Copying rabbitmq repo file"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbitmq"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabling rabbitmq"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Starting rabbitmq"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD &>>$LOG_FILE
VALIDATE $? "Adding Roboshop user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE