import pandas as pd
from pathlib import Path


class Config:
    def __init__(self, cfg_file: str):
        if cfg_file:
            self.load_cfg(cfg_file)
        else:
            print("Loading blank config...\nPlease set the values manually.")
            self.files = {"volume": "", "opfront": "", "results": ""}
            self.airway_length = 0

    def save_cfg(self, out_file: str) -> None:
        cfg_data = {"files": self.files, "airway_length": self.airway_length}
        try:
            pd.DataFrame(cfg_data).to_csv(out_file)
        except FileNotFoundError:
            Path.mkdir(Path(out_file).parent)

    def set_files(self, file_id: str, file_path: str) -> None:
        if file_id == "volume" or file_id == "opfront" or file_id == "results":
            self.files[file_id] = file_path
        else:
            print("Incorrect file_id. Options are 'volume', 'opfront', 'results'")

    def set_airway_length(self, min_length):
        self.airway_length = min_length

    def load_cfg(self, in_file: str):
        try:
            config_df = pd.read_csv(in_file)
            self.files = config_df.files
            self.airway_length = config_df.min_air_length
        except FileNotFoundError as e:
            print(
                f"File {in_file} does not exist. Check file path and try again.\n{e.errno}"
            )
