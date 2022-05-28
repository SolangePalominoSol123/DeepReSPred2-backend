import os

BUCKET_NAME=os.getenv('BUCKET_NAME') 
IP_INFO_TOKEN=os.getenv('IP_INFO_TOKEN') 

URL_BACK_END_DEEPRESPRED = os.getenv('URL_BACK_END_DEEPRESPRED')
URL_FRONT_END_DEEPRESPRED= os.getenv('URL_FRONT_END_DEEPRESPRED')

EMAIL_SENDER = os.getenv('EMAIL_SENDER')
EMAIL_TOKEN = os.getenv('EMAIL_TOKEN') 


#BD config
DB_USER=os.getenv('DB_USER') 
DB_PASS=os.getenv('DB_PASS') 
DB_ADDR=os.getenv('DB_ADDR') 
DB_PORT=os.getenv('DB_PORT')              #Mysql port is 3306 by default
DB_NAME=os.getenv('DB_NAME') 

#AWS s3 config - True (default) if the back-end env has direct access to aws s3, False to use set variables values in constants_aws.json file
LOCAL_AWS_FLAG=os.getenv('LOCAL_AWS_FLAG') 

####-----------------------------Do not modify-----------------------------------------
CONFIG_FILENAME="config"

BASE_DIR_REPO="/home"                                               #Base Directory of repository

BASE_PATH=BASE_DIR_REPO+"/back_project"                             #Base Directory of back_end project
ALGORITHM_FOLDER=BASE_PATH+"/deepReSPred"                           #Directory with run_repeat_prediction.sh and MappingFasta.py
DAEMON_FOLDER=BASE_PATH + "/autProcess"                             #Directory where daemon proccesing will work
UPLOAD_FOLDER=DAEMON_FOLDER + "/filesInFolder"                      #Directory where input data from front-end will be saved to upload it to S3
DAEMON_QUEUE_FOLDER=DAEMON_FOLDER + "/queueReq"                     #Directory where a file with ID request will be created as a flag to daemon queue
ALGORITHM_PROCESSING=DAEMON_FOLDER + "/processingPred"              #Directory where the prediction algorithm will work
FILES_DOWNLOADED=DAEMON_FOLDER + "/filesDownloaded"                 #Directory as support to saved files downloaded from S3, this files will be deleted after their use
S3_UPLOAD_DIR=DAEMON_FOLDER + "/s3UploadDir"                        #Directory where some files could be in order to upload them to S3 from local
CONSTANT_AWS_S3_KEY_JSON="constants_aws.json"                       #Path to json file with aws s3 keys