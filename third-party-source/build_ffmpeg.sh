#!/usr/bin/env bash
# Scripts/build_ffmpeg.sh
# Builds the self-contained (statically linked) ffmpeg + ffprobe the app
# bundles, from pinned, checksum-verified source. Only macOS system libraries
# are linked dynamically, so the binaries run on any Apple Silicon Mac with
# macOS 14+ — no Homebrew needed on the user's machine.
#
# The build is LGPL-only (no --enable-gpl / --enable-nonfree): the app never
# re-encodes video, so it needs no x264/x265. Only the components the app (and
# its test suite) actually use are compiled in.
#
# Requires: Xcode Command Line Tools (clang, make). Takes a few minutes.
set -euo pipefail

FFMPEG_VERSION=8.1.3
FFMPEG_SHA256=7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3
LAME_VERSION=3.100
LAME_SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
MIN_MACOS=14.0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Deliberately NOT under $ROOT: ffmpeg's configure bakes --prefix (and the
# cwd it built from) into the binary's own --buildconf string. A path
# under $ROOT would leak this machine's home directory into every copy of
# the app shipped to users. /private/tmp is itself an ephemeral build
# scratch space — nothing here needs to survive a reboot.
WORK="${DENOISE_FFMPEG_WORK:-/private/tmp/denoise-ffmpeg-build}"
PREFIX="$WORK/prefix"
DEST="$ROOT/Sources/DenoiseApp/Resources/bin"
# Verified source tarballs + the script that built them, archived here
# (gitignored, but persistent across runs) so make_release.sh can attach
# them to each GitHub release — the actual LGPL §6 "source + means to
# rebuild" offer, independent of this repo's own visibility.
SOURCE_ARCHIVE="$ROOT/dist/third-party-source"
JOBS="$(sysctl -n hw.ncpu)"

export MACOSX_DEPLOYMENT_TARGET="$MIN_MACOS"
ARCH_FLAGS="-arch arm64 -mmacosx-version-min=$MIN_MACOS"

mkdir -p "$WORK" "$PREFIX"
cd "$WORK"

fetch() {
    local url="$1" file="$2" sha="$3"
    [ -f "$file" ] || curl -fL --retry 3 -o "$file" "$url"
    echo "$sha  $file" | shasum -a 256 -c -
}

fetch "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz" "ffmpeg-$FFMPEG_VERSION.tar.xz" "$FFMPEG_SHA256"
fetch "https://downloads.sourceforge.net/project/lame/lame/$LAME_VERSION/lame-$LAME_VERSION.tar.gz" "lame-$LAME_VERSION.tar.gz" "$LAME_SHA256"

rm -rf "lame-$LAME_VERSION" "ffmpeg-$FFMPEG_VERSION" "$PREFIX"
tar xzf "lame-$LAME_VERSION.tar.gz"
tar xJf "ffmpeg-$FFMPEG_VERSION.tar.xz"

# lame 3.100 lists a symbol that no longer exists in its export file, which
# modern Apple linkers reject (same fix Homebrew applies).
sed -i '' '/lame_init_old/d' "lame-$LAME_VERSION/include/libmp3lame.sym"

(
    cd "lame-$LAME_VERSION"
    CFLAGS="$ARCH_FLAGS -O2" LDFLAGS="$ARCH_FLAGS" ./configure \
        --prefix="$PREFIX" --build=aarch64-apple-darwin \
        --disable-shared --enable-static --disable-frontend --disable-dependency-tracking
    make -j"$JOBS"
    make install
)

(
    cd "ffmpeg-$FFMPEG_VERSION"
    ./configure \
        --prefix="$PREFIX" \
        --cc=clang \
        --extra-cflags="$ARCH_FLAGS -I$PREFIX/include" \
        --extra-ldflags="$ARCH_FLAGS -L$PREFIX/lib" \
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
install -m 755 "$PREFIX/bin/ffmpeg" "$DEST/ffmpeg"
install -m 755 "$PREFIX/bin/ffprobe" "$DEST/ffprobe"

mkdir -p "$SOURCE_ARCHIVE"
cp "$WORK/ffmpeg-$FFMPEG_VERSION.tar.xz" "$WORK/lame-$LAME_VERSION.tar.gz" "$SOURCE_ARCHIVE/"
cp "$ROOT/Scripts/build_ffmpeg.sh" "$SOURCE_ARCHIVE/"

echo
echo "Installed to $DEST:"
for b in ffmpeg ffprobe; do
    echo "  $b — non-system dylibs: $(otool -L "$DEST/$b" | tail -n +2 | grep -vc '/usr/lib/\|/System/Library/' || true)"
    echo "  $b — \$HOME leaked into build strings: $(strings "$DEST/$b" | grep -c "$HOME" || true)"
done
echo "Source tarballs + build script archived to $SOURCE_ARCHIVE"
