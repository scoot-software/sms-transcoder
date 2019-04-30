#!/bin/sh

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

# Download
download () {
    echo "*** Downloading Yasm ***"
    wget -N http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/yasm-1.3.0.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading Nasm ***"
    wget -N https://www.nasm.us/pub/nasm/releasebuilds/2.13.03/nasm-2.13.03.tar.gz -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/nasm-2.13.03.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading x264 ***"
    wget -N ftp://ftp.videolan.org/pub/videolan/x264/snapshots/last_x264.tar.bz2 -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/last_x264.tar.bz2 -C "$BUILD_DIR"

    echo "*** Downloading x265 ***"
    wget -N https://bitbucket.org/multicoreware/x265/downloads/x265_3.0.tar.gz -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/x265_3.0.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading Fraunhofer FDK AAC ***"
    wget -N https://github.com/mstorsjo/fdk-aac/archive/v0.1.6.tar.gz -O "$DOWNLOAD_DIR"/fdk-aac-v0.1.6.tar.gz
    tar -xf "$DOWNLOAD_DIR"/fdk-aac-v0.1.6.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading LAME MP3 ***"
    wget -N https://datapacket.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/lame-3.100.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading Ogg ***"
    wget -N http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/libogg-1.3.3.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading Vorbis ***"
    wget -N http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.gz -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/libvorbis-1.3.6.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading NVIDIA Headers ***"
    wget -N https://github.com/FFmpeg/nv-codec-headers/releases/download/n8.1.24.2/nv-codec-headers-8.1.24.2.tar.gz -P "$DOWNLOAD_DIR"
    tar -xf "$DOWNLOAD_DIR"/nv-codec-headers-8.1.24.2.tar.gz -C "$BUILD_DIR"

    echo "*** Downloading FFmpeg ***"
    wget -N https://github.com/FFmpeg/FFmpeg/archive/n4.1.3.tar.gz -O "$DOWNLOAD_DIR"/ffmpeg.tar.gz
    tar -xf "$DOWNLOAD_DIR"/ffmpeg.tar.gz -C "$BUILD_DIR"
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

    # x264
    echo "*** Building x264 ***"
    cd $BUILD_DIR/x264*
    PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR --enable-static --disable-opencl --enable-pic
    PATH="$BIN_DIR:$PATH" make -j 2
    make install

    echo "*** Building x265 ***"
    cd $BUILD_DIR/x265*
    cd build/linux
    PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DENABLE_SHARED:BOOL=OFF -DSTATIC_LINK_CRT:BOOL=ON -DENABLE_CLI:BOOL=OFF ../../source
    sed -i 's/-lgcc_s/-lgcc_eh/g' x265.pc
    make -j 2
    make install

    echo "*** Building Fraunhofer FDK AAC ***"
    cd $BUILD_DIR/fdk-aac*
    autoreconf -fiv
    ./configure --prefix=$TARGET_DIR --disable-shared
    make -j 2
    make install

    echo "*** Building LAME MP3 ***"
    cd $BUILD_DIR/lame*
    ./configure --prefix=$TARGET_DIR --enable-nasm --disable-shared
    make
    make install

    echo "*** Building Ogg ***"
    cd $BUILD_DIR/libogg*
    ./configure --prefix=$TARGET_DIR --disable-shared
    make
    make install

    echo "*** Building Vorbis ***"
    cd $BUILD_DIR/libvorbis*
    ./configure --prefix=$TARGET_DIR --with-ogg=$TARGET_DIR --disable-shared
    make
    make install

    echo "*** Building NVIDIA Headers ***"
    cd $BUILD_DIR/nv-codec-headers*
    make PREFIX=$TARGET_DIR
    make install PREFIX=$TARGET_DIR

    # FFmpeg
    echo "*** Building FFmpeg ***"
    cd $BUILD_DIR/FFmpeg*
    PATH="$BIN_DIR:$PATH" PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig" ./configure \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$TARGET_DIR/include" \
    --extra-ldflags="-L$TARGET_DIR/lib" \
    --extra-libs="-lpthread" \
    --enable-static \
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
    --enable-cuvid \
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
    --disable-zlib

    PATH="$BIN_DIR:$PATH" make -j 4
}

install () {
    # FFmpeg
    echo "*** Install FFmpeg ***"
    cd $BUILD_DIR/FFmpeg*
    make install
}

clean () {
    echo "*** Cleaning build directories ***"
    rm -rf "$BUILD_DIR" "$TARGET_DIR" "$DOWNLOAD_DIR" "$BIN_DIR"
}

while getopts ':ic' OPTION
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
  ?)
      printf "Usage: %s [-i] [-c]\n" $(basename $0) >&2
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
