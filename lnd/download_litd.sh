#!/bin/bash

LITD_RELEASE="v0.12.2-alpha"
DOWNLOAD_URL="https://github.com/lightninglabs/lightning-terminal/releases/download/{$LITD_RELEASE}/lightning-terminal-linux-amd64-${LITD_RELEASE}.tar.gz"
MANIFEST_URL="https://github.com/lightninglabs/lightning-terminal/releases/download/{$LITD_RELEASE}/manifest-${LITD_RELEASE}.sig"
MANIFEST_SIGNATURE_URL="https://github.com/lightninglabs/lightning-terminal/releases/download/{$LITD_RELEASE}/manifest-${LITD_RELEASE}.txt"

mkdir -p download-folder
cd download-folder

scurl-download $DOWNLOAD_URL 
scurl-download $MANIFEST_URL 
scurl-download $MANIFEST_SIGNATURE_URL 

gpg --verify manifest-${LITD_RELEASE}.sig manifest-${LITD_RELEASE}.txt

echo "---"
echo "Be mindful of the verification result above and proceed only if it succeeded."
rm manifest-${LITD_RELEASE}.sig
