#!/bin/bash
# Created by Antonio:
# Compute measurements on given airway lumen and outer wall segmentations. Receives original volume ($1) and input surface segmentations '.dcm' ($2, $3). Results are stored in ($4).
# Added by Antonio: export paths to missing libraries needed by executables in ($5)

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ] || [ "$5" == "" ]
then
    echo Usage: $0 VOLUME_FILE INIT_VOL_INNER_FILE INIT_VOL_OUTER_FILE OUTPUT_FOLDER ADD_LIBRARIES_PATH
    exit 1
fi

# INDPUT PARAMETERS
VOL=$1
INNER_VOL=$2
OUTER_VOL=$3
FOLDEROUT=$4

# EXPORT PATHS TO MISSING LIBRARIES
ADD_LIBRARIES_PATH=$5
export LD_LIBRARY_PATH=$ADD_LIBRARIES_PATH:${LD_LIBRARY_PATH}

# PUT HERE THE PATH TO THE COMPILED EXECUTABLES FROM OPFRONT-PLAYGROUND
BINARY_DIR="/archive/pulmo/Code_APerez/Cluster/Jens/binaries/"

# get the root of the name without extension
FILE=$(basename "${VOL}")
FILE_NO_EXTENSION="${FILE%.*}"
ROOT="${FOLDEROUT}/${FILE_NO_EXTENSION}"
FILE=$(basename "${INNER_VOL}")
FILE_NO_EXTENSION="${FILE%.*}"
ROOT_INNER_VOL="${FOLDEROUT}/${FILE_NO_EXTENSION}"
FILE=$(basename "${OUTER_VOL}")
FILE_NO_EXTENSION="${FILE%.*}"
ROOT_OUTER_VOL="${FOLDEROUT}/${FILE_NO_EXTENSION}"

INNER_VOL_CON6="${ROOT_INNER_VOL}_seg-6con.dcm" # Initial segmentation after 6-connexion
OUTER_VOL_CON6="${ROOT_OUTER_VOL}_seg-6con.dcm"

INNER_SURFACE="${ROOT_INNER_VOL}.gts" # Initial segmentation after 6-conexion as a surface
OUTER_SURFACE="${ROOT_OUTER_VOL}.gts"

#INNER_VOL_NEW="${ROOT_INNER_VOL}_new.dcm" # Results from conversions from .gts (compare with initial dicom)
#OUTER_VOL_NEW="${ROOT_OUTER_VOL}_new.dcm"

INNER_VOL_ISO="${ROOT_INNER_VOL}_iso05.dcm" # Results from opfront, converted to isotropic volumes.
INNER_VOL_ISO_TH1="${ROOT_INNER_VOL}_iso05_th1.dcm"

BRANCHES_ISO="${ROOT_INNER_VOL}_iso05_th1-branch.brh" # Results of computing branches, DO NOT EDIT
BRANCHES="${ROOT}_airways.brh"

INNER_RESULTS="${ROOT}_inner.csv"
OUTER_RESULTS="${ROOT}_outer.csv"
INNER_RESULTS_LOCAL="${ROOT}_inner_localRadius.csv"
OUTER_RESULTS_LOCAL="${ROOT}_outer_localRadius.csv"

BRANCHES_VOL="${ROOT}_airways_centrelines.dcm" 
BRANCHES_MATLAB="${ROOT}_airways_centrelines.m"

mkdir -p $FOLDEROUT

echo -e "\n *** ${FILE_NO_EXTENSION} ***\n"
echo -e "Volume: $VOL"
echo -e "Inner Surface: $INNER_VOL"
echo -e "Outer Surface: $OUTER_VOL"
echo -e "Results folder: $FOLDEROUT\n"

# ------------------------------------------------ EXECUTION STEPS ---------------------------------------

echo -e "\n6-connecting initial surface: inner surface"
CALL="${BINARY_DIR}/6con $INNER_VOL $INNER_VOL_CON6"
echo -e "\n$CALL"
eval $CALL

echo -e "\n6-connecting initial surface: outer surface"
CALL="${BINARY_DIR}/6con $OUTER_VOL $OUTER_VOL_CON6"
echo -e "\n$CALL"
eval $CALL

echo -e "\nCreating mesh surface using marching cubes: inner surface"
CALL="${BINARY_DIR}/segment2gts -s $INNER_VOL_CON6 -g $INNER_SURFACE"
echo -e "\n$CALL"
eval $CALL

echo -e "\nCreating mesh surface using marching cubes: outer surface"
CALL="${BINARY_DIR}/segment2gts -s $OUTER_VOL_CON6 -g $OUTER_SURFACE"
echo -e "\n$CALL"
eval $CALL

echo -e "\nConverting inner surface to 0.5mm isotropic voxels:"
CALL="${BINARY_DIR}/gts2segment -g $INNER_SURFACE -i 0.5 -s $INNER_VOL_ISO -v $VOL -u 3"
echo -e "\n$CALL"
eval $CALL

echo -e "\nBinarising isotropic inner surface with threshold 1 for branch extraction:"
CALL="${BINARY_DIR}/convert-jens -i $INNER_VOL_ISO -o $INNER_VOL_ISO_TH1 -t 0 -x 1"
echo -e "\n$CALL"
eval $CALL

# -- BRANCHES ----------------------------------
echo -e "\nComputing branches:" # this creates $BRANCHES_ISO
CALL="${BINARY_DIR}/be $INNER_VOL_ISO_TH1 -o $FOLDEROUT -vs 0.5 0.5 0.5" # -vessels added (or use of OUTTER_VOL_ISO_TH14) for >1 iterations in the opfront (to allow for disconnectivity)
echo -e "\n$CALL"
eval $CALL

echo -e "\nRescaling branches to original spacing:"
CALL="${BINARY_DIR}/scale_branch -f $INNER_VOL_ISO -t $VOL -b $BRANCHES_ISO -o $BRANCHES"
echo -e "\n$CALL"
eval $CALL

echo -e "\nMeasure inner surface:"
CALL="${BINARY_DIR}/gts_ray_measure -g $INNER_SURFACE -v $VOL -b $BRANCHES -o $INNER_RESULTS -l $INNER_RESULTS_LOCAL"
echo -e "\n$CALL"
eval $CALL

echo -e "\nMeasure outer surface:"
CALL="${BINARY_DIR}/gts_ray_measure -g $OUTER_SURFACE -v $VOL -b $BRANCHES -o $OUTER_RESULTS -l $OUTER_RESULTS_LOCAL"
echo -e "\n$CALL"
eval $CALL

echo -e "\nConvert branches to volume:"
CALL="${BINARY_DIR}/brh2vol $BRANCHES -volume $VOL -o $BRANCHES_VOL"
echo -e "\n$CALL"
eval $CALL

echo -e "\n\nConvert branches to MATLAB readable format:"
CALL="${BINARY_DIR}/brh2matlab $BRANCHES $BRANCHES_MATLAB"
echo -e "\n$CALL"
echo -e "DONE\n"
eval $CALL

# -- CLEAN UNNECESSARY FILES
echo -e "\nClean unnecessary files:"
CALL="rm $INNER_VOL_ISO $INNER_VOL_ISO_TH1 $BRANCHES_ISO"
echo -e "\n$CALL"
eval $CALL

