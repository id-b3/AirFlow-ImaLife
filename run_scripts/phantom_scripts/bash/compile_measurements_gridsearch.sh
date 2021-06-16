#!/bin/bash
# Obtains the final vessel based segmentation
 
# PARAMETERS
OPFRONT_QUEUE="day"
MEMORY="10G"

BASEDIR="/scratch/agarcia/Tests/ValidationPhantom_IMALIFE/"
BASEBIN="/scratch/agarcia/Tests/ValidationPhantom_IMALIFE/Scripts/"

FOLDER_VOLUME="${BASEDIR}/Volume/"
FOLDER_SEGMENTATIONS_ALL="${BASEDIR}/Phantom_Opfronted_Regions_All/"
FOLDER_RESULTS_ALL="${BASEDIR}/Phantom_Measurements_Regions_All/"
FOLDER_LOGS="${FOLDER_RESULTS_ALL}/logs/"

DOAARANALYSIS_BIN="${BASEBIN}/compile_measurements.m"
NOW="$(date +%d-%m-%Y_%H-%M-%S)"
LOG_FILE="${FOLDER_LOGS}/Phantom_measurements_All_${NOW}.log"


mkdir -p $FOLDER_RESULTS_ALL
mkdir -p $FOLDER_LOGS

echo "FOLDER_VOLUME: $FOLDER_VOLUME" > $LOG_FILE
echo "FOLDER_SEGMENTATIONS_ALL: $FOLDER_SEGMENTATIONS_ALL" >> $LOG_FILE
echo "FOLDER_RESULTS_ALL: $FOLDER_RESULTS_ALL" >> $LOG_FILE
cat $LOG_FILE


LISTDIRS_OPFRONT_ALL=($(find $FOLDER_SEGMENTATIONS_ALL -mindepth 1 -maxdepth 1 -type d | sort))


LOAD_MCR="module load matlab/R2015b"
UNLOAD_MCR="module remove matlab/R2015b"


function LAUNCH_MATLAB_SCRIPT (){
    if [ "$1" == "" ] || [ "$2" == "" ]
    then
    	echo "ERROR in 'LAUNCH_MATLAB_SCRIPT': wrong input arguments: ${1}, ${2}... EXIT"
    	exit 1
    fi
    FUNCTION_SCRIPT=$(basename ${DOAARANALYSIS_BIN%.m})
    CALLMAT_ADDPATH="addpath('${BASEBIN}')"

    CALL="matlab -nodisplay -nosplash -nodesktop -r \"try; ${CALLMAT_ADDPATH}; ${FUNCTION_SCRIPT}('${1}', '${2}'); catch; exit; end; exit;\""
    echo ${CALL}
}


for I in ${!LISTDIRS_OPFRONT_ALL[@]}
do
    FOLDER_SEGMENTATIONS="${LISTDIRS_OPFRONT_ALL[I]}/"
    FOLDER_SEGMENTATIONS_NOSUFFIX="${FOLDER_SEGMENTATIONS_ALL}Phantom_Opfronted_"
    SUFFIX_SEGMENTATIONS=${FOLDER_SEGMENTATIONS#$FOLDER_SEGMENTATIONS_NOSUFFIX}
    FOLDER_RESULTS="${FOLDER_RESULTS_ALL}/Phantom_Measurements_OpfrontParams_${SUFFIX_SEGMENTATIONS}/"

    echo "FOLDER_VOLUME: $FOLDER_VOLUME" >> $LOG_FILE
    echo "FOLDER_SEGMENTATIONS: $FOLDER_SEGMENTATIONS" >> $LOG_FILE
    echo "FOLDER_RESULTS: $FOLDER_RESULTS" >> $LOG_FILE
    eval cat $LOG_FILE

    mkdir -p $FOLDER_RESULTS


    JOBLOG_FILE="${FOLDER_LOGS}/Phantom_measurements_opfrontParams_${SUFFIX_SEGMENTATIONS}_${NOW}.log"
    MATLOG_FILE="${FOLDER_RESULTS}/Phantom_measurements.log"
    JOB_NAME="Phan_${SUFFIX_SEGMENTATIONS}" 

    CALL="${LOAD_MCR}; $(LAUNCH_MATLAB_SCRIPT ${FOLDER_SEGMENTATIONS} ${FOLDER_RESULTS}); ${UNLOAD_MCR}" 


    echo $CALL >> $LOG_FILE
    echo $CALL && eval $CALL
    #echo $CALL | qsub -q ${OPFRONT_QUEUE} -l h_vmem=${MEMORY} -j y -N ${JOB_NAME} -o ${FOLDER_LOGS}/${JOB_NAME}_${NOW}.log
done
