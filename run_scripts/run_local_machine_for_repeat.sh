#!/bin/bash

# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUT_DIR=${1}
VOL_FILE=${2}
VOL_NO_EXTENSION="${VOL_FILE%.*}"
OUTPUTFOLDER=${3}
LOGFILE=${4:-${OUTPUTFOLDER}/PROCESS_LOG.log}

#mkdir -p /eureka/input/dicom-series-in/
#CALL="python /bronchinet/airway_analysis/util_scripts/fix_transfer_syntax.py ${INPUT_DIR} ${INPUTFILE}"
#eval "$CALL"

echo "Input File: ${VOL_FILE}"
echo "Output Folder: ${3}"

DATADIR=/temp_work/processing
DESTAIR=${DATADIR}/CoarseAirways
DESTLUNG=${DATADIR}/Lungs
DESTIMG=${DATADIR}/RAW/DICOM
NIFTIIMG=${DATADIR}/Images

MODELFILE=/bronchinet/model/model_imalife.pt

# RESULTS DIRS
RESDIR=/temp_work/results
SEGDIR=${RESDIR}/${VOL_NO_EXTENSION}
POSWRKDIR=${RESDIR}/PosteriorsWorkData
POSDIR=${RESDIR}/Posteriors
KEYFILE=${RESDIR}/referenceKeys_posteriors.npy

echo "Running Lung Segmentation. Destination folder $DESTLUNG"
echo "-------------------------------------------------------"

mkdir -p $DESTAIR
mkdir -p $DESTLUNG
mkdir -p $DESTIMG
mkdir -p "$SEGDIR"
mkdir -p "${OUTPUTFOLDER}"
mkdir -p /temp_work/processing/Airways

echo "Converting slices into volume..."
CALL="volume_maker ${INPUT_DIR} $DESTIMG -manual_name ${VOL_FILE}"
echo "$CALL"
eval "$CALL"

if [ $? -eq 1 ]
then
  echo "Failed to create DICOM volume"
  rm -r $DATADIR
  rm -r $RESDIR
  rm -r "$SEGDIR"
  echo "${VOL_NO_EXTENSION} failed." >> "$LOGFILE"
  exit $?
else
  echo "SUCCESS CREATING DICOM VOLUME"
fi

INPUTFILE="${DESTIMG}/${VOL_FILE}"
cp "$INPUTFILE" "${OUTPUTFOLDER}"

cd /temp_work || exit
ln -s /bronchinet/src Code
ln -s /temp_work/processing BaseData

segment_lungs() {
	CALL="lung_segmentation --verbose false --source $INPUTFILE --skip_distance 30 --min_intensity -1048 --airway_threshold -${1} --scan bottom --savepath $DESTLUNG"
	echo "$CALL"
	eval "$CALL"
}

