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

mkdir -p $LOGS_FOLDER
echo -e "Script started running at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]
then
    echo -e "$R ERROR: Please run the script with root access $N"  | tee -a $LOG_FILE
    exit 1
else
    echo -e "You are running the script with root access"  | tee -a $LOG_FILE
fi

echo "Please enter the Mysql rorot password"  | tee -a $LOG_FILE
read -s MYSQL_ROOT_PASSWORD

VALIDATE()
{
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ...$G SUCCESS $N"  | tee -a $LOG_FILE
    else
        echo -e "$2 is ...$R FAILURE $N"  | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install mysql-server -y  &>>$LOG_FILE
VALIDATE $? "Installing Mysql"

systemctl enable mysqld  &>>$LOG_FILE
VALIDATE $? "Enabling Mysql"

systemctl start mysqld   &>>$LOG_FILE
VALIDATE $? "Starting Mysql"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD  &>>$LOG_FILE
VALIDATE $? "Set root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. $Y Time taken: $TOTAL_TIME seconds $N"  | tee -a $LOG_FILE