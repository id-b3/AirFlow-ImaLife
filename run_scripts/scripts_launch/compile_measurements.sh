#!/bin/bash
# Obtains the final vessel based segmentation
 
# PARAMETERS
OPFRONT_QUEUE="day"
MEMORY="10G"

BASEDIR="/scratch/agarcia/Tests/ValidationPhantom_IMALIFE/"
BASEBIN="/scratch/agarcia/Tests/ValidationPhantom_IMALIFE/Scripts/"

FOLDER_VOLUME="${BASEDIR}/Volume/"
FOLDER_SEGMENTATIONS="${BASEDIR}/Segmentations/"
FOLDER_RESULTS="${BASEDIR}/Measurements/"

DOAARANALYSIS_BIN="${BASEBIN}/compile_measurements.m"
NOW="$(date +%d-%m-%Y_%H-%M-%S)"
LOG_FILE="${FOLDER_RESULTS}/measurements_${NOW}.log"


mkdir -p $FOLDER_RESULTS

echo "FOLDER_VOLUME: $FOLDER_VOLUME" > $LOG_FILE
echo "FOLDER_SEGMENTATIONS: $FOLDER_SEGMENTATIONS" >> $LOG_FILE
echo "FOLDER_RESULTS: $FOLDER_RESULTS" >> $LOG_FILE
cat $LOG_FILE


LOAD_MCR="module load matlab/R2015b"
UNLOAD_MCR="module remove matlab/R2015b"


function LAUNCH_MATLAB_SCRIPT (){
    FUNCTION_SCRIPT=$(basename ${DOAARANALYSIS_BIN%.m})
    CALLMAT_ADDPATH="addpath('${BASEBIN}')"

    CALL="matlab -nodisplay -nosplash -nodesktop -r \"try; ${CALLMAT_ADDPATH}; ${FUNCTION_SCRIPT}; catch; exit; end; exit;\""
    echo ${CALL}
}


MATLOG_FILE="${FOLDER_RESULTS}/measurements.log"
JOB_NAME="Compi_Meas"

CALL="${LOAD_MCR}; $(LAUNCH_MATLAB_SCRIPT); ${UNLOAD_MCR}"

echo $CALL >> $LOG_FILE
echo $CALL && eval $CALL
#echo $CALL | qsub -q ${OPFRONT_QUEUE} -l h_vmem=${MEMORY} -j y -N ${JOB_NAME} -o ${FOLDER_LOGS}/${JOB_NAME}_${NOW}.log
