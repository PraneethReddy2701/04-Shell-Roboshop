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
echo "Script started running at : $(date)"   

if [ $USER_ID -ne 0 ]
then
    echo -e "$R ERROR $N: Please run the script with root user"  
    exit 1
else
    echo "Running the script with root user" 

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

dnf module disable redis -y  &>>$LOG_FILE
VALIDATE $? "Disabling the redis default version"

dnf module enable redis:7 -y  &>>$LOG_FILE
VALIDATE $? "Enabling the redis:7 version"

dnf install redis -y  &>>$LOG_FILE
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  &>>$LOG_FILE
VALIDATE $? "Changing redis.conf to accept remote connections"

systemctl enable redis   &>>$LOG_FILE
VALIDATE $? "Enabling redis"

systemctl start redis   &>>$LOG_FILE
VALIDATE $? "Starting redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. Time taken : $Y $TOTAL_TIME seconds $Y"  | tee -a $LOG_FILE