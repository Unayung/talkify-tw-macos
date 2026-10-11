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
# A certificate of this Mac's own making. macOS ties the Microphone, Speech
# Recognition and Accessibility grants to who signed the app; signed by the
# same certificate every time, a rebuild keeps them. It lives in a keychain
# of its own, whose password is a file only this user can read, so nothing
# here asks for the login keychain.
identity="Talkify TW Local Signing"
keychain="$HOME/Library/Keychains/talkify-signing.keychain-db"
secret="$HOME/.config/talkify/signing-keychain"

make_identity() {
  local work password
  work="$(mktemp -d)"
  # The system's openssl throughout: Homebrew's writes a PKCS#12 that
  # `security import` cannot read.
  mkdir -p "$(dirname "$secret")"
  (umask 077; /usr/bin/openssl rand -hex 24 > "$secret")
  password="$(cat "$secret")"
  cat > "$work/req.cnf" <<CNF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $identity
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CNF
  /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$work/req.cnf" \
    -keyout "$work/key.pem" -out "$work/cert.pem" 2>/dev/null
  /usr/bin/openssl pkcs12 -export -inkey "$work/key.pem" -in "$work/cert.pem" \
    -out "$work/identity.p12" -passout "pass:$password"
  security create-keychain -p "$password" "$keychain"
  # No timeout: it is unlocked for each build and holds nothing else.
  security set-keychain-settings "$keychain"
  security import "$work/identity.p12" -k "$keychain" -P "$password" -T /usr/bin/codesign >/dev/null
  # Lets codesign use the key without a dialog nobody is there to answer.
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain" >/dev/null
  rm -rf "$work"
}

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
if [[ ! -f "$keychain" || ! -f "$secret" ]]; then
  echo "Making this Mac's signing certificate"
  rm -f "$keychain"
  make_identity
  first_signing=1
fi
security unlock-keychain -p "$(cat "$secret")" "$keychain"
# One signature over the app and Sparkle's framework, and no hardened
# runtime: with it, the loader refuses a framework that has no Team ID.
codesign --force --deep --keychain "$keychain" --sign "$identity" \
  --entitlements "$here/Talkify.entitlements" "$dest"

if [[ ! -f "$model" ]]; then
  echo "Downloading Breeze ASR 25 (1 GB)"
  mkdir -p "$(dirname "$model")"
  curl --location --fail --continue-at - --output "$model" \
    https://huggingface.co/alan314159/Breeze-ASR-25-whispercpp/resolve/main/ggml-model-q5_k.bin
fi

open "$dest"
echo
echo "Talkify TW is running in the menu bar. Pick 中文（台灣）in Settings → Language."
if [[ -n "${first_signing:-}" ]]; then
  cat <<'NEXT'

It is signed with a new certificate, so macOS asks once more for the
Microphone, Speech Recognition and Accessibility. Later builds keep them.
NEXT
fi
