#!/bin/bash

#check and create logfile
log_filename="/config/customscripts/radarrClean3r$(date +'%Y%m%d').log"
if [ ! -e "$log_filename" ]; then
    touch $log_filename 
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] - Start radarrClean3r" | tee -a $log_filename >&2
echo "[$(date +'%Y-%m-%d %H:%M:%S')] - Movie ${radarr_movie_title} (${radarr_movie_tmdbid}) was added with perfect condition." | tee -a $log_filename >&2



# check if radarr_movie_tmdbid is set. example: a local test run. if so then skip to the end
if [ -z "$radarr_movie_tmdbid" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - radarr_movie_tmdbid was not set, jump to end" | tee -a $log_filename >&2
    curl -X POST -s \
    --form-string "token=YOURPUSHOVERAPPTOKEN" \
    --form-string "user=YOURPUSHOVERUSERKEY" \
    --form-string "message=radarr_movie_tmdbid was not set, jump to end" \
    https://api.pushover.net/1/messages.json
else
    # call 2nd radarr instance with tmdbId from 1st instance to get the internal id of the movie (2nd instance)
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - Calling PRERETAIL RADARR to get the internal id." | tee -a $log_filename >&2
    response=$(curl -X 'GET' "http://IP_OF_PRERETAIL_RADARR:PORT/api/v3/movie?tmdbId=${radarr_movie_tmdbid}&apikey=YOURAPIKEY" -s)
    myId=$(echo "$response" | jq '.[0].id')
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - The internal id is: $myId" | tee -a $log_filename >&2


    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - Calling PRERETAIL RADARR to delete the movie" | tee -a $log_filename >&2


    # Make a DELETE request with curl and capture the response headers into a variable
    delete_response=$(curl -I -X DELETE -s -o /dev/null -w "%{http_code}" "http://IP_OF_PRERETAIL_RADARR:PORT/api/v3/movie/$myId?deleteFiles=true&addImportExclusion=true&apikey=YOURAPIKEY" -s)

    # Check the HTTP status code and take appropriate action
    if [ "$delete_response" == "200" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] - The Movie ${radarr_movie_title} (${radarr_movie_tmdbid}) successfully deleted." | tee -a $log_filename >&2
        curl -X POST -s \
        --form-string "token=YOURPUSHOVERAPPTOKEN" \
        --form-string "user=YOURPUSHOVERUSERKEY" \
        --form-string "message=The Movie ${radarr_movie_title} (${radarr_movie_tmdbid}) successfully deleted." \
        https://api.pushover.net/1/messages.json
        curl -X PUT -s "https://YOURPLEXIP/library/sections/YOURPRERETAILSECTIONASNUMBER/emptyTrash?X-Plex-Token=YOURPLEXTOKEN"
    elif [ "$delete_response" == "404" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] - The Movie ${radarr_movie_title} (${radarr_movie_tmdbid}) was not found on PRERETAIL RADARR." | tee -a $log_filename >&2
        curl -X POST -s \
        --form-string "token=YOURPUSHOVERAPPTOKEN" \
        --form-string "user=YOURPUSHOVERAPPTOKEN" \
        --form-string "message=The Movie ${radarr_movie_title} (${radarr_movie_tmdbid}) was not found on PRERETAIL RADARR." \
        https://api.pushover.net/1/messages.json
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] - ERROR: HTTP status code is $delete_response" | tee -a $log_filename >&2
        curl -X POST -s \
        --form-string "token=YOURPUSHOVERAPPTOKEN" \
        --form-string "user=YOURPUSHOVERUSERKEY" \
        --form-string "message=The Movie ${radarr_movie_title} (${radarr_movie_tmdbid}) successfully deleted." \
        https://api.pushover.net/1/messages.json
    fi
fi
echo "[$(date +'%Y-%m-%d %H:%M:%S')] - End radarrClean3r" | tee -a $log_filename >&2
