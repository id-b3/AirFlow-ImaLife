import argparse
import nibabel
import pydicom


def convertslice(array, file_path, index=0):
    dicom_file = pydicom.dcmread(file_path)
    array = array.astype("uint16")
    dicom_file.Rows = array.shape[0]
    dicom_file.Columns = array.shape[1]
    dicom_file.PhotometricInterpretation = "MONOCHROME2"
    dicom_file.SamplesPerPixel = 1
    dicom_file.BitsStored = 16
    dicom_file.BitsAllocated = 16
    dicom_file.HighBit = 15
    dicom_file.PixelRepresentation = 1
    dicom_file.PixelData = array.tobytes()


def main(args):
    nifti_file = nibabel.load(args.nifti_in)
    nifti_array = nifti_file.get_fdata()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("nifti_in", type=str, help="NIFTI Image to convert.")
    parser.add_argument(
        "dicom_in", type=str, help="DICOM volume from which to get metadata to be used."
    )
    parser.add_argument("dicom_out", type=str, help="Resulting DICOM volume.")
    args = parser.parse_args()

    main(args)
