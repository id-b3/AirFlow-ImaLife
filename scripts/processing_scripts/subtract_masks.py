import argparse
from dataloaders.imagefilereader import ImageFileReader
from imageoperators.maskoperator import MaskOperator
from pathlib import Path


def main(args):
    print("Operation: Substract two images (img1 - img2)...")
    first_mask = ImageFileReader.get_image(args.mask_1)
    second_mask = ImageFileReader.get_image(args.mask_2)
    inout_metadata = ImageFileReader.get_image_metadata_info(args.mask_1)
    inout_image = MaskOperator.substract_two_masks(first_mask, second_mask)
    out_path = Path(args.out_dir).resolve()
    out_filename = Path(out_path / "airway_wall.nii.gz")
    ImageFileReader.write_image(out_filename, inout_image, metadata=inout_metadata)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("mask_1", type=str, help="First Mask.")
    parser.add_argument("mask_2", type=str, help="Second Mask (to be subtracted)")
    parser.add_argument("out_dir", type=str, help="Output folder.")
    args = parser.parse_args()

    main(args)
