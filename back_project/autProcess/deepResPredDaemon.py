#Este daemon se encargará de encolar las solicitudes de predicción, de verificar si el algoritmo esta ejecutando una prediccion
#ejecutar la siguiente solicitud en caso de que no (disminuyendo la cola y consultando toda la información desde bd)

#utilizará los servicios del back para poder consultar a la bd e insertar los datos necesarios

#tambien verificará si algun parametro de ejecucion ha sido cambiado

from Bio import SeqIO
from collections import deque
from werkzeug.utils import secure_filename
from resultsManager import processingResults
from auxiliarFunctionsDaemon import clearDir
from auxiliarFunctionsDaemon import createDir
from auxiliarFunctionsDaemon import convertSto2Fasta
from auxiliarFunctionsDaemon import validateAndAssignResults
from auxiliarFunctionsDaemon import verifyDirOrCreate

import fnmatch
import os
import sys
import subprocess
import requests
import shutil
import time

current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

previousIdRequest=""
actualIdRequest=""
freeAlgorithm=True
timeIni=0
timeFin=0

#this import is after because this file is in a subdirectory
from constants import DAEMON_QUEUE_FOLDER
from constants import URL_BACK_END_DEEPRESPRED
from constants import ALGORITHM_FOLDER
from constants import ALGORITHM_PROCESSING
from constants import UPLOAD_FOLDER


##---------------------------------------LOGGER-----------------
from base_logger import logger
##--------------------------------------------------------------

q = deque()

