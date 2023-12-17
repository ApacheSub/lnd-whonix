#!/bin/bash

RTL_RELEASE="v0.15.0"
DOWNLOAD_URL="https://github.com/Ride-The-Lightning/RTL/archive/refs/tags/${RTL_RELEASE}.tar.gz"
SIGNATURE_URL="https://github.com/Ride-The-Lightning/RTL/releases/download/${RTL_RELEASE}/${RTL_RELEASE}.tar.gz.asc"

mkdir -p download-folder
cd download-folder

scurl-download $DOWNLOAD_URL 
scurl-download $SIGNATURE_URL 

gpg --verify ${RTL_RELEASE}.tar.gz.asc

echo "---"
echo "Be mindful of the verification result above and proceed only if it succeeded."
rm ${RTL_RELEASE}.tar.gz.asc
