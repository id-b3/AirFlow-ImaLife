#!/bin/bash
# receives original volume ($1) and initial segmentation ($2), and then converts binary segmentation to surface (after 6-connecting it) and calls for opfront.
# results are stored on $3

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]
then
    echo Usage: "$0" VOLUME_FILE_NIFTI INITIAL_SEGMENTATION_FILE OUTPUT_FOLDER OPFRONT_PARAMETERS
    exit 1
fi

# INDPUT PARAMETERS
VOL=$1
SEG=$2
FOLDEROUT=$3

# capture all remainign aprameters
OPFRONT_PARAMETERS=${*:4:$#} # (e.g.: "-i 15 -o 15 -I 2 -O 2 -d 6.8 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.41 -G -0.57")

# PUT HERE THE PATH TO THE COMPILED EXECUTABLES FROM OPFRONT-PLAYGROUND
BINARY_DIR="/usr/local/bin"
# Location of python scripts
PYTHON_SCR="/bronchinet/airway_analysis/util_scripts"

# get the root of the name without extension
FILE=$(basename "${VOL}")
FILE_NO_EXTENSION="${FILE%%.*}"
ROOT="${FOLDEROUT}/${FILE_NO_EXTENSION}"
LOGFILE="${ROOT}.log"

# NAMES for all generated files
SEG_CON6="${ROOT}-seg-6con.nii.gz" # Initial segmentaiton after 6-connexion
SEG_SURFACE="${ROOT}-seg.gts" # Initial segmentaitno after 6-conexion as a surface

INNER_SURFACE="${ROOT}surface0.gts" # Converted results from opfront, DO NOT EDIT.
OUTER_SURFACE="${ROOT}surface1.gts"

INNER_VOL="${ROOT}_surface0.nii.gz" # Results from opfront, original sizes
INNER_VOL_ISO="${ROOT}_surface0_iso.nii.gz" # Results from opfront, original sizes
OUTER_VOL="${ROOT}_surface1.nii.gz"

mkdir -p "$FOLDEROUT"

echo -e "\n Starting Phantom Opfront..."

{
echo -e "\n *** ${FILE_NO_EXTENSION} ***\n"
echo -e "Volume: $VOL"
echo -e "Segmentation: $SEG"
echo -e "Opfront parameters: $OPFRONT_PARAMETERS"
echo -e "Results folder: $FOLDEROUT\n"
echo -e "File without extension: $FILE_NO_EXTENSION\n"
} >> "$LOGFILE"
# ------------------------------------------------ EXECUTION STEPS ---------------------------------------
{
echo -e "\n6-connecting initial surface:"
CALL="${BINARY_DIR}/6con $SEG $SEG_CON6"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nCreating mesh surface using marching cubes:"
CALL="${BINARY_DIR}/img2gts -s $SEG_CON6 -g $SEG_SURFACE"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nRunning opfront:"
CALL="${BINARY_DIR}/segwall -v $VOL -s $SEG_SURFACE -p $ROOT $OPFRONT_PARAMETERS"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nConverting inner surface to binary with the original spacing (with subsampling):"
CALL="${BINARY_DIR}/gts2img -g $INNER_SURFACE -s $INNER_VOL -v $VOL -u 3"
echo -e "\n$CALL"
eval "$CALL"

#echo -e "\nScaling Inner surface to isometric voxels of 0.5 0.5 0.5"
#CALL="python ${PYTHON_SCR}/rescale_image.py -i $INNER_VOL -o $INNER_VOL_ISO -r 0.5 0.5 0.5"
#echo -e "\n$CALL"
#eval "$CALL"

echo -e "\nConverting outer surface to binary with the original spacing (with subsampling):"
CALL="${BINARY_DIR}/gts2img -g $OUTER_SURFACE -s $OUTER_VOL -v $VOL -u 3"
echo -e "\n$CALL"
eval "$CALL"

} >> "$LOGFILE"