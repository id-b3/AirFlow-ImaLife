# ImaLife Air-Flow Pipeline

[![CodeFactor](https://www.codefactor.io/repository/github/id-b3/air_flow_imalife/badge?s=1dae3aeee26afb253ec4aedd3b702d828daacdf3)](https://www.codefactor.io/repository/github/id-b3/air_flow_imalife)
[![GitHub Super-Linter](https://github.com/id-b3/air_flow_imalife/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter) [![Docker](https://github.com/id-b3/Air_Flow_ImaLife/actions/workflows/docker-publish.yml/badge.svg?branch=optimise_phantom)](https://github.com/id-b3/Air_Flow_ImaLife/actions/workflows/docker-publish.yml)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
-------------------

## Introduction
This repo combines a number of tools into an automated process for the
extraction and measurement of bronchial parameters on a low-dose CT scan.

It combines the 3D-Unet method [bronchinet](/bronchinet) to obtain the initial airway lumen segmentation.
This is followed by the [Opfront](/opfront) method which uses optimal-surface graph-cut to separate the inner surface of the airway from the outer surface of the airway.
From this, various bronchial parameters can be derived.

## Repository Structure
<pre>
    .
    ├── airway_analysis     -> python code for processing opfront output and producing summary measures of airways  
    ├── <i>bronchinet</i>          -> 3D-Unet developed for airway lumen segmentations 
    ├── <i>legacy</i>              -> resources for compiling /playground tools  
    ├── <i>opfront</i>             -> Opfront tools for segmenting airway lumen and wall surfaces  
    ├── phantom_trainer     -> Set of tools for automatically determining parameters for the opfront tool  
    ├── <i>playground</i>          -> set of tools for post-processin opfront results  
    ├── run_scripts         -> Bash scripts used to automate the docker image. 
    ├── util                -> Set of utility scripts for manipulating volume/segmentation files.
    ├─────── Dockerfile          -> Dockerfile for building docker image of the pipeline  
    ├─────── airflow_libs.tar.gz -> Package containing runtime libraries for opfront tools  
    ├─────── README.md           -> This file.  
    ├─────── requirements.txt    -> List of required packages for python tools. Install with pip install -r requirements.txt  
    └─────── test_docker.sh      -> Script to rapidly run docker container into bash for testing/debugging.
    <i>Submodules in italics.</i>
</pre>