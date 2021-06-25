#!/bin/bash
# receives original volume ($1) and initial segmentation ($2), and then converts binary segmentation to surface (after 6-connecting it) and calls for opfront.
# results are stored on $3

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]
then
    echo Usage: "$0" VOLUME_FILE_NIFTI INITIAL_SEGMENTATION_FILE OUTPUT_FOLDER
    exit 1
fi

# INDPUT PARAMETERS
VOL=$1
FOLDEROUT=$3

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

# INNER_VOL_ISO="${ROOT}_surface0_iso05.nii.gz" # Results from opfront, converted to isotropic volumes.
INNER_VOL_TH1="${ROOT}_surface0_th1.nii.gz"

BRANCHES_ISO="${ROOT}_surface0_th1.nii-branch.brh" # Results of computing branches, DO NOT EDIT
BRANCHES="${ROOT}_airways.brh"

INNER_RESULTS="${ROOT}_inner.csv"
OUTER_RESULTS="${ROOT}_outer.csv"
INNER_RESULTS_LOCAL="${ROOT}_inner_localRadius.csv"
OUTER_RESULTS_LOCAL="${ROOT}_outer_localRadius.csv"
INNER_RESULTS_LOCAL_PANDAS="${ROOT}_inner_localRadius_pandas.csv"
OUTER_RESULTS_LOCAL_PANDAS="${ROOT}_outer_localRadius_pandas.csv"

BRANCHES_VOL="${ROOT}_airways_centrelines.nii.gz"
BRANCHES_PANDAS="${ROOT}_airways_centrelines.csv"