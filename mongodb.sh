#!/bin/bash

START_TIME=$(date +%s)
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started running at : $(date)"

if [ $USER_ID -ne 0 ]
then
    echo -e "ERROR : $R Please run the script with root access $N" 
    exit 1
else
    echo "Running the script with root user" 
fi

VALIDATE()
{
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp mongodb.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB Repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
VALIDATE $? "Editing MongoDB conf file for remote conncections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MONGODB"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. Time taken : $Y $TOTAL_TIME seconds $N" | tee -a $LOG_FILE