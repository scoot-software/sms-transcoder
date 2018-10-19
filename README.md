# Scoot Media Streamer Transcoder
Scoot Media Streamer uses FFmpeg to parse and transcode media. You can follow the instructions below to build a version of FFmpeg which enables the full functionality of SMS Server on Linux.

## Dependencies
### Ubuntu
``` bash
sudo apt-get install \
    build-essential \
    tar \
    unzip \
    libtool \
    cmake \
    automake \
    autoconf \
    pkg-config \
    wget \
    libva-dev \
    ocl-icd-opencl-dev \
    opencl-headers
```

## Optional Dependencies
### Intel OpenCL Support
``` bash
sudo apt-get install \
    beignet \
    beignet-opencl-icd
```

## Build
``` bash
git clone https://github.com/scoot-software/sms-transcoder.git
cd sms-transcoder
./build.sh
sudo ./build.sh -i
```

