import argparse
import pandas as pd


def main(args):
    with open(args.lung_vol, "r") as f:
        lung_vol = float(f.readline().strip()) / 1000000
    with open(args.air_vol, "r") as f:
        air_vol = float(f.readline().strip()) / 1000000
    bp_df = pd.read_csv(args.bp_file)
    tcount = bp_df["bp_tcount"].max()
    tree = pd.read_pickle(args.tree_pickle)
    max_rad = tree[tree.generation > 5]["inner_radius"].max()
    bp_df["bp_tlv"] = lung_vol
    bp_df["bp_airvol"] = air_vol
    print(f"{lung_vol}, {air_vol}, {tcount}, {max_rad}")

    lungs = lung_vol > 8.0 or lung_vol < 3.0
    airs = air_vol > 0.5 or air_vol < 0.25
    counts = tcount > 400 or tcount < 100
    rads = max_rad > 4
    if lungs or airs or counts or rads:
        print("Segmentation Potentially Incomplete.")
        bp_df["bp_seg_error"] = 1
        bp_df.to_csv(args.bp_file, index=False)
    else:
        bp_df.to_csv(args.bp_file, index=False)
        print("Segmentation Complete.")


if __name__ == "__main__":
    print("*********************************************")
    print("Checking segmentation for potential errors...")
    print("*********************************************")
    parser = argparse.ArgumentParser()
    parser.add_argument("lung_vol", type=str, help="Lung Volume")
    parser.add_argument("air_vol", type=str, help="Airway Volume")
    parser.add_argument("bp_file", type=str, help="Bronchial Summary File")
    parser.add_argument("tree_pickle", type=str, help="Airway Tree pickle file.")
    args = parser.parse_args()

    main(args)
