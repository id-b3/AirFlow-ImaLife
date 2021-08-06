#!/bin/bash

# INPUT PARAMETERS
IN_SEGMEN_FILE="./Initial/COPDGene_Phantom_Qr59_Lumen.nii.gz"
IN_BOUNDBOXES_FILE="./boundboxes_regions_phantom.pkl"
OUT_SEGMEN_REGIONS_DIR="."

CODEDIR="/home/antonio/Codes/Air_Flow_ImaLife/phantom_trainer/phantoptimize/split/"
SCRIPT_CALC_BOUBOXES="${CODEDIR}/calc_boundbox_regions.py"
SCRIPT_SPLIT_SEGMEN="${CODEDIR}/split_segmentation_regions.py"

mkdir -p $OUT_SEGMEN_REGIONS_DIR


echo -e "\n Starting Test..."

echo -e "\nCompute the coordinates of bounding-boxes of every region in COPDgene phantom:"
CALL="python3 ${SCRIPT_CALC_BOUBOXES} -i ${IN_SEGMEN_FILE} -o ${IN_BOUNDBOXES_FILE}"
echo -e "\n$CALL"
eval "$CALL"

echo -e "\nSplit the segmentation in 8 regions present in the COPDgene phantom:"
CALL="python3 ${SCRIPT_SPLIT_SEGMEN} -i ${IN_SEGMEN_FILE} -ib ${IN_BOUNDBOXES_FILE} -o ${OUT_SEGMEN_REGIONS_DIR}"
echo -e "\n$CALL"
eval "$CALL"
