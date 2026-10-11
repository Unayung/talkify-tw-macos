#!/usr/bin/env bash
# Builds Talkify TW on this Mac and installs it in /Applications.
#
# This fork has no signed releases: it is built where it runs. The Speech
# Model's library comes from the Linux Talkify's repository, expected beside
# this one (TALKIFY_CORE says otherwise) and cloned there when it is missing.
#
#   ./build-local.sh
#
# Needs Xcode, and Rust and cmake (brew install rust cmake).
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
core="${TALKIFY_CORE:-$here/../omarchy-talkify-tw}"
dest="/Applications/Talkify TW.app"
model="$HOME/.local/share/talkify/models/breeze-asr-25-q5_k/ggml-model-q5_k.bin"
export PATH="/opt/homebrew/bin:$HOME/.cargo/bin:$PATH"

for tool in cargo cmake xcodebuild; do
  command -v "$tool" >/dev/null || { echo "build-local.sh: $tool is needed (brew install rust cmake)" >&2; exit 1; }
done

if [[ ! -d "$core" ]]; then
  echo "Fetching the Speech Model's library into $core"
  git clone --quiet https://github.com/Unayung/omarchy-talkify-tw.git "$core"
fi

echo "Building the Speech Model's library"
# The app deploys to macOS 26; the library must not ask for anything newer.
MACOSX_DEPLOYMENT_TARGET=26.0 cargo build --release --quiet \
  --manifest-path "$core/Cargo.toml" -p talkify-ffi --features metal

echo "Building the app"
# No developer account: signed to run locally. The Metal Toolchain is a
# separate download since Xcode 26 (xcodebuild -downloadComponent MetalToolchain).
xcodebuild -project "$here/Talkify.xcodeproj" -scheme Talkify -configuration Release \
  -derivedDataPath "$here/build" TALKIFY_CORE="$core" \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual \
  build -quiet

echo "Installing $dest"
pkill -x Talkify 2>/dev/null || true
rm -rf "$dest"
ditto "$here/build/Build/Products/Release/Talkify.app" "$dest"
# One signature over the app and Sparkle's framework, and no hardened
# runtime: with it, the loader refuses a framework that has no Team ID.
codesign --force --deep --sign - --entitlements "$here/Talkify.entitlements" "$dest"

if [[ ! -f "$model" ]]; then
  echo "Downloading Breeze ASR 25 (1 GB)"
  mkdir -p "$(dirname "$model")"
  curl --location --fail --continue-at - --output "$model" \
    https://huggingface.co/alan314159/Breeze-ASR-25-whispercpp/resolve/main/ggml-model-q5_k.bin
fi

open "$dest"
cat <<'NEXT'

Talkify TW is running in the menu bar. Pick 中文（台灣）in Settings → Language.

A locally signed app is a new app to macOS each time it is built, so after
every build it asks again for the Microphone, Speech Recognition and
Accessibility.
NEXT