while True:

    #Verify new prediction request and append it to queue (files are flags)
    newReqs_list = os.listdir(DAEMON_QUEUE_FOLDER)
    if len(newReqs_list)>0:
        idRequest=newReqs_list[0]
        logger.info(idRequest)
        if q.count(idRequest)<=0:
            q.append(idRequest)
            logger.info("Daemon queue status:")
            logger.info(q)


    #If algorithm is free, unqueue a request (if any)  and process
    if freeAlgorithm and len(q)>0:

        freeAlgorithm=False
        idRequest = q.popleft()
        actualIdRequest=idRequest

        timeIni = time.time()
        logger.info("Starting a prediction request ID: "+str(actualIdRequest))

        #bring data from DB
        dataInput={
            "idRequest":actualIdRequest
        }
        response = requests.post(URL_BACK_END_DEEPRESPRED+"searchpred/", json=dataInput)
        rsp=response.json()

        idStatus=rsp["idStatus"]
        typeInput=rsp["typeInput"]
        actualIdRequest=rsp["idRequest"]
        email=rsp["email"]
        pfamID=rsp["pfamID"]
        logger.info(rsp)
        

        #update status request in DB : Processing
        dataInput= {
            "idRequest": actualIdRequest,
            "idStatus": 3
        }
        response = requests.put(URL_BACK_END_DEEPRESPRED+"request/", json=dataInput)
        rsp=response.json()
        logger.info(rsp)
        
        already=False
        #verify if pfamID is not null and if pfamId has a already calculated results
        if ((pfamID is not None) or (typeInput=="pfamCode")):
            already=validateAndAssignResults(actualIdRequest,pfamID,email, typeInput)
            logger.info("Already calculated?")
            logger.info(already)
            

        if not already:

            #start prediction
            createDir(ALGORITHM_PROCESSING)
            algorithmPath=os.path.join(ALGORITHM_FOLDER, secure_filename("run_repeat_prediction.sh"))
            
            if(typeInput=="pfamCode"):
                exit_code = subprocess.call(["sh",algorithmPath,pfamID,ALGORITHM_PROCESSING])
                logger.info(exit_code)
                logger.info("IS A PFAM CODE PREDICTION")
            else: # seqSto, seqFasta, seqOnly

                logger.info("IS NOT A PFAM CODE PREDICTION")
                #Download files
                verifyDirOrCreate(UPLOAD_FOLDER)
                #Files are in filesInFolder Folder
                dataInput={
                    "idRequest":actualIdRequest
                }
                response = requests.get(URL_BACK_END_DEEPRESPRED+"filexreqInfo/", json=dataInput)
                rsp=response.json()
                logger.info("filexreqInfo API: ")
                logger.info(rsp)
                if(not rsp["error"]):
                    nameFileInput=rsp["nameFile"]
                    nameFileFullPathInput=os.path.join(UPLOAD_FOLDER, secure_filename(nameFileInput))  #Here is where files are

                    destinationDir=ALGORITHM_PROCESSING+"/target"
                    if createDir(destinationDir):                                   #Here is where files must be
                        logger.info("moving file")
                        shutil.move(nameFileFullPathInput, destinationDir)

                        if(typeInput=="seqOnly"):
                            logger.info("copying .txt file to .fasta")
                            fileTxt=os.path.join(destinationDir, secure_filename(nameFileInput))  #Here is where files are
                            posDot=nameFileInput.find(".")
                            logger.info(nameFileInput)
                            logger.info(posDot)
                            newNameFileInput=nameFileInput[:posDot]+".fasta"
                            logger.info("new namefile: "+ newNameFileInput)
                            fileFasta=os.path.join(destinationDir, secure_filename(newNameFileInput))
                            shutil.copy(fileTxt, fileFasta)
                            nameFileFullPathInput=fileFasta
                            os.remove(fileTxt)

                    if(typeInput=="seqSto"):
                        #convert to fasta
                        nameFileFullPathInput=os.path.join(destinationDir, secure_filename(nameFileInput))

                        logger.info("Converting to Fasta from SeqSto")
                        nameFileFullPathInput=convertSto2Fasta(nameFileFullPathInput)
                    
                    logger.info("Executing Prediction algorithm")
                    exit_code = subprocess.call(["sh",algorithmPath,nameFileFullPathInput,ALGORITHM_PROCESSING])
                    logger.info("Ending Prediction algorithm - exit code:")
                    logger.info(exit_code)
            

        else:
            
            nameFileFull=os.path.join(DAEMON_QUEUE_FOLDER, secure_filename(actualIdRequest))
            if os.path.exists(nameFileFull):
                os.remove(nameFileFull)
                logger.info("File queue of prediction idRequest removed. The prediction process has finished.")
                logger.info(actualIdRequest)
            else:
                logger.info("The file queue of prediction idRequest to remove does not exist.")

            freeAlgorithm=True
        #sys.exit()


    if not freeAlgorithm:
        #verify status of algorithm, if the prediction has finished (counting files)
        logger.info("In a prediction process...")
        dirFasta=os.path.join(ALGORITHM_PROCESSING, secure_filename("target"))
        dirFlags=os.path.join(ALGORITHM_PROCESSING, secure_filename("flagsEnding"))
        dirPDBAux=os.path.join(ALGORITHM_PROCESSING, secure_filename("auxFiles"))
        dirResults=os.path.join(ALGORITHM_PROCESSING, secure_filename("results"))

        logger.info(dirFasta)
        logger.info(dirFlags)
        logger.info(dirPDBAux)
        logger.info(dirResults)

        verifyDirOrCreate(dirFasta)
        verifyDirOrCreate(dirResults)
        verifyDirOrCreate(dirFlags)
        verifyDirOrCreate(dirPDBAux)

        cantFasta=len(fnmatch.filter(os.listdir(dirFasta), '*.fasta'))
        cantResults=len(fnmatch.filter(os.listdir(dirResults), 'test_*'))
        cantFlags=len(fnmatch.filter(os.listdir(dirFlags), '*txt'))
        cantPDBAux=len(fnmatch.filter(os.listdir(dirPDBAux), '*pdb'))

        if(cantFasta>0 and cantFlags>0 and cantFasta==cantFlags):

            clearDir(dirFlags)
            clearDir(dirFasta)  #all relevant info are in PDB and results (here also fasta)

            timeFin = time.time()
            totalSeconds = timeFin-timeIni

            #update status request in DB and totalTimeProcess in seconds
            dataInput= {
                "idRequest": actualIdRequest,
                "idStatus": 4,
                "totalTimeProcess": int(totalSeconds)
            }
            response = requests.put(URL_BACK_END_DEEPRESPRED+"request/", json=dataInput)
            rsp=response.json()

            logger.info("Making TMalignments...")
            processingResults(dirPDBAux, dirResults,actualIdRequest)

            logger.info("Sending email with results")
            #bring data from DB
            dataInput={
                "idRequest":actualIdRequest
            }
            response = requests.post(URL_BACK_END_DEEPRESPRED+"searchpred/", json=dataInput)
            rsp=response.json()

            idStatus=rsp["idStatus"]
            typeInput=rsp["typeInput"]
            actualIdRequest=rsp["idRequest"]
            email=rsp["email"]
            pfamID=rsp["pfamID"]
            logger.info(rsp)

            if (email!=""):
                dataInput={
                    "email" : email,
                    "idRequest" : idRequest,
                    "inputType" : typeInput,
                    "inputContent" : pfamID
                }
                requests.post(URL_BACK_END_DEEPRESPRED+"sendEmail/", json=dataInput)


            #taking out from queue request id

            nameFileFull=os.path.join(DAEMON_QUEUE_FOLDER, secure_filename(actualIdRequest))

            if os.path.exists(nameFileFull):
                os.remove(nameFileFull)
                logger.info("File queue of prediction idRequest removed. The prediction process has finished.")
                logger.info(str(idRequest))
            else:
                logger.info("The file queue of prediction idRequest to remove does not exist")
    
            freeAlgorithm=True