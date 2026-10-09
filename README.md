# denoise

A native macOS app that removes background noise — rain, a fan, hum,
general room ambience — from a video or audio file's audio track, while
keeping the voice underneath. Runs fully offline; your file never leaves
your Mac.

Free, and built as an alternative to paying for CapCut Pro's denoise
feature.

## Download

1. **[Download denoise for macOS](https://github.com/raiyara/denoise/releases/latest/download/denoise.dmg)**
   (always the latest version — see [Releases](../../releases) for
   release notes, checksums, and older versions).
2. Open the `.dmg`, drag **denoise** into **Applications**.
3. Open it from Launchpad or Spotlight. The **first time**, macOS will
   refuse with *"Apple could not verify 'denoise' is free of malware
   that may harm your Mac or compromise your privacy"* — only options
   **Move to Trash** or **Done**. That's expected, not a sign anything's
   wrong — see below for how to actually open it.

### Why macOS warns on first launch, and how to open it anyway

This app isn't notarized — that requires a paid Apple Developer account
($99/year), which this free tool doesn't have. The app is still signed
(so macOS can verify it hasn't been tampered with since it was built),
just not by an Apple-registered identity, so Gatekeeper calls it
"unidentified" and, on current macOS, doesn't offer a bypass in that
first dialog at all — **Done** just dismisses it.

**To open it anyway:**
1. Click **Done** on the warning (not **Move to Trash**).
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the **Security** section — you'll see a line saying
   denoise was blocked. Click **Open Anyway**.
4. Authenticate (password or Touch ID), then open the app once more; a
   final confirmation dialog with a real **Open** button appears.

You only need to do this once; after that it opens normally. (Source:
[Apple's own support article on this](https://support.apple.com/en-us/102445).
Right-click → Open → Open used to be a one-step shortcut for this on
older macOS — it may still work on your version, but don't count on it.)

## How it works

`ffmpeg` extracts the audio → [DeepFilterNet3](https://github.com/Rikorose/DeepFilterNet)
(`deep-filter`) denoises it → `ffmpeg` remuxes the cleaned audio back onto
the original file (the video stream is always copied, never re-encoded).
All three binaries are bundled inside the app and statically linked —
nothing to install separately, no Homebrew required.

The flow: drop a file → adjust **Strength** (and optionally toggle
**Extra cleanup**) → **Denoise** → A/B the original against the result,
each independently playable and scrubbable → **Re-analyze** to try
different settings, or **Save**.

**Save** writes `<name>_denoised.<ext>` next to the source file, in the
same container and format. If that name is already taken it saves as
`<name>_denoised 2.<ext>`, `3`, and so on — it never overwrites an
existing file. For video, the video stream (and any subtitles) is
copied byte-for-byte, never re-encoded; audio channel count (mono/
stereo) is preserved from the original.

**Supported for saving:** `.mp4` `.m4v` `.mov` `.mkv` `.m4a` `.aac`
`.mp3` `.flac` `.wav` `.aif`/`.aiff` `.w64` `.caf`. A handful of other
formats this build can *read* (Ogg, WebM, …) don't have a matching
writer yet — dropping one of those tells you immediately, before
running the full denoise.

## Requirements

**macOS 14+**, Apple Silicon (M1 or later).

## Checking for updates

denoise never phones home on its own — **Check for Updates…** (in the
app's menu) is the only network request the app ever makes, and only
when you click it; it just opens this repo's [Releases](../../releases)
page in your browser.

## License

denoise's own code is MIT — see [`LICENSE`](LICENSE). It bundles three
third-party binaries with their own licenses — see
[`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md) (DeepFilterNet3:
MIT/Apache-2.0; ffmpeg/ffprobe: LGPL-2.1+, built from source with no
GPL-only components). All license texts, plus the app's own Credits
panel, ship inside the downloaded app itself
(`Contents/Resources/Licenses/`) and at the top level of the `.dmg` —
not just in this repo.

**LGPL source offer:** ffmpeg and LAME are statically linked into the
bundled `ffmpeg`/`ffprobe`, which the LGPL permits provided the complete
source and the means to rebuild and relink a modified version are made
available. [`third-party-source/build_ffmpeg.sh`](third-party-source/build_ffmpeg.sh)
is that mechanism — the exact upstream version, SHA-256, and `configure`
flags used — and the precise source tarballs it built from, plus a copy
of the script itself, are attached as assets to every
[release](../../releases) alongside the `.dmg`.
