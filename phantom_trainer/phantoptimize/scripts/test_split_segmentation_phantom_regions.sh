#!/bin/bash

# INPUT PARAMETERS
IN_VOLSEG="./Initial/COPDGene_Phantom_Qr59_Lumen.nii.gz"
OUT_DIR="./phantom_split/"
IN_VOLSEG_ISO="${OUT_DIR}/COPDGene_Phantom_Qr59_Lumen_iso.nii.gz"
IN_VOLSEG_BOXES="${OUT_DIR}/boundboxes_regions_phantom.pkl"

CODEDIR="/home/antonio/Codes/Air_Flow_ImaLife/"
SCR_RESCALE="${CODEDIR}/airway_analysis/util_scripts/rescale_image.py"
SCR_CALC_BOXES="${CODEDIR}/phantom_trainer/phantoptimize/split/calc_boundbox_regions.py"
SCR_SPLIT_SEG="${CODEDIR}/phantom_trainer/phantoptimize/split/split_segmentation_regions.py"

mkdir -p $OUT_DIR

echo -e "\n Starting Test..."

echo -e "\nRescale input surface to isometric resolution of 0.5, 0.5, 0.5:"
CALL="python3 ${SCR_RESCALE} -i $IN_VOLSEG -o $IN_VOLSEG_ISO -r 0.5 0.5 0.5 --is_binary True"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nCompute coordinates of bounding-boxes of every region in phantom:"
CALL="python3 ${SCR_CALC_BOXES} -i $IN_VOLSEG_ISO -o $IN_VOLSEG_BOXES"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nSplit segmentation in 8 regions in phantom:"
CALL="python3 ${SCR_SPLIT_SEG} -i $IN_VOLSEG_ISO -ib $IN_VOLSEG_BOXES -o $OUT_DIR"
echo -e "\n$CALL"
eval "$CALL"
