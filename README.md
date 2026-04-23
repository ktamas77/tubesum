# tubesum

A tiny shell script that summarizes a YouTube video in 2-3 paragraphs.

It downloads the audio with [`yt-dlp`](https://github.com/yt-dlp/yt-dlp),
transcribes it locally with [`whisper.cpp`](https://github.com/ggerganov/whisper.cpp),
and asks the [`claude`](https://docs.claude.com/en/docs/claude-code/overview) CLI
for a plain-prose summary, which it prints to the terminal.

## Prerequisites

All available via Homebrew:

```sh
brew install yt-dlp whisper-cpp ffmpeg claude
```

You also need the `claude` CLI to be authenticated (run `claude` once
interactively and sign in).

## Install

Clone the repo, then either run `tubesum.sh` directly from the repo, or use the
installer to symlink it onto your `PATH`:

```sh
git clone https://github.com/ktamas77/tubesum.git
cd tubesum
./install.sh     # symlinks tubesum -> ~/.local/bin/tubesum
```

By default the installer targets `~/.local/bin`. Override with:

```sh
INSTALL_DIR=/usr/local/bin ./install.sh
```

To remove:

```sh
./uninstall.sh
```

The uninstaller only removes the symlink if it points at this repo's
`tubesum.sh`, so it won't touch an unrelated `tubesum` binary on your PATH.

## Usage

```sh
./tubesum.sh <youtube-url>
```

Example:

```sh
./tubesum.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

The first run downloads a whisper ggml model (default: `base.en`, ~142 MB) into
`~/.cache/tubesum/models/`. Subsequent runs reuse it.

## Configuration

Environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `TUBESUM_MODEL` | `base.en` | whisper ggml model name (e.g. `base`, `small`, `small.en`, `medium`) |
| `TUBESUM_CACHE_DIR` | `~/.cache/tubesum` | where to store downloaded models |

Use a multilingual model for non-English videos:

```sh
TUBESUM_MODEL=small ./tubesum.sh <youtube-url>
```

## How it works

1. `yt-dlp` extracts audio and `ffmpeg` resamples it to 16 kHz mono WAV.
2. `whisper-cli` (from the `whisper-cpp` formula) transcribes the WAV to text.
3. The transcript is piped to `claude -p` with a short summarize prompt.
4. The summary is printed to stdout. Intermediate files live in a temp dir
   that is wiped on exit.

## License

MIT — see [LICENSE](LICENSE).
