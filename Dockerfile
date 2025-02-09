# Choose the base image in for the compilation environment
FROM ubuntu:trusty AS playground_builder

# Prepare building tools and libraries
RUN apt-get update && apt-get install -y cmake wget build-essential uuid-dev libgmp-dev libmpfr-dev libnifti-dev libx11-dev libboost-all-dev
RUN apt-get install -y --no-install-recommends libgts-dev libsdl2-dev libsdl2-2.0 libcgal-dev libgsl0-dev

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Legacy Tools
WORKDIR /lungseg

# COPY SOURCECODE
COPY ["./airflow_legacy/legacy/", "./legacy/"]
COPY ["./airflow_legacy/playground/", "./playground/"]
RUN tar xf ./playground/thirdparty.tar.gz -C ./playground
RUN mv ./playground/thirdparty/CImg.h /usr/include/CImg.h

# 2. ITK - PATCHED VERSION - Pre-compiler mod.
RUN mkdir -p playground/thirdparty/itkbin && \
        cd playground/thirdparty/itkbin && \
        cmake -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_TESTING:BOOL=OFF -DBUILD_SHARED_LIBS:BOOL=ON ../InsightToolkit-3.20.1/ && \
        make -j install

RUN make -C /lungseg/playground/thirdparty/kdtree install

# Compile the necessary tools
RUN make -C /lungseg/playground/src/libac && \
    make -C /lungseg/playground/src/libmy_functions && \
    make -C /lungseg/playground/src/lung_segmentation && \
    make -C /lungseg/playground/src/6con && \
    make -C /lungseg/playground/src/be && \
    make -C /lungseg/playground/src/scale_branch && \
    make -C /lungseg/playground/src/brh_translator && \
    make -C /lungseg/playground/src/connected_brh && \
    make -C /lungseg/playground/src/gts_ray_measure && \
    make -C /lungseg/playground/src/brh2vol && \
    make -C /lungseg/playground/src/volume_maker && \
    make -C /lungseg/playground/src/measure_volume && \
    make -C /lungseg/playground/src/histogram && \
    make -C /lungseg/playground/src/thumbnail

# Copy the tool binaries
RUN mkdir /lungseg/bins && \
    cp /lungseg/playground/src/lung_segmentation/lung_segmentation /lungseg/bins && \
    cp /lungseg/playground/src/6con/6con /lungseg/bins && \
    cp /lungseg/playground/src/be/be /lungseg/bins && \
    cp /lungseg/playground/src/scale_branch/scale_branch /lungseg/bins && \
    cp /lungseg/playground/src/gts_ray_measure/gts_ray_measure /lungseg/bins && \
    cp /lungseg/playground/src/connected_brh/connected_brh /lungseg/bins && \
    cp /lungseg/playground/src/brh_translator/brh_translator /lungseg/bins && \
    cp /lungseg/playground/src/brh2vol/brh2vol /lungseg/bins && \
    cp /lungseg/playground/src/volume_maker/volume_maker /lungseg/bins && \
    cp /lungseg/playground/src/histogram/histogram /lungseg/bins && \
    cp /lungseg/playground/src/measure_volume/measure_volume /lungseg/bins && \
    cp /lungseg/playground/src/thumbnail/thumbnail /lungseg/bins

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# PART 2: OPFRONT COMPILATION
FROM ubuntu:focal as opfront_builder

# Prepare cmake
ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y cmake build-essential
WORKDIR /opfront

# -----------------------------------------
# DEPENDENCIES
# 2. Prepare NiftiCLib, GTS, CImg
RUN apt-get install -y --no-install-recommends libboost-all-dev libgts-dev libnifti-dev libsdl2-dev libsdl2-2.0 wget unzip

# CIMG
RUN wget -nv https://github.com/dtschump/CImg/archive/refs/tags/v.179.zip && \
        unzip -d /opfront/thirdparty v.179.zip && \
        mv /opfront/thirdparty/CImg-v.179/CImg.h /usr/include/CImg.h

# ----------------------------------------
# Copy source and compile
COPY ./opfront/src /opfront/src
COPY ./opfront/thirdparty /opfront/thirdparty
WORKDIR /opfront/bin
RUN cmake /opfront/src
RUN make -j install

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# PART 3: Move compiled bins to cuda image. Port libraries.
# Use the nvidia cuda image as the base
FROM nvidia/cuda:11.2.2-base-ubuntu20.04 AS runtime

# This is where you can change the image information, or force a build to update the cached temporary build images.
LABEL version="ima_1.0"
LABEL maintainer="i.dudurych@rug.nl" location="Groningen" type="Hospital" role="Airway Segmentation Tool"
LABEL model="24_ImaLife_Masked"
LABEL descrption="Version ima_1.0: Using Bronchinet model trained on 24 ImaLife scans with large airway masking."

# Get latest key from nvidia
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub

# Update apt and install RUNTIME dependencies (lower size etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.8 python3-pip python-is-python3 \
    dcm2niix dcmtk pigz \
    openctm-tools admesh \
    libgts-bin \
    libnifti2 libx11-6 libglib2.0-0 \
    libboost-program-options1.71.0 \
    && apt-get clean

# Copy python requirements.
WORKDIR /airflow
COPY ["./bronchinet/requirements_torch.txt", "./requirements.txt", "./"]

#Update the python install based on requirement. No cache to lower image size..
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir -r requirements_torch.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy binaries and libraries for the opfront and pre/post-processing tools.
COPY --from=playground_builder /lungseg/bins /usr/local/bin
COPY --from=opfront_builder /usr/local/bin /usr/local/bin
ADD ["airflow_libs.tar.gz", "."]
RUN mv ./airflow_libs/* /usr/local/lib && ldconfig

# Set up the file structure for CT scan processing.
ENV PYTHONPATH "/airflow/bronchinet/src:/airflow/AirMorph"
RUN mkdir ./files && \
    ln -s /airflow/bronchinet/src Code && \
    mkdir -p ./temp_work/files && \
    ln -s ./files ./temp_work/BaseData && \
    ln -s ./temp_work/files BaseData

# Copy the source code to the working directory
COPY ["./bronchinet/src/", "./bronchinet/src/"]
# TODO: Place your own version of the U-Net model into /model_to_dockerise or point to correct folder.
# For default bronchinet, source is ./bronchinet/models
ARG MODEL_DIR=./imalife_models/imalife_2
COPY ["${MODEL_DIR}", "./model/"]
COPY ["./scripts/", "./scripts/"]
# Clean up apt-get cache to lower image size
RUN rm -rf /var/lib/apt/lists/*
COPY ["./AirMorph", "./AirMorph"]

# Run Launch script when container starts.
ENTRYPOINT ["/airflow/scripts/run_machine.sh"]
# Arguments to pass to launch script.

CMD ["/input", "/output"]
