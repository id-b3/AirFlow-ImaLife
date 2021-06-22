#!/bin/bash

INPUT_DIR="${1:-~/temp_scan}"
IMAGE_N_VERSION="${2}"

if [ "$1" == "" ] || [ "$2" == "" ]
then
    echo Usage: "$0" INPUT_DIR IMAGE_NAME_VERSION e.g. airflow:0.9.0
    exit 1
fi

CALL="docker run --user ${UID}:${GID} --gpus all -ti --entrypoint \"/bin/bash\" -v ${INPUT_DIR}:/input ${IMAGE_N_VERSION}"
echo -e "$CALL"
eval "$CALL"
