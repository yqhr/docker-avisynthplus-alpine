FROM alpine:latest AS base

RUN mkdir -p /usr/local/src

RUN \
apk add --no-cache --update build-base boost-dev git curl nasm tar bzip2 \
zlib-dev openssl-dev yasm-dev lame-dev libogg-dev \
x264-dev libvpx-dev libvorbis-dev x265-dev freetype-dev \
libass-dev libwebp-dev rtmpdump-dev libtheora-dev opus-dev \
py3-pip ninja cmake libgcc libstdc++ ca-certificates \
libcrypto1.1 libssl1.1 libgomp expat libva-intel-driver libva-dev \
dav1d-dev aom-dev fdk-aac-dev meson intel-media-sdk-dev && \
pip3 install meson==0.62.0

FROM base AS build

# avisynth+
RUN \
cd /usr/local/src && \
git clone --depth 1 -b v3.7.2 https://github.com/AviSynth/AviSynthPlus.git && \
cd AviSynthPlus && \
mkdir avisynth-build && \
cd avisynth-build && \
cmake ../ -G Ninja || true && \
ninja -v && \
ninja install && \
ldconfig || true


# # libsvtav1
RUN \
cd /usr/local/src && \
git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
cd SVT-AV1/Build && \
cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
make -j && \
make install

# ffmpeg
RUN \
cd /usr/local/src && \
git clone --depth 1 -b n4.4.2 git://git.ffmpeg.org/ffmpeg.git && \
cd ffmpeg && \
./configure --enable-gpl --enable-version3 --disable-doc --disable-debug --enable-avisynth --enable-libx264 --enable-libx265 --enable-nonfree --enable-libmfx --enable-gnutls --enable-libaom --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libsvtav1 --enable-libdav1d --enable-libvorbis --enable-libvpx && \
make -j && \
make install


# l-smash
RUN \
cd /usr/local/src && \
git clone --depth 1 https://github.com/l-smash/l-smash.git && \
cd l-smash && \
./configure --enable-shared && \
make -j && \
make install && \
ldconfig || true


# l-smash-works
RUN \
cd /usr/local/src && \
git clone --depth 1 -b 20210423 https://github.com/HolyWu/L-SMASH-Works.git && \
cd L-SMASH-Works/AviSynth && \
LDFLAGS="-Wl,-Bsymbolic" meson build && \
cd build && ninja -v && \
ninja install && \
ldconfig || true


# JoinLogoScpTrialSet
RUN \
cd /usr/local/src && \
git clone --depth 1 --recursive https://github.com/tobitti0/JoinLogoScpTrialSetLinux.git && \
cd JoinLogoScpTrialSetLinux/modules/chapter_exe/src/ && \
make -j && \
cp -a chapter_exe /usr/local/bin/. && \
cd ../../logoframe/src/ && \
make -j && \
cp -a logoframe /usr/local/bin/. && \
cd ../../join_logo_scp/src/ && \
make -j && \
cp -a join_logo_scp /usr/local/bin/. && \
cd ../../tsdivider/ && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE=Release .. && \
make -j && \
cp -a tsdivider /usr/local/bin/.


# delogo
RUN \
cd /usr/local/src/ && \
git clone --depth 1 https://github.com/tobitti0/delogo-AviSynthPlus-Linux.git && \
cd delogo-AviSynthPlus-Linux/src && \
make -j && \
make install && \
ldconfig || true

FROM  base AS release

ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

CMD         ["--help"]
ENTRYPOINT  ["ffmpeg"]

COPY --from=build /usr/local /usr/local/
