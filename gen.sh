#!/bin/bash

#########################################################################
#																		#
#		ASCIIDOCTOR STATUS PAGE GENERATOR (1/2 - gen.sh)				#
#		BASH script created by Lukas Balonek (2023)						#
#		<lukas.balonek@gmail.com>										#
#																		#
#########################################################################

### CONFIGURATION ###

# Name of service provider
SERVICE_PROVIDER="contoso.net (lmao)"

# Target directory where status page and it's data should be stored
# THESE THREE VARS MUST MATCH IN <update-data.sh> and <gen.sh> !!!
TARGET_DIR=public
DATA_DIR=${TARGET_DIR}/host_data
RESULTS_DIR=${TARGET_DIR}/results_data

# usable variables :-D
TIMESTAMP=$(date +%F_%H-%M-%S)
TIMESTAMP_MONKEY_READABLE=$(date +"%H:%M:%S %D")

# MEDIA
MEDIA_BAR_DEFAULT_OPTS="width=12"
BAR_OK="image:media/bar_ok.png"
BAR_FAIL="image:media/bar_fail.png"

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

########## START ##########

# update host data
source update-data.sh

# Prepare target dir
mkdir -p ${TARGET_DIR}

# STATUS PAGE GENERATION PHASE
echo -e "\e[33mGenerating <index.html> from <index.adoc> using asciidoctor\e[m"
{
echo "= ${SERVICE_PROVIDER} service status"
echo "Last updated: ${TIMESTAMP_MONKEY_READABLE}"
echo

# loop throught host_groups
for host_group in config/host_groups/*; do

  # do only for directories
  if [[ -d ${host_group} ]]; then

    # tactical(formatting) newline
	echo

    # define and show host_group_name (category of host)
    host_group_name=$(cat ${host_group}/NAME)
    echo "== ${host_group_name}"
	
	# Running throught hosts in host_groups/*
    for curr_host in ${host_group}/hosts/*; do
	
	  # Load host configuration
	  source ${curr_host}
	
	  # Show HOST's hostname
      if [[ -n ${HOST} ]]; then
	    echo
        echo "=== ${HOST}"
      fi

      # Loop throught collected data
      for curr_data in $(ls -tr ${DATA_DIR}/${HOST}*); do
        
		# load current data
		source ${curr_data}

		####################
		
		# First of all, we assume it will pass (lmao)
		HOST_CHECK="PASSED"
		
		# Make an error if any check fail
        if [[ ${PING_CHECK} = "FAILED" ]]; then HOST_CHECK="FAILED"; fi
        if [[ ${HTTP_CHECK} = "FAILED" ]]; then HOST_CHECK="FAILED"; fi
		if [[ ${HTTPS_CHECK} = "FAILED" ]]; then HOST_CHECK="FAILED"; fi
		
		####################
		
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
		unset HTTP_CHECK
		unset HTTPS_CHECK

        # tactical(formatting) newline
	    echo
		
      done

	done

  fi
  
done

} 1> index.adoc

# PART, WHERE .ADOC BECOMES AN .HTML
adoc-generate index.adoc

# END
if [ $0 ]; then
  echo -e "\e[33mRemoving source files used for page generation ..\e[m"
  rm -fv index.adoc

  echo -e "\e[33mMoving generated <index.html> into ${TARGET_DIR} ..\e[m"
  mv -fv index.html ${TARGET_DIR}/

  echo -e "\e[33mCopying config/media directory into ${TARGET_DIR} ..\e[m"
  cp -rfv config/media ${TARGET_DIR}/

  echo -e "\e[32m✓\e[m Successfully generated status page in folder ${TARGET_DIR}"
  exit 0
else
  echo -e "\e[31m✕\e[m <index.adoc> failed to generate <index.html>. Try running \"asciidoctor index.adoc\" to get more details about errors occured"
  exit 69
fi
