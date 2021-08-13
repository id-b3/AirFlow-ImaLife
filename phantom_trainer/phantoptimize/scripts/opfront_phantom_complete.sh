#!/bin/bash
# script to compute the measurements from opfront segmentation of phantom COPDgene.
#   - need to split the opfronted phantom into as many files as regions in phantom, measure the branches separately in each file, and then merge them together.
# receives original volume ($1) and initial segmentation ($2), and then outputs in ($3) the measurements of branches lumen and outer wall.

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]
then
    echo Usage: "$0" VOLUME_FILE_NIFTI INITIAL_SEGMENTATION_FILE OUTPUT_FOLDER OPFRONT_PARAMETERS
    exit 1
fi

# INPUT PARAMETERS
VOL=$1
SEG=$2
FOLDEROUT=$3

# capture all remainign aprameters
OPFRONT_PARAMETERS=${*:4:$#} # (e.g.: "-i 15 -o 15 -I 2 -O 2 -d 6.8 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.41 -G -0.57")

# PUT HERE THE PATH TO THE COMPILED EXECUTABLES FROM OPFRONT-PLAYGROUND
BINARY_DIR="/usr/local/bin"
# Location of python scripts
PYTHON_SCR_DIR="/bronchinet/airway_analysis/util_scripts"
PYTHON_SCR_PHANTOM_DIR="/bronchinet/phantom_trainer/phantoptimize/split"

# get the root of the name without extension
FILE=$(basename "${SEG}")
FILE_NO_EXTENSION="${FILE%%.*}"
ROOT="${FOLDEROUT}/${FILE_NO_EXTENSION}"
LOGFILE="${ROOT}.log"

# NAMES for all generated files
SEG_CON6="${ROOT}_seg-6con.nii.gz"            # Initial segmentation after 6-connexion
SEG_SURFACE="${ROOT}_seg.gts"                 # Initial segmentation after 6-conexion as a surface

INNER_SURFACE="${ROOT}surface0.gts"           # Converted results from opfront
OUTER_SURFACE="${ROOT}surface1.gts"

INNER_VOL="${ROOT}_surface0.nii.gz"           # Results from opfront, original sizes
INNER_VOL_ISO="${ROOT}_surface0_iso05.nii.gz" # Results from opfront, rescaled to isometric resolution
OUTER_VOL="${ROOT}_surface1.nii.gz"

BRANCHES="${ROOT}_airways.brh"                # Results of computing branches
BRANCHES_ISO="${ROOT}_surface0_iso05_branch.brh"
BRANCHES_VOL_ISO="${ROOT}_surface0_iso05_branch.nii.gz"

INNER_RESULTS="${ROOT}_inner.csv"             # Branch measurements (both lumen and outer wall)
OUTER_RESULTS="${ROOT}_outer.csv"
INNER_RESULTS_LOCAL="${ROOT}_inner_localRadius.csv"
OUTER_RESULTS_LOCAL="${ROOT}_outer_localRadius.csv"
INNER_RESULTS_PANDAS="${ROOT}_inner_local_pandas.csv"
OUTER_RESULTS_PANDAS="${ROOT}_outer_local_pandas.csv"

BRANCHES_PANDAS="${ROOT}_airways_centrelines.csv" # Branch centerline measurements
BRANCHES_ISO_PANDAS="${ROOT}_airways_centrelines_ISO.csv"

FOLDER_VOLS_REGIONS="${ROOT}_regions/"         # Temporary dir with split phantom in regions
VOL_REGIONS_BOXES="${FOLDER_VOLS_REGIONS}/boundboxes_regions_phantom.pkl"

mkdir -p "$FOLDEROUT"

{
  echo -e "\n Starting Phantom Opfront..."
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

  echo -e "\nConverting outer surface to binary with the original spacing (with subsampling):"
  CALL="${BINARY_DIR}/gts2img -g $OUTER_SURFACE -s $OUTER_VOL -v $VOL -u 3"
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\nScaling Inner surface to isometric voxels of 0.5 0.5 0.5:"
  CALL="python ${PYTHON_SCR_DIR}/rescale_image.py -i $INNER_VOL -o $INNER_VOL_ISO -r 0.5 0.5 0.5 --is_binary True"
  echo -e "\n$CALL"
  eval "$CALL"
} >> "$LOGFILE"
# ------------------------------------------------ SPLIT PHANTOM SEGMENTATION ---------------------------------------
{
  mkdir -p "$FOLDER_VOLS_REGIONS"

  echo -e "\nCompute coordinates of bounding-boxes of regions in phantom:"
  CALL="python ${PYTHON_SCR_PHANTOM_DIR}/calc_boundbox_regions.py -i $INNER_VOL_ISO -o $BOXES_REGIONS"
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\nSplit the segmentation in 8 regions present in the COPDgene phantom:"
  CALL="python ${PYTHON_SCR_PHANTOM_DIR}/split_segmentation_regions.py -i $INNER_VOL_ISO -ib $BOXES_REGIONS -o $FOLDER_VOLS_REGIONS"
  echo -e "\n$CALL"
  eval "$CALL"
} >> "$LOGFILE"
# ------------------------------------------------ BRANCH EXTRACTOR STEPS ---------------------------------------
{
  LIST_VOLS_REGIONS_ISO=$(find $FOLDER_VOLS_REGIONS -type f -name "*.nii.gz")

  count=1
  for VOL_REGION_ISO in $LIST_VOLS_REGIONS_ISO
  do
    echo -e "\nComputing branches, for region ${count}:"
    CALL="${BINARY_DIR}/be $VOL_REGION_ISO -o $FOLDER_VOLS_REGIONS"
    echo -e "\n$CALL"
    eval "$CALL"

    ROOL_VOL_REGION_ISO="${VOL_REGION_ISO%.nii.gz}"

    echo -e "\nRename output branch files (solve issue with nifti file extension), for region ${count}:"
    CALL="mv ${ROOL_VOL_REGION_ISO}.nii-branch.brh ${ROOL_VOL_REGION_ISO}-branch.brh && mv ${ROOL_VOL_REGION_ISO}.nii-branch.nii.gz ${ROOL_VOL_REGION_ISO}-branch.nii.gz"
    echo -e "\n$CALL"
    eval "$CALL"

    count=$((count+1))
  done
} >> "$LOGFILE"
# ------------------------------------------------ MERGE BRANCHES FROM BRANCH EXTRACTOR ---------------------------------------
{
  echo -e "\nMerge the branches extracted in every region in phantom:"
  CALL="python ${PYTHON_SCR_PHANTOM_DIR}/merge_branches_regions.py -i $FOLDER_VOLS_REGIONS -o $BRANCHES_ISO --is_merge_vols=True -ib $BOXES_REGIONS -ov $BRANCHES_VOL_ISO"
  echo -e "\n$CALL"
  eval "$CALL"

  echo -e "\nRemove the temp branch data in regions in phantom:"
  CALL="rm -r ${FOLDER_VOLS_REGIONS}"
  echo -e "\n$CALL"
  eval "$CALL"
} >> "$LOGFILE"
# ------------------------------------------------ EXECUTION STEPS ---------------------------------------
{
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
  eval "$CALL"
  CALL="${BINARY_DIR}/brh_translator $BRANCHES_ISO -pandas $BRANCHES_ISO_PANDAS"
  echo -e "\n$CALL"
  echo -e "DONE\n"
  eval "$CALL"
} >> "$LOGFILE"
