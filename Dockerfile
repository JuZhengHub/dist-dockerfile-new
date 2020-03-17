FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu16.04

MAINTAINER zhengju@nuctech.com

# add tsinghua
COPY proxy/sources.list /etc/apt/sources.list
COPY proxy/.pip/ /root/.pip/

RUN rm -rf /etc/apt/sources.list.d/* && apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get update -o Acquire-by-hash=yes -o Acquire::https::No-Cache=True -o Acquire::http::No-Cache=True && \
    apt-get install -y --allow-downgrades --allow-change-held-packages --no-install-recommends \
    build-essential software-properties-common cmake git wget curl vim g++-4.8 ca-certificates cifs-utils nfs-common pciutils \
    python-dev python3-dev python-setuptools python3-setuptools python-pip python3-pip python-opencv \
    libjpeg-dev libpng-dev udev libcap2 kmod libnuma1 && \
    rm -rf /etc/apt/sources.list.d/* 

# Download and install Mellanox OFED 5.0-1.0.0.0 for Ubuntu 16.04
# COPY ./MLNX_OFED_LINUX-5.0-1.0.0.0-ubuntu16.04-x86_64.tgz /root
# # # RUN wget http://content.mellanox.com/ofed/MLNX_OFED-5.0-1.0.0.0/MLNX_OFED_LINUX-5.0-1.0.0.0-ubuntu16.04-x86_64.tgz && \
# RUN cd /root && \
RUN wget http://content.mellanox.com/ofed/MLNX_OFED-5.0-1.0.0.0/MLNX_OFED_LINUX-5.0-1.0.0.0-ubuntu16.04-x86_64.tgz && \
    tar -xzvf MLNX_OFED_LINUX-5.0-1.0.0.0-ubuntu16.04-x86_64.tgz && \
    MLNX_OFED_LINUX-5.0-1.0.0.0-ubuntu16.04-x86_64/mlnxofedinstall --user-space-only --without-fw-update --all -q && \
    cd .. && \
    rm -rf ${MOFED_DIR} && \
    rm -rf *.tgz

RUN python3 -m pip install --no-cache-dir future typing numpy lxml opencv-python scikit-learn tensorflow-gpu==1.14.0 keras h5py mxnet-cu100 torch torchvision

# Install Open MPI
RUN ln -s /usr/lib/x86_64-linux-gnu/libnuma.so.1 /usr/lib/x86_64-linux-gnu/libnuma.so && \
    mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://www.open-mpi.org/software/ompi/v3.1/downloads/openmpi-3.1.5.tar.gz && \
    tar zxf openmpi-3.1.5.tar.gz && \
    cd openmpi-3.1.5 && \
    ./configure --enable-orterun-prefix-by-default && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi

# Install Horovod, temporarily using CUDA stubs
RUN ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs && \
    HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_GPU_BROADCAST=NCCL HOROVOD_WITH_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 HOROVOD_WITH_MXNET=1 \
         pip install --no-cache-dir horovod && \
    ldconfig

# Install OpenSSH for MPI to communicate between containers
RUN apt-get install -y --no-install-recommends openssh-client openssh-server && \
    mkdir -p /var/run/sshd

# Allow OpenSSH to talk to containers without asking for confirmation
RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

