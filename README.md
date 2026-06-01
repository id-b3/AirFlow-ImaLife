# AirFlow-ImaLife

**_Pipeline for automated calculation of bronchial parameters_**

[![CodeFactor](https://www.codefactor.io/repository/github/id-b3/air_flow_imalife/badge?s=1dae3aeee26afb253ec4aedd3b702d828daacdf3)](https://www.codefactor.io/repository/github/id-b3/air_flow_imalife)
[![GitHub Super-Linter](https://github.com/id-b3/air_flow_imalife/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter) [![Docker](https://github.com/id-b3/Air_Flow_ImaLife/actions/workflows/docker-publish.yml/badge.svg?branch=optimise_phantom)](https://github.com/id-b3/Air_Flow_ImaLife/actions/workflows/docker-publish.yml)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

---

## Introduction

This repo combines a number of tools into an automated process for the
extraction and measurement of bronchial parameters on a low-dose CT scan.

It combines the 3D-Unet method [bronchinet](/bronchinet) to obtain the initial airway lumen segmentation.
This is followed by the [Opfront](/opfront) method which uses optimal-surface graph-cut to separate the inner surface of the airway from the outer surface of the airway.
From this, various bronchial parameters can be derived.

---

## Prerequisites

- **Docker** ≥ 19.03 with [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed
- **NVIDIA GPU** with ≥ 8 GB VRAM (CUDA 11.2 compatible)
- **Git** with submodule support (`git clone --recurse-submodules`)
- A trained U-Net model file (default expected at `./imalife_models/imalife_2/model_imalife.pt`)

---

## Building the Docker Image

The Dockerfile uses a multi-stage build:

1. **Stage 1** (`playground_builder`) – Compiles legacy C/C++ preprocessing and measurement tools on Ubuntu 14.04.
2. **Stage 2** (`opfront_builder`) – Compiles the Opfront graph-cut segmentation tools on Ubuntu 20.04.
3. **Stage 3** (`runtime`) – Assembles the final image on `nvidia/cuda:11.2.2-base-ubuntu20.04` with Python 3.8, PyTorch, and all compiled binaries.

### Build command

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/id-b3/AirFlow-ImaLife.git
cd AirFlow-ImaLife

# Build the image (default model directory: ./imalife_models/imalife_2)
docker build -t airflow:imalife_base .
```

### Using a custom model

Pass the `MODEL_DIR` build argument to point to your own trained model:

```bash
docker build --build-arg MODEL_DIR=./path/to/your/model -t airflow:my_model .
```

> **Note:** The model directory must contain a file named `model_imalife.pt`.

### Build time and size

The full build compiles ITK 3.20, Boost libraries, and the Opfront tools from source. Expect:

- **Build time:** 30–60 minutes (depending on CPU cores and network speed)
- **Image size:** ~8–10 GB

---

## Deploying the Docker Container

### Single scan (quick start)

Use the provided `run_docker.sh` helper:

```bash
./run_docker.sh /absolute/path/to/dicom/slices /absolute/path/to/output airflow:imalife_base
```

Or run directly:

```bash
docker run --gpus all --rm -t \
    -v /path/to/input:/input \
    -v /path/to/output:/output \
    airflow:imalife_base /input /output
```

| Parameter                    | Description                              |
| ---------------------------- | ---------------------------------------- |
| `--gpus all`                 | Exposes all NVIDIA GPUs to the container |
| `--rm`                       | Removes the container after execution    |
| `-v /path/to/input:/input`   | Mounts the DICOM slice directory (read)  |
| `-v /path/to/output:/output` | Mounts the output directory (write)      |

### Input format

The input directory must contain a single DICOM series as individual slice files (`.dcm`). The pipeline will:

1. Assemble slices into a single DICOM volume
2. Extract the participant ID from the DICOM header
3. Create a named output subfolder under the output mount

### Batch processing (multiple scans)

For processing many scans in parallel, use the launch script:

```bash
python scripts/launch_scripts/airflowmp.py /path/to/scan/folders /path/to/output -n 4
```

| Argument       | Description                                                     |
| -------------- | --------------------------------------------------------------- |
| `main_dir`     | Directory containing subdirectories, each with one DICOM series |
| `out_dir`      | Output directory for results                                    |
| `-n, --number` | Number of simultaneous Docker containers (default: 8)           |

The script automatically moves processed scans to `completed_scans/` or `failed_scans/` subdirectories and logs execution times.

> **GPU memory:** Each container requires ~8 GB VRAM. When running in parallel, the pipeline includes a GPU-busy lock mechanism to prevent out-of-memory errors. Adjust `-n` based on your available GPU memory.

---

## Running Inference

### Pipeline stages

When a container starts, the entrypoint script (`scripts/run_machine.sh`) executes the following stages automatically:

| Stage                     | Duration   | Description                                                        |
| ------------------------- | ---------- | ------------------------------------------------------------------ |
| Volume creation           | ~1 min     | Assembles DICOM slices into a single volume                        |
| Coarse segmentation       | ~3–5 min   | Segments lungs and extracts coarse airways (adaptive thresholding) |
| Pruning                   | ~2 min     | Cleans the coarse airway segmentation                              |
| U-Net pre-processing      | ~5 min     | Converts to NIfTI, computes bounding boxes, prepares data          |
| U-Net inference (GPU)     | ~5 min     | Fine airway lumen segmentation using 3D-Unet                       |
| U-Net post-processing     | ~1 min     | Binarises and cleans predicted segmentation                        |
| Opfront wall segmentation | ~15–25 min | Graph-cut based inner/outer airway wall separation                 |
| Post-processing           | ~1 min     | Generates 3D models (STL/OBJ), thumbnails, volume measurements     |
| Bronchial parameters      | ~2 min     | Measures wall thickness, lumen area, Pi10, and branch labelling    |
| Cleanup                   | ~1 min     | Packages results into `.tar.gz`, removes intermediates             |

**Total estimated time: 35–45 minutes per scan.**

### Outputs

Results are saved to `<output_dir>/<participant_id>/`:

| File                               | Description                                                   |
| ---------------------------------- | ------------------------------------------------------------- |
| `*_bronchial_results.tar.gz`       | Compressed archive of all results                             |
| `*_lumen.obj`                      | 3D mesh of airway lumen surface                               |
| `*_wall.obj`                       | 3D mesh of airway wall surface                                |
| `bp_summary_redcap.csv`            | Bronchial parameters (wall thickness, lumen area, Pi10, etc.) |
| `airway_tree.pickle`               | Serialised airway tree structure with branch measurements     |
| `*_check_airway_segmentation.jpeg` | Thumbnail for visual quality check                            |
| `PROCESS_LOG.log`                  | Detailed execution log                                        |
| `status.json`                      | Execution status code (0 = success)                           |

### Status codes

| Code | Meaning                                                         |
| ---- | --------------------------------------------------------------- |
| 0    | Completed successfully                                          |
| 2    | Volume too small (incomplete DICOM series)                      |
| 3    | Critical failure (see log for details)                          |
| 6    | Retrying (transient failure, GPU busy, or threshold adjustment) |

### Troubleshooting

- **GPU out of memory:** Ensure no other processes occupy the GPU. Check with `nvidia-smi`.
- **Volume creation fails:** Verify the input folder contains a complete DICOM series.
- **Coarse segmentation fails:** The pipeline tries decreasing thresholds (800→700) automatically. Persistent failure may indicate a non-standard scan (e.g., very noisy or low-dose).

---

## Analysis

### Bronchial parameter outputs

The pipeline produces per-branch airway measurements using the [bronchipy](https://pypi.org/project/bronchipy/) package. Key parameters include:

| Parameter                  | Description                                                   |
| -------------------------- | ------------------------------------------------------------- |
| Wall thickness (WT)        | Mean wall thickness per airway branch                         |
| Lumen area (LA)            | Cross-sectional lumen area                                    |
| Wall area (WA)             | Cross-sectional wall area                                     |
| Wall area percentage (WA%) | WA / (WA + LA) × 100                                          |
| Pi10                       | Hypothetical wall thickness at an internal perimeter of 10 mm |
| Total airway count (TAC)   | Number of segmented airway branches                           |

### Lobar labelling

Branch measurements are labelled by lung lobe using the AirMorph module. This allows per-lobe aggregation of bronchial parameters for regional analysis.

### Reproducibility analysis

Scripts for assessing measurement reproducibility are provided in `scripts/reproducibility_analysis_scripts/`:

```bash
# Bland-Altman plots and R² for repeat scans
python scripts/reproducibility_analysis_scripts/bronchial_parameters_per_generation.py \
    --input_dir /path/to/repeat/results \
    --output_dir /path/to/plots
```

This generates:

- Bland-Altman plots for limits of agreement
- Regression plots with R² values
- Per-generation (airway depth) analysis

### Working with results programmatically

```python
from bronchipy.io.branchio import load_pickle_tree

# Load the airway tree
tree = load_pickle_tree("path/to/airway_tree.pickle")

# Access branch-level measurements
for branch in tree.branches:
    print(f"Branch {branch.id}: WT={branch.wall_thickness:.2f}, LA={branch.lumen_area:.2f}")
```

---

## Repository Structure

<pre>
    .
    ├── <i>AirMorph</i>     -> Lobar lung segmentation and lobar airway branch labelling.  
    ├── <i>airflow_legacy</i>      -> Legacy resources for compiling pre/post processing tools.  
    ├── airway_analysis     -> Package processing opfront output and calculating bronchial parameters.
    ├── <i>bronchinet</i>          -> 3D-Unet developed for airway lumen segmentations.  
    ├── <i>opfront</i>          -> Opfront tools for segmenting airway lumen and wall surfaces.  
    ├── phantom_trainer     -> Set of tools for automatically determining parameters for the opfront tool  
    ├── scripts             -> Bash/Python scripts used to automate the docker image.  
    │   ├── launch_scripts  -> Batch processing and parallelised Docker launch utilities.
    │   ├── opfront_scripts -> Opfront execution wrapper.
    │   ├── processing_scripts -> Pre/post-processing helpers (thumbnails, measurements, etc.).
    │   └── reproducibility_analysis_scripts -> Statistical analysis and plotting tools.
    ├─────── Dockerfile          -> Multi-stage Dockerfile for the pipeline  
    ├─────── airflow_libs.tar.gz -> Package containing compiled legacy runtime libraries for opfront tools.  
    ├─────── README.md           -> This file.  
    ├─────── requirements.txt    -> List of required packages for airflow docker. Install with pip install -r requirements.txt  
    <i>Submodules in italics.</i>
</pre>
