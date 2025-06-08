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
        echo -e "$2 is... $G SUCCESS $N"
    else
        echo -e "$2 is... $R FAILURE $N"
        exit 1
    fi
}

cp mongodb.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "Copying MongoDB Repo"

dnf install mongodb-org -y
VALIDATE $? "Installing MongoDB"

systemctl enable mongod
VALIDATE $? "Enabling MongoDB"

systemctl start mongod
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MongoDB conf file for remote conncections"

systemctl enable mongod
VALIDATE $? "Enabling MongoDB"

systemctl restart mongod
VALIDATE $? "Restarting MONGODB"
