# ImaLife Air-Flow Pipeline

[![CodeFactor](https://www.codefactor.io/repository/github/id-b3/air_flow_imalife/badge?s=1dae3aeee26afb253ec4aedd3b702d828daacdf3)](https://www.codefactor.io/repository/github/id-b3/air_flow_imalife)

-------------------

## Introduction
This repo combines a number of tools into an automated process for the
extraction and measurement of bronchial parameters on a low-dose CT scan.

It combines the 3D-Unet method [bronchinet](/bronchinet) to obtain the initial airway lumen segmentation.
This is followed by the [Opfront](/opfront) method which uses optimal-surface graph-cut to separate the inner surface of the airway from the outer surface of the airway.
From this, various bronchial parameters can be derived.

## Repository Structure
    .
    ├── airflow_libs      -> backup of c++ libraries required for opfront and playground tools   
    ├── airway_analysis   -> python code for processing opfront output and producing summary measures of airways  
    ├── bronchinet        -> 3D-Unet developed for airway lumen segmentations
    ├── Dockerfile        -> Dockerfile for building docker image of the pipeline  
    ├── legacy            -> resources for compiling /playground tools  
    ├── opfront           -> Opfront tools for segmenting airway lumen and wall surfaces  
    ├── phantom_trainer   -> Set of tools for automatically determining parameters for the opfront tool  
    ├── playground        -> set of tools for post-processin opfront results  
    ├── README.md         -> This file.  
    ├── requirements.txt  -> List of required packages for python tools. Install with pip install -r requirements.txt  
    ├── run_scripts       -> Bash scripts used to automate the docker image. 
    ├── test_docker.sh    -> Script to rapidly run docker container into bash for testing/debugging.  
    └── util              -> Set of utility scripts for manipulating volume/segmentation files.
