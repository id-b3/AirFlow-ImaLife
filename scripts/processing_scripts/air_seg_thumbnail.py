import numpy as np
import matplotlib.pyplot as plt
import argparse
import nibabel as nib
from pydicom.dataset import Dataset, FileMetaDataset
from pydicom.sequence import Sequence
from pydicom.uid import RLELossless


def conv_to_dicom(arr):
    # File meta info data elements
    file_meta = FileMetaDataset()
    file_meta.FileMetaInformationGroupLength = 198
    file_meta.FileMetaInformationVersion = b'\x00\x01'
    file_meta.MediaStorageSOPClassUID = '1.2.840.10008.5.1.4.1.1.2'
    file_meta.MediaStorageSOPInstanceUID = '1.3.12.2.1107.5.1.4.75485.30000018011707080445600055666'
    file_meta.TransferSyntaxUID = '1.2.840.10008.1.2.1'
    file_meta.ImplementationClassUID = '1.2.40.0.13.1.1'
    file_meta.ImplementationVersionName = 'dcm4che-2.0'
    file_meta.SourceApplicationEntityTitle = 'ENACT'

# Main data elements
    ds = Dataset()
    ds.SpecificCharacterSet = 'ISO_IR 100'
    ds.ImageType = ['ORIGINAL', 'PRIMARY', 'AXIAL',
                    'CT_SOM5 SPI DUAL', 'STD', 'SNRG', 'DET_AB']
    ds.SOPClassUID = '1.2.840.10008.5.1.4.1.1.2'
    ds.SOPInstanceUID = '3.4.11571279942983760564316107167'
    ds.StudyDate = '00010101'
    ds.SeriesDate = '00010101'
    ds.AcquisitionDate = '00010101'
    ds.ContentDate = '00010101'
    ds.AcquisitionDateTime = '00010101010101.000000+0000'
    ds.StudyTime = '000000.00'
    ds.SeriesTime = '000000.00'
    ds.AcquisitionTime = '000000.00'
    ds.ContentTime = '000000.00'
    ds.AccessionNumber = ''
    ds.Modality = 'CT'
    ds.Manufacturer = 'SIEMENS'
    ds.InstitutionName = 'Anonymized'
    ds.ReferringPhysicianName = ''
    ds.StationName = 'Anonymized'
    ds.ManufacturerModelName = 'SOMATOM Force'

# Referenced Image Sequence
    refd_image_sequence = Sequence()
    ds.ReferencedImageSequence = refd_image_sequence

# Referenced Image Sequence: Referenced Image 1
    refd_image1 = Dataset()
    refd_image1.ReferencedSOPClassUID = ''
    refd_image1.ReferencedSOPInstanceUID = ''
    refd_image_sequence.append(refd_image1)


# Source Image Sequence
    source_image_sequence = Sequence()
    ds.SourceImageSequence = source_image_sequence
    ds.NumberOfFrames = arr.shape[0]

# Source Image Sequence: Source Image 1
    source_image1 = Dataset()
    source_image1.ReferencedSOPClassUID = ''
    source_image1.ReferencedSOPInstanceUID = ''
    source_image_sequence.append(source_image1)

    ds.PatientName = ''
    ds.PatientID = ''

# Issuer of Patient ID Qualifiers Sequence
    issuer_of_patient_id_qualifiers_sequence = Sequence()
    ds.IssuerOfPatientIDQualifiersSequence = issuer_of_patient_id_qualifiers_sequence

# Issuer of Patient ID Qualifiers Sequence: Issuer of Patient ID Qualifiers 1
    issuer_of_patient_id_qualifiers1 = Dataset()
    issuer_of_patient_id_qualifiers1.IdentifierTypeCode = 'PI'
    issuer_of_patient_id_qualifiers_sequence.append(
        issuer_of_patient_id_qualifiers1)

    ds.PatientBirthDate = '00010101'
    ds.PatientSex = ''
    ds.BodyPartExamined = 'BRONCHI'
    ds.SliceThickness = '1.0'
    ds.DeviceSerialNumber = 'Anonymized'
    ds.SoftwareVersions = 'Air Flow ImaLife'
    ds.ProtocolName = 'Airway Segmentation'
    ds.ConvolutionKernel = 'Qr59d'

# CTDI Phantom Type Code Sequence
    ctdi_phantom_type_code_sequence = Sequence()
    ds.CTDIPhantomTypeCodeSequence = ctdi_phantom_type_code_sequence

