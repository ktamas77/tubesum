#!/usr/bin/env bash
#
# tubesum - download a YouTube video, transcribe it with whisper.cpp,
# and print a 2-3 paragraph summary of the content via the claude CLI.
#
# Usage: tubesum.sh <youtube-url>

set -euo pipefail

VIDEO_URL="${1:-}"
if [[ -z "$VIDEO_URL" ]]; then
  echo "Usage: $(basename "$0") <youtube-url>" >&2
  exit 1
fi

require() {
  local cmd="$1" pkg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found. Install with: brew install $pkg" >&2
    exit 1
  fi
}

require yt-dlp yt-dlp
require whisper-cli whisper-cpp
require ffmpeg ffmpeg
require curl curl
require claude claude

CACHE_DIR="${TUBESUM_CACHE_DIR:-$HOME/.cache/tubesum}"
MODEL_DIR="$CACHE_DIR/models"
mkdir -p "$MODEL_DIR"

MODEL_NAME="${TUBESUM_MODEL:-base.en}"
MODEL_FILE="$MODEL_DIR/ggml-${MODEL_NAME}.bin"

if [[ ! -f "$MODEL_FILE" ]]; then
  echo ">> Downloading whisper model: $MODEL_NAME" >&2
  curl -fL --retry 3 -o "$MODEL_FILE" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL_NAME}.bin"
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo ">> Downloading audio" >&2
yt-dlp \
  --quiet --no-warnings --progress \
  -f bestaudio \
  -x --audio-format wav \
  --postprocessor-args "ffmpeg:-ar 16000 -ac 1" \
  -o "$WORK_DIR/audio.%(ext)s" \
  "$VIDEO_URL" >&2

AUDIO_FILE=$(find "$WORK_DIR" -maxdepth 1 -name "audio.wav" | head -n 1)
if [[ -z "$AUDIO_FILE" ]]; then
  echo "Error: audio download failed (no wav produced)." >&2
  exit 1
fi

echo ">> Transcribing (model: $MODEL_NAME)" >&2
TRANSCRIPT_BASE="$WORK_DIR/transcript"
whisper-cli \
  -m "$MODEL_FILE" \
  -f "$AUDIO_FILE" \
  -otxt -of "$TRANSCRIPT_BASE" \
  >/dev/null 2>&1

TRANSCRIPT_FILE="${TRANSCRIPT_BASE}.txt"
if [[ ! -s "$TRANSCRIPT_FILE" ]]; then
  echo "Error: transcription produced no output." >&2
  exit 1
fi

echo ">> Summarizing with claude" >&2

PROMPT='Summarize the following YouTube video transcript in 2-3 paragraphs describing what the video is about. Return only the summary prose, no preamble, no bullet points, no headings.

Transcript:
'

SUMMARY=$({ printf '%s' "$PROMPT"; cat "$TRANSCRIPT_FILE"; } | claude -p)

if [[ -z "$SUMMARY" ]]; then
  echo "Error: claude returned no summary." >&2
  exit 1
fi

echo
echo "$SUMMARY"
