import logging
import logging.handlers as handlers

logger = logging.getLogger('deepReSPredLog')
logger.setLevel(logging.INFO)

formatter = logging.Formatter('%(levelname)-7s - %(asctime)s ::: f. %(funcName)-15s - line %(lineno)-4s ::: %(message)s')

logHandler = handlers.RotatingFileHandler('/home/back_project/autProcess/logs_daemon/deepReSPred.log', maxBytes=10240000, backupCount=5)
logHandler.setLevel(logging.INFO)
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)