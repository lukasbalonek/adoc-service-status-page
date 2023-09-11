#!/bin/bash

###########################################################################################
#											  #
#		ASCIIDOCTOR STATUS PAGE GENERATOR (2/2 - update-data.sh)		  #
#		BASH script created by Lukas Balonek (2023)				  #
#		<lukas.balonek@gmail.com>						  #
#											  #
###########################################################################################


### CONFIGURATION ###

# THESE THREE VARS MUST MATCH IN <update-data.sh> and <gen.sh> !!!
TARGET_DIR=public
DATA_DIR=${TARGET_DIR}/host_data
RESULTS_DIR=${TARGET_DIR}/results_data

# maximum history (number of bars represented)
declare -i HIST_MAX=20

# usable variables :-D
TIMESTAMP=$(date +%F_%H-%M-%S)
TIMESTAMP_MONKEY_READABLE=$(date +"%H:%M:%S %D")

# MEDIA
MEDIA_BACK_BTN_DEFAULT_OPTS="width=32,height=32"
BACK_BTN="image:../media/back.png"
MEDIA_CHECK_DEFAULT_OPTS="width=24,height=24"
CHECK_OK="image:../media/status_ok.png[${MEDIA_CHECK_DEFAULT_OPTS}]"
CHECK_FAIL="image:../media/status_fail.png[${MEDIA_CHECK_DEFAULT_OPTS}]"

# functions
adoc-generate(){
cp -f config/docinfo.html .
asciidoctor \
--backend html \
--base-dir . \
-a docinfo=shared \
-a doctype=book \
-a favicon=media/favicon.png \
-a last-update-label! \
-a nofooter \
"$1"
rm -f docinfo.html
}

# Default commands
CMD_CURL="curl --connect-timeout 10 -o /dev/null -I --silent -w "%{http_code}""

########## START ##########

echo -e "\e[33mRefreshing data ..\e[m"

mkdir -p ${DATA_DIR} ${RESULTS_DIR}

# loop throught host_groups
for host_group in config/host_groups/*; do

  # do only for directories
  if [[ -d ${host_group} ]]; then

    # Loop throught hosts in host_groups
    for curr_host in ${host_group}/hosts/*; do

        # Load host configuration
        source ${curr_host}

        # Do ONLY when HOST if configured
        if [[ -n ${HOST} ]]; then

          # Define data file where results will be written
          DATA_FILE="${HOST}_${TIMESTAMP}"
	  DATA_FILE_PATH="${DATA_DIR}/${DATA_FILE}"

	  ### CHECKS ###
          # PING
          if [[ ${PING} = 'y' ]]; then

            # formatting newline
	    echo "" >> "${DATA_FILE_PATH}"

            # perform the test
            PING_RESPONSE=$(ping -W10 -c1 ${HOST} 2>&1)

	    if [[ $? -eq 0 ]]; then
              PING_RESPONSE_TIME="$(echo ${PING_RESPONSE} | grep -oE "time=[0-9][[:digit:]]" | cut -d = -f2)"
	      echo -e "#DEL_ME PING => ${CHECK_OK} \nPING_CHECK=PASSED \nPING=${PING_RESPONSE_TIME}ms" >> "${DATA_FILE_PATH}"
            else
              echo -e "#DEL_ME PING => ${CHECK_FAIL} \nPING_CHECK=FAILED \nPING_RESULT=\"${PING_RESPONSE}\"" >> "${DATA_FILE_PATH}"
            fi

          fi

          # HTTP
	  if [[ ${HTTP} = 'y' ]]; then

	    echo -e "\e[33mPerforming tests on ${HOST}\e[m"

            # formatting newline
	    echo "" >> "${DATA_FILE_PATH}"

            # set default values if not set in configuration file
            if [[ -z ${HTTP_PORT} ]]; then HTTP_PORT=80; fi

            # perform the test
	    URL="http://${HOST}:${HTTP_PORT}${HTTP_PATH}"
            HTTP_RESPONSE=$(${CMD_CURL} ${URL})
	    if [[ $? -eq 0 ]]; then
	      echo -e "#DEL_ME HTTP => ${CHECK_OK} \nHTTP_CHECK=PASSED \nHTTP_PORT=${HTTP_PORT}" >> "${DATA_FILE_PATH}"
            else
              echo -e "#DEL_ME HTTP => ${CHECK_FAIL} \nHTTP_CHECK=FAILED \nHTTP_PORT=${HTTP_PORT} \nHTTP_RESULT=\"server returned: ${HTTP_RESPONSE}\"" >> "${DATA_FILE_PATH}"
            fi

          fi

         # HTTPS
         if [[ ${HTTPS} = 'y' ]]; then

            # formatting newline
	    echo "" >> "${DATA_FILE_PATH}"

            # set default values if not set in configuration file
            if [[ -z ${HTTPS_PORT} ]]; then HTTPS_PORT=443; fi

            # perform the test
	    URL="https://${HOST}:${HTTPS_PORT}${HTTPS_PATH}"
            HTTPS_RESPONSE=$(${CMD_CURL} ${URL})
	    if [[ $? -eq 0 ]]; then
              echo -e "#DEL_ME HTTPS => ${CHECK_OK} \nHTTPS_CHECK=PASSED \nHTTPS_PORT=${HTTPS_PORT}" >> "${DATA_FILE_PATH}"
            else
              echo -e "#DEL_ME HTTPS => ${CHECK_FAIL} \nHTTPS_CHECK=FAILED \nHTTPS_PORT=${HTTPS_PORT} \nHTTPS_RESULT=\"server returned: ${HTTPS_RESPONSE}\"" >> "${DATA_FILE_PATH}"
            fi

          fi

          # Create page where results are dumped
	  src_file=dump.adoc
	  echo "# ${HOST}" > ${src_file}
	  echo -e "Time: ${TIMESTAMP_MONKEY_READABLE} \n" >> ${src_file}
	  echo -e "${BACK_BTN}[${MEDIA_BACK_BTN_DEFAULT_OPTS},link=../index.html,title=Back] \n" >> ${src_file}
          cat ${DATA_DIR}/${DATA_FILE} | tr ' ' '\n' >> ${src_file}
          adoc-generate ${src_file}
	  rm ${src_file}
          mv -fv dump.html ${RESULTS_DIR}/${DATA_FILE}.html

          # remove old .html results (there's $HIST_MAX set that represents maximum count of "history files")
	  while [[ $(ls ${RESULTS_DIR}/${HOST}* | wc -l) -gt ${HIST_MAX} ]]; do
	    file_to_rm=$(ls -t ${RESULTS_DIR}/${HOST}* | tail -n1)
            echo "Deleting old result: ${file_to_rm}"
	    rm -fv ${file_to_rm}
	  done

          # remove old records (there's $HIST_MAX set that represents maximum count of "history files")
	  while [[ $(ls ${DATA_DIR}/${HOST}* | wc -l) -gt ${HIST_MAX} ]]; do
	    file_to_rm=$(ls -t ${DATA_DIR}/${HOST}* | tail -n1)
            echo "Deleting old data: ${file_to_rm}"
            rm -fv ${file_to_rm}

          done

          # unset variables that could've been used
          unset HOST
          unset PING_CHECK
	  unset PING_RESULT
          unset HTTP
          unset HTTP_PORT
          unset HTTP_PATH
          unset HTTPS
          unset HTTPS_PORT
          unset HTTPS_PATH

        fi

    # done looping throught hosts
    done

  # done searching directories
  fi

# done loopin throught host_groups
done
