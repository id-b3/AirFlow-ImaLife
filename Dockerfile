FROM ubuntu:trusty AS builder

# Prepare cmake
RUN apt-get update && apt-get install -y cmake wget build-essential uuid-dev libgmp-dev libmpfr-dev libnifti-dev libx11-dev
RUN apt-get install -y --no-install-recommends libgts-dev libsdl2-dev libsdl2-2.0
#RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang-3.9 100 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-3.9 100

# COMMON DEPENDENCIES
# 1. Prepare Boost
#RUN mkdir -p ~/dev/boost && \
 #       cd ~/dev/boost && \
  #      wget -nv https://boostorg.jfrog.io/artifactory/main/release/1.63.0/source/boost_1_63_0.tar.gz && \
   #     tar xzf boost_1_63_0.tar.gz && \
    #    cd boost_1_63_0 && \
     #   ./bootstrap.sh --with-libraries=program_options,timer,system,filesystem,thread,regex,iostreams && \
      #  ./b2 -j12 install
RUN apt-get install -y libboost-all-dev
# OPFRONT
# -----------------------------------------
WORKDIR /opfront
# RUN wget -nv pub.ist.ac.at/~vnk/software/maxflow-v3.04.src.zip && unzip -d /opfront/thirdparty maxflow-v3.04.src.zip

COPY ./opfront .
RUN mv /opfront/thirdparty/CImg.h /usr/include/CImg.h
RUN mkdir /opfront/bin && cd /opfront/bin && cmake /opfront/src && make -j16 install

# PLAYGROUND
# -----------------------------------------

WORKDIR /lungseg

# 2. ITK - PATCHED VERSION - Pre-compiler mod.
COPY ./InsightToolkit-3.20.1 ./InsightToolkit-3.20.1
RUN mkdir itkbin && cd itkbin && cmake -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_TESTING:BOOL=OFF -DBUILD_SHARED_LIBS:BOOL=ON ../InsightToolkit-3.20.1/ && make -j install
# RUN cp /usr/local/lib/InsightToolkit/* /usr/lib

RUN apt install -y --no-install-recommends libcgal-dev libgsl0-dev

# -----------------------------------------
# SOURCECODE
COPY ["./legacy/", "./legacy/"]
# COPY ["./cmake/", "./cmake/"]

COPY ["./playground/", "./playground/"]

RUN make -C /lungseg/playground/thirdparty/kdtree install

RUN make -C /lungseg/playground/src/libac && \
    make -C /lungseg/playground/src/libmy_functions && \
    make -C /lungseg/playground/src/lung_segmentation && \
    make -C /lungseg/playground/src/6con && \
    make -C /lungseg/playground/src/be && \
    make -C /lungseg/playground/src/scale_branch && \
    make -C /lungseg/playground/src/gts_ray_measure && \
    make -C /lungseg/playground/src/connected_brh && \
    make -C /lungseg/playground/src/smooth_brh

RUN make -C /lungseg/playground/src/brh_translator && \
    make -C /lungseg/playground/src/imgconv

RUN mkdir /lungseg/bins && \
    cp /lungseg/playground/src/lung_segmentation/lung_segmentation /lungseg/bins && \
    cp /lungseg/playground/src/6con/6con /lungseg/bins && \
    cp /lungseg/playground/src/be/be /lungseg/bins && \
    cp /lungseg/playground/src/scale_branch/scale_branch /lungseg/bins && \
    cp /lungseg/playground/src/gts_ray_measure/gts_ray_measure /lungseg/bins && \
    cp /lungseg/playground/src/connected_brh/connected_brh /lungseg/bins && \
    cp /lungseg/playground/src/smooth_brh/smooth_brh /lungseg/bins

RUN cp /lungseg/playground/src/imgconv/imgconv /lungseg/bins && \
    cp /lungseg/playground/src/brh_translator/brh_translator /lungseg/bins

# PART 2: ELECTRIC BOOGALOO - I.E. Try to get this all working with Ubuntu 20.04 and CUDA

FROM nvidia/cuda:11.2.2-base-ubuntu20.04 AS runtime

LABEL version="0.2"
LABEL maintainer="i.dudurych@rug.nl" location="Groningen" type="Hospital" role="Airway Segmentation Tool"

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.8 python3-pip \
        dcm2niix dcmtk \
        && apt-get clean

WORKDIR /bronchinet
COPY ["./bronchinet/requirements.txt", "./bronchinet/test_environment.py", "./"]

#Update the python install based on requirements and run a test file.
RUN pip3 install -r requirements.txt && python3 test_environment.py
RUN apt-get install python-is-python3

# Copy binaries and libraries for the opfront and pre/post-processing tools.
COPY --from=builder /lungseg/bins /usr/local/bin
COPY --from=builder /usr/local/bin /usr/local/bin
COPY ["./airflow_libs", "/usr/local/lib"]
#COPY --from=builder ["/usr/local/lib/InsightToolkit/", "/usr/local/lib/libkdtree.a", "/usr/local/lib/libkdtree.so", "/usr/local/lib/libkdtree.so.0", "/usr/local/lib/libkdtree.so.0.1", "/usr/local/lib/"]
# COPY --from=builder /usr/lib /airflow/libs

RUN apt-get install -y libnifti2 libx11-6 libglib2.0-0

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
COPY ["./run_machine.sh", "./"]

# Test the container set up correctly and try a help file.
# ENTRYPOINT ["./predict.sh"]

ENTRYPOINT ["/bin/bash"]
