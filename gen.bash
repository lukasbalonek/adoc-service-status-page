#!/bin/bash

#################################################################################
#                                                               		#
#		ASCIIDOCTOR STATUS PAGE GENERATOR (1/2 - gen.sh)		#
#		BASH script created by Lukas Balonek (2023)			#
#		<lukas.balonek@gmail.com>					#
#										#
#################################################################################

### CONFIGURATION ###

# This page belongs to ..
SERVICE_PROVIDER="contoso or some bulles-shites"
# and it is a:
SERVICE_PROVIDER+=" services status"

# Target directory where status page and it's data should be stored
TARGET_DIR=public
# Raw data collected from tests
DATA_DIR=${TARGET_DIR}/host_data
# Results as .html pages
RESULTS_DIR=${TARGET_DIR}/results_data
# Where configuration is stored
CONFIG_DIR=config

# maximum history (number of bars represented)
declare -i HIST_MAX=96

# usable variables :-D
TIMESTAMP=$(date +%F_%H-%M-%S)
TIMESTAMP_MONKEY_READABLE=$(date +"%H:%M:%S %D")

# MEDIA
MEDIA_BACK_BTN_DEFAULT_OPTS="width=96,height=48"
BACK_BTN="image:../media/back.png"

MEDIA_BAR_DEFAULT_OPTS="width=12"
BAR_OK="image:media/bar_ok.png"
BAR_FAIL="image:media/bar_fail.png"

MEDIA_CHECK_DEFAULT_OPTS="width=24,height=24"
CHECK_OK_PATH="media/status_ok.png"
CHECK_FAIL_PATH="media/status_fail.png"
CHECK_OK="image:${CHECK_OK_PATH}[${MEDIA_CHECK_DEFAULT_OPTS}]"
CHECK_FAIL="image:${CHECK_FAIL_PATH}[${MEDIA_CHECK_DEFAULT_OPTS}]"
CHECK_OK_HIST=$(echo ${CHECK_OK} | sed "s@image:@image:../@g")
CHECK_FAIL_HIST=$(echo ${CHECK_FAIL} | sed "s@image:@image:../@g")

FAVICON_PATH="media/favicon.png"


# Default commands
CMD_CURL="curl --connect-timeout 10 -o /dev/null -I --silent -w "%{http_code}""

# functions
adoc-generate(){
cp -f ${CONFIG_DIR}/docinfo.html .
asciidoctor \
--backend html \
--base-dir . \
-a docinfo=shared \
-a doctype=book \
-a favicon=${FAVICON_PATH} \
-a last-update-label! \
-a nofooter \
"$1"
rm -f docinfo.html
}

########## START ##########

# update host data
source update-data.bash

# Prepare target dir
mkdir -p ${TARGET_DIR}

