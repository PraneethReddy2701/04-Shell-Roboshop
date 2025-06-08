#!/bin/bash

START_TIME=$(date -u)
USER_ID=(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=$($LOGS_FOLDER/$SCRIPT_NAME.log)
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER 
echo "Script Started running at : $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]
then    
    echo -e "ERROR: $R Please run the script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "Running the script with root access" &>>$LOG_FILE | tee -a $LOG_FILE
fi

VALIDATE()
{
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling the nodejs default version"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling the nodejs:20 version"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating the roboshop system user"
else
    echo -e "System user roboshop is already created.. $Y SO SKIPPING $N" &>>$LOG_FILE
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating the app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading the catalogue code"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the Catalogue code"

npm install &>>$LOG_FILE
VALIDATE $? "Download dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copying the catalogue service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon-reload"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling Catalogue"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Starting Catalogue"

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB repo file"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Client"

STATUS=$(mongo mongodb.bittu27.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")') 
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.bittu27.site </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already Loaded... $Y SO SKIPPING $N" &>>$LOG_FILE
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. Time taken : $Y $TOTAL_TIME seconds $N" | tee -a $LOG_FILE