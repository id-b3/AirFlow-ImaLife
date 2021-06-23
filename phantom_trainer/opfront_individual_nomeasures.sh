#!/bin/bash
# receives original volume ($1) and initial segmentation ($2), and then converts binary segmentation to surface (after 6-connecting it) and calls for opfront.
# results are stored on $3

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ] || [ "$5" == "" ]
then
    echo Usage: $0 VOLUME_FILE INITIAL_SEGMENTATION_FILE OUTPUT_FOLDER ADD_LIBRARIES_PATH OPFRONT_PARAMETERS
    exit 1
fi

# INDPUT PARAMETERS
VOL=$1
SEG=$2
FOLDEROUT=$3

# EXPORT PATHS TO MISSING LIBRARIES
ADD_LIBRARIES_PATH=$4
export LD_LIBRARY_PATH=$ADD_LIBRARIES_PATH:${LD_LIBRARY_PATH}

# capture all remainign aprameters
OPFRONT_PARAMETERS=${@:5:$#} # (e.g.: "-i 15 -o 15 -I 2 -O 2 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0")

# PUT HERE THE PATH TO THE COMPILED EXECUTABLES FROM OPFRONT-PLAYGROUND
BINARY_DIR="/archive/pulmo/Code_APerez/Cluster/Jens/binaries/"

# get the root of the name without extension
FILE=$(basename "${VOL}")
FILE_NO_EXTENSION="${FILE%.*}"
ROOT="${FOLDEROUT}/${FILE_NO_EXTENSION}"

# NAMES for all generated files
SEG_CON6="${ROOT}-seg-6con.dcm" # Initial segmentaiton after 6-connexion
SEG_SURFACE="${ROOT}-seg.gts" # Initial segmentaitno after 6-conexion as a surface

INNER_SURFACE="${ROOT}_surface0.gts" # Converted results from opfront, DO NOT EDIT.
OUTER_SURFACE="${ROOT}_surface1.gts"

INNER_VOL="${ROOT}_surface0.dcm" # Results from opfront, original sizes
OUTER_VOL="${ROOT}_surface1.dcm"

mkdir -p $FOLDEROUT

echo -e "\n *** ${FILE_NO_EXTENSION} ***\n"
echo -e "Volume: $VOL"
echo -e "Segmentation: $SEG"
echo -e "Opfront parameters: $OPFRONT_PARAMETERS"
echo -e "Results folder: $FOLDEROUT\n"

# ------------------------------------------------ EXECUTION STEPS ---------------------------------------

echo -e "\n6-connecting initial surface:"
CALL="${BINARY_DIR}/6con $SEG $SEG_CON6"
echo -e "\n$CALL"
eval $CALL

echo -e "\nCreating mesh surface using marching cubes:"
CALL="${BINARY_DIR}/segment2gts -s $SEG_CON6 -g $SEG_SURFACE"
echo -e "\n$CALL"
eval $CALL

echo -e "\nRunning opfront:"
CALL="${BINARY_DIR}/opfront -v $VOL -s $SEG_SURFACE -p $ROOT $OPFRONT_PARAMETERS"
echo -e "\n$CALL"
eval $CALL

echo -e "\nConverting inner surface to binary with the original spacing (with subsampling):"
CALL="${BINARY_DIR}/gts2segment -g $INNER_SURFACE -s $INNER_VOL -v $VOL -u 3"
echo -e "\n$CALL"
eval $CALL

echo -e "\nConverting outer surface to binary with the original spacing (with subsampling):"
CALL="${BINARY_DIR}/gts2segment -g $OUTER_SURFACE -s $OUTER_VOL -v $VOL -u 3"
echo -e "\n$CALL"
eval $CALL

# -- CLEAN UNNECESSARY FILES
echo -e "\nClean unnecessary files:"
CALL="rm $SEG_CON6 $SEG_SURFACE"
echo -e "\n$CALL"
eval $CALL

