# denoise

Remove background noise (rain, fans, hum, a noisy room) from your videos
and voice recordings. Your voice stays. It's free, and everything happens
on your own computer. Nothing is uploaded.

## Download

**[Download denoise for Mac](https://github.com/raiyara/denoise/releases/latest/download/denoise.dmg)**

**[Download denoise for Windows](https://github.com/raiyara/denoise/releases/download/windows-v0.1.0/denoise-windows-x64-setup.exe)**

### Mac

Needs a Mac with Apple Silicon (M1 or newer) and macOS 14 or later.

1. Open the downloaded file and drag **denoise** into **Applications**.
2. Open denoise. The first time, macOS shows a warning. That's expected.
   Follow the steps below once and you're set.

### Windows

Needs Windows 10 (version 1809 or later) or Windows 11, 64-bit.

1. Run the downloaded file. It installs for your account only, so it
   doesn't need administrator permission.
2. The first time, Windows shows a warning. That's expected. Follow the
   steps below once and you're set.
3. Open denoise from the Start menu.

## Opening it the first time

### Mac

1. Click **Done** on the warning (not **Move to Trash**).
2. Open **System Settings → Privacy & Security**.
3. Scroll down and click **Open Anyway** next to denoise.
4. Enter your password, open denoise again, and click **Open**.

You only do this once. ([Apple's guide to this](https://support.apple.com/en-us/102445))

**Why the warning?** Being a registered Apple developer costs $99 a
year. I built this as a free tool and haven't paid for that, so macOS
doesn't recognize me yet.

### Windows

1. When **Windows protected your PC** appears, click **More info**.
2. Click **Run anyway**.

You only do this once.

**Why the warning?** A Windows code-signing certificate costs money every
year. I built this as a free tool and haven't paid for one, so Windows
doesn't recognize me yet.

### Windows requirements

denoise needs Microsoft's **Edge WebView2 Runtime**, which comes with
Windows 11 and most up-to-date Windows 10 PCs. If yours doesn't have it,
denoise shows a message when you open it. Install the runtime from
[Microsoft](https://developer.microsoft.com/microsoft-edge/webview2/) and
open denoise again.

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
  **denoise → Check for Updates…** in the menu bar on Mac, or
  **Help → Check for Updates…** on Windows. It opens this page in your
  browser.

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

Each release has a `.sha256` file next to the download. To check the file
you downloaded matches, put both in the same folder and run:

On Mac:

```sh
shasum -a 256 -c denoise.dmg.sha256
```

On Windows (PowerShell), this prints `True` if it matches:

```powershell
(Get-FileHash denoise-windows-x64-setup.exe -Algorithm SHA256).Hash.ToLower() -eq (Get-Content denoise-windows-x64-setup.exe.sha256).Split(' ')[0]
```

### License

denoise's own code is MIT, see [`LICENSE`](LICENSE). It bundles
third-party tools with their own licenses, see
[`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md): DeepFilterNet3
(MIT / Apache-2.0) and ffmpeg/ffprobe (LGPL-2.1 or later, built from
source with no GPL-only parts). All license texts also ship with the app:
inside it at `Contents/Resources/Licenses/` and at the top level of the
`.dmg` on Mac, and in the `Licenses` folder of the install directory on
Windows.

**LGPL source offer:** ffmpeg and LAME are statically linked into the
bundled `ffmpeg`/`ffprobe`. The LGPL allows this as long as the complete
source and the means to rebuild it are available.
[`third-party-source/build_ffmpeg.sh`](third-party-source/build_ffmpeg.sh)
(Mac) and
[`third-party-source/windows/build_ffmpeg.sh`](third-party-source/windows/build_ffmpeg.sh)
(Windows) are those build scripts (exact versions, checksums and build
settings), and the exact source tarballs each one used, plus a copy of
the script, are attached to every [release](../../releases) next to the
download.

</details>
