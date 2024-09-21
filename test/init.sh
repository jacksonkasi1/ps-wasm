#!/bin/bash

# Set variables for paths and versions
GHOSTSCRIPT_VERSION="9.26"
GHOSTSCRIPT_DOWNLOAD_URL="https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs926/ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"
PROJECT_ROOT=$(pwd)
GHOSTSCRIPT_FOLDER="${PROJECT_ROOT}/ghostscript-${GHOSTSCRIPT_VERSION}"
PATCH_FOLDER="${PROJECT_ROOT}/code_patch"
OUTPUT_DIR="${PROJECT_ROOT}/bin"

# Install dependencies
echo "Installing Emscripten dependencies..."
if ! command -v emsdk &> /dev/null
then
    git clone https://github.com/emscripten-core/emsdk.git
    cd emsdk
    ./emsdk install latest
    ./emsdk activate latest
    source ./emsdk_env.sh
    cd ..
else
    echo "Emscripten is already installed."
    source ./emsdk/emsdk_env.sh
fi

# Download and extract Ghostscript source code
if [ ! -d "$GHOSTSCRIPT_FOLDER" ]; then
  echo "Downloading Ghostscript..."
  wget ${GHOSTSCRIPT_DOWNLOAD_URL}
  tar -xzf "ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"
else
  echo "Ghostscript is already downloaded."
fi

# Apply the patch
echo "Applying patches..."
if [ -d "${PATCH_FOLDER}" ]; then
  cp "${PATCH_FOLDER}"/* "${GHOSTSCRIPT_FOLDER}/arch/"
else
  echo "No patch folder found."
fi

# Navigate to the Ghostscript directory
cd "${GHOSTSCRIPT_FOLDER}"

# Configure Ghostscript for WebAssembly
echo "Configuring Ghostscript for WASM..."
emconfigure ./configure --disable-threading --disable-cups --disable-dbus --disable-gtk --with-drivers=PS CC=emcc CCAUX=gcc --with-arch_h=${GHOSTSCRIPT_FOLDER}/arch/wasm.h

# Compile Ghostscript to WebAssembly
echo "Compiling Ghostscript to WebAssembly..."
emmake make XE=".html" GS_LDFLAGS="-s ALLOW_MEMORY_GROWTH=1 -s EXIT_RUNTIME=1"

# Move the output files to the bin directory
echo "Moving compiled files to output directory..."
mkdir -p ${OUTPUT_DIR}
cp -r bin/* "${OUTPUT_DIR}/"

# Clean up
echo "Cleaning up..."
cd "${PROJECT_ROOT}"
rm -f "ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"

# Done
echo "Ghostscript WASM build completed and files are in ${OUTPUT_DIR}"