check_lung_vol() {
	LUNG_VOL=$(measure_volume -s $DESTLUNG/*-lungs.dcm -v "$INPUTFILE")
	AIR_VOL=$(measure_volume -s $DESTLUNG/*-airways.dcm -v "$INPUTFILE")
	echo "**************************************************"
	echo "Airway Volume for ${VOL_NO_EXTENSION} is ${AIR_VOL}"
	echo "**************************************************"
    if [ "$LUNG_VOL" -gt 4500000 ]
    then
        if [ "$AIR_VOL" -gt 30000 ]
       	then
            # shellcheck disable=SC2086
            echo $LUNG_VOL > "$OUTPUTFOLDER"/lung_volume.txt
            echo "$AIR_VOL" > "$OUTPUTFOLDER"/air_volume.txt
            echo "Success Segmenting at ${1}"
            return 0
	    else
		    echo "Airway volume too small for Large Lungs, retrying..."
		    return 1
	    fi
    else
        if [ "$AIR_VOL" -gt 25000 ]
       	then
            echo "$LUNG_VOL" > "$OUTPUTFOLDER"/lung_volume.txt
            echo "$AIR_VOL" > "$OUTPUTFOLDER"/air_volume.txt
            echo "Success Segmenting at ${1}"
            return 0
	    else
		    echo "Airway volume too small for Small Lungs, retrying..."
		    return 1
	    fi
    fi
}

LUNG_COMPLETE=1
L_THRESHOLD=800

while [ "$LUNG_COMPLETE" == 1 ]
do
	segment_lungs $L_THRESHOLD
	if [ $? -eq 1 ]
	then
	  echo "Failed to Segment Lungs. Retrying"
	  echo "${VOL_NO_EXTENSION} failed at $L_THRESHOLD threshold." >> "$LOGFILE"
	  echo "Failed to Segment Lungs at $L_THRESHOLD threshold."
	else
	  echo "SUCCESS Segmenting Lungs at $L_THRESHOLD"
	  echo "Checking volumes..."
	  check_lung_vol $L_THRESHOLD
	  LUNG_COMPLETE=$?
	  echo "************ LUNG_COMPLETE $LUNG_COMPLETE *************"
	fi
	if [ "$LUNG_COMPLETE" == 1 ]; then
		((L_THRESHOLD=L_THRESHOLD-10))
	else
		echo "Completed lung segmentation at $L_THRESHOLD"
	fi
done

mkdir -p "${OUTPUTFOLDER}"/"${VOL_NO_EXTENSION}"_initial/
mv $DESTLUNG/*.bmp "${OUTPUTFOLDER}"/"${VOL_NO_EXTENSION}"_initial/
mv $DESTLUNG/*-airways.dcm $DESTAIR/

echo 'PRE-PROCESS COARSE AIRWAYS (PRUNING)'
echo '-----------------------------------'
/bronchinet/scripts/pre-processing_scripts/prepare_coarse_airway.sh $DESTAIR
if [ $? -eq 1 ]
then
    exit $?
fi
thumbnail -s $DESTAIR/*nii.gz -o "$OUTPUTFOLDER"/"$VOL_NO_EXTENSION"_pruned_airways.bmp
echo 'DONE PRUNING COARSE AIRWAYS'
echo '---------------------------'

{
  echo 'CONVERTING DICOM TO NIFTY'
  echo '-------------------------'
  python Code/scripts_util/convert_images_to_nifti.py $DESTIMG $NIFTIIMG
  echo $?

  echo 'Pre-Processing...........'
  echo '-------------------------'
  python Code/scripts_preparedata/compute_boundingbox_images.py --datadir=$DATADIR
  python Code/scripts_preparedata/prepare_data.py --datadir=$DATADIR --is_prepare_labels=False
  echo $?

  echo '-------------------------'
  echo 'Distributing Data........'
  echo '-------------------------'
  python Code/scripts_experiments/distribute_data.py --basedir=/temp_work --type_data=testing --propdata_train_valid_test="(0,0,1)"
  echo $?

# Check if the gpu is free enough to start launch the next scan.
  free_mem=$(nvidia-smi --query-gpu=memory.free --format=csv | grep -Eo [0-9]+)

  while [ "$free_mem" -lt 7000 ]; do
    echo '*-*-*-*-*-* Waiting for GPU to be free... *-*-*-*-*-*'
    sleep $((2 + $RANDOM % 22))
    free_mem=$(nvidia-smi --query-gpu=memory.free --format=csv | grep -Eo [0-9]+)
    echo "*-*-*-*-*-* GPU is free with ${free_mem} *-*-*-*-*-*"
  done

  echo '-------------------------'
  echo 'Predict Segmentation.....'
  echo '-------------------------'
  python Code/scripts_experiments/predict_model.py --basedir=/temp_work --testing_datadir=TestingData --is_backward_compat=False --name_output_predictions_relpath=${POSWRKDIR} --name_output_reference_keys_file=${KEYFILE} ${MODELFILE}
  echo $?

  echo '-------------------------'
  echo 'Post-process Segmentation'
  echo '-------------------------'
  python Code/scripts_evalresults/postprocess_predictions.py --basedir=/temp_work --name_input_predictions_relpath=${POSWRKDIR} --name_output_posteriors_relpath=${POSDIR} --name_input_reference_keys_file=${KEYFILE}
  python Code/scripts_evalresults/process_predicted_airway_tree.py --basedir=/temp_work --name_input_posteriors_relpath=${POSDIR} --name_output_binary_masks_relpath=${SEGDIR}
  echo $?

  echo '-------------------------'
  echo 'CLEAN UP.................'
  echo '-------------------------'
  rm -r ${POSDIR}
  rm -r ${POSWRKDIR}
  rm ${KEYFILE}
} | tee "$LOGFILE"

echo '-------------------------'
echo 'RUNNING OPFRONT..........'
echo '-------------------------'

/bronchinet/scripts/opfront_scripts/opfront_repeat_scan.sh ${NIFTIIMG}/*.nii.gz ${SEGDIR}/*.nii.gz "${OUTPUTFOLDER}" "-i 17 -o 17 -I 7 -O 7 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.58 -G -0.68 -C 2"
if [ $? -eq 1 ]
then
  echo "${VOL_NO_EXTENSION} failed opfront step." >> "$LOGFILE"
  echo "Failed opfront"
  rm -r ${DATADIR}
  rm -r "${SEGDIR}"
  exit $?
else
  find ${OUTPUTFOLDER} -type f -name "*.mm" -delete
  find ${OUTPUTFOLDER} -type f -name "*-seg*" -delete
  find ${OUTPUTFOLDER} -type f -name "*.col" -delete
  find ${OUTPUTFOLDER} -type f -name "*filled*" -delete
  rm ${OUTPUTFOLDER}/${VOL_FILE}
  measure_volume -s ${OUTPUTFOLDER}/*_surface1.nii.gz -v ${NIFTIIMG}/*.nii.gz >> ${OUTPUTFOLDER}/airway_volume.txt
  thumbnail -s ${OUTPUTFOLDER}/*_surface0.nii.gz -o ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_thumbnail.bmp
  thumbnail -s ${OUTPUTFOLDER}/*nii-branch.nii.gz -o ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_thumbnail_iso.bmp
  cp -r ${DESTLUNG}/* ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_initial/
  cp -r ${DESTAIR}/* ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_initial/
  cp ${NIFTIIMG}/*.nii.gz ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_initial/${VOL_NO_EXTENSION}.nii.gz
  python /bronchinet/airway_analysis/airway_summary.py ${NIFTIIMG}/*.nii.gz --inner_csv "${OUTPUTFOLDER}"/*_inner.csv --inner_rad_csv "${OUTPUTFOLDER}"/*_inner_localRadius_pandas.csv --outer_csv "${OUTPUTFOLDER}"/*_outer.csv --outer_rad_csv "${OUTPUTFOLDER}"/*_outer_localRadius_pandas.csv --branch_csv "${OUTPUTFOLDER}"/*_airways_centrelines.csv --output "${OUTPUTFOLDER}" --name "${VOL_NO_EXTENSION}"
fi

echo '-------------------------'
echo 'CLEANING UP..............'
echo '-------------------------'
rm -r ${DATADIR}
rm -r "${SEGDIR}"
