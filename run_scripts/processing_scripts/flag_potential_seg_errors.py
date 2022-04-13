import argparse
import pandas as pd


def main(args):
    with open(args.lung_vol, "r") as f:
        lung_vol = float(f.readline().strip()) / 1000000
    with open(args.air_vol, "r") as f:
        air_vol = float(f.readline().strip()) / 1000000
    bp_df = pd.read_csv(args.bp_file)
    tree = pd.read_pickle(args.tree_pickle)
    max_rad = tree[tree.generation > 5]["inner_radius"].max()

    if 3.0 > lung_vol > 8.0 or 0.1 > air_vol > 0.5 or 150 > bp_df["count"] > 400 or max_rad > 4:
        print("Segmentation Potentially Incomplete.")
        bp_df["bp_seg_error"] = 1
        bp_df.to_csv(args.bp_file)
    else:
        print("Segmentation Complete.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("lung_vol", type=str, help="Lung Volume")
    parser.add_argument("air_vol", type=str, help="Airway Volume")
    parser.add_argument("bp_file", type=str, help="Bronchial Summary File")
    parser.add_argument("tree_pickle", type=str, help="Airway Tree pickle file.")
    args = parser.parse_args()

    main(args)
