# Third-party licenses

This app bundles three external binaries inside
`DenoiseApp.app/Contents/Resources/bin/`. `deep-filter` is redistributed
exactly as built by its own upstream project. `ffmpeg`/`ffprobe` are built
from unmodified upstream source, except for one small build-system patch
to LAME noted below. Full license texts are included in
[`licenses/`](licenses/), and also shipped inside the app itself at
`Contents/Resources/Licenses/` and at the top level of the release `.dmg`.

## deep-filter (DeepFilterNet3)

- **Version:** 0.5.6 (official release binary, `deep-filter-0.5.6-aarch64-apple-darwin`)
- **Source:** https://github.com/Rikorose/DeepFilterNet
- **License:** dual MIT / Apache-2.0 — either may be used.
  [`licenses/MIT-deepfilternet.txt`](licenses/MIT-deepfilternet.txt),
  [`licenses/APACHE-2.0-deepfilternet.txt`](licenses/APACHE-2.0-deepfilternet.txt)
- Downloaded and checksum-verified by `Scripts/fetch_bundled_binaries.sh`
  (SHA-256 pinned in that script).
- `deep-filter` is a statically-linked Rust binary and itself bundles a
  number of third-party crates under their own MIT/Apache-2.0/BSD-style
  licenses. We don't vendor a combined notice file for those here — see
  the dependency list at the upstream repo's
  [`Cargo.lock` at tag `v0.5.6`](https://github.com/Rikorose/DeepFilterNet/blob/v0.5.6/Cargo.lock)
  for the full list.

## ffmpeg / ffprobe

- **Version:** 8.1.3, built from unmodified upstream source via
  `Scripts/build_ffmpeg.sh`.
- **Source:** https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz
- **License:** LGPL-2.1-or-later.
  [`licenses/LGPL-2.1-ffmpeg.txt`](licenses/LGPL-2.1-ffmpeg.txt)

This build passes neither `--enable-gpl` nor `--enable-nonfree` to
FFmpeg's `configure`, and links no GPL-licensed component (notably no
libx264/libx265) — the app only ever copies video streams, it never
re-encodes them, so an encoder for H.264/HEVC is never needed. The
result, including the `ffmpeg`/`ffprobe` command-line tools themselves
(`fftools/ffmpeg.c`, `fftools/ffprobe.c`), is LGPL-2.1-or-later, not GPL.

The one statically-linked external component is **LAME** (for MP3
encoding), itself LGPL-2 (`licenses/LGPL-2-lame.txt`), version 3.100
from https://sourceforge.net/projects/lame/. One line of LAME's own
`include/libmp3lame.sym` export list (`lame_init_old`, a symbol that no
longer exists in the library itself) is deleted by `build_ffmpeg.sh` —
the same fix Homebrew's own LAME formula applies — so modern Apple
linkers don't reject the build. No other change is made to either
library's source.

**LGPL §6 compliance (static linking):** both libraries are statically
linked into `ffmpeg`/`ffprobe` rather than linked as shared libraries at
runtime. The LGPL permits this provided the complete corresponding
source, and the means to rebuild and relink a modified version of the
library against this app, are made available. `Scripts/build_ffmpeg.sh`
*is* that mechanism — it pins the exact upstream version and SHA-256 of
every source tarball and the exact `configure` flags used, and reproduces
this build from scratch. Swap either library's source, rerun the script,
and the app runs against your modified copy — `Sources/DenoiseApp/Audio/BinaryLocator.swift`
resolves the binaries by name from `Resources/bin/`, with no other coupling.
The exact source tarballs this build used, plus the build script itself,
are attached to every GitHub release alongside the `.dmg` — not just
reachable through this repository — so the offer stands independent of
whether this repo ever changes visibility.

## Regenerating the bundled binaries

```sh
./Scripts/fetch_bundled_binaries.sh   # deep-filter (checksum-pinned download)
                                       # + runs build_ffmpeg.sh for ffmpeg/ffprobe
```
