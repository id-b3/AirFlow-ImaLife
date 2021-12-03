#!/bin/bash

# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUT_DIR=${1}
VOL_FILE=${2}
VOL_NO_EXTENSION="${VOL_FILE%.*}"
OUTPUTFOLDER=${3}
LOGFILE=${4:-./PROCESS_LOG.log}

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

CALL="lung_segmentation --verbose true --source $INPUTFILE --skip_distance 10 --min_intensity -1048 --airway_threshold -800 --scan bottom --savepath $DESTLUNG"
echo "$CALL"

if ! $CALL
then
  echo "Failed to Segment Lungs"
  rm -r $RESDIR
  rm -r $DATADIR
  rm -r "$SEGDIR"
  echo "${VOL_NO_EXTENSION} failed." >> "$LOGFILE"
  exit $?
else
  echo "SUCCESS Segmenting Lungs"
fi

mkdir -p "${OUTPUTFOLDER}"/"${VOL_NO_EXTENSION}"_initial/
mv $DESTLUNG/*.bmp "${OUTPUTFOLDER}"/"${VOL_NO_EXTENSION}"_initial/
mv $DESTLUNG/*-airways.dcm $DESTAIR/

CALL="measure_volume -s $DESTLUNG/*.dcm -v $INPUTFILE >> $OUTPUTFOLDER/lung_volume.txt"
eval $CALL

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

echo '-------------------------'
echo 'Predict Segmentation.....'
echo '-------------------------'
python Code/scripts_experiments/predict_model.py --basedir=/temp_work --testing_datadir=TestingData --is_backward_compat=True --name_output_predictions_relpath=${POSWRKDIR} --name_output_reference_keys_file=${KEYFILE} ${MODELFILE}
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

echo '-------------------------'
echo 'RUNNING OPFRONT..........'
echo '-------------------------'

/bronchinet/scripts/opfront_scripts/opfront_repeat_scan.sh ${NIFTIIMG}/*.nii.gz ${SEGDIR}/*.nii.gz "${OUTPUTFOLDER}" "-i 17 -o 17 -I 9 -O 9 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.588 -G -0.688 -C 2"
if [ $? -eq 1 ]
then
  echo "${VOL_NO_EXTENSION} failed." >> "$LOGFILE"
  echo "Failed opfront"
  rm -r ${DATADIR}
  rm -r "${SEGDIR}"
else
  rm *filled* *.mm *.col *6con*
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