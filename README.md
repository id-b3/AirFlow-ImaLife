# AirFlow-ImaLife
***Pipeline for automated calculation of bronchial parameters***

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
    ├── <i>AirMorph</i>     -> Lobar lung segmentation and lobar airway branch labelling.  
    ├── <i>airflow_legacy</i>      -> Legacy resources for compiling pre/post processing tools.  
    ├── airway_analysis     -> Package processing opfront output and calculating bronchial parameters.
    ├── <i>bronchinet</i>          -> 3D-Unet developed for airway lumen segmentations.  
    ├── <i>opfront</i>          -> Opfront tools for segmenting airway lumen and wall surfaces.  
    ├── phantom_trainer     -> Set of tools for automatically determining parameters for the opfront tool  
    ├── run_scripts         -> Bash scripts used to automate the docker image.  
    ├─────── Dockerfile          -> Dockerfile for the pipeline  
    ├─────── airflow_libs.tar.gz -> Package containing compiled legacy runtime libraries for opfront tools.  
    ├─────── README.md           -> This file.  
    ├─────── requirements.txt    -> List of required packages for airflow docker. Install with pip install -r requirements.txt  
    <i>Submodules in italics.</i>
</pre>
