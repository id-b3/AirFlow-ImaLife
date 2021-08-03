#!/bin/bash
# Created by Antonio:
# Compute measurements on given airway lumen and outer wall segmentations. Receives original volume ($1) and input surface segmentations '.dcm' ($2, $3). Results are stored in ($4).
# Added by Antonio: export paths to missing libraries needed by executables in ($5)
# Modified by Ivan: Work with docker and newer opfront tools.

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]; then
  echo Usage: "$0" VOLUME_FILE INIT_VOL_INNER_FILE INIT_VOL_OUTER_FILE OUTPUT_FOLDER
  exit 1
fi

# INDPUT PARAMETERS
VOL=$1
INNER_VOL=$2
OUTER_VOL=$3
FOLDEROUT=$4

# PUT HERE THE PATH TO THE COMPILED EXECUTABLES FROM OPFRONT-PLAYGROUND
BINARY_DIR="/usr/local/bin/"

# Location of python scripts
PYTHON_SCR="/bronchinet/scripts/util"

# get the root of the name without extension
FILE=$(basename "${VOL}")
FILE_NO_EXTENSION="${FILE%%.*}"
ROOT="${FOLDEROUT}/${FILE_NO_EXTENSION}"
FILE=$(basename "${INNER_VOL}")
FILE_NO_EXTENSION="${FILE%%.*}"
ROOT_INNER_VOL="${FOLDEROUT}/${FILE_NO_EXTENSION}"
FILE=$(basename "${OUTER_VOL}")
FILE_NO_EXTENSION="${FILE%%.*}"
ROOT_OUTER_VOL="${FOLDEROUT}/${FILE_NO_EXTENSION}"

INNER_SURFACE="${ROOT_INNER_VOL}.gts" # Initial segmentation after 6-conexion as a surface
INNER_VOL_ISO="${ROOT_INNER_VOL}_iso.nii.gz" #Thresholding the opfront result to 0/1
OUTER_SURFACE="${ROOT_OUTER_VOL}.gts"

BRANCHES_ISO="${ROOT_INNER_VOL}_iso.nii-branch.brh" # Results of computing branches, DO NOT EDIT
BRANCHES="${ROOT}_airways.brh"

INNER_RESULTS="${ROOT}_inner.csv"
OUTER_RESULTS="${ROOT}_outer.csv"
INNER_RESULTS_LOCAL="${ROOT}_inner_localRadius.csv"
OUTER_RESULTS_LOCAL="${ROOT}_outer_localRadius.csv"
INNER_RESULTS_PANDAS="${ROOT}_inner_local_pandas.csv"
OUTER_RESULTS_PANDAS="${ROOT}_outer_local_pandas.csv"

BRANCHES_PANDAS="${ROOT}_airways_centrelines.csv"

LOGFILE="${ROOT}.log"


mkdir -p "$FOLDEROUT"
{
  echo -e "\n *** ${FILE_NO_EXTENSION} ***\n"
  echo -e "Volume: $VOL"
  echo -e "Inner Surface: $INNER_VOL"
  echo -e "Outer Surface: $OUTER_VOL"
  echo -e "Branches Iso: $BRANCHES_ISO"
  echo -e "Results folder: $FOLDEROUT\n"
} >> "$LOGFILE"
# ------------------------------------------------ EXECUTION STEPS ---------------------------------------

{
  echo -e "\nCreating mesh surface using marching cubes: inner surface"

  CALL="${BINARY_DIR}/img2gts -s $INNER_VOL -g $INNER_SURFACE"
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\nCreating mesh surface using marching cubes: outer surface"

  CALL="${BINARY_DIR}/img2gts -s $OUTER_VOL -g $OUTER_SURFACE"
  echo -e "\n$CALL"
  eval "$CALL"

  # -- BRANCHES ----------------------------------
  echo -e "\nComputing branches:"                          # this creates $BRANCHES_ISO
  CALL="${BINARY_DIR}/be $INNER_VOL_ISO -o $FOLDEROUT" # -vessels added (or use of OUTTER_VOL_ISO_TH14) for >1 iterations in the opfront (to allow for disconnectivity)
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\nRescaling branches to original scaling:" # this creates $BRANCHES_ISO
  CALL="${BINARY_DIR}/scale_branch -f $INNER_VOL_ISO -t $VOL -b $BRANCHES_ISO -o $BRANCHES"
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\nMeasure inner surface:"
  CALL="${BINARY_DIR}/gts_ray_measure -g $INNER_SURFACE -v $VOL -b $BRANCHES -o $INNER_RESULTS -l $INNER_RESULTS_LOCAL -p $INNER_RESULTS_PANDAS"
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\nMeasure outer surface:"
  CALL="${BINARY_DIR}/gts_ray_measure -g $OUTER_SURFACE -v $VOL -b $BRANCHES -o $OUTER_RESULTS -l $OUTER_RESULTS_LOCAL -p $OUTER_RESULTS_PANDAS"
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\n\nConvert branches to pandas readable format:"
  CALL="${BINARY_DIR}/brh_translator $BRANCHES -pandas $BRANCHES_PANDAS"
  echo -e "\n$CALL"
  echo -e "DONE\n"
  eval "$CALL"

  # -- CLEAN UNNECESSARY FILES
  echo -e "\nClean unnecessary files:"
  CALL="rm $INNER_VOL_ISO $BRANCHES_ISO"
  echo -e "\n$CALL"
  eval "$CALL"
} >> "$LOGFILE"
