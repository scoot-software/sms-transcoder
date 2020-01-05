#!/bin/bash

set -e
set -u

ENV_ROOT=`pwd`

BUILD_DIR="${BUILD_DIR:-$ENV_ROOT/build}"
TARGET_DIR="${TARGET_DIR:-$ENV_ROOT/target}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$ENV_ROOT/download}"
BIN_DIR="${BIN_DIR:-$ENV_ROOT/bin}"

LDFLAGS="-L${TARGET_DIR}/lib"
PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig"
CFLAGS="-I${TARGET_DIR}/include $LDFLAGS"
PATH="${TARGET_DIR}/bin:${PATH}"

FFMPEG_CONFIG="\
    --disable-debug \
    --enable-pic \
    --enable-gpl \
    --enable-nonfree \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-indevs \
    --disable-outdevs \
    --enable-vaapi \
    --disable-alsa \
    --disable-appkit \
    --disable-avfoundation \
    --disable-bzlib \
    --disable-coreimage \
    --disable-iconv \
    --enable-libfdk-aac \
    --enable-libmp3lame \
    --enable-libvorbis \
    --enable-libx264 \
    --enable-libx265 \
    --disable-lzma \
    --enable-opencl \
    --disable-sndio \
    --disable-schannel \
    --disable-sdl2 \
    --disable-securetransport \
    --disable-xlib \
    --enable-libzimg \
    --disable-zlib
"

# Download
download () {
    echo "*** Downloading Yasm ***"
    wget -N http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz -O "$DOWNLOAD_DIR"/yasm.tar.gz
    tar -xf "$DOWNLOAD_DIR"/yasm.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading Nasm ***"
    wget -N https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.gz -O "$DOWNLOAD_DIR"/nasm.tar.gz
    tar -xf "$DOWNLOAD_DIR"/nasm.tar.gz -C "$BUILD_DIR"
    
    echo "*** Downloading NVIDIA Headers ***"
    wget -N https://github.com/FFmpeg/nv-codec-headers/releases/download/n9.1.23.1/nv-codec-headers-9.1.23.1.tar.gz -O "$DOWNLOAD_DIR"/nv-codec-headers.tar.gz
    tar -xf "$DOWNLOAD_DIR"/nv-codec-headers.tar.gz -C "$BUILD_DIR"
    
    echo "*** Downloading zimg ***"
    wget -N https://github.com/sekrit-twc/zimg/archive/release-2.9.2.tar.gz -O "$DOWNLOAD_DIR"/zimg.tar.gz
    tar -xf "$DOWNLOAD_DIR"/zimg.tar.gz -C "$BUILD_DIR"
    
    echo "*** Downloading x265 ***"
    wget -N https://bitbucket.org/multicoreware/x265/downloads/x265_3.2.tar.gz -O "$DOWNLOAD_DIR"/x265.tar.gz
    tar -xf "$DOWNLOAD_DIR"/x265.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading FFmpeg ***"
    wget -N https://github.com/FFmpeg/FFmpeg/archive/n4.2.1.zip -O "$DOWNLOAD_DIR"/ffmpeg.zip
    unzip "$DOWNLOAD_DIR"/ffmpeg.zip -d "$BUILD_DIR"
}

# Build
build () {
    # Yasm
    echo "*** Building Yasm ***"
    cd $BUILD_DIR/yasm*
    ./configure --prefix=$TARGET_DIR --bindir=$BIN_DIR
    make
    make install

    # Nasm
    echo "*** Building Nasm ***"
    cd $BUILD_DIR/nasm*
    ./configure --prefix=$TARGET_DIR --bindir=$BIN_DIR
    make
    make install

    # Nvidia Headers
    echo "*** Building NVIDIA Headers ***"
    cd $BUILD_DIR/nv-codec-headers*
    make PREFIX=$TARGET_DIR
    make install PREFIX=$TARGET_DIR
    
    # zimg
    echo "*** Building zimg ***"
    cd $BUILD_DIR/zimg*
    ./autogen.sh
    ./configure --prefix=$TARGET_DIR --disable-shared --enable-static
    make
    make install
    
    # x265
    echo "*** Building x265 ***"
    cd $BUILD_DIR/x265*/build/linux
    PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DENABLE_SHARED=off ../../source
    PATH="$BIN_DIR:$PATH" make
    make install

    # FFmpeg
    echo "*** Building FFmpeg ***"
    cd $BUILD_DIR/FFmpeg*
    PATH="$BIN_DIR:$PATH" PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig" ./configure \
    --extra-cflags="-I$TARGET_DIR/include" \
    --extra-ldflags="-L$TARGET_DIR/lib" \
    --extra-libs="-lpthread -lm -lz" \
    --pkg-config-flags="--static" \
    ${FFMPEG_CONFIG}

    PATH="$BIN_DIR:$PATH" make -j 4
}

install () {
    # FFmpeg
    echo "*** Install FFmpeg ***"
    cd $BUILD_DIR/FFmpeg*
    make install
    ldconfig
}

clean () {
    echo "*** Cleaning build directories ***"
    rm -rf "$BUILD_DIR" "$TARGET_DIR" "$DOWNLOAD_DIR" "$BIN_DIR"
}

while getopts ':ico:' OPTION
do
  case $OPTION in
  i)
      install
      exit 0
      ;;
  c)
      clean
      exit 0
      ;;
  o)
      if [[ $OPTARG == *"nvidia"* ]]; then
          FFMPEG_CONFIG+=" --enable-cuvid --enable-cuda-nvcc"
      fi
      ;;
  ?)
      printf "Usage: %s [-i] [-c] [-o nvidia]\n" $(basename $0) >&2
      exit 2
      ;;
  esac
done
shift $(($OPTIND - 1))

# Remove old build
rm -rf "$BUILD_DIR" "$TARGET_DIR" "$BIN_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR" "$DOWNLOAD_DIR" "$BIN_DIR"

download
build
