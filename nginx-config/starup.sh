#--------------------------------SERVICES CONFIGURATION--------------------------------

#BD-Flask Config
cd /home/back_project
python migrate.py db init
python migrate.py db migrate
python migrate.py db upgrade

#Services deployment
mkdir logs
gunicorn --access-logfile logs/access_logfile.log --error-logfile logs/error_logfile.log --capture-output --log-level debug --workers 3 --bind unix:deeprespred.sock -m 007 run:app &
chmod 666 deeprespred.sock
chmod +x deeprespred.sock
cd /usr/share/nginx/html
cp /home/nginx-config/default.conf /default.conf

#Algorithm daemon deployment
cd /home/back_project/autProcess
mkdir queueReq && mkdir processingPred && mkdir filesDownloaded && mkdir s3UploadDir

nohup python deepResPredDaemon.py &

# Startup to be executable nginx
nginx-debug -g 'daemon off;'