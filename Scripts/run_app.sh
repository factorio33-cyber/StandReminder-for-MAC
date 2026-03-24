#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
"$ROOT_DIR/Scripts/build_app.sh"
open "$ROOT_DIR/dist/StandUpReminder.app"
