#!/bin/bash
# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUT_DIR=${1}
GENOUTPUTDIR=${2}

CALL="python /airflow/scripts/processing_scripts/get_id_from_header.py ${INPUT_DIR}"
echo "Getting participant ID"
eval "$CALL"
VOL_NO_EXTENSION=$(head -n 1 participant_id.txt)
VOL_NO_EXTENSION="$(echo -e "${VOL_NO_EXTENSION}" | tr -d '[:space:]')"
VOL_FILE="${VOL_NO_EXTENSION}.dcm"

OUTPUTFOLDER=${GENOUTPUTDIR}
echo "Output Folder: ${OUTPUTFOLDER}"
OUTBASENAME=${OUTPUTFOLDER}/${VOL_NO_EXTENSION}
LOGFILE=${3:-${OUTPUTFOLDER}/PROCESS_LOG.log}

mkdir -p "${OUTPUTFOLDER}"
echo -n "Progress: ${VOL_NO_EXTENSION} [--------------------]"
echo " Elapsed Time: $((SECONDS/60))min - Volume Creation (~1min)"
echo " Elapsed Time: $((SECONDS/60))min - Volume Creation (~1min)"
    echo "Input Dir: ${INPUT_DIR}"
    echo "Input File: ${VOL_FILE}"
    echo "Output Folder: ${OUTPUTFOLDER}"
    SECONDS=0
    now=$(date +"%T")
    echo "Start Time: $now"

    DATADIR=/temp_work/processing
    DESTAIR=${DATADIR}/CoarseAirways
    DESTLUNG=${DATADIR}/Lungs
    DESTIMG=${DATADIR}/RAW/DICOM
    NIFTIIMG=${DATADIR}/Images

    MODELFILE=/airflow/model/model_imalife.pt

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
mkdir -p /temp_work/processing/Airways


execution_status() {
    echo "{execution_status: $1}" > ${OUTPUTFOLDER}/status.json
}


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
    execution_status 3
    echo "${VOL_NO_EXTENSION},${DURATION},FAILED_VOLUME_CREATION" >> ${GENOUTPUTDIR}/PROCESSED_SCANS_LIST.csv
    exit 1
else
    INPUTFILE="${DESTIMG}/${VOL_FILE}"
    #    python /airflow/scripts/processing_scripts/get_date.py "${INPUTFILE}" "${OUTBASENAME}"_date.txt
    vol_size=$(wc -c <"$INPUTFILE")
    if [ $vol_size -ge 100000 ]; then
        echo "SUCCESS CREATING DICOM VOLUME"
    else
        echo "CREATED VOLUME TOO SMALL $vol_size"
        echo "Check if all slices downloaded. Aborting."
        execution_status 2
        echo "${VOL_NO_EXTENSION},${DURATION},FAILED_VOLUME_SMALL" >> ${GENOUTPUTDIR}/PROCESSED_SCANS_LIST.csv
        exit 1
        fi
    fi


echo -n "Progress: ${VOL_NO_EXTENSION} [##------------------]"
echo " Elapsed Time: $((SECONDS/60))min - Coarse Lung and Airway Segmentation (~3-5min)"


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
            if [ "$AIR_VOL" -gt 10000 ]
            then
                # shellcheck disable=SC2086
                echo $LUNG_VOL > "$OUTPUTFOLDER"/lung_volume.txt
                echo "$AIR_VOL" > "$OUTPUTFOLDER"/air_volume.txt
                echo "Success Segmenting at ${1}"
                return 0
            else
                echo "Airway volume too small for Large Lungs, retrying..."
                execution_status 6
                return 1
            fi
        else
            if [ "$AIR_VOL" -gt 10000 ]
            then
                echo "$LUNG_VOL" > "$OUTPUTFOLDER"/lung_volume.txt
                echo "$AIR_VOL" > "$OUTPUTFOLDER"/air_volume.txt
                echo "Success Segmenting at ${1}"
                return 0
            else
                echo "Airway volume too small for Small Lungs, retrying..."
                execution_status 6
                return 1
            fi
        fi
    }

    cp "$INPUTFILE" "${OUTPUTFOLDER}"

    cd /temp_work || exit
    ln -s /airflow/bronchinet/src Code
    ln -s /temp_work/processing BaseData

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
            execution_status 6
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
                execution_status 3
                echo "${VOL_NO_EXTENSION},${DURATION},FAILED_COARSE_SEGMENTATION" >> ${GENOUTPUTDIR}/PROCESSED_SCANS_LIST.csv
                exit 1
            fi
            ((L_THRESHOLD=L_THRESHOLD-10))
        else
            echo "Completed lung segmentation at $L_THRESHOLD"
        fi

    done

