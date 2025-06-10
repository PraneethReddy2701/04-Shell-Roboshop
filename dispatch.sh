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
echo -e "Script started running at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]
then
    echo -e "$R ERROR: Please run the script with root access $N"  | tee -a $LOG_FILE
    exit 1
else
    echo -e "You are running the script with root access"  | tee -a $LOG_FILE
fi

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

dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Installing golang"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop | tee -a $LOG_FILE
    VALIDATE $? "Creating the Roboshop system user"
else
    echo -e "Roboshop system user is already available... $Y SO SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app  &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the dispatch code"

rm -rf /app/*
cd /app 
unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the dispatch code"

go mod init dispatch &>>$LOG_FILE
go get  &>>$LOG_FILE
go build &>>$LOG_FILE
VALIDATE $? "Downloading dependencies"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOG_FILE
VALIDATE $? "Copying the dispatch.service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon-reload"

systemctl enable dispatch &>>$LOG_FILE
VALIDATE $? "Enabling dispatch"

systemctl start dispatch &>>$LOG_FILE
VALIDATE $? "Starting dispatch"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE