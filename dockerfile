FROM nvidia/cuda:11.7.0-devel-ubuntu20.04
ENV DEBIAN_FRONTEND noninteractive

ENV CUDNN_VERSION=8.5.0.96-1+cuda11.7
ENV NCCL_VERSION=2.13.4-1+cuda11.7


ARG python=3.8
ENV PYTHON_VERSION=${python}

# Set default shell to /bin/bash
SHELL ["/bin/bash", "-cu"]

#RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN apt-get clean
RUN apt-get update && apt-get install openssh-server -y
RUN service ssh start

RUN apt-get update &&  apt-get install -y --allow-downgrades \
    --allow-change-held-packages --no-install-recommends \
    build-essential \
    sudo \
    cmake \
    git \
    bzip2 \
    curl \
    vim \
    wget \
    w3m \
    libx11-6 \
    gcc \
    g++ \
    libusb-1.0.0 \
    libssl-dev \
    ca-certificates \
    libcudnn8=${CUDNN_VERSION} \
    libnccl2=${NCCL_VERSION} \
    libnccl-dev=${NCCL_VERSION} \
    libjpeg-dev \
    libpng-dev \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-distutils \
    librdmacm1 \
    libibverbs1 \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y python3-opencv \
&& rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python

RUN nvcc --version 

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip install --upgrade pip

ENV TORCH_CUDA_ARCH_LIST="8.0"

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash liulj \
 && chown -R liulj:liulj /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-liulj
USER liulj

# All users can use /home/user as their home directory
ENV HOME=/home/liulj
RUN chmod 777 /home/liulj

# Install Miniconda and Python 3.8
ENV CONDA_AUTO_UPDATE_CONDA=false
ENV PATH=/home/liulj/miniconda/bin:$PATH
RUN curl -sLo ~/miniconda.sh https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py38_4.8.3-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh \
 && conda install -y python==3.8.3 \
 && conda clean -ya
RUN conda config --set show_channel_urls yes 
# && ls -alh && pwd && ls /home/liulj -alh
# COPY --chown=liulj .condarc /home/liulj/.condarc

RUN cd /home/liulj
RUN conda config --env --set always_yes true
RUN conda update -n base -c defaults conda -y

COPY environment.yml environment.yml
RUN conda env create -f environment.yml

RUN conda init bash 


