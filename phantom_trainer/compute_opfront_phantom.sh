#!/bin/bash
# Obtains the final vessel based segmentation

IS_QUEUE_CLUSTER="true"

if [ "$IS_QUEUE_CLUSTER" == "true" ]
then
    # PARAMETERS QUEUE
    OPFRONT_QUEUE="day"
    MEMORY="50G"
fi

OPFRONT_PARAMETERS="-i 15 -o 15 -I 2 -O 2 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0" # original from Jens
#OPFRONT_PARAMETERS="-i 64 -I 3 -o 64 -O 1 -d 0 -b 0.3 -k 0.5 -r 0.7 -c 17 -e 0.6 -K 0 -M 5 -N 7"

PARAMETER_NAME="i15_I2_o15_O2"


CODEDIR="/home/antonio/Codes/Air_Flow_ImaLife/"
BASEDIR="/scratch/agarcia/Tests/ValidationPhantom_IMALIFE/"

FOLDER_VOLUME="${BASEDIR}/Volume/"
FOLDER_INITIAL="${BASEDIR}/Initial/"
FOLDER_RESULTS="${BASEDIR}/Phantom_Opfronted_${PARAMETER_NAME}/"

FOLDER_LOGS="${FOLDER_RESULTS}/logs"
NOW="$(date +%d-%m-%Y_%H-%M-%S)"
LOG_FILE="${FOLDER_LOGS}/opfront_phantom_${NOW}.log"

OPFRONT_BIN="${CODEDIR}/phantom_trainer/opfront_individual_nomeasures.sh"
MEASURES_BIN="${CODEDIR}/phantom_trainer/measurements_individual.sh"
BOUNDBOXREGS_BIN="${CODEDIR}/phantom_trainer/util/compute_boundbox_regions.py"
SPLITSEGSREGS_BIN="${CODEDIR}/phantom_trainer/util/split_opfrontsegs_regions.py"


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


mkdir -p $FOLDER_RESULTS
mkdir -p $FOLDER_LOGS

echo "FOLDER_OPFRONT_RESULTS: $FOLDER_RESULTS" >> $LOG_FILE
echo "OPFRONT_PARAMETERS: $OPFRONT_PARAMETERS" >> $LOG_FILE
eval cat $LOG_FILE

INPUT_VOLUME="${FOLDER_VOLUME}/COPDGene_Phantom_Qr59.dcm"
INPUT_LUMEN="${FOLDER_INITIAL}/COPDGene_Phantom_Qr59_Lumen.dcm"
INPUT_BOUNDBOXREGS="${BASEDIR}/COPDGene_boundboxes_regions.npy"


# 1 STEP: COMPUTE OPFRONT SEGMENTATION
# -------
CALL="${OPFRONT_BIN} ${INPUT_VOLUME} ${INPUT_LUMEN} ${FOLDER_RESULTS} ${PATH_LIBRARIES} ${OPFRONT_PARAMETERS}"
echo $CALL >> $LOG_FILE

if [ "$IS_QUEUE_CLUSTER" == "true" ]
then
    echo $CALL && eval $CALL
else
    JOB_NAME="OPr_Phantom_${PARAMETERS_NAME}"
    echo $CALL | qsub -q ${OPFRONT_QUEUE} -l h_vmem=${MEMORY} -j y -N ${JOB_NAME} -o ${FOLDER_LOGS}/${JOB_NAME}_${NOW}.log
fi

# IMPORTANT: IF QUEUE IN CLUSTER, NEED TO WAIT FOR JOBS TO FINISH BEFORE CONTINUING


# 2 STEP: SPLIT THE OPFRONT SEGMENTATIONS FOR EACH REGION (8 IN TOTAL)
# -------
if [ ! -f "$INPUT_BOUNDBOXREGS"]
then
    # COMPUTE FILE WITH BOUNDING-BOXES COORDS
    CALL="python3 ${BOUNDBOXREGS_BIN} ${INPUT_LUMEN} --output_file=${INPUT_BOUNDBOXREGS}"
    echo $CALL && eval $CALL
fi

CALL="python3 ${SPLITSEGSREGS_BIN} ${FOLDER_RESULTS} --in_boundboxes_file=${INPUT_BOUNDBOXREGS}"
echo $CALL && eval $CALL

# COMPRESS OUTPUT DICOMS
LIST_OUT_DICOMS=$(find ${FOLDER_RESULTS}_region[0-9] -type f)

for IFILE in $LIST_OUT_DICOMS
do
    CALL="dcmcjpeg $IFILE $IFILE"
    echo $CALL && eval $CALL
done


# 3 STEP: COMPUTE MEASUREMENTS FOR EACH REGION 
# -------
LIST_FOLDERS_RESULTS_REGS=$(find ${BASEDIR} -type d -name "_region[0-9]")

for IFOLDER_RESULTS in $LIST_FOLDERS_RESULTS_REGS
do
    IN_SEGMEN_INNER_FILE="${IFOLDER_RESULTS}/COPDGene_Phantom_Qr59_surface0.dcm"
    IN_SEGMEN_OUTER_FILE="${IFOLDER_RESULTS}/COPDGene_Phantom_Qr59_surface1.dcm"

    CALL="${MEASURES_BIN} ${INPUT_VOLUME} ${IN_SEGMEN_INNER_FILE} ${IN_SEGMEN_OUTER_FILE} ${IFOLDER_RESULTS} ${PATH_LIBRARIES}"

    if [ "$IS_QUEUE_CLUSTER" == "true" ]
    then
	echo $CALL && eval $CALL
    else
	JOB_NAME="Meas_Phantom_${PARAMETERS_NAME}"
	echo $CALL | qsub -q ${OPFRONT_QUEUE} -l h_vmem=${MEMORY} -j y -N ${JOB_NAME} -o ${FOLDER_LOGS}/${JOB_NAME}_${NOW}.log
    fi

    # IMPORTANT: IF QUEUE IN CLUSTER, NEED TO WAIT FOR JOBS TO FINISH BEFORE CONTINUING
done


# ... TO BE CONTINUED
