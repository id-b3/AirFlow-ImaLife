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

MODELFILE=/bronchinet/model/model_imalife_luvar.pt

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
	LUNG_VOL=$(measure_volume -s $DESTLUNG/*-lungs.dcm -v $INPUTFILE)
	AIR_VOL=$(measure_volume -s $DESTLUNG/*-airways.dcm -v $INPUTFILE)
	echo "**************************************************"
	echo "Airway Volume for ${VOL_NO_EXTENSION} is ${AIR_VOL}"
	echo "**************************************************"
    if [ "$LUNG_VOL" -gt 4500000 ]
    then
        if [ "$AIR_VOL" -gt 30000 ]
       	then
            echo $LUNG_VOL > "$OUTPUTFOLDER"/lung_volume.txt
            echo $AIR_VOL > "$OUTPUTFOLDER"/air_volume.txt
            echo "Success Segmenting at ${1}"
            return 0
	    else
		    echo "Airway volume too small for Large Lungs, retrying..."
		    return 1
	    fi
    else
        if [ "$AIR_VOL" -gt 25000 ]
       	then
            echo $LUNG_VOL > "$OUTPUTFOLDER"/lung_volume.txt
            echo $AIR_VOL > "$OUTPUTFOLDER"/air_volume.txt
            echo "Success Segmenting at ${1}"
            return 0
	    else
		    echo "Airway volume too small for Small Lungs, retrying..."
		    return 1
	    fi
    fi
}

LUNG_COMPLETE=1
L_THRESHOLD=870

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


echo '-------------------------'
echo 'CLEANING UP..............'
echo '-------------------------'
rm -r ${DATADIR}
rm -r "${SEGDIR}"
