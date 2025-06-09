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

echo "Enter Mysql Root password" | tee -a $LOG_FILE
read -s MYSQL_ROOT_PASSWD

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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven and Java"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "Roboshop user is already present $Y SO SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the shipping code"

rm -rf /app/*
cd /app
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Shipping code"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Downloading dependencies"

mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE
VALIDATE $? "Copying and renaming Shipping jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying Shipping.service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon-reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Start Shipping"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Installing Mysql client"


mysql -h mysql.bittu27.site -u root -pMYSQL_ROOT_PASSWD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.bittu27.site -uroot -pMYSQL_ROOT_PASSWD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.bittu27.site -uroot -pMYSQL_ROOT_PASSWD < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.bittu27.site -uroot -pMYSQL_ROOT_PASSWD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into shipping"
else
    echo "Data is already loaded" | tee -a $LOG_FILE
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE