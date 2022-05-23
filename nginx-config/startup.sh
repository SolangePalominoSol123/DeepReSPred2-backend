#!/bin/bash

#--------------------------------DATABASE CONFIGURATION--------------------------------
#chmod +x /startup.sh && ./startup.sh

#BD-Flask Config
cd /home/back_project

export DB_SNEW=$(echo $DB_SNEW | tr 'a-z' 'A-Z')
echo "Variable New Database:" $DB_SNEW


if [[ "$DB_SNEW" == "TRUE" ]] ; then
    echo "Considering Database is a new brand database"

    #In case it is a new brand database
    python migrate.py db init
    python migrate.py db migrate
    python migrate.py db upgrade

    #Insert data in Database
    cd /home/database
    mysql -u $DB_USER --password=$DB_PASS $DB_NAME -h $DB_ADDR -P $DB_PORT < initialScripts.sql
else
    echo "Considering Database is an already existed database (with models included)"

    #In case it is an already existed database (with models included)
    python migrate.py db init
    #----use a temporary database in Mysql to create migrations
    export ORIGINDATABASE=$DB_NAME
    export DB_NAME=$DB_NAMEAUX
    python migrate.py db migrate
    #----change the database to the old one
    python migrate.py db stamp head
    export DB_NAME=$ORIGINDATABASE
fi

#--------------------------------SERVICES CONFIGURATION--------------------------------

#Services deployment
mkdir /home/back_project/logs
cd  /home/back_project && gunicorn --access-logfile /home/back_project/logs/access_logfile.log --error-logfile /home/back_project/logs/error_logfile.log --capture-output --log-level debug --workers 3 --bind unix:deeprespred.sock -m 007 run:app &
chmod 666 /home/back_project/deeprespred.sock
chmod +x /home/back_project/deeprespred.sock

# Remove default nginx static assets
cd /usr/share/nginx/html && rm -rf ./*
# Copy configuration
cp /home/nginx-config/default.conf /default.conf

#Algorithm daemon deployment
cd /home/back_project/autProcess && mkdir queueReq && mkdir processingPred && mkdir filesDownloaded && mkdir s3UploadDir

nohup python /home/back_project/autProcess/deepResPredDaemon.py &

# Startup to be executable nginx
nginx -g 'daemon off;'