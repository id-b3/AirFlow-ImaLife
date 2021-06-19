#!/bin/bash

INPUT_DIR="${1:-~/temp_scan}"
VERSION="${2}"

if [ "$1" == "" ] || [ "$2" == "" ]
then
    echo Usage: "$0" INPUT_DIR IMAGE_VERSION
    exit 1
fi

CALL="docker run --gpus all -ti --entrypoint \"/bin/bash\" -v ${INPUT_DIR}:/input airflow:${VERSION}"
echo -e "$CALL"
eval "$CALL"