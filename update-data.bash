#!/bin/bash

###################################################################
#											                                            #
#		ASCIIDOCTOR STATUS PAGE GENERATOR (2/2 - update-data.sh)		  #
#		BASH script created by Lukas Balonek (2023)				            #
#                                                                 #
###################################################################

echo -e "\e[33mRefreshing data ..\e[m"

mkdir -p ${DATA_DIR} ${RESULTS_DIR}

# loop throught host_groups
for host_group in ${CONFIG_DIR}/host_groups/*; do

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
              PING_RESPONSE_TIME="$(echo ${PING_RESPONSE} | cut -d / -f5)"
	      echo -e "#DEL_ME PING => ${CHECK_OK_HIST} \nPING_CHECK=PASSED \nPING=${PING_RESPONSE_TIME}ms" >> "${DATA_FILE_PATH}"
            else
              echo -e "#DEL_ME PING => ${CHECK_FAIL_HIST} \nPING_CHECK=FAILED \nPING_RESULT=\"${PING_RESPONSE}\"" >> "${DATA_FILE_PATH}"
            fi

          fi

          # TFTP
	  if [[ ${TFTP} = 'y' ]]; then

            if [[ -n ${TFTP_PATH} ]]; then

              # formatting newline
              echo "" >> "${DATA_FILE_PATH}"

              # set default values if not set in configuration file
              if [[ -z ${TFTP_PORT} ]]; then TFTP_PORT=69; fi

              # perform the test
              URL="tftp://${HOST}:${TFTP_PORT}${TFTP_PATH}"
              TFTP_RESPONSE=$(${CMD_CURL} ${URL})
	      if [[ $? -eq 0 ]]; then
	        echo -e "#DEL_ME TFTP => ${CHECK_OK_HIST} \nTFTP_CHECK=PASSED \nTFTP_PORT=${TFTP_PORT}" >> "${DATA_FILE_PATH}"
              else
                echo -e "#DEL_ME TFTP => ${CHECK_FAIL_HIST} \nTFTP_CHECK=FAILED \nTFTP_PORT=${TFTP_PORT} \nTFTP_RESULT=\"server returned: ${TFTP_RESPONSE}\"" >> "${DATA_FILE_PATH}"
              fi

            else

              echo -e "\e[31mVariable \e[m\$TFTP_PATH\e[31m for host ${HOST} MUST be specified ! \e[m"

            fi

          fi

          # HTTP
	  if [[ ${HTTP} = 'y' ]]; then

            # formatting newline
	    echo "" >> "${DATA_FILE_PATH}"

            # set default values if not set in configuration file
            if [[ -z ${HTTP_PORT} ]]; then HTTP_PORT=80; fi

            # perform the test
	    URL="http://${HOST}:${HTTP_PORT}${HTTP_PATH}"
            HTTP_RESPONSE=$(${CMD_CURL} ${URL})
	    if [[ $? -eq 0 ]]; then
	      echo -e "#DEL_ME HTTP => ${CHECK_OK_HIST} \nHTTP_CHECK=PASSED \nHTTP_PORT=${HTTP_PORT}" >> "${DATA_FILE_PATH}"
            else
              echo -e "#DEL_ME HTTP => ${CHECK_FAIL_HIST} \nHTTP_CHECK=FAILED \nHTTP_PORT=${HTTP_PORT} \nHTTP_RESULT=\"server returned: ${HTTP_RESPONSE}\"" >> "${DATA_FILE_PATH}"
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
              echo -e "#DEL_ME HTTPS => ${CHECK_OK_HIST} \nHTTPS_CHECK=PASSED \nHTTPS_PORT=${HTTPS_PORT}" >> "${DATA_FILE_PATH}"
            else
              echo -e "#DEL_ME HTTPS => ${CHECK_FAIL_HIST} \nHTTPS_CHECK=FAILED \nHTTPS_PORT=${HTTPS_PORT} \nHTTPS_RESULT=\"server returned: ${HTTPS_RESPONSE}\"" >> "${DATA_FILE_PATH}"
            fi

          fi

          # Create page where results are dumped
	  src_file=dump.adoc
          if [[ -n ${HOST_PRETTY_NAME} ]]; then
            echo "== ${HOST_PRETTY_NAME} (${HOST})" > ${src_file}
          else
            echo "== ${HOST}" > ${src_file}
          fi
	  echo -e "Check time: ${TIMESTAMP_MONKEY_READABLE} \n" >> ${src_file}
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
          unset TFTP
          unset TFTP_PORT
          unset TFTP_PATH
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
