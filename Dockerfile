# Choose the base image in for the compilation environment
FROM ubuntu:trusty AS builder

# Prepare building tools and libraries
RUN apt-get update && apt-get install -y cmake wget build-essential uuid-dev libgmp-dev libmpfr-dev libnifti-dev libx11-dev libboost-all-dev
RUN apt-get install -y --no-install-recommends libgts-dev libsdl2-dev libsdl2-2.0 libcgal-dev libgsl0-dev


# OPFRONT and PLAYGROUND
# -----------------------------------------
WORKDIR /lungseg

# COPY SOURCECODE
COPY ["./legacy/", "./legacy/"]
COPY ["./opfront", "/opfront/"]
COPY ["./playground/", "./playground/"]
RUN tar xf ./playground/thirdparty.tar.gz -C ./playground
RUN mv ./playground/thirdparty/CImg.h /usr/include/CImg.h
RUN mkdir /opfront/thirdparty && mv ./playground/thirdparty/maxflow-v3.04.src /opfront/thirdparty
RUN mkdir /opfront/bin && cd /opfront/bin && cmake /opfront/src && make -j install

# 2. ITK - PATCHED VERSION - Pre-compiler mod.
RUN mkdir -p playground/thirdparty/itkbin && \
        cd playground/thirdparty/itkbin && \
        cmake -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_TESTING:BOOL=OFF -DBUILD_SHARED_LIBS:BOOL=ON ../InsightToolkit-3.20.1/ && \
        make -j install

RUN make -C /lungseg/playground/thirdparty/kdtree install



# Compile the playground
RUN make -C /lungseg/playground/src/libac && \
    make -C /lungseg/playground/src/libmy_functions && \
    make -C /lungseg/playground/src/lung_segmentation && \
    make -C /lungseg/playground/src/6con && \
    make -C /lungseg/playground/src/be && \
    make -C /lungseg/playground/src/scale_branch && \
    make -C /lungseg/playground/src/brh_translator && \
    make -C /lungseg/playground/src/connected_brh && \
    make -C /lungseg/playground/src/smooth_brh && \
    make -C /lungseg/playground/src/imgconv && \
    make -C /lungseg/playground/src/gts_ray_measure && \
    make -C /lungseg/playground/src/brh2vol && \
    make -C /lungseg/playground/src/volume_maker

# Copy the tool binaries
RUN mkdir /lungseg/bins && \
    cp /lungseg/playground/src/lung_segmentation/lung_segmentation /lungseg/bins && \
    cp /lungseg/playground/src/6con/6con /lungseg/bins && \
    cp /lungseg/playground/src/be/be /lungseg/bins && \
    cp /lungseg/playground/src/scale_branch/scale_branch /lungseg/bins && \
    cp /lungseg/playground/src/gts_ray_measure/gts_ray_measure /lungseg/bins && \
    cp /lungseg/playground/src/connected_brh/connected_brh /lungseg/bins && \
    cp /lungseg/playground/src/smooth_brh/smooth_brh /lungseg/bins && \
    cp /lungseg/playground/src/imgconv/imgconv /lungseg/bins && \
    cp /lungseg/playground/src/brh_translator/brh_translator /lungseg/bins && \
    cp /lungseg/playground/src/brh2vol/brh2vol /lungseg/bins && \
    cp /lungseg/playground/src/volume_maker/volume_maker /lungseg/bins

RUN make -C /lungseg/playground/src/histogram/ && \
    make -C /lungseg/playground/src/measure_volume && \
    cp /lungseg/playground/src/histogram/histogram /lungseg/bins && \
    cp /lungseg/playground/src/measure_volume/measure_volume /lungseg/bins

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# PART 2: ELECTRIC BOOGALOO - I.E. Try to get this all working with Ubuntu 20.04 and CUDA

# Use the nvidia cuda image as the base
FROM nvidia/cuda:11.2.2-base-ubuntu20.04 AS runtime

# This is where you can change the image information, or force a build to update the cached temporary build images.
LABEL version="0.9.2"
LABEL maintainer="i.dudurych@rug.nl" location="Groningen" type="Hospital" role="Airway Segmentation Tool"


# Update apt and install RUNTIME dependencies (lower size etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.8 python3-pip python-is-python3 \
        dcm2niix dcmtk \
        libnifti2 libx11-6 libglib2.0-0 \
        && apt-get clean

# Copy python requirements.
WORKDIR /bronchinet
COPY ["./bronchinet/requirements.txt", "./"]

#Update the python install based on requirement. No cache to lower image size..
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy binaries and libraries for the opfront and pre/post-processing tools.
COPY --from=builder /lungseg/bins /usr/local/bin
COPY --from=builder /usr/local/bin /usr/local/bin
ADD ["airflow_libs.tar.gz", "."]
RUN mv ./airflow_libs/* /usr/local/lib && ldconfig

# Set up the file structure for CT scan processing.
ENV PYTHONPATH "/bronchinet/src:/bronchinet/airway_analysis"
RUN mkdir ./files && \
        ln -s ./src Code && \
        mkdir -p ./temp_work/files && \
        ln -s ./files ./temp_work/BaseData && \
        ln -s ./temp_work/files BaseData

# Copy the source code to the working directory
COPY ["./bronchinet/src/", "./src/"]
# TODO: Place your own version of the U-Net model into /model_to_dockerise or point to correct folder.
# For default bronchinet, source is ./bronchinet/models
ARG MODEL_DIR=./imalife_models/imalife
COPY ["${MODEL_DIR}", "./model/" ]
COPY ["./util/", "./scripts/util/"]
COPY ["./run_scripts/", "./scripts/"]
RUN pip3 install --no-cache-dir optuna
# Clean up apt-get cache to lower image size
RUN rm -rf /var/lib/apt/lists/*

# Include Airway Analysis Tools
COPY ["./airway_analysis", "./airway_analysis"]

# Include Phantom Training tools
COPY ["./phantom_trainer", "./phantom_trainer"]

# Run Launch script when container starts.
# ENTRYPOINT ["/bronchinet/scripts/run_machine.sh"]
ENTRYPOINT ["/bin/bash"]
# Arguments to pass to launch script.
# CMD ["/eureka/input/*.dcm", "/eureka/output/nifti-series-out"]
