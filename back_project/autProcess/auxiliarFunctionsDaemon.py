from werkzeug.utils import secure_filename
import pandas as pd
from Bio import SeqIO
import os
import requests
import shutil
import sys
import wget
import ssl

current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

from constants import FILES_DOWNLOADED
from constants import URL_BACK_END_DEEPRESPRED
from emailconfig import sendEmail
from base_logger import logger

def clearDir(directory):
    try:
        shutil.rmtree(directory)
    except OSError as e:
        logger.error("%s: %s" % (directory, e.strerror))

def createDir(directory):
    isdir = os.path.isdir(directory) 
    if isdir:
        clearDir(directory)
    try:
        os.makedirs(directory)
    except Exception as e:
        logger.error("%s: %s" % (directory, e.strerror))
        return False
    
    return True

def convertSto2Fasta(dirFile):
    posDot=dirFile.find('.')
    if (posDot>0):
        nameOnly=dirFile[:posDot]
        nameFastaFull=nameOnly+".fasta"
        records = SeqIO.parse(dirFile, "stockholm")
        count = SeqIO.write(records, nameFastaFull, "fasta")
        logger.info("Converted %i records" % count)
    return nameFastaFull

def downloadFilesToLocal(filename, extension):
    #s3file/?code=prueba&ext=fasta&typed=1
    dataInput={
        "code":filename,
        "ext":extension,
        "typed":2
    }
    response = requests.get(URL_BACK_END_DEEPRESPRED+"s3file/", params=dataInput)
    rsp=response.json()
    if not rsp["error"]:
        logger.info("File downloaded: "+rsp["fullNamePath"])
        return rsp["fullNamePath"]
    else:
        logger.error("File not downloaded: "+filename)
        return ""


def validateAndAssignResults(idRequest,pfamID,email, inputType):
    dataInput={
        "idRequest":idRequest,
        "pfamID":pfamID
    }
    response = requests.get(URL_BACK_END_DEEPRESPRED+"existsPFAMreq/", json=dataInput)
    rsp=response.json()

    existsPFAMresults=rsp["result"]

    if existsPFAMresults:
        #send email with results of prediction
        if(email!=""):
            dataInput={
                "email" : email,
                "idRequest" : idRequest,
                "inputType" : inputType,
                "inputContent" : pfamID
            }
            requests.post(URL_BACK_END_DEEPRESPRED+"sendEmail/", json=dataInput)
        return True
    else:

        return False

def verifyDirOrCreate(directory):
    isdir = os.path.isdir(directory) 
        
    if not isdir:        
        try:
            os.makedirs(directory)
        except:
            logger.error("Error verifying or creating directory: "+directory)