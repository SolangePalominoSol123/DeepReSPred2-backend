import boto3
import json
from constants import CONSTANT_AWS_S3_KEY_JSON
from constants import LOCAL_AWS_FLAG

#A json file is used due to allow aws credentials change after Back-end services were deployed
def gettingCredentialsFromJson():
    f = open(CONSTANT_AWS_S3_KEY_JSON)
    data = json.load(f)

    credentials=data['keys']
    f.close()
    return credentials

def getS3config():

    if LOCAL_AWS_FLAG:
        s3 = boto3.client('s3')
    else:
        keys = gettingCredentialsFromJson()
        s3 = boto3.client('s3',
                        aws_access_key_id = keys["ACCESS_KEY_ID"],
                        aws_secret_access_key = keys["ACCESS_SECRET_KEY"],
                        aws_session_token = keys["AWS_SESSION_TOKEN"]
                    )
    
    return s3