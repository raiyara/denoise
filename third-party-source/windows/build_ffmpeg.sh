#!/usr/bin/env bash
# windows/Scripts/build_ffmpeg.sh
# Builds the self-contained (statically linked) ffmpeg + ffprobe the
# Windows app bundles, from the same pinned, checksum-verified source as
# the macOS build (Scripts/build_ffmpeg.sh at the repo root) — same
# version, same checksums (identical upstream tarballs), same enabled
# feature set, so format support is identical across platforms. Only the
# toolchain differs: MSYS2 + mingw-w64 instead of Xcode's clang.
#
# The build is LGPL-only (no --enable-gpl / --enable-nonfree): the app
# never re-encodes video, so it needs no x264/x265.
#
# Requires: MSYS2 (https://www.msys2.org/), run from an "MSYS2 MinGW
# x64" shell specifically — NOT the plain "MSYS2 MSYS" shell. The MinGW64
# environment produces binaries linked against the Windows CRT with no
# msys-2.0.dll runtime dependency; the plain MSYS environment does not.
set -euo pipefail

if [ -z "${MSYSTEM:-}" ] || [ "$MSYSTEM" != "MINGW64" ]; then
    echo "error: run this from an 'MSYS2 MinGW x64' shell (MSYSTEM=MINGW64), not $( [ -z "${MSYSTEM:-}" ] && echo "a plain shell" || echo "MSYSTEM=$MSYSTEM" )." >&2
    echo "Install MSYS2 from https://www.msys2.org/, then open 'MSYS2 MinGW x64' from the Start menu." >&2
    exit 1
fi

for tool in pacman make curl sha256sum gcc nasm; do
    command -v "$tool" >/dev/null 2>&1 || { echo "error: $tool not found in this shell — make/curl/sha256sum/pacman ship in MSYS2's base install, but gcc and nasm need: pacman -S --needed mingw-w64-x86_64-toolchain mingw-w64-x86_64-nasm make" >&2; exit 1; }
done

FFMPEG_VERSION=8.1.3
FFMPEG_SHA256=7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3
LAME_VERSION=3.100
LAME_SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Same reasoning as the macOS script: build outside the repo so no
# machine-specific path gets baked into ffmpeg's --buildconf string, and
# use mktemp so another account on a shared machine can't pre-create a
# predictable scratch dir and swap the verified sources mid-build.
if [ -n "${DENOISE_FFMPEG_WORK:-}" ]; then
    WORK="$DENOISE_FFMPEG_WORK"
else
    WORK="$(mktemp -d /tmp/denoise-ffmpeg-build.XXXXXX)"
    trap 'rm -rf "$WORK"' EXIT
fi
PREFIX="$WORK/prefix"
DEST="$ROOT/windows/src-tauri/resources/bin"
SOURCE_ARCHIVE="$ROOT/dist/third-party-source-windows"
JOBS="$(nproc)"

mkdir -p "$WORK" "$PREFIX"
cd "$WORK"

fetch() {
    local url="$1" file="$2" sha="$3"
    [ -f "$file" ] || curl -fL --retry 3 -o "$file" "$url"
    echo "$sha  $file" | sha256sum -c -
}

fetch "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz" "ffmpeg-$FFMPEG_VERSION.tar.xz" "$FFMPEG_SHA256"
fetch "https://downloads.sourceforge.net/project/lame/lame/$LAME_VERSION/lame-$LAME_VERSION.tar.gz" "lame-$LAME_VERSION.tar.gz" "$LAME_SHA256"

rm -rf "lame-$LAME_VERSION" "ffmpeg-$FFMPEG_VERSION" "$PREFIX"
tar xzf "lame-$LAME_VERSION.tar.gz"
tar xJf "ffmpeg-$FFMPEG_VERSION.tar.xz"

(
    cd "lame-$LAME_VERSION"
    CFLAGS="-O2" ./configure \
        --prefix="$PREFIX" --build=x86_64-w64-mingw32 \
        --disable-shared --enable-static --disable-frontend --disable-dependency-tracking
    make -j"$JOBS"
    make install
)

(
    cd "ffmpeg-$FFMPEG_VERSION"
    ./configure \
        --prefix="$PREFIX" \
        --target-os=mingw32 \
        --arch=x86_64 \
        --extra-cflags="-static -I$PREFIX/include" \
        --extra-ldflags="-static -L$PREFIX/lib" \
        --pkg-config-flags="--static" \
        --enable-static --disable-shared \
        --disable-autodetect --enable-zlib \
        --disable-doc --disable-debug --disable-ffplay --disable-network \
        --disable-everything \
        --enable-ffmpeg --enable-ffprobe \
        --enable-libmp3lame \
        --enable-protocol=file,pipe \
        --enable-indev=lavfi \
        --enable-demuxer=mov,mp3,wav,aac,flac,aiff,caf,ogg,matroska,w64 \
        --enable-muxer=wav,mov,mp4,ipod,mp3,flac,aiff,adts,matroska,null,caf,w64 \
        --enable-decoder='aac,aac_latm,alac,mp3,mp3float,mp2,mp2float,flac,opus,vorbis,ac3,eac3,pcm_*,adpcm_ima_wav,adpcm_ms,h264,hevc,prores,mpeg4,mjpeg,vp9,wrapped_avframe' \
        --enable-encoder=pcm_s16le,pcm_s16be,pcm_s24le,aac,libmp3lame,flac,alac,ac3,mpeg4,wrapped_avframe \
        --enable-parser=aac,aac_latm,mpegaudio,flac,opus,vorbis,ac3,h264,hevc,mpeg4video,vp9,mjpeg \
        --enable-bsf=aac_adtstoasc,extract_extradata,vp9_superframe \
        --enable-filter=aresample,aformat,anull,atrim,null,format,trim,crop,hflip,vflip,transpose,scale,sine,anullsrc,testsrc
    make -j"$JOBS"
    make install
)

mkdir -p "$DEST"
install -m 755 "$PREFIX/bin/ffmpeg.exe" "$DEST/ffmpeg.exe"
install -m 755 "$PREFIX/bin/ffprobe.exe" "$DEST/ffprobe.exe"

mkdir -p "$SOURCE_ARCHIVE"
cp "$WORK/ffmpeg-$FFMPEG_VERSION.tar.xz" "$WORK/lame-$LAME_VERSION.tar.gz" "$SOURCE_ARCHIVE/"
cp "$ROOT/windows/Scripts/build_ffmpeg.sh" "$SOURCE_ARCHIVE/"

echo
echo "Installed to $DEST:"
for b in ffmpeg.exe ffprobe.exe; do
    echo "  $b — non-MSYS2 DLL deps: $(objdump -p "$DEST/$b" | grep -i 'DLL Name' | grep -ivc 'msys-\|KERNEL32\|msvcrt\|USER32\|ADVAPI32\|ws2_32\|ole32\|SHELL32\|bcrypt' || true)"
    echo "  $b — \$USERPROFILE leaked into build strings: $(LC_ALL=C grep -caF -- "${USERPROFILE:-$HOME}" "$DEST/$b" || true)"
done
echo "Source tarballs + build script archived to $SOURCE_ARCHIVE"
