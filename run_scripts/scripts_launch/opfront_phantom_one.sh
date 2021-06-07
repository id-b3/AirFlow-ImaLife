#!/bin/bash
# receives original volume ($1) and initial segmentation ($2), and then converts binary segmentation to surface (after 6-connecting it) and calls for opfront.
# results are stored on $3

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]
then
    echo Usage: $0 VOLUME_FILE INITIAL_SEGMENTATION_FILE OUTPUT_FOLDER ADD_LIBRARIES_PATH OPFRONT_PARAMETERS
    exit 1
fi

# INDPUT PARAMETERS
VOL=$1
SEG=$2
FOLDEROUT=$3

# capture all remainign aprameters
OPFRONT_PARAMETERS=${@:4:$#} # (e.g.: "-i 15 -o 15 -I 2 -O 2 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0")

# PUT HERE THE PATH TO THE COMPILED EXECUTABLES FROM OPFRONT-PLAYGROUND
BINARY_DIR="/usr/local/bin"

# get the root of the name without extension
FILE=$(basename "${VOL}")
FILE_NO_EXTENSION="${FILE%.*.*}"
ROOT="${FOLDEROUT}/${FILE_NO_EXTENSION}"

# NAMES for all generated files
SEG_CON6="${ROOT}-seg-6con.nii.gz" # Initial segmentaiton after 6-connexion
SEG_SURFACE="${ROOT}-seg.gts" # Initial segmentaitno after 6-conexion as a surface

INNER_SURFACE="${ROOT}surface0.gts" # Converted results from opfront, DO NOT EDIT.
OUTER_SURFACE="${ROOT}surface1.gts"

INNER_VOL="${ROOT}_surface0.nii.gz" # Results from opfront, original sizes
OUTER_VOL="${ROOT}_surface1.nii.gz"

INNER_VOL_TH14="${ROOT}_surface0_th14.nii.gz"
OUTER_VOL_TH14="${ROOT}_surface1_th14.nii.gz"

# INNER_VOL_ISO="${ROOT}_surface0_iso05.nii.gz" # Results from opfront, converted to isotropic volumes.
INNER_VOL_TH1="${ROOT}_surface0_th1.nii.gz"

BRANCHES_ISO="${ROOT}_surface0_th1-branch.brh" # Results of computing branches, DO NOT EDIT
BRANCHES="${ROOT}_airways.brh"

INNER_RESULTS="${ROOT}_inner.csv"
OUTER_RESULTS="${ROOT}_outer.csv"
INNER_RESULTS_LOCAL="${ROOT}_inner_localRadius.csv"
OUTER_RESULTS_LOCAL="${ROOT}_outer_localRadius.csv"

BRANCHES_VOL="${ROOT}_airways_centrelines.nii.gz"
BRANCHES_MATLAB="${ROOT}_airways_centrelines.m"

# Smoothed branches
BRANCHES_ISO_CONNECTED="${ROOT}_surface0_iso05_th14-branch_connected.brh"
BRANCHES_ISO_SMOOTHED="${ROOT}_surface0_iso05_th14-branch_connected_smoothed.brh"
BRANCHES_SMOOTHED="${ROOT}_airways_smoothed.brh"

INNER_RESULTS_SMOOTHED="${ROOT}_inner_smoothed.csv"
OUTER_RESULTS_SMOOTHED="${ROOT}_outer_smoothed.csv"
INNER_RESULTS_LOCAL_SMOOTHED="${ROOT}_inner_localRadius_smoothed.csv"
OUTER_RESULTS_LOCAL_SMOOTHED="${ROOT}_outer_localRadius_smoothed.csv"

BRANCHES_VOL_SMOOTHED="${ROOT}_airways_centrelines_smoothed.nii.gz"
BRANCHES_MATLAB_SMOOTHED="${ROOT}_airways_centrelines_smoothed.m"

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
CALL="${BINARY_DIR}/img2gts -s $SEG_CON6 -g $SEG_SURFACE"
echo -e "\n$CALL"
eval $CALL

echo -e "\nRunning opfront:"
CALL="${BINARY_DIR}/segwall -v $VOL -s $SEG_SURFACE -p $ROOT $OPFRONT_PARAMETERS"
echo -e "\n$CALL"
eval $CALL

echo -e "\nConverting inner surface to binary with the original spacing (with subsampling):"
CALL="${BINARY_DIR}/gts2img -g $INNER_SURFACE -s $INNER_VOL -v $VOL -u 3"
echo -e "\n$CALL"
eval $CALL

echo -e "\nConverting outer surface to binary with the original spacing (with subsampling):"
CALL="${BINARY_DIR}/gts2img -g $OUTER_SURFACE -s $OUTER_VOL -v $VOL -u 3"
echo -e "\n$CALL"
eval $CALL

# echo -e "\nConverting inner surface to 0.5mm isotropic voxels: [-i 0.5 NOT PRESENT IN NEW VERSION OF TOOL]"
# CALL="${BINARY_DIR}/gts2img -g $INNER_SURFACE -s $INNER_VOL_ISO -v $VOL -u 3"
# echo -e "\n$CALL"
# eval $CALL

echo -e "\nBinarising isotropic inner surface with threshold 1 for branch extraction:"
CALL="${BINARY_DIR}/imgconv -i $INNER_VOL -o $INNER_VOL_TH1 -t 0 -x 1"
echo -e "\n$CALL"
eval $CALL

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
#CALL="rm $SEG_CON6 $SEG_SURFACE $INNER_VOL_ISO $INNER_VOL_ISO_TH1 $BRANCHES_ISO $BRANCHES_ISO_SMOOTHED"
CALL="rm $SEG_CON6 $SEG_SURFACE $INNER_VOL_TH1"
echo -e "\n$CALL"
eval $CALL

