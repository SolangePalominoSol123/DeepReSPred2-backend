from sys import maxsize
from werkzeug.utils import secure_filename
from auxiliarFunctionsDaemon import createDir
import requests
import fnmatch
import subprocess
import os
import shutil
import sys
import re

current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

from constants import URL_BACK_END_DEEPRESPRED
from constants import S3_UPLOAD_DIR
from base_logger import logger

def processingResults(dirPDBAux, dirResults, idRequest):
    PDBAux_list = os.listdir(dirPDBAux)

    flagPDBAux=False
    if len(PDBAux_list)>0:
        logger.info("There is a PDB aux to evaluate predicted fragments...")
        PDBAux_file=PDBAux_list[0]
        PDBAux_fileFull=os.path.join(dirPDBAux, secure_filename(PDBAux_file))
        logger.info(PDBAux_fileFull)
        flagPDBAux=True
    else:
        logger.info("There is not any PDB aux to evaluate predicted fragments...")
        

    group=1
    dirResults_list = os.listdir(dirResults)
    for dirResult in dirResults_list:
        dirResult_full=os.path.join(dirResults, secure_filename(dirResult)) #dir ../results/test_seq*/
        logger.info("------------------------------------------------------")
        logger.info("Current dir: "+dirResult_full)
        logger.info("Subgroup: "+str(group))

        #Final
        fileFullInput=""
        fileFullPDB=""
        fileFull21c=""
        fileFullmap=""
        fileFullAlign=""
        isFragmentFlag=False


        #Auxiliar
        dirFilesResult=os.path.join(dirResult_full, secure_filename("output"))
        listFilesInputIS=fnmatch.filter(os.listdir(dirResult_full), 'is_*.fasta')
        listFilesInputNR=fnmatch.filter(os.listdir(dirResult_full), 'nr_*.fasta')
        listFiles21c=fnmatch.filter(os.listdir(dirResult_full), '*.21c')
        listFilesMap=fnmatch.filter(os.listdir(dirResult_full), '*.map')

        logger.info("N° files is_*.fasta: "+ str(len(listFilesInputIS)))
        logger.info("N° files nr_*.fasta: "+ str(len(listFilesInputNR)))
        logger.info("N° dir output: "+ str(len(dirFilesResult)))

        maxGen=0
        #Is a fragment, not a complete sequence
        if len(listFilesInputIS)>0: 
            logger.info("Evaluating a fragment...")
            listFilesResults=fnmatch.filter(os.listdir(dirFilesResult), 'final_*.pdb')
            logger.info("listFilesResults: "+str(len(listFilesResults)))

            if flagPDBAux:
                maxGen=0
                fileResultFullGen=""
                for fileResult in listFilesResults:
                    logger.info("Evaluating TM-align between:")
                    #TMalign
                    fileResultFull=os.path.join(dirFilesResult, secure_filename(fileResult)) #.PDB generated                    
                    logger.info(fileResultFull)
                    logger.info(PDBAux_fileFull)

                    proc = subprocess.Popen(['TMalign', PDBAux_fileFull, fileResultFull], stdout=subprocess.PIPE)
                    output = str(proc.stdout.read())

                    maxTM=0
                    for m in re.finditer('TM-score= ', output):
                        posValue=m.end()
                        value=float(output[posValue:posValue+7])
                        logger.info("TM-score: "+str(value))
                        #value=0.6 ######################################################################
                        if value>maxTM:
                            maxTM=value

                    logger.info("TM-score_aux: "+str(maxTM))

                    if maxTM>maxGen:
                        maxGen=maxTM
                        fileResultFullGen=fileResultFull


                if maxGen>0.5:
                    #aprobado fileResultFullGen .pdb
                    logger.info("Fragment aproved...")
                    fullFragmentInput=os.path.join(dirResult_full, secure_filename(listFilesInputIS[0])) #.fasta
                    fileFullInput=fullFragmentInput
                    fileFullPDB=fileResultFullGen
                    logger.info(fullFragmentInput)
                    logger.info(fileResultFullGen)
                    isFragmentFlag=True

                    fullPathAlign1=os.path.join(dirResult_full, secure_filename("TM.sup"))
                    fullPathAlign2=os.path.join(dirResult_full, secure_filename("TM.sup_atm"))
                    proc = subprocess.Popen(['TMalign', fileFullPDB, PDBAux_fileFull, "-o", fullPathAlign1])
                    fileFullAlign=fullPathAlign2
                    logger.info("TM-align file generated: "+fileFullAlign)
                    
            else:
                #no hay PDB aux
                if(len(listFilesResults)>0):
                    logger.info("There is not PDB aux to evaluate TM-score. Selecting the first: final_1.pdb")
                    #fileResultFull=os.path.join(dirFilesResult, secure_filename(listFilesResults[0])) #.PDB generated  
                    fileResultFull=os.path.join(dirFilesResult, secure_filename("final_1.pdb")) #.PDB generated  
                    fullFragmentInput=os.path.join(dirResult_full, secure_filename(listFilesInputIS[0])) #.fasta
                    isFragmentFlag=True
                    fileFullInput=fullFragmentInput
                    fileFullPDB=fileResultFull
                else:
                    logger.info("There is not PDB aux to evaluate TM-score, nor any predicted structure PDB")


        #Is a complete sequence
        if len(listFilesInputNR)>0: 
            logger.info("Evaluating a complete sequence...")
            listFilesResults=fnmatch.filter(os.listdir(dirFilesResult), 'final_1.pdb')

            if len(listFilesResults)>0:
                fileResultFull=os.path.join(dirFilesResult, secure_filename(listFilesResults[0])) #.PDB generated
                fullFragmentInput=os.path.join(dirResult_full, secure_filename(listFilesInputNR[0])) #.fasta
                
                logger.info("NR - Complete sequence:")
                logger.info(fileResultFull)
                logger.info(fullFragmentInput)
                fileFullInput=fullFragmentInput
                fileFullPDB=fileResultFull
                isFragmentFlag=False
            else:
                logger.info("Any predicted structure PDB was finded")
                


        fileFull21c=os.path.join(dirResult_full, secure_filename(listFiles21c[0])) #.21c
        fileFullmap=os.path.join(dirResult_full, secure_filename(listFilesMap[0])) #.map

        if(fileFullInput!="" and fileFullPDB!="" and fileFull21c!="" and fileFullmap!=""):
            logger.info("----------")
            logger.info("Good prediction")
            logger.info(fileFullInput)
            logger.info(fileFullPDB)
            logger.info(fileFull21c)
            logger.info(fileFullmap)
            logger.info("Is Fragment: "+str(isFragmentFlag))
            logger.info("Subgroup: " + str(group))
            logger.info("ID Request: "+str(idRequest))
            logger.info("----------")

            logger.info("Saving data to DB and S3 bucket...")
            #Fasta
            posDot=fileFullInput.find(".")
            dataInput={
                "idRequest" : idRequest,
                "idSubGroup" : group,
                "haveStructure" : flagPDBAux,
                "extension" : fileFullInput[posDot:],
                "isFragment" : isFragmentFlag,
                "dbAlgorithm" : "PFAM",
                "tmscore" : 0,
                "isResult" : False
            }
            response = requests.post(URL_BACK_END_DEEPRESPRED+"filexreqInfo/", json=dataInput)
            logger.info(response)
            rsp=response.json()
            registeredFasta=rsp["nameFile"]

            regFullAfter=os.path.join(S3_UPLOAD_DIR, secure_filename(registeredFasta))

            try:
                shutil.copy(fileFullInput, regFullAfter)
                posDot=registeredFasta.find(".")
                #Upload to S3
                dataInput={
                    "name" : registeredFasta[:posDot],
                    "extension" : registeredFasta[posDot:]
                }
                response = requests.post(URL_BACK_END_DEEPRESPRED+"s3file/", json=dataInput)
            except Exception as e:
                logger.error("Error in resultsManager line 187: "+str(e))

            #---------------

            #PDB
            posDot=fileFullPDB.find(".")
            dataInput={
                "idRequest" : idRequest,
                "idSubGroup" : group,
                "haveStructure" : flagPDBAux,
                "extension" : fileFullPDB[posDot:],
                "isFragment" : isFragmentFlag,
                "dbAlgorithm" : "PFAM",
                "tmscore" : maxGen,
                "isResult" : True
            }
            response = requests.post(URL_BACK_END_DEEPRESPRED+"filexreqInfo/", json=dataInput)
            logger.info(response)
            rsp=response.json()
            registeredPDB=rsp["nameFile"]

            regFullAfter=os.path.join(S3_UPLOAD_DIR, secure_filename(registeredPDB))

            try:
                shutil.copy(fileFullPDB, regFullAfter)
                posDot=registeredPDB.find(".")
                #Upload to S3
                dataInput={
                        "name" : registeredPDB[:posDot],
                        "extension" : registeredPDB[posDot:]
                }
                response = requests.post(URL_BACK_END_DEEPRESPRED+"s3file/", json=dataInput)
            except Exception as e:
                logger.error("Error in resultsManager line 220: "+str(e))

            #-------------------------------

            #21c
            posDot=fileFull21c.find(".")
            dataInput={
                "idRequest" : idRequest,
                "idSubGroup" : group,
                "haveStructure" : flagPDBAux,
                "extension" : fileFull21c[posDot:],
                "isFragment" : isFragmentFlag,
                "dbAlgorithm" : "PFAM",
                "tmscore" : 0,
                "isResult" : False
            }
            response = requests.post(URL_BACK_END_DEEPRESPRED+"filexreqInfo/", json=dataInput)
            logger.info(response)
            rsp=response.json()
            registered21c=rsp["nameFile"]

            regFullAfter=os.path.join(S3_UPLOAD_DIR, secure_filename(registered21c))

            try:
                shutil.copy(fileFull21c, regFullAfter)
                posDot=registered21c.find(".")
                #Upload to S3
                dataInput={
                        "name" : registered21c[:posDot],
                        "extension" : registered21c[posDot:]
                }
                response = requests.post(URL_BACK_END_DEEPRESPRED+"s3file/", json=dataInput)
            except Exception as e:
                logger.error("Error in resultsManager line 253: "+str(e))

            #--------------

            #map
            posDot=fileFullmap.find(".")
            dataInput={
                "idRequest" : idRequest,
                "idSubGroup" : group,
                "haveStructure" : flagPDBAux,
                "extension" : fileFullmap[posDot:],
                "isFragment" : isFragmentFlag,
                "dbAlgorithm" : "PFAM",
                "tmscore" : 0,
                "isResult" : False
            }
            response = requests.post(URL_BACK_END_DEEPRESPRED+"filexreqInfo/", json=dataInput)
            logger.info(response)
            rsp=response.json()
            registeredMap=rsp["nameFile"]

            regFullAfter=os.path.join(S3_UPLOAD_DIR, secure_filename(registeredMap))

            try:
                shutil.copy(fileFullmap, regFullAfter)
                posDot=registeredMap.find(".")
                #Upload to S3
                dataInput={
                        "name" : registeredMap[:posDot],
                        "extension" : registeredMap[posDot:]
                }
                response = requests.post(URL_BACK_END_DEEPRESPRED+"s3file/", json=dataInput)
            except Exception as e:
                logger.error("Error in resultsManager line 286: "+str(e))

            #---------------

            #TMalign
            if (flagPDBAux and fileFullAlign!=""):
                posDot=fileFullAlign.find(".")
                dataInput={
                    "idRequest" : idRequest,
                    "idSubGroup" : group,
                    "haveStructure" : flagPDBAux,
                    "extension" : fileFullAlign[posDot:],
                    "isFragment" : True,
                    "dbAlgorithm" : "PFAM",
                    "tmscore" : maxGen,
                    "isResult" : True
                }
                response = requests.post(URL_BACK_END_DEEPRESPRED+"filexreqInfo/", json=dataInput)
                logger.info(response)
                rsp=response.json()
                registeredAlign=rsp["nameFile"]

                regFullAfter=os.path.join(S3_UPLOAD_DIR, secure_filename(registeredAlign))

                try:
                    shutil.copy(fileFullAlign, regFullAfter)
                    posDot=registeredAlign.find(".")
                    #Upload to S3
                    dataInput={
                            "name" : registeredAlign[:posDot],
                            "extension" : registeredAlign[posDot:]
                    }
                    response = requests.post(URL_BACK_END_DEEPRESPRED+"s3file/", json=dataInput)
                except Exception as e:
                    logger.error("Error in resultsManager line 320: "+str(e))
            



        group+=1

    ############################################ CLEAR ALL
    createDir(dirPDBAux)
    createDir(dirResults)
    createDir(S3_UPLOAD_DIR)
