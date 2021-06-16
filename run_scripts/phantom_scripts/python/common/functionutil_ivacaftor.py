
from collections import OrderedDict
import numpy as np
import sys


def remove_exclude_cases_from_subjects_info(in_subjects_info, in_cases_exclude):
    subjects_casesID = list(in_subjects_info.values())[0]

    for icase in in_cases_exclude:
        if icase in subjects_casesID:
            index_case = subjects_casesID.index(icase)
            for ifield, data_field in in_subjects_info.items():
                data_field.pop(index_case)

    return in_subjects_info


def compute_twoScans_per_patient_from_subjects_info(in_subjects_info, is_exclude_cases_non_twoScans=False):
    subjects_casesID    = in_subjects_info['ID']
    subjects_patientID  = in_subjects_info['patientID2']
    subjects_isfollowup = in_subjects_info['isfollowup']

    unique_patientsID = list(np.unique(subjects_patientID))

    out_subj_twoScans_per_patient = OrderedDict()

    for ipatient in unique_patientsID:

        indexes_cases_this_patient = [i for i, elem in enumerate(subjects_patientID) if elem == ipatient]
        num_cases_this_patient = len(indexes_cases_this_patient)

        if num_cases_this_patient == 1:
            index_1st_caseID = indexes_cases_this_patient[0]

            first_caseID = subjects_casesID[index_1st_caseID]
            print('WARNING: patient \'%s\' has only 1 scan \'%s\'...' %(ipatient, first_caseID))

            if subjects_isfollowup[index_1st_caseID] == 0:
                out_twoScans_this_patient = (first_caseID, -1)
            elif subjects_isfollowup[index_1st_caseID] == 1:
                out_twoScans_this_patient = (-1, first_caseID)

            out_subj_twoScans_per_patient[ipatient] = out_twoScans_this_patient

        elif num_cases_this_patient == 2:
            index_1st_caseID = indexes_cases_this_patient[0]
            index_2nd_caseID = indexes_cases_this_patient[1]

            first_caseID  = subjects_casesID[index_1st_caseID]
            second_caseID = subjects_casesID[index_2nd_caseID]

            if (subjects_isfollowup[index_1st_caseID] == 0) and (subjects_isfollowup[index_2nd_caseID] == 1):
                out_twoScans_this_patient = (first_caseID, second_caseID)
            elif (subjects_isfollowup[index_1st_caseID] == 1) and (subjects_isfollowup[index_2nd_caseID] == 0):
                out_twoScans_this_patient = (second_caseID, first_caseID)
            else:
                print('ERROR FATAL...')
                sys.exit(0)

            out_subj_twoScans_per_patient[ipatient] = out_twoScans_this_patient

        else:
            print('ERROR FATAL...')
            sys.exit(0)

    if is_exclude_cases_non_twoScans:
        for ipatient in list(out_subj_twoScans_per_patient.keys()):
            (first_caseID, second_caseID) = out_subj_twoScans_per_patient[ipatient]
            if (first_caseID == -1) or (second_caseID == -1):
                out_subj_twoScans_per_patient.pop(ipatient)


    return out_subj_twoScans_per_patient


def compute_twoScans_per_patient_treated_or_control(in_subjects_info, in_subj_twoScans_per_patient):
    subjects_casesID = in_subjects_info['ID']
    subjects_istreated = in_subjects_info['istreated']

    out_subj_twoScans_per_patient_control = OrderedDict()
    out_subj_twoScans_per_patient_treated = OrderedDict()

    for ipatient, (first_caseID, second_caseID) in in_subj_twoScans_per_patient.items():
        if ('unknown' in ipatient) or (first_caseID == -1) or (second_caseID == -1):
            print('WARNING: excluded patient \'%s\' with assigned scans \'%s\' and \'%s\'...' % (ipatient, first_caseID, second_caseID))
            continue

        index_1st_caseID = subjects_casesID.index(first_caseID)
        index_2nd_caseID = subjects_casesID.index(second_caseID)

        if (subjects_istreated[index_1st_caseID] == 0) and (subjects_istreated[index_2nd_caseID] == 0):
            out_subj_twoScans_per_patient_control[ipatient] = [first_caseID, second_caseID]
        elif (subjects_istreated[index_1st_caseID] == 1) and (subjects_istreated[index_2nd_caseID] == 1):
            out_subj_twoScans_per_patient_treated[ipatient] = [first_caseID, second_caseID]
        else:
            print('ERROR FATAL...')
            sys.exit(0)

    return (out_subj_twoScans_per_patient_control, out_subj_twoScans_per_patient_treated)