# STATUS PAGE GENERATION PHASE
echo -e "\e[33mGenerating <index.html> from <index.adoc> using asciidoctor\e[m"
{
echo "== ${SERVICE_PROVIDER}"
echo "Last updated: ${TIMESTAMP_MONKEY_READABLE}"
echo

# loop throught host_groups
for host_group in $(ls -t ${CONFIG_DIR}/host_groups/); do

  # define path to host_group
  host_group_path=${CONFIG_DIR}/host_groups/${host_group}

  # do only for directories
  if [[ -d ${host_group_path} ]]; then

    # tactical(formatting) newline
    echo

    # define and show host_group_name (category of host)
    host_group_name=$(cat ${host_group_path}/NAME)
    echo "=== ${host_group_name}"

    # Running throught hosts in host_groups/*
    for curr_host in ${host_group_path}/hosts/*; do

      # Load host configuration
      source ${curr_host}

      # Show HOST's hostname
      if [[ -n ${HOST} ]]; then
        echo "==== ${HOST}"
      fi

      # make collapsible "history" (start)
      echo ".History"
      echo "[%collapsible]"
      echo "===="

      # Loop throught collected data
      for curr_data in $(ls -tr ${DATA_DIR}/${HOST}*); do

		# load current data
		source ${curr_data}

		# First of all, we assume it will pass (lmao)
		HOST_CHECK="PASSED"

		# Make an error if any check fail
	        if [[ ${PING_CHECK} = "FAILED" ]]; then HOST_CHECK="FAILED"; fi
        	if [[ ${TFTP_CHECK} = "FAILED" ]]; then HOST_CHECK="FAILED"; fi
        	if [[ ${HTTP_CHECK} = "FAILED" ]]; then HOST_CHECK="FAILED"; fi
		if [[ ${HTTPS_CHECK} = "FAILED" ]]; then HOST_CHECK="FAILED"; fi

		# result file
		RESULT_FILE_PATH="$(basename ${RESULTS_DIR})/$(basename ${curr_data}).html"
		# Replace "#DEL_ME" with "nothing"
	        sed -i "s/^<p>#DEL_ME/<p>/g" "${TARGET_DIR}/${RESULT_FILE_PATH}"

	        # Display bar after information supplied
	        if [[ ${HOST_CHECK} = "PASSED" ]]; then
	          echo -n "${BAR_OK}[${MEDIA_BAR_DEFAULT_OPTS}, link=${RESULT_FILE_PATH}, title=${TIMESTAMP}]"
		# if some check failed
	        else
	          echo -n "${BAR_FAIL}[${MEDIA_BAR_DEFAULT_OPTS}, link=${RESULT_FILE_PATH}, title=${TIMESTAMP}]"
		fi

		# unset variable that defines any failed check
        	unset HOST_CHECK

		# unset loaded variables
		unset PING_CHECK
                unset TFTP_CHECK
		unset HTTP_CHECK
		unset HTTPS_CHECK

		# that could make it confucius
		unset HOST_PRETTY_NAME

                # tactical(formatting) newline
                echo

      done

      # make collapsible "history" (end)
      echo "===="

    done

  fi

done

} 1> index.adoc

# Unset variable, that defines if any check failed
unset SOME_CHECK_FAILED

# check last hosts' status
for HOST_FILE in ${CONFIG_DIR}/host_groups/*/hosts/*; do

  # Load HOST's configuration
  source $HOST_FILE

  # Test latest data for *CHECK=PASSED, if not found, it failed ..
  LATEST_DATA=$(ls -t public/host_data/$(basename ${HOST})* | head -n1)
  if grep -q "CHECK=FAILED" ${LATEST_DATA}; then

    # if host has pretty name
    if [[ -n ${HOST_PRETTY_NAME} ]]; then
      sed -i "s\== ${HOST}.*\== ${CHECK_FAIL} ${HOST_PRETTY_NAME}\g" index.adoc
    else
      # Replace <hostname> with <check image + hostname>
      sed -i "s\== ${HOST}.*\== ${CHECK_FAIL} ${HOST}\g" index.adoc
    fi

    # to change favicon based on any failed job
    SOME_CHECK_FAILED=1

  else

    # if host has pretty name
    if [[ -n ${HOST_PRETTY_NAME} ]]; then
      sed -i "s\== ${HOST}.*\== ${CHECK_OK} ${HOST_PRETTY_NAME}\g" index.adoc
    else
      # Replace <hostname> with <check image + hostname>
      sed -i "s\== ${HOST}\== ${CHECK_OK} ${HOST}\g" index.adoc
    fi

  fi

done

# if some check failed, set favicon to CHECK_FAIL, otherwise CHECK_OK ofc
if [[ ${SOME_CHECK_FAILED} -eq 1 ]]; then
  cp -fv ${CONFIG_DIR}/${CHECK_FAIL_PATH} ${CONFIG_DIR}/${FAVICON_PATH}
else
  cp -fv ${CONFIG_DIR}/${CHECK_OK_PATH} ${CONFIG_DIR}/${FAVICON_PATH}
fi

# PART, WHERE .ADOC BECOMES AN .HTML
adoc-generate index.adoc

# END
if [ $0 ]; then
  echo -e "\e[33mRemoving source files used for page generation ..\e[m"
  rm -fv index.adoc

  echo -e "\e[33mMoving generated <index.html> into ${TARGET_DIR} ..\e[m"
  mv -fv index.html ${TARGET_DIR}/

  echo -e "\e[33mCopying ${CONFIG_DIR}/media directory into ${TARGET_DIR} ..\e[m"
  cp -rfv ${CONFIG_DIR}/media ${TARGET_DIR}/

  echo -e "\e[32m✓\e[m Successfully generated status page in folder ${TARGET_DIR}"
  exit 0
else
  echo -e "\e[31m✕\e[m <index.adoc> failed to generate <index.html>. Try running \"asciidoctor index.adoc\" to get more details about errors occured"
  exit 69
fi
