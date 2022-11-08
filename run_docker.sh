#!/bin/bash

# Input folder of DICOM series (slices)
INPUT_PATH=${1}
# Output folder for results
OUTPUT_PATH=${2}
# Docker image name and version. Default: colossali/airflow:ima_1.0
DOCKER_NAME=${3}
# The participant I.D. for output naming and summary file.
PARTICIPANT_ID=${4}

echo "Input Parameters: \n"
echo "Input: $INPUT_PATH"
echo "Output: $OUTPUT_PATH"
echo "ID: $PARTICIPANT_ID"

# Run docker image with gpus enabled. Mount input and output folders. Pass participant ID.
CALL="docker run --gpus all --rm -t -v ${INPUT_PATH}:/input -v ${OUTPUT_PATH}:/output ${DOCKER_NAME} /input ${PARTICIPANT_ID} /output"
echo "$CALL"

eval "$CALL"
