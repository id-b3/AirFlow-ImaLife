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

# Smoothed branches
#BRANCHES_ISO_CONNECTED="${ROOT_INNER_VOL}_iso05_th14-branch_connected.brh"
#BRANCHES_ISO_CONNECTED="${ROOT_OUTER_VOL}_iso05_th14-branch_connected.brh"
#BRANCHES_ISO_SMOOTHED="${ROOT_INNER_VOL}_iso05_th14-branch_connected_smoothed.brh"
#BRANCHES_ISO_SMOOTHED="${ROOT_OUTER_VOL}_iso05_th14-branch_connected_smoothed.brh"
#BRANCHES_SMOOTHED="${ROOT}_airways_smoothed.brh"

#INNER_RESULTS_SMOOTHED="${ROOT}_inner_smoothed.csv"
#OUTER_RESULTS_SMOOTHED="${ROOT}_outer_smoothed.csv"
#INNER_RESULTS_LOCAL_SMOOTHED="${ROOT}_inner_localRadius_smoothed.csv"
#OUTER_RESULTS_LOCAL_SMOOTHED="${ROOT}_outer_localRadius_smoothed.csv"

#BRANCHES_VOL_SMOOTHED="${ROOT}_airways_centrelines_smoothed.dcm" 
#BRANCHES_MATLAB_SMOOTHED="${ROOT}_airways_centrelines_smoothed.m"

mkdir -p $FOLDEROUT

echo -e "\n *** ${FILE_NO_EXTENSION} ***\n"
echo -e "Volume: $VOL"
echo -e "Inner Surface: $INNER_VOL"
echo -e "Outer Surface: $OUTER_VOL"
echo -e "Results folder: $FOLDEROUT\n"

# ------------------------------------------------ EXECUTION STEPS ---------------------------------------

#echo -e "\n6-connecting initial surface: inner surface"
#CALL="${BINARY_DIR}/6con $INNER_VOL $INNER_VOL_CON6"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\n6-connecting initial surface: outer surface"
#CALL="${BINARY_DIR}/6con $OUTER_VOL $OUTER_VOL_CON6"
#echo -e "\n$CALL"
#eval $CALL

echo -e "\nCreating mesh surface using marching cubes: inner surface"
#CALL="${BINARY_DIR}/segment2gts -s $INNER_VOL_CON6 -g $INNER_SURFACE"
CALL="${BINARY_DIR}/segment2gts -s $INNER_VOL -g $INNER_SURFACE"
echo -e "\n$CALL"
eval $CALL

echo -e "\nCreating mesh surface using marching cubes: outer surface"
#CALL="${BINARY_DIR}/segment2gts -s $OUTER_VOL_CON6 -g $OUTER_SURFACE"
CALL="${BINARY_DIR}/segment2gts -s $OUTER_VOL -g $OUTER_SURFACE"
echo -e "\n$CALL"
eval $CALL

#echo -e "\nConverting inner surface to binary with the original spacing (with subsampling):"
#CALL="${BINARY_DIR}/gts2segment -g $INNER_SURFACE -s $INNER_VOL_NEW -v $VOL -u 3"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\nConverting outer surface to binary with the original spacing (with subsampling):"
#CALL="${BINARY_DIR}/gts2segment -g $OUTER_SURFACE -s $OUTER_VOL_NEW -v $VOL -u 3"
#echo -e "\n$CALL"
#eval $CALL

echo -e "\nConverting inner surface to 0.5mm isotropic voxels:"
CALL="${BINARY_DIR}/gts2segment -g $INNER_SURFACE -i 0.5 -s $INNER_VOL_ISO -v $VOL -u 3"
#CALL="${BINARY_DIR}/gts2segment -g $OUTER_SURFACE -i 0.5 -s $OUTER_VOL_ISO -v $VOL -u 3"
echo -e "\n$CALL"
eval $CALL

