#!/usr/bin/env bash
set -euo pipefail
__dirname=$(cd "$(dirname "$0")"; pwd -P)
cd "${__dirname}"

platform="Linux"
case "$(uname)" in
  "Darwin") platform="MacOS / OSX" ;;
  MINGW*)   platform="Windows" ;;
esac

usage(){
  echo "Usage: $0 [--port N] [--debug] [--api-keys]"
  echo
  echo "Run LibreTranslate using docker."
  exit 0
}

export LT_PORT=${LT_PORT:-5050}
DB_VOLUME=${DB_VOLUME:-}   # will be set by --api-keys if used
ARGS=()

# Parse args for overrides
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      [[ $# -ge 2 ]] || { echo "Missing value for --port"; exit 1; }
      export LT_PORT="$2"
      ARGS+=("$1" "$2")
      shift 2
      ;;
    --debug)
      export LT_DEBUG=YES
      ARGS+=("$1")
      shift
      ;;
    --api-keys)
      export DB_VOLUME="-v lt-db:/app/db"
      ARGS+=("$1")
      shift
      ;;
    --help|-h) usage ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

# Detect TTY and set docker flags accordingly
DOCKER_FLAGS=(--rm -p "${LT_PORT}:${LT_PORT}")
[[ -n "${DB_VOLUME}" ]] && DOCKER_FLAGS+=(${DB_VOLUME})

if [[ -t 0 && -t 1 ]]; then
  # interactive terminal: allow TTY
  DOCKER_FLAGS=(-i -t "${DOCKER_FLAGS[@]}")
fi

# Run container (ARGS are passed through to libretranslate)
exec docker run "${DOCKER_FLAGS[@]}" libretranslate/libretranslate "${ARGS[@]}"