echo -n "Progress: ${VOL_NO_EXTENSION} [####----------------]"
echo " Elapsed Time: $((SECONDS/60))min - Pruning Coarse Airway Segmentation (~2min)"

    now=$(date +"%T")
    echo "Elapsed Time: $((SECONDS/60))min"
    echo "Current Time: $now"

    mkdir -p "${OUTPUTFOLDER}"/"${VOL_NO_EXTENSION}"_initial/
    mv $DESTLUNG/*.bmp "${OUTPUTFOLDER}"/"${VOL_NO_EXTENSION}"_initial/
    mv $DESTLUNG/*-airways.dcm $DESTAIR/


echo -n "Progress: ${VOL_NO_EXTENSION} [######--------------]"
echo " Elapsed Time: $((SECONDS/60))min - Fine Airway Segmentation - Pre-processing (~5min)"

    now=$(date +"%T")
    echo "Elapsed Time: $((SECONDS/60))min"
    echo "Current Time: $now"

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

echo -n "Progress: ${VOL_NO_EXTENSION} [#######-------------]"
echo " Elapsed Time: $((SECONDS/60))min - Fine Airway Segmentation - Using GPU (~5min)"
nvidia-smi

echo '-------------------------'
echo 'Predict Segmentation.....'
echo '-------------------------'
PRED_DONE=1
ATTEMPTS=1

echo "*-*-*-*-*-* GPU is free with ${free_mem} *-*-*-*-*-*"
nvidia-smi
python Code/scripts_experiments/predict_model.py --basedir=/temp_work --testing_datadir=TestingData --is_backward_compat=False --name_output_predictions_relpath=${POSWRKDIR} --name_output_reference_keys_file=${KEYFILE} ${MODELFILE}
PRED_DONE=$?
if [ $PRED_DONE -eq 1 ]; then
    echo "Prediction failed, likely due to GPU not free. Attempt $ATTEMPTS. Retrying..."
    execution_status 6
    ((++ATTEMPTS))
    if [ $ATTEMPTS -gt 15 ]; then
        echo "Failed to process GPU part of segmentation."
        execution_status 3
        echo "${VOL_NO_EXTENSION},${DURATION},FAILED_GPU" >> ${GENOUTPUTDIR}/PROCESSED_SCANS_LIST.csv
        exit $PRED_DONE
    fi
fi
echo "Done using GPU."


echo -n "Progress: ${VOL_NO_EXTENSION} [########------------]"
echo " Elapsed Time: $((SECONDS/60))min - Post-processing Fine Airway Segmentation (~1min)"

    echo '-------------------------'
    echo 'Post-process Segmentation'
    echo '-------------------------'
    python Code/scripts_evalresults/postprocess_predictions.py --basedir=/temp_work --name_input_predictions_relpath=${POSWRKDIR} --name_output_posteriors_relpath=${POSDIR} --name_input_reference_keys_file=${KEYFILE}
    python /airflow/scripts/processing_scripts/air_seg_thumbnail.py ${POSDIR}/*.nii.gz ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_unet_thumbnail.jpeg
    python Code/scripts_evalresults/process_predicted_airway_tree.py --basedir=/temp_work --name_input_posteriors_relpath=${POSDIR} --name_output_binary_masks_relpath=${SEGDIR}
    echo $?

    echo '-------------------------'
    echo 'CLEAN UP.................'
    echo '-------------------------'
    rm -r ${POSDIR}
    rm -r ${POSWRKDIR}
    rm ${KEYFILE}

echo -n "Progress: ${VOL_NO_EXTENSION} [##########----------]"
echo " Elapsed Time: $((SECONDS/60))min - Wall Segmentation (~15-25min)"

    now=$(date +"%T")
    echo "Elapsed Time: $((SECONDS/60))min"
    echo "Current Time: $now"

    echo '-------------------------'
    echo 'RUNNING OPFRONT..........'
    echo '-------------------------'

    /airflow/scripts/opfront_scripts/opfront_scan.sh ${NIFTIIMG}/*.nii.gz ${SEGDIR}/*.nii.gz "${OUTPUTFOLDER}" "-i 50 -o 50 -I 7 -O 7 -d 1.2 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.58 -G -0.68 -C 2"
    if [ $? -eq 1 ]
    then
        echo "${VOL_NO_EXTENSION} failed opfront step." >> "$LOGFILE"
        echo "Failed opfront"
        rm -r ${DATADIR}
        rm -r "${SEGDIR}"
        execution_status 3
        echo "${VOL_NO_EXTENSION},${DURATION},FAILED_OPFRONT" >> ${GENOUTPUTDIR}/PROCESSED_SCANS_LIST.csv
        exit 1
    fi

echo -n "Progress: ${VOL_NO_EXTENSION} [############--------]"
echo " Elapsed Time: $((SECONDS/60))min - Post-processing Segmentations (~1min)"

    now=$(date +"%T")
    echo "Elapsed Time: $((SECONDS/60))min"
    echo "Current Time: $now"

    echo "\nSuccess with opfront steps. Final computations and cleanup..."
    python /airflow/scripts/processing_scripts/air_seg_thumbnail.py ${OUTPUTFOLDER}/*surface0.nii.gz ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_check_airway_segmentation.jpeg
    python /airflow/scripts/processing_scripts/air_seg_thumbnail.py ${OUTPUTFOLDER}/*nii-branch.nii.gz ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_airwayseg_branchids.dcm -d
    measure_volume -s ${OUTPUTFOLDER}/*_surface1.nii.gz -v ${NIFTIIMG}/*.nii.gz >> ${OUTPUTFOLDER}/airway_volume.txt
    # Process the GTS files into obj files for easy 3D model use.
    gts2stl < ${OUTPUTFOLDER}/*surface0.gts > ${OUTBASENAME}_lumen.stl
    gts2stl < ${OUTPUTFOLDER}/*surface1.gts > ${OUTBASENAME}_wall.stl
    admesh ${OUTBASENAME}_lumen.stl -b ${OUTBASENAME}_lumen.stl
    admesh ${OUTBASENAME}_wall.stl -b ${OUTBASENAME}_wall.stl
    ctmconv ${OUTBASENAME}_wall.stl ${OUTBASENAME}_wall.obj
    ctmconv ${OUTBASENAME}_lumen.stl ${OUTBASENAME}_lumen.obj

echo -n "Progress: ${VOL_NO_EXTENSION} [##############------]"
echo " Elapsed Time: $((SECONDS/60))min - Measuring Bronchial Parameters (~2min)"

# Measure the bronchial parameters
echo "Measuring Bronchial Parameters..."
python /airflow/scripts/processing_scripts/airway_summary.py ${OUTBASENAME}_*surface0.nii.gz --inner_csv "${OUTPUTFOLDER}"/*_inner.csv --inner_rad_csv "${OUTPUTFOLDER}"/*_inner_localRadius_pandas.csv --outer_csv "${OUTPUTFOLDER}"/*_outer.csv --outer_rad_csv "${OUTPUTFOLDER}"/*_outer_localRadius_pandas.csv --branch_csv "${OUTPUTFOLDER}"/*_airways_centrelines.csv --output "${OUTPUTFOLDER}" --name "${VOL_NO_EXTENSION}"
if [ $? -eq 1 ]
then
    echo "Failed to measure bronchial parameters"
    execution_status 3
fi
# Label the branches with lobes
python /airflow/AirMorph/label_branch_lobes.py ${NIFTIIMG}/*.nii.gz ${OUTPUTFOLDER}/airway_tree.pickle ${OUTPUTFOLDER}
# Get the scan date
python /airflow/scripts/processing_scripts/get_date.py $INPUTFILE ${OUTPUTFOLDER}/scan_date.txt
# Flag segmentation as complete
python /airflow/scripts/processing_scripts/flag_potential_seg_errors.py ${OUTPUTFOLDER}/lung_volume.txt ${OUTPUTFOLDER}/airway_volume.txt ${OUTPUTFOLDER}/bp_summary_redcap.csv ${OUTPUTFOLDER}/airway_tree.pickle
# Delete unnecessary output files
if [ $? -eq 1 ]
then
    echo "Failed to check summary file."
    execution_status 3
fi

echo -n "Progress: ${VOL_NO_EXTENSION} [##################--]"
echo " Elapsed Time: $((SECONDS/60))min - Cleaning Up (~1min)"

    find ${OUTPUTFOLDER} -type f -name "*nii-branch.nii.gz" -exec mv {} "${OUTBASENAME}"_labelled_tree.nii.gz \;
    find ${OUTPUTFOLDER} -type f -name "*.mm" -delete
    find ${OUTPUTFOLDER} -type f -name "*-seg*" -delete
    find ${OUTPUTFOLDER} -type f -name "*.stl" -delete
    find ${OUTPUTFOLDER} -type f -name "*.col" -delete
    find ${OUTPUTFOLDER} -type f -name "*filled*" -delete
    find ${OUTPUTFOLDER} -type f -name "*surface0_iso*" -delete
    rm ${OUTPUTFOLDER}/${VOL_FILE}
    find ${OUTPUTFOLDER} -type f -name "*.brh" -delete
    find ${OUTPUTFOLDER} -type f -name "*localRadius.csv" -delete
    cd "${OUTPUTFOLDER}" || exit
    echo '---- Packing results into tar ----'
    rm -rf *initial
    find . -type f -name "*.gts" -delete
eval "tar -czf ${VOL_NO_EXTENSION}_bronchial_results.tar.gz --exclude='*.dcm' --exclude='*.json' ./*"
    find . -type f -name "*.csv" -delete
    find . -type f -name "*.nii.gz" -delete
    find . -type f -name "*.obj" -delete
    find . -type f -name "*.jpeg" -delete
    find . -type f -name "*.jpg" -delete
    find . -type f -name "*.pickle" -delete
    find . -type f -name "*.txt" -delete

    echo '-------------------------'
    echo 'CLEANING UP..............'
    echo '-------------------------'
    rm -r ${DATADIR}
    rm -r "${SEGDIR}"
    DURATION=$(($SECONDS/60))
    echo "PROCESS TOOK $DURATION MINUTES"
    execution_status 0
echo "${VOL_NO_EXTENSION},${DURATION},COMPLETED" >> ${GENOUTPUTDIR}/PROCESSED_SCANS_LIST.csv

echo -n "Progress: $VOL_NO_EXTENSION [####################]"
echo " Elapsed Time: $((SECONDS/60))min - Completed"
echo "********** ${VOL_NO_EXTENSION} DONE **********"
