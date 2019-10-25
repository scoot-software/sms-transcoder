# Scoot Media Streamer Transcoder
Scoot Media Streamer uses FFmpeg to parse and transcode media. You can follow the instructions below to build a version of FFmpeg which enables the full functionality of SMS Server on Linux.

## Dependencies
### Ubuntu
``` bash
sudo apt-get install \
    autoconf \
    automake \
    build-essential \
    cmake \
    libfdk-aac-dev \
    libmp3lame-dev \
    libnuma-dev \
    libogg-dev \
    libtool \
    libva-dev \
    libvorbis-dev \
    libx264-dev \
    ocl-icd-opencl-dev \
    opencl-headers \
    pkg-config \
    tar \
    texinfo \
    unzip \
    wget \
    zlib1g-dev
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