# CTDI Phantom Type Code Sequence: CTDI Phantom Type Code 1
    ctdi_phantom_type_code1 = Dataset()
    ctdi_phantom_type_code1.CodeValue = '113691'
    ctdi_phantom_type_code1.CodingSchemeDesignator = 'DCM'
    ctdi_phantom_type_code1.CodeMeaning = 'IEC Body Dosimetry Phantom'
    ctdi_phantom_type_code_sequence.append(ctdi_phantom_type_code1)

    ds.StudyInstanceUID = '6.49.6.111364.3.2.3.4.61542.16609.435.10222981'
    ds.SeriesInstanceUID = '5.5.9.9749.2.6.8.18236.08153239494545049841664600817'
    ds.StudyID = ''
    ds.SeriesNumber = '2'
    ds.AcquisitionNumber = '2'
    ds.InstanceNumber = '1'
    ds.SamplesPerPixel = 1
    ds.PhotometricInterpretation = 'MONOCHROME2'
    ds.Rows = arr.shape[1]
    ds.Columns = arr.shape[2]
    ds.BitsAllocated = 8
    ds.BitsStored = 8
    ds.HighBit = 7
    ds.PixelRepresentation = 0
    ds.SmallestImagePixelValue = 0
    ds.LargestImagePixelValue = 100
    ds.StudyStatusID = 'STARTED'
    ds.StudyPriorityID = 'LOW'
    ds.RequestedProcedureDescription = ''
    # ds.PixelData = encapsulate([arr.tobytes()])
    ds.file_meta = file_meta
    ds.is_implicit_VR = False
    ds.is_little_endian = True
    ds.compress(RLELossless, arr)
    return ds


def crop_image(image: np.ndarray, padding: tuple = (0, 0, 0)) -> np.ndarray:
    """
    Crop a 3D mask to minimum size + padding
    :param image: 3D mask
    :param padding: voxels to pad in the x, y, z axes
    :return: cropped 3D mask
    """

    def fit_to_image(boundbox: tuple):
        # get the max between x1 and 0 (lower bound)
        # and min between x2 and max image size (upper bound)
        fx1 = (max(boundbox[0][0], 0), min(boundbox[0][1], image.shape[0]))
        fy1 = (max(boundbox[1][0], 0), min(boundbox[1][1], image.shape[1]))
        fz1 = (max(boundbox[2][0], 0), min(boundbox[2][1], image.shape[2]))
        return fx1, fy1, fz1

    # Find the coordinates of the largest rectangle with the mask.
    idx_mask = np.argwhere(
        image != 0
    )  # Get the coordinates of the non-zero elements (tilde is an inverse of the mask)
    x1 = (
        min(idx_mask[:, 0]) - padding[0]
    )  # Get the minimum x coordinate of the non-zero elements and pad it with the borders
    x2 = (
        max(idx_mask[:, 0]) + padding[0]
    )  # Get the maximum x coordinate of the non-zero elements and pad it with the borders
    y1 = min(idx_mask[:, 1]) - padding[1]
    y2 = max(idx_mask[:, 1]) + padding[1]
    z1 = min(idx_mask[:, 2]) - padding[2]
    z2 = max(idx_mask[:, 2]) + padding[2]

    coords = fit_to_image(
        ((x1, x2), (y1, y2), (z1, z2))
    )  # Make sure the bounding box is within the image.
    cropped_img = image[
        coords[0][0]: coords[0][1],
        coords[1][0]: coords[1][1],
        coords[2][0]: coords[2][1],
    ]  # Crop the image.
    return cropped_img


def main(args):
    print(f"Making Segmentation Thumbnail:\n{args.in_seg}\n{args.out_img}")
    air_seg = nib.load(args.in_seg).get_fdata()

    if args.dicom:
        slices = air_seg
        slices = slices * 100
        slices = slices.astype("uint8")
        res = conv_to_dicom(slices)
        res.save_as(f"{args.out_img}")
    else:
        air_seg = crop_image(air_seg, padding=(4, 4, 4))
        f, axarr = plt.subplots(1, 3, figsize=(42, 12))
        axarr[0].imshow(np.rot90(air_seg.sum(axis=0)),
                        interpolation="hanning",
                        cmap="gray")
        axarr[1].imshow(np.rot90(air_seg.sum(axis=1)),
                        interpolation="hanning",
                        cmap="gray")
        axarr[2].imshow(air_seg.sum(axis=2),
                        interpolation="hanning",
                        cmap="gray")
        axarr[0].axis("off")
        axarr[1].axis("off")
        axarr[2].axis("off")
        plt.tight_layout()
        f.savefig(f"{args.out_img}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("in_seg", type=str, help="Input segmentation file.")
    parser.add_argument("out_img", type=str, help="Output segmentation file.")
    parser.add_argument("--dicom",
                        "-d",
                        action="store_true",
                        default=False,
                        help="If flag, will save as DICOM file.")
    in_args = parser.parse_args()
    main(in_args)
