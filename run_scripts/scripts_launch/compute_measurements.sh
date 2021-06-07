#!/bin/bash
# Obtains the final vessel based segmentation
 
# PARAMETERS
OPFRONT_QUEUE="day"
MEMORY="10G"

BASEDIR="/scratch/agarcia/Tests/ValidationPhantom_IMALIFE/"
BASEBIN="/scratch/agarcia/Tests/ValidationPhantom_IMALIFE/Scripts/"

FOLDER_VOLUME="${BASEDIR}/Volume/"
FOLDER_RESULTS="${BASEDIR}/Phantom_Opfronted_Regions/"

FOLDER_LOGS="${FOLDER_RESULTS}/logs"
NOW="$(date +%d-%m-%Y_%H-%M-%S)"
LOG_FILE="${FOLDER_LOGS}/opfront_phantom_${NOW}.log"
MEASURES_BIN="${BASEBIN}/measurements_individual.sh"


# PATHS TO REQUIRED LIBRARIES
BASELIBS="/archive/pulmo/Code_APerez/Cluster/Libraries/"
# libboost_filesystem.so.1.47.0
PATH_LIBRARIES="${BASELIBS}/boost_cluster/bin/lib/"
# libCGAL.so
PATH_LIBRARIES="${BASELIBS}/CGAL/CGAL-4.4/lib/:${PATH_LIBRARIES}"
# libgmp.so
PATH_LIBRARIES="${BASELIBS}/GMP/build/lib/:${PATH_LIBRARIES}"
# libgsl.so
PATH_LIBRARIES="${BASELIBS}/GSL_unnecesary/:${PATH_LIBRARIES}"
# libgts-0.7.so
PATH_LIBRARIES="${BASELIBS}/GTS/build/lib/:${PATH_LIBRARIES}"
# libmpfr.so
PATH_LIBRARIES="${BASELIBS}/MPFR/build/lib/:${PATH_LIBRARIES}"
# libkdtree.so
PATH_LIBRARIES="${BASELIBS}/kdtree/build/lib/:${PATH_LIBRARIES}"


mkdir -p $FOLDER_LOGS

INPUT_VOLUME="${FOLDER_VOLUME}/COPDGene_Phantom_Qr59.dcm"
IN_SEGMEN_INNER_FILE="${FOLDER_RESULTS}/COPDGene_Phantom_Qr59_surface0.dcm"
IN_SEGMEN_OUTER_FILE="${FOLDER_RESULTS}/COPDGene_Phantom_Qr59_surface1.dcm"

CALL="${MEASURES_BIN} ${INPUT_VOLUME} ${IN_SEGMEN_INNER_FILE} ${IN_SEGMEN_OUTER_FILE} ${FOLDER_RESULTS} ${PATH_LIBRARIES}"

echo $CALL >> $LOG_FILE

# COMMENT-OUT IF RUN IN CLUSTER
echo $CALL && eval $CALL

# COMMENT-OUT IF RUN LOCALLY
#JOB_NAME="Meas_Phan"
#echo $CALL | qsub -q ${OPFRONT_QUEUE} -l h_vmem=${MEMORY} -j y -N ${JOB_NAME} -o ${FOLDER_LOGS}/${JOB_NAME}_${NOW}.log
