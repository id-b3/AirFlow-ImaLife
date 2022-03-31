#!/bin/bash

# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUT_DIR=${1}
VOL_FILE=${2}
VOL_NO_EXTENSION="${VOL_FILE%.*}"
OUTPUTFOLDER=${3}
LOGFILE=${4:-${OUTPUTFOLDER}/PROCESS_LOG.log}
OUTBASENAME=${OUTPUTFOLDER}/${VOL_NO_EXTENSION}

mkdir -p /eureka/input/series-in/
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
    INPUTFILE="${DESTIMG}/${VOL_FILE}"
    python /bronchinet/scripts/processing_scripts/get_date.py "${INPUTFILE}" "${OUTBASENAME}"_date.txt
    vol_size=$(wc -c <"$INPUTFILE")
    if [ $vol_size -ge 100000000 ]; then
      echo "SUCCESS CREATING DICOM VOLUME"
    else
      echo "CREATED VOLUME TOO SMALL $vol_size"
      echo "Check if all slices downloaded. Aborting."
    exit 1
    fi
fi

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
        if [ "$AIR_VOL" -gt 21000 ]
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
        if [ "$L_THRESHOLD" -le 700 ]; then
            echo "Total failure of scan to segment lungs and coarse airways."
            exit 1
        fi
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
/bronchinet/scripts/processing_scripts/prepare_coarse_airway.sh $DESTAIR
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

  echo '-------------------------'
  echo 'Predict Segmentation.....'
  echo '-------------------------'
  PRED_DONE=1
  while [ "$PRED_DONE" -eq 1 ]; do
    while [ "$free_mem" -lt 7800 ]; do
      echo '*-*-*-*-*-* Waiting for GPU to be free... *-*-*-*-*-*'
      sleep $((1 + $RANDOM % 15))
      free_mem=$(nvidia-smi --query-gpu=memory.free --format=csv | grep -Eo [0-9]+)
    done
    echo "*-*-*-*-*-* GPU is free with ${free_mem} *-*-*-*-*-*"
    python Code/scripts_experiments/predict_model.py --basedir=/temp_work --testing_datadir=TestingData --is_backward_compat=False --name_output_predictions_relpath=${POSWRKDIR} --name_output_reference_keys_file=${KEYFILE} ${MODELFILE}
    PRED_DONE=$?
    if [ $PRED_DONE -eq 1 ]; then
        echo "Prediction failed, likely due to GPU not free. Retrying..."
    fi
  done

  echo '-------------------------'
  echo 'Post-process Segmentation'
  echo '-------------------------'
  python Code/scripts_evalresults/postprocess_predictions.py --basedir=/temp_work --name_input_predictions_relpath=${POSWRKDIR} --name_output_posteriors_relpath=${POSDIR} --name_input_reference_keys_file=${KEYFILE}
  thumbnail -s ${POSDIR}/*.nii.gz -o ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_unet_thumbnail.bmp
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

/bronchinet/scripts/opfront_scripts/opfront_repeat_scan.sh ${NIFTIIMG}/*.nii.gz ${SEGDIR}/*.nii.gz "${OUTPUTFOLDER}" "-i 50 -o 50 -I 7 -O 7 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.4 -G -0.6 -C 2"
if [ $? -eq 1 ]
then
  echo "${VOL_NO_EXTENSION} failed opfront step." >> "$LOGFILE"
  echo "Failed opfront"
  rm -r ${DATADIR}
  rm -r "${SEGDIR}"
  exit $?
else
{
    echo "\nSuccess with opfront steps. Final computations and cleanup..."
  thumbnail -s ${OUTPUTFOLDER}/*_surface0.nii.gz -o ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_thumbnail.bmp
  thumbnail -s ${OUTPUTFOLDER}/*nii-branch.nii.gz -o ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_thumbnail_iso.bmp
  measure_volume -s ${OUTPUTFOLDER}/*_surface1.nii.gz -v ${NIFTIIMG}/*.nii.gz >> ${OUTPUTFOLDER}/airway_volume.txt
  # Process the GTS files into obj files for easy 3D model use.
  gts2stl < ${OUTPUTFOLDER}/*surface0.gts > ${OUTBASENAME}_lumen.stl
  gts2stl < ${OUTPUTFOLDER}/*surface1.gts > ${OUTBASENAME}_wall.stl
  admesh ${OUTBASENAME}_lumen.stl -b ${OUTBASENAME}_lumen.stl
  admesh ${OUTBASENAME}_wall.stl -b ${OUTBASENAME}_wall.stl
  ctmconv ${OUTBASENAME}_wall.stl ${OUTBASENAME}_wall.obj
  ctmconv ${OUTBASENAME}_lumen.stl ${OUTBASENAME}_lumen.obj
  # Create a mask segmentation
  python /bronchinet/scripts/processing_scripts/subtract_masks.py ${OUTPUTFOLDER}/*surface1.nii.gz ${OUTPUTFOLDER}/*surface0.nii.gz ${OUTPUTFOLDER}
  # Measure the bronchial parameters
  python /bronchinet/airway_analysis/airway_summary.py ${NIFTIIMG}/*.nii.gz --inner_csv "${OUTPUTFOLDER}"/*_inner.csv --inner_rad_csv "${OUTPUTFOLDER}"/*_inner_localRadius_pandas.csv --outer_csv "${OUTPUTFOLDER}"/*_outer.csv --outer_rad_csv "${OUTPUTFOLDER}"/*_outer_localRadius_pandas.csv --branch_csv "${OUTPUTFOLDER}"/*_airways_centrelines.csv --output "${OUTPUTFOLDER}" --name "${VOL_NO_EXTENSION}"

  # Delete unnecessary output files
  find ${OUTPUTFOLDER} -type f -name "*.mm" -delete
  find ${OUTPUTFOLDER} -type f -name "*-seg*" -delete
  find ${OUTPUTFOLDER} -type f -name "*.stl" -delete
  find ${OUTPUTFOLDER} -type f -name "*.col" -delete
  find ${OUTPUTFOLDER} -type f -name "*filled*" -delete
  find ${OUTPUTFOLDER} -type f -name "*surface0_iso*" -delete
  rm ${OUTPUTFOLDER}/${VOL_FILE}
  find ${OUTPUTFOLDER} -type f -name "*.gts" -delete
  find ${OUTPUTFOLDER} -type f -name "*.stl" -delete
  find ${OUTPUTFOLDER} -type f -name "*.brh" -delete
  find ${OUTPUTFOLDER} -type f -name "*localRadius.csv" -delete
  cp -r ${DESTLUNG}/* ${OUTBASENAME}_initial/
  cp -r ${DESTAIR}/* ${OUTBASENAME}_initial/
  cp ${NIFTIIMG}/*.nii.gz ${OUTBASENAME}_initial/${VOL_NO_EXTENSION}.nii.gz
  rm -r ${OUTBASENAME}_initial/
  tar cszf intermediate-files.tar.gz *.obj *.csv *.nii.gz *.log
  echo '-------------------------'
echo 'CLEANING UP..............'
echo '-------------------------'
rm -r ${DATADIR}
rm -r "${SEGDIR}"
} >> "$LOGFILE"
fi


