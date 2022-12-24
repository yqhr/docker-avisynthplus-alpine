FROM ubuntu:latest AS base

WORKDIR /tmp/workdir

RUN apt update && \
  apt install -yy \
  build-essential \
  cmake \
  git \
  ninja-build \
  checkinstall \
  autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libmp3lame-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  meson \
  ninja-build \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev \
  libunistring-dev \
  libaom-dev \
  libdav1d-dev \
  libva-dev \
  libmfx-dev \
  nasm \
  libx264-dev \
  libx265-dev \
  libnuma-dev \
  libvpx-dev \
  libfdk-aac-dev \
  libopus-dev \
  pkg-config \
  python3-pip \
  gcc-9 \
  g++-9 && \
  pip3 install meson==0.62.0

FROM base AS build

# avisynth+
RUN \
cd /usr/local/src && \
git clone --depth 1 -b v3.7.2 https://github.com/AviSynth/AviSynthPlus.git && \
cd AviSynthPlus && \
mkdir avisynth-build && \
cd avisynth-build && \
cmake ../ -G Ninja && \
ninja && \
checkinstall --pkgname=avisynth --pkgversion="$(grep -r \
Version avs_core/avisynth.pc | cut -f2 -d " ")-$(date --rfc-3339=date | \
sed 's/-//g')-git" --backup=no --deldoc=yes --delspec=yes --deldesc=yes \
--strip=yes --stripso=yes --addso=yes --fstrans=no --default ninja install && \
ldconfig

# libsvtav1
RUN \
cd /usr/local/src && \
git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
cd SVT-AV1/Build && \
cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
make -j $(nproc) && \
make install

# ffmpeg
RUN \
cd /usr/local/src && \
git clone --depth 1 -b n4.4.2 git://git.ffmpeg.org/ffmpeg.git && \
cd ffmpeg && \
./configure --enable-gpl --enable-version3 --disable-doc --disable-debug --enable-avisynth -enable-libx264 --enable-libx265 --enable-nonfree --enable-libmfx --enable-gnutls --enable-libaom --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libsvtav1 --enable-libdav1d --enable-libvorbis --enable-libvpx && \
make -j $(nproc) && \
make install

# l-smash
RUN \
cd /usr/local/src && \
git clone --depth 1 https://github.com/l-smash/l-smash.git && \
cd l-smash && \
./configure --enable-shared && \
make -j $(nproc) && \
make install && \
ldconfig

# l-smash-works
RUN \
cd /usr/local/src && \
git clone --depth 1 -b 20210423 https://github.com/HolyWu/L-SMASH-Works.git && \
cd L-SMASH-Works/AviSynth && \
LDFLAGS="-Wl,-Bsymbolic" meson build && \
cd build && \
ninja -v && \
ninja install && \
ldconfig

# JoinLogoScpTrialSet
RUN \
cd /usr/local/src && \
git clone --depth 1 --recursive https://github.com/tobitti0/JoinLogoScpTrialSetLinux.git && \
cd JoinLogoScpTrialSetLinux/modules/chapter_exe/src/ && \
make -j $(nproc) && \
cp -a chapter_exe /usr/local/bin/. && \
cd ../../logoframe/src/ && \
make -j $(nproc) && \
cp -a logoframe /usr/local/bin/. && \
cd ../../join_logo_scp/src/ && \
make -j $(nproc) && \
cp -a join_logo_scp /usr/local/bin/.

# delogo
RUN \
cd /usr/local/src/ && \
git clone --depth 1 https://github.com/tobitti0/delogo-AviSynthPlus-Linux.git && \
cd delogo-AviSynthPlus-Linux/src && \
make -j $(nproc) CC=gcc-9 CXX=gcc-9 LD=gcc-9 && \
make install && \
ldconfig

FROM  base AS release

ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

CMD         ["--help"]
ENTRYPOINT  ["ffmpeg"]

COPY --from=build /usr/local /usr/local/
