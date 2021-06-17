#!/bin/bash
# Obtains COPDGene phantom segmentations.

# smoothness penalties are p in paper, -i and -o in tool
LIST_INNER_PENALTY=("1" "2" "4" "8" "16" "32" "64" "128" "256" "512")
LIST_INNER_CONSTRAINT=("1" "2" "3" "4" "10000")
LIST_FLOW_MAXLENGTH_IN=("0" "1" "3" "5")
LIST_FLOW_MAXLENGTH_OUT=("0" "1" "3" "5")
# SEPARATION PENALTY is q in paper -d in tool
LIST_SEPARATION_PENALTY=("0" "3" "6.8")
# KERNEL SPACING IS small sigma in paper -k in tool
LIST_FLOW_KERNEL_SPACING=("0.1" "0.3" "0.5" "0.8" "1")
# derivatives are small gamma in paper -F and -G in tool
LIST_INNER_DERIVATIVE_W=("0" "-0.41" "0.41")
LIST_OUTER_DERIVATIVE_W=("0" "-0.57" "0.57")

LIST_OPFRONT_PARAMETERS=()
LIST_PARAMETERS_NAME=()

for INNER_WEIGHT in "${LIST_INNER_DERIVATIVE_W[@]}"
do
    for OUTER_WEIGHT in "${LIST_OUTER_DERIVATIVE_W[@]}"
    do
      for SEPARATION_PENALTY in "${LIST_SEPARATION_PENALTY[@]}"
      do
        LIST_OPFRONT_PARAMETERS+=("-i 48 -o 23 -I 2 -O 2 -d ${SEPARATION_PENALTY} -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F ${INNER_WEIGHT} -G ${OUTER_WEIGHT} -n \"y\"")
        LIST_PARAMETERS_NAME+=("d${SEPARATION_PENALTY}_F${INNER_WEIGHT}_G${OUTER_WEIGHT}")
      done
    done
done

BASEDIR=${2:-/input/Validation}
BASEBIN=${1:-/input/}
FOLDER_BASE_RESULTS="${BASEDIR}/gridsearch_all"
NOW="$(date +%d-%m-%Y_%H-%M)"
OPFRONT_BIN="${BASEBIN}/opfront_phantom_single.sh"
INPUT_VOLUME="${BASEDIR}/phantom_volume.nii.gz"
INPUT_LUMEN="${BASEDIR}/phantom_lumen.nii.gz"

for I in "${!LIST_OPFRONT_PARAMETERS[@]}"
do
    OPFRONT_PARAMETERS=${LIST_OPFRONT_PARAMETERS[I]}
    PARAMETERS_NAME=${LIST_PARAMETERS_NAME[I]}

    FOLDER_RESULTS="${FOLDER_BASE_RESULTS}/parameters_${PARAMETERS_NAME}"

    FOLDER_LOGS="${FOLDER_RESULTS}/logs"
    LOG_FILE="${FOLDER_LOGS}/opfront_phantom_${NOW}.log"

    mkdir -p "$FOLDER_RESULTS"
    mkdir -p "$FOLDER_LOGS"

    echo "FOLDER_OPFRONT_RESULTS: $FOLDER_RESULTS" >> "$LOG_FILE"
    echo "OPFRONT_PARAMETERS: $OPFRONT_PARAMETERS" >> "$LOG_FILE"
    eval cat "$LOG_FILE"

    CALL="${OPFRONT_BIN} ${INPUT_VOLUME} ${INPUT_LUMEN} ${FOLDER_RESULTS} ${OPFRONT_PARAMETERS}"

    echo "$CALL" >> "$LOG_FILE"

    # COMMENT-OUT IF RUN IN CLUSTER
    echo "$CALL" && eval "$CALL"

    # COMMENT-OUT IF RUN LOCALLY
    #JOB_NAME="OPr_Phan_${PARAMETERS_NAME}"
    #echo $CALL | qsub -q ${OPFRONT_QUEUE} -l h_vmem=${MEMORY} -j y -N ${JOB_NAME} -o ${FOLDER_LOGS}/${JOB_NAME}_${NOW}.log
done
