FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04
# TensorFlow version is tightly coupled to CUDA and cuDNN so it should be selected carefully
ENV TENSORFLOW_VERSION=1.14.0
ENV PYTORCH_VERSION=1.4.0
ENV TORCHVISION_VERSION=0.5.0
ENV CUDNN_VERSION=7.6.5.32-1+cuda10.0
ENV NCCL_VERSION=2.4.8-1+cuda10.0
ENV MXNET_VERSION=1.6.0

# Python 2.7 or 3.6 is supported by Ubuntu Bionic out of the box
ARG python=3.6
ENV PYTHON_VERSION=${python}

# Set default shell to /bin/bash
SHELL ["/bin/bash", "-cu"]

# add tsinghua
COPY proxy/sources.list /etc/apt/sources.list
COPY proxy/.pip/ /root/.pip/

RUN rm -rf /etc/apt/sources.list.d/* && apt-get update && apt-get install -y --allow-downgrades --allow-change-held-packages --no-install-recommends \
        build-essential \
        cmake \
        g++-4.9 \
        gcc-4.9 \
        git \
        curl \
        vim \
        wget \
        ca-certificates \
        libjpeg-dev \
        libpng-dev \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev 

RUN rm -rf /usr/bin/gcc  && ln -s /usr/bin/gcc-4.9 /usr/bin/gcc && \
    rm -rf /usr/bin/g++ && ln -s /usr/bin/g++-4.9 /usr/bin/g++ && \
    rm -rf /usr/bin/x86_64-linux-gnu-gcc && ln -s /usr/bin/gcc-4.9 /usr/bin/x86_64-linux-gnu-gcc && \
    rm -rf /usr/bin/x86_64-linux-gnu-g++ && ln -s /usr/bin/g++-4.9 /usr/bin/x86_64-linux-gnu-g++ && \
    gcc --version && g++ --version && x86_64-linux-gnu-gcc --version && x86_64-linux-gnu-g++ --version

RUN if [[ "${PYTHON_VERSION}" == "3.6" ]]; then \
        apt-get install -y python${PYTHON_VERSION}-distutils; \
    fi
RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python

COPY ./get-pip.py ./get-pip.py
# RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
RUN python get-pip.py && \
    rm get-pip.py
# RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
#     python get-pip.py && \
#     rm get-pip.py

# Install TensorFlow, Keras, PyTorch and MXNet
RUN pip install future typing numpy \
        tensorflow-gpu==${TENSORFLOW_VERSION} \
        keras \
        h5py

RUN mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-4.0.0.tar.gz && \
    tar zxf openmpi-4.0.0.tar.gz && \
    cd openmpi-4.0.0 && \
    ./configure --enable-orterun-prefix-by-default && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi

# RUN ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs && \
#     HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_GPU_BROADCAST=NCCL HOROVOD_WITH_TENSORFLOW=1  \
#          pip install --no-cache-dir horovod && \
#     ldconfig




