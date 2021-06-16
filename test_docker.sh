#!/bin/bash

CALL="docker run -ti --entrypoint \"/bin/bash\" -v ~/temp_scan:/input airflow:$1"
echo -e "$CALL"
eval "$CALL"
