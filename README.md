# denoise

Remove background noise (rain, fans, hum, a noisy room) from your videos
and voice recordings. Your voice stays. It's free, and everything happens
on your Mac. Nothing is uploaded.

## Download

**[Download denoise for Mac](https://github.com/raiyara/denoise/releases/latest/download/denoise.dmg)**

Needs a Mac with Apple Silicon (M1 or newer) and macOS 14 or later.

1. Open the downloaded file and drag **denoise** into **Applications**.
2. Open denoise. The first time, macOS shows a warning. That's expected.
   Follow the steps below once and you're set.

## Opening it the first time

1. Click **Done** on the warning (not **Move to Trash**).
2. Open **System Settings → Privacy & Security**.
3. Scroll down and click **Open Anyway** next to denoise.
4. Enter your password, open denoise again, and click **Open**.

You only do this once. ([Apple's guide to this](https://support.apple.com/en-us/102445))

**Why the warning?** Apple charges developers $99 a year to be verified.
denoise is free, so it isn't.

## How to use it

1. Drop a video or audio file onto the window.
2. Use the **Noise removal** slider to choose how much to remove. Turn on
   **Extra cleanup** for stubborn noise.
3. Click **Denoise**.
4. Play the original and the cleaned version to compare. Not happy?
   Change the settings and click **Re-analyze**.
5. Click **Save**.

## Good to know

- denoise saves a new copy next to your original, called
  *yourfile_denoised*. Your original is never changed, and nothing is
  ever overwritten.
- For videos, the picture stays exactly as it was. Only the sound is
  cleaned.
- Works with MP4, MOV, M4V, MKV, MP3, M4A, AAC, WAV, AIFF, FLAC, CAF and
  W64. Ogg and WebM aren't supported yet.
- denoise never connects to the internet. To get a new version, choose
  **denoise → Check for Updates…** in the menu bar. It opens this page in
  your browser.

## Why I built this

I was paying for CapCut Pro every month and only used the denoise
feature, so I built my own.

<details>
<summary><b>Technical details and licenses</b></summary>

### How it works

`ffmpeg` extracts the audio, [DeepFilterNet3](https://github.com/Rikorose/DeepFilterNet)
(`deep-filter`) removes the noise, and `ffmpeg` puts the cleaned audio
back into a copy of the original file. Video is copied as-is, never
re-encoded. All three tools are bundled inside the app, so there's
nothing else to install.

### Checking your download

Each release has a `.sha256` file next to the `.dmg`. To check the file
you downloaded matches, put both in the same folder and run:

```sh
shasum -a 256 -c denoise.dmg.sha256
```

### License

denoise's own code is MIT, see [`LICENSE`](LICENSE). It bundles
third-party tools with their own licenses, see
[`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md): DeepFilterNet3
(MIT / Apache-2.0) and ffmpeg/ffprobe (LGPL-2.1 or later, built from
source with no GPL-only parts). All license texts also ship inside the
app (`Contents/Resources/Licenses/`), in its About window, and at the top
level of the `.dmg`.

**LGPL source offer:** ffmpeg and LAME are statically linked into the
bundled `ffmpeg`/`ffprobe`. The LGPL allows this as long as the complete
source and the means to rebuild it are available.
[`third-party-source/build_ffmpeg.sh`](third-party-source/build_ffmpeg.sh)
is that build script (exact versions, checksums and build settings), and
the exact source tarballs it used, plus a copy of the script, are
attached to every [release](../../releases) next to the `.dmg`.

</details>
