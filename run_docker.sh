#!/bin/bash

# Input folder of DICOM series (slices)
INPUT_PATH=${0}
# Output folder for results
OUTPUT_PATH=${1}
# Docker image name and version. Default: colossali/airflow:ima_1.0
DOCKER_NAME=${2:-"colossali/airflow:ima_1.0"}
# The participant I.D. for output naming and summary file.
PARTICIPANT_ID=${3}

# Run docker image with gpus enabled. Mount input and output folders. Pass participant ID.
docker run --gpus all --rm -t -v ${INPUT_PATH}:/input -v ${OUTPUT_PATH}:/output ${DOCKER_NAME} /input ${PARTICIPANT_ID} /output /output/${PARTICIPANT_ID}_airflow.log
