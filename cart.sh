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

dnf module disable nodejs -y    &>>$LOG_FILE
VALIDATE $? "Disabling the nodejs default version"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "Enabling the nodejs:20 version"

dnf install nodejs -y   &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop    &>>$LOG_FILE
    VALIDATE $? "Creating the system user roboshop"
else
    echo -e "System user roboshop is already created.. $Y SO SKIPPING $N"   | tee -a $LOG_FILE
fi

mkdir -p /app   &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip    &>>$LOG_FILE
VALIDATE $? "Downloading the cart code"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping the cart code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service    &>>$LOG_FILE
VALIDATE $? "Copying cart.service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon-reload"

systemctl enable cart   &>>$LOG_FILE
VALIDATE $? "Enabling cart"

systemctl start cart    &>>$LOG_FILE
VALIDATE $? "Starting cart"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script executed successfully. Time taken : $Y $TOTAL_TIME seconds $N" | tee -a $LOG_FILE