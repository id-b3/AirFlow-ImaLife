#!/bin/bash

# Input folder of DICOM series (slices)
INPUT_PATH=${1}
# Output folder for results
OUTPUT_PATH=${2}
# External run_script path
SCRIPT_PATH=${3}
# Docker image name and version. Default: colossali/airflow:ima_1.0
DOCKER_NAME=${3}

echo "Parameters: \n"
echo "Input: $INPUT_PATH"
echo "Output: $OUTPUT_PATH"
echo "Script: $SCRIPT_PATH"
echo "Docker: $DOCKER_NAME"

# Run docker image with gpus enabled. Mount input and output folders. Pass participant ID.
CALL="docker run --gpus all --rm -t -v ${INPUT_PATH}:/input -v ${OUTPUT_PATH}:/output -v ${SCRIPT_PATH}:/airflow/scripts/run_machine.sh ${DOCKER_NAME} /input /output"
echo "$CALL"
eval "$CALL"
