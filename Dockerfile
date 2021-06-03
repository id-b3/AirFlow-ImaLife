FROM ubuntu:trusty AS builder

# Prepare building tools and libraries
RUN apt-get update && apt-get install -y cmake wget build-essential uuid-dev libgmp-dev libmpfr-dev libnifti-dev libx11-dev libboost-all-dev
RUN apt-get install -y --no-install-recommends libgts-dev libsdl2-dev libsdl2-2.0 libcgal-dev libgsl0-dev

# OPFRONT
# -----------------------------------------
WORKDIR /opfront
COPY ./opfront .
RUN mv /opfront/thirdparty/CImg.h /usr/include/CImg.h
RUN mkdir /opfront/bin && cd /opfront/bin && cmake /opfront/src && make -j16 install

# PLAYGROUND
# -----------------------------------------
WORKDIR /lungseg

# 2. ITK - PATCHED VERSION - Pre-compiler mod.
COPY ./playground/thirdparty/InsightToolkit-3.20.1 ./InsightToolkit-3.20.1
RUN mkdir itkbin && cd itkbin && cmake -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_TESTING:BOOL=OFF -DBUILD_SHARED_LIBS:BOOL=ON ../InsightToolkit-3.20.1/ && make -j install

# -----------------------------------------
# SOURCECODE
COPY ["./legacy/", "./legacy/"]
COPY ["./playground/", "./playground/"]

RUN make -C /lungseg/playground/thirdparty/kdtree install

# Compile the tools
RUN make -C /lungseg/playground/src/libac && \
    make -C /lungseg/playground/src/libmy_functions && \
    make -C /lungseg/playground/src/lung_segmentation && \
    make -C /lungseg/playground/src/6con && \
    make -C /lungseg/playground/src/be && \
    make -C /lungseg/playground/src/scale_branch && \
    make -C /lungseg/playground/src/gts_ray_measure && \
    make -C /lungseg/playground/src/connected_brh && \
    make -C /lungseg/playground/src/smooth_brh && \
    make -C /lungseg/playground/src/brh_translator && \
    make -C /lungseg/playground/src/imgconv
RUN make -C /lungseg/playground/src/brh2vol

# Copy the tools
RUN mkdir /lungseg/bins && \
    cp /lungseg/playground/src/lung_segmentation/lung_segmentation /lungseg/bins && \
    cp /lungseg/playground/src/6con/6con /lungseg/bins && \
    cp /lungseg/playground/src/be/be /lungseg/bins && \
    cp /lungseg/playground/src/scale_branch/scale_branch /lungseg/bins && \
    cp /lungseg/playground/src/gts_ray_measure/gts_ray_measure /lungseg/bins && \
    cp /lungseg/playground/src/connected_brh/connected_brh /lungseg/bins && \
    cp /lungseg/playground/src/smooth_brh/smooth_brh /lungseg/bins && \
    cp /lungseg/playground/src/imgconv/imgconv /lungseg/bins && \
    cp /lungseg/playground/src/brh_translator/brh_translator /lungseg/bins
RUN cp /lungseg/playground/src/brh2vol/brh2vol /lungseg/bins
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# PART 2: ELECTRIC BOOGALOO - I.E. Try to get this all working with Ubuntu 20.04 and CUDA

# Use the nvidia cuda image as the base
FROM nvidia/cuda:11.2.2-base-ubuntu20.04 AS runtime

# This is where you can change the image information, or force a build to update the cached temporary build images.
LABEL version="0.9.1"
LABEL maintainer="i.dudurych@rug.nl" location="Groningen" type="Hospital" role="Airway Segmentation Tool"

# Update apt and install RUNTIME dependencies (lower size etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.8 python3-pip python-is-python3 \
        dcm2niix dcmtk \
        libnifti2 libx11-6 libglib2.0-0 \
        && apt-get clean

# Copy python requirements document.
WORKDIR /bronchinet
COPY ["./bronchinet/requirements.txt", "./"]

#Update the python install based on requirements and run a test file.Hi
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy binaries and libraries for the opfront and pre/post-processing tools.
COPY --from=builder /lungseg/bins /usr/local/bin
COPY --from=builder /usr/local/bin /usr/local/bin
COPY ["./airflow_libs", "/usr/lib"]
RUN ldconfig

# Set up the file structure for CT scan processing.
ENV PYTHONPATH "/bronchinet/src"
RUN mkdir ./files && \
        ln -s ./src Code && \
        mkdir -p ./temp_work/files && \
        ln -s ./files ./temp_work/BaseData && \
        ln -s ./temp_work/files BaseData

# Copy the source code to the working directory
COPY ["./bronchinet/src/", "./src/"]
COPY ["./bronchinet/model_to_dockerise/", "./model/" ]
COPY ["./run_machine.sh", "./util/fix_transfer_syntax.py", "./scripts/"]
COPY ["./airway_measures_COPDgene/", "./scripts/"]

# RUN apt install -y vim
RUN rm -rf /var/lib/apt/lists/*
# Open bash when running container.
# ENTRYPOINT ["/bin/bash"]

ENTRYPOINT ["/bin/bash"]
#ENTRYPOINT ["/bronchinet/scripts/run_machine.sh"]
# CMD ["/eureka/input/*.dcm", "/eureka/output/nifti-series-out"]