echo -e "\nBinarising isotropic inner surface with threshold 1 for branch extraction:"
CALL="${BINARY_DIR}/convert-jens -i $INNER_VOL_ISO -o $INNER_VOL_ISO_TH1 -t 0 -x 1"
#CALL="${BINARY_DIR}/convert-jens -i $OUTER_VOL_ISO -o $OUTER_VOL_ISO_TH1 -t 0 -x 1"
echo -e "\n$CALL"
eval $CALL

# -- BRANCHES ----------------------------------
echo -e "\nComputing branches:" # this creates $BRANCHES_ISO
CALL="${BINARY_DIR}/be $INNER_VOL_ISO_TH1 -o $FOLDEROUT -vs 0.5 0.5 0.5" # -vessels added (or use of OUTTER_VOL_ISO_TH14) for >1 iterations in the opfront (to allow for disconnectivity)
#CALL="${BINARY_DIR}/be $OUTER_VOL_ISO_TH1 -o $FOLDEROUT -vs 0.5 0.5 0.5" # -vessels added (or use of OUTTER_VOL_ISO_TH14) for >1 iterations in the opfront (to allow for disconnectivity)
echo -e "\n$CALL"
eval $CALL

echo -e "\nRescaling branches to original spacing:"
CALL="${BINARY_DIR}/scale_branch -f $INNER_VOL_ISO -t $VOL -b $BRANCHES_ISO -o $BRANCHES"
#CALL="${BINARY_DIR}/scale_branch -f $OUTER_VOL_ISO -t $VOL -b $BRANCHES_ISO -o $BRANCHES"
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

# -- SMOOTHED BRANCHES --------------------------
#echo -e "\nConnecting branches (at iso space):"
#CALL="${BINARY_DIR}/connected_brh -s $INNER_VOL_ISO -b $BRANCHES_ISO -o $BRANCHES_ISO_CONNECTED"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\nSmoothing branches (at iso space):"
#CALL="${BINARY_DIR}/smooth_brh -b $BRANCHES_ISO_CONNECTED -s $INNER_VOL_ISO -o $BRANCHES_ISO_SMOOTHED --quiet"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\nRescaling smoothed branches to original spacing:"
#CALL="${BINARY_DIR}/scale_branch -f $INNER_VOL_ISO -t $VOL -b $BRANCHES_ISO_SMOOTHED -o $BRANCHES_SMOOTHED"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\nMeasure inner surface (with smoothed branches):"
#CALL="${BINARY_DIR}/gts_ray_measure -g $INNER_SURFACE -v $VOL -b $BRANCHES_SMOOTHED -o $INNER_RESULTS_SMOOTHED -l $INNER_RESULTS_LOCAL_SMOOTHED"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\nMeasure outer surface (with smoothed branches):"
#CALL="${BINARY_DIR}/gts_ray_measure -g $OUTER_SURFACE -v $VOL -b $BRANCHES_SMOOTHED -o $OUTER_RESULTS_SMOOTHED -l $OUTER_RESULTS_LOCAL_SMOOTHED"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\nConvert smoothed branches to volume:"
#CALL="${BINARY_DIR}/brh2vol $BRANCHES_SMOOTHED -volume $VOL -o $BRANCHES_VOL_SMOOTHED"
#echo -e "\n$CALL"
#eval $CALL

#echo -e "\n\nConvert smoothed branches to MATLAB readable format:"
#CALL="${BINARY_DIR}/brh2matlab $BRANCHES_SMOOTHED $BRANCHES_MATLAB_SMOOTHED"
#echo -e "\n$CALL"
#echo -e "DONE\n"
#eval $CALL

# -- CLEAN UNNECESSARY FILES
echo -e "\nClean unnecessary files:"
CALL="rm $INNER_VOL_ISO $INNER_VOL_ISO_TH1 $BRANCHES_ISO"
#CALL="rm $OUTER_VOL_ISO $OUTER_VOL_ISO_TH1 $BRANCHES_ISO"
echo -e "\n$CALL"
eval $CALL

