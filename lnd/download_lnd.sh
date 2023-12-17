#!/bin/bash

LND_RELEASE="v0.17.3-beta"
DOWNLOAD_URL="https://github.com/lightningnetwork/lnd/releases/download/${LND_RELEASE}/lnd-linux-amd64-${LND_RELEASE}.tar.gz"
MANIFEST_URL="https://github.com/lightningnetwork/lnd/releases/download/${LND_RELEASE}/manifest-${LND_RELEASE}.txt"
ROASBEEF_SIG_URL="https://github.com/lightningnetwork/lnd/releases/download/${LND_RELEASE}/manifest-roasbeef-${LND_RELEASE}.sig"
BHANDRAS_SIG_URL="https://github.com/lightningnetwork/lnd/releases/download/${LND_RELEASE}/manifest-bhandras-${LND_RELEASE}.sig"

mkdir -p download-folder
cd download-folder

scurl-download $DOWNLOAD_URL
scurl-download $MANIFEST_URL
scurl-download $ROASBEEF_SIG_URL
scurl-download $BHANDRAS_SIG_URL

ROASBEEF_KEY="E4D85299674B2D31FAA1892E372CBD7633C61696"
BHANDRAS_KEY="9FC6B0BFD597A94DBF09708280E5375C094198D8"
if [ !$(gpg --list-keys | grep -w "$ROASBEEF_KEY") ]; then
  scurl https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc | gpg --import
fi
if [ !$(gpg --list-keys | grep -w "$BHANDRAS_KEY") ]; then
  scurl https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/bhandras.asc | gpg --import
fi

gpg --verify manifest-roasbeef-${LND_RELEASE}.sig manifest-${LND_RELEASE}.txt
gpg --verify manifest-bhandras-${LND_RELEASE}.sig manifest-${LND_RELEASE}.txt

echo "---"
echo "Be mindful of the verification result above and proceed only if it succeeded."
rm ./manifest-*.txt
rm ./manifest-*.sig
