#!/bin/bash
# receives original volume ($1) and initial segmentation ($2), and then converts binary segmentation to surface (after 6-connecting it) and calls for opfront.
# results are stored on $3

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]
then
    echo Usage: "$0" VOLUME_FILE_DICOM VOLUME_FILE_NIFTI INITIAL_SEGMENTATION_FILE OUTPUT_FOLDER OPFRONT_PARAMETERS
    echo e.g. default opfront params: -i 15 -o 15 -I 2 -O 2 -d 6.8 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.41 -G -0.57
    exit 1
fi

# INDPUT PARAMETERS
VOL_DICOM=$1
VOL=$2
SEG=$3
FOLDEROUT=$4

# capture all remainign aprameters
OPFRONT_PARAMETERS=${*:5:$#} # eg. "-i 15 -o 15 -I 2 -O 2 -d 6.8 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.41 -G -0.57"

# PUT HERE THE PATH TO THE COMPILED EXECUTABLES FROM OPFRONT-PLAYGROUND
BINARY_DIR="/usr/local/bin"

# get the root of the name without extension
FILE=$(basename "${VOL}")
FILE_NO_EXTENSION="${FILE%.*.*}"
ROOT="${FOLDEROUT}/${FILE_NO_EXTENSION}"
LOGFILE="${ROOT}.log" # Process Log File

# NAMES for all generated files
SEG_CON6="${ROOT}-seg-6con.nii.gz" # Initial segmentaiton after 6-connexion
SEG_SURFACE="${ROOT}-seg.gts" # Initial segmentaitno after 6-conexion as a surface

INNER_SURFACE="${ROOT}surface0.gts" # Converted results from opfront, DO NOT EDIT.
OUTER_SURFACE="${ROOT}surface1.gts"

INNER_VOL="${ROOT}_surface0.nii.gz" # Results from opfront, original sizes
OUTER_VOL="${ROOT}_surface1.nii.gz"

INNER_VOL_TH1="${ROOT}_surface0_th1.nii.gz" #Thresholding the opfront result to 0/1

BRANCHES_ISO="${ROOT}_surface0_th1.nii-branch.brh" # Results of computing branches, DO NOT EDIT
BRANCHES="${ROOT}_airways.brh"

INNER_RESULTS="${ROOT}_inner.csv"
OUTER_RESULTS="${ROOT}_outer.csv"
INNER_RESULTS_LOCAL="${ROOT}_inner_localRadius.csv"
OUTER_RESULTS_LOCAL="${ROOT}_outer_localRadius.csv"
INNER_RESULTS_LOCAL_PANDAS="${ROOT}_inner_localRadius_pandas.csv"
OUTER_RESULTS_LOCAL_PANDAS="${ROOT}_outer_localRadius_pandas.csv"

BRANCHES_PANDAS="${ROOT}_airways_centrelines.csv"

mkdir -p "$FOLDEROUT"

{
  echo -e "\n *** ${FILE_NO_EXTENSION} ***\n"
  echo -e "Volume: $VOL"
  echo -e "Segmentation: $SEG"
  echo -e "Opfront parameters: $OPFRONT_PARAMETERS"
  echo -e "Results folder: $FOLDEROUT\n"
  echo -e "File without extension: $FILE_NO_EXTENSION\n"
} | tee "$LOGFILE"
# ------------------------------------------------ EXECUTION STEPS ---------------------------------------

{
echo -e "\n6-connecting initial surface:"
CALL="${BINARY_DIR}/6con $SEG $SEG_CON6"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nCreating mesh surface using marching cubes:"
CALL="${BINARY_DIR}/img2gts -s $SEG_CON6 -d short -g $SEG_SURFACE"
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

echo -e "\nConverting outer surface to binary with the original spacing (with subsampling):"
CALL="${BINARY_DIR}/gts2img -g $OUTER_SURFACE -s $OUTER_VOL -v $VOL -u 3"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nBinarising isotropic inner surface with threshold 1 for branch extraction:"
CALL="${BINARY_DIR}/imgconv -i $INNER_VOL -o $INNER_VOL_TH1 -t 0 -x 1"
echo -e "\n$CALL"
eval "$CALL"

# -- BRANCHES ----------------------------------
echo -e "\nComputing branches:" # this creates $BRANCHES_ISO
CALL="${BINARY_DIR}/be $INNER_VOL_TH1 -v $VOL -o $FOLDEROUT"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nRenaming Branches File:"
CALL="mv $BRANCHES_ISO $BRANCHES"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nMeasure inner surface:"
CALL="${BINARY_DIR}/gts_ray_measure -g $INNER_SURFACE -v $VOL_DICOM -b $BRANCHES -o $INNER_RESULTS -l $INNER_RESULTS_LOCAL -p $INNER_RESULTS_LOCAL_PANDAS"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nMeasure outer surface:"
CALL="${BINARY_DIR}/gts_ray_measure -g $OUTER_SURFACE -v $VOL_DICOM -b $BRANCHES -o $OUTER_RESULTS -l $OUTER_RESULTS_LOCAL -p $OUTER_RESULTS_LOCAL_PANDAS"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\n\nConvert branches to MATLAB readable format:"
CALL="${BINARY_DIR}/brh_translator $BRANCHES $BRANCHES_PANDAS -pandas"
echo -e "\n$CALL"
echo -e "DONE\n"
eval "$CALL"
} | tee "$LOGFILE"