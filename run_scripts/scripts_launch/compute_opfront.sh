#!/bin/bash
# Obtains the final vessel based segmentation

# PARAMETERS
OPFRONT_QUEUE="day"
MEMORY="50G"


OPFRONT_PARAMETERS="-i 15 -o 15 -I 2 -O 2 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0" # original from Jens
#OPFRONT_PARAMETERS="-i 64 -I 3 -o 64 -O 1 -d 0 -b 0.3 -k 0.5 -r 0.7 -c 17 -e 0.6 -K 0 -M 5 -N 7"

PARAMETER_NAME="i15_I2_o15_O2"

BASEDIR="/input/Validation/COPDGene/"
BASEBIN="/bronchinet/scripts/"

FOLDER_VOLUME="${BASEDIR}"
FOLDER_INITIAL="${BASEDIR}"
FOLDER_RESULTS="${BASEDIR}/Phantom_Opfronted_${PARAMETER_NAME}/"

FOLDER_LOGS="${FOLDER_RESULTS}/logs"
NOW="$(date +%d-%m-%Y_%H-%M-%S)"
LOG_FILE="${FOLDER_LOGS}/opfront_phantom_${NOW}.log"
OPFRONT_BIN="${BASEBIN}/opfront_individual.sh"

# PATHS TO REQUIRED LIBRARIES
# BASELIBS="/archive/pulmo/Code_APerez/Cluster/Libraries/"
# libboost_filesystem.so.1.47.0
# PATH_LIBRARIES="${BASELIBS}/boost_cluster/bin/lib/"
# libCGAL.so
# PATH_LIBRARIES="${BASELIBS}/CGAL/CGAL-4.4/lib/:${PATH_LIBRARIES}"
# libgmp.so
# PATH_LIBRARIES="${BASELIBS}/GMP/build/lib/:${PATH_LIBRARIES}"
# libgsl.so
# PATH_LIBRARIES="${BASELIBS}/GSL_unnecesary/:${PATH_LIBRARIES}"
# libgts-0.7.so
# PATH_LIBRARIES="${BASELIBS}/GTS/build/lib/:${PATH_LIBRARIES}"
# libmpfr.so
# PATH_LIBRARIES="${BASELIBS}/MPFR/build/lib/:${PATH_LIBRARIES}"
# libkdtree.so
# PATH_LIBRARIES="${BASELIBS}/kdtree/build/lib/:${PATH_LIBRARIES}"

mkdir -p $FOLDER_RESULTS
mkdir -p $FOLDER_LOGS

echo "FOLDER_OPFRONT_RESULTS: $FOLDER_RESULTS" >> $LOG_FILE
echo "OPFRONT_PARAMETERS: $OPFRONT_PARAMETERS" >> $LOG_FILE
eval cat $LOG_FILE

INPUT_VOLUME="${FOLDER_VOLUME}/COPDGene_Phantom_Qr59_Volume.dcm"
INPUT_LUMEN="${FOLDER_INITIAL}/COPDGene_Phantom_Qr59_Lumen.dcm"

CALL="${OPFRONT_BIN} ${INPUT_VOLUME} ${INPUT_LUMEN} ${FOLDER_RESULTS} ${PATH_LIBRARIES} ${OPFRONT_PARAMETERS}"

echo $CALL >> $LOG_FILE

# COMMENT-OUT IF RUN IN CLUSTER
echo $CALL && eval $CALL

# COMMENT-OUT IF RUN LOCALLY
#JOB_NAME="OPr_Phan_${PARAMETERS_NAME}"
#echo $CALL | qsub -q ${OPFRONT_QUEUE} -l h_vmem=${MEMORY} -j y -N ${JOB_NAME} -o ${FOLDER_LOGS}/${JOB_NAME}_${NOW}.log
