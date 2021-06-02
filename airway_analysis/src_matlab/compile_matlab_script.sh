#!/bin/bash

SCRIPT_NAME=$1

BASE_SCRIPT_NAME=$(basename $SCRIPT_NAME)
DIR_SCRIPT_NAME=$(dirname $SCRIPT_NAME)
DIRAUX_COMPILED="${DIR_SCRIPT_NAME}/tmp_compiled/"

OUT_BINARY_NAME=${BASE_SCRIPT_NAME%.m}
OUT_RUN_BINARY_SCRIPT="run_${OUT_BINARY_NAME}.sh"

mkdir -p $DIRAUX_COMPILED


#module load matlab/R2013b
module load matlab/R2015b

# mcc compiler options:
# -m : macro to generate a standalone application
# -d : place output in specified folder
# -K : directs mcc to not delete output files if the compilation ends prematurely, due to error
# -o : specify name of final output binary file
# -a : add path to the deployable archive
# -R : specify runtime options
# -v : display compilation steps

mcc -m $SCRIPT_NAME -a $PWD/functions/ -d $DIRAUX_COMPILED -K -o $OUT_BINARY_NAME -R nojvm -R nodisplay -v

#module remove matlab/R2013b
module remove matlab/R2015b


echo "output binary:" ${DIR_SCRIPT_NAME}/${OUT_BINARY_NAME}
mv ${DIRAUX_COMPILED}/${OUT_BINARY_NAME} ${DIR_SCRIPT_NAME}/${OUT_BINARY_NAME}

echo "output run script:" ${DIR_SCRIPT_NAME}/${OUT_RUN_BINARY_SCRIPT}
mv ${DIRAUX_COMPILED}/${OUT_RUN_BINARY_SCRIPT} ${DIR_SCRIPT_NAME}/${OUT_RUN_BINARY_SCRIPT}

rm -rf $DIRAUX_COMPILED
