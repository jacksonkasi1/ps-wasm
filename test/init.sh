#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# ---------------------------
# Configuration Variables
# ---------------------------

# Ghostscript version and download URL
GHOSTSCRIPT_VERSION="10.04.0"
RELEASE_TAG="gs10040"
GHOSTSCRIPT_DOWNLOAD_URL="https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/${RELEASE_TAG}/ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"

# Project directories
PROJECT_ROOT=$(pwd)
GHOSTSCRIPT_FOLDER="${PROJECT_ROOT}/ghostscript-${GHOSTSCRIPT_VERSION}"
PATCH_FOLDER="${PROJECT_ROOT}/code_patch"
OUTPUT_DIR="${PROJECT_ROOT}/bin"

# ---------------------------
# Function Definitions
# ---------------------------

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install Git without sudo (if possible)
install_git() {
    echo "Git is not installed and sudo is not available. Please install Git manually."
    exit 1
}

# ---------------------------
# Check and Install Git
# ---------------------------

echo "Checking if Git is installed..."
if ! command_exists git; then
    echo "Git not found. Attempting to install Git..."
    if command_exists sudo; then
        sudo apt-get update && sudo apt-get install -y git
    else
        install_git
    fi
else
    echo "Git is already installed."
fi

# ---------------------------
# Install Emscripten Dependencies
# ---------------------------

echo "Installing Emscripten dependencies..."
if ! command_exists emcc; then
    echo "Emscripten not found. Cloning and installing EMSDK..."
    git clone https://github.com/emscripten-core/emsdk.git
    cd emsdk
    ./emsdk install latest
    ./emsdk activate latest
    source ./emsdk_env.sh
    cd "${PROJECT_ROOT}"
else
    echo "Emscripten is already installed."
    source ./emsdk/emsdk_env.sh
fi

# Set up environment variables for Emscripten
export CC=emcc
export CXX=em++
export AR=emar
export RANLIB=emranlib

# ---------------------------
# Download and Extract Ghostscript
# ---------------------------

if [ ! -d "$GHOSTSCRIPT_FOLDER" ]; then
    echo "Downloading Ghostscript version ${GHOSTSCRIPT_VERSION}..."
    wget "${GHOSTSCRIPT_DOWNLOAD_URL}"
    tar -xzf "ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"
else
    echo "Ghostscript source code already exists. Skipping download."
fi

# ---------------------------
# Apply the Patch (wasm.h)
# ---------------------------

echo "Applying patches..."
TARGET_WASM_H="${GHOSTSCRIPT_FOLDER}/arch/wasm.h"
SOURCE_WASM_H="${PATCH_FOLDER}/arch/wasm.h"

if [ -f "${SOURCE_WASM_H}" ]; then
    if [ -f "${TARGET_WASM_H}" ]; then
        echo "wasm.h already exists in Ghostscript arch directory. Skipping copy."
    else
        echo "Copying wasm.h to Ghostscript arch directory..."
        cp "${SOURCE_WASM_H}" "${TARGET_WASM_H}"
        echo "wasm.h copied successfully."
    fi
else
    echo "wasm.h not found in ${SOURCE_WASM_H}. Please ensure the file exists."
    exit 1
fi

# ---------------------------
# Configure Ghostscript for WASM
# ---------------------------

cd "${GHOSTSCRIPT_FOLDER}"

echo "Configuring Ghostscript for WASM..."
if [ ! -f "Makefile" ]; then
    emconfigure ./configure \
        --disable-threading \
        --disable-cups \
        --disable-dbus \
        --disable-gtk \
        --with-drivers=PS \
        --with-arch_h="${TARGET_WASM_H}"
    echo "Configuration completed successfully."
else
    echo "Makefile already exists. Skipping configuration."
fi

# ---------------------------
# Compile Ghostscript to WebAssembly
# ---------------------------

echo "Compiling Ghostscript to WebAssembly..."
emmake make XE=".html" GS_LDFLAGS="-s ALLOW_MEMORY_GROWTH=1 -s EXIT_RUNTIME=1"
echo "Compilation completed successfully."

# ---------------------------
# Move Compiled Files to Output Directory
# ---------------------------

echo "Moving compiled files to output directory..."
mkdir -p "${OUTPUT_DIR}"
if [ -d "bin" ]; then
    cp -r bin/* "${OUTPUT_DIR}/"
    echo "Compiled files moved to ${OUTPUT_DIR}."
else
    echo "bin directory not found. Compilation may have failed."
    exit 1
fi

# ---------------------------
# Clean Up
# ---------------------------

echo "Cleaning up..."
cd "${PROJECT_ROOT}"
rm -f "ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"

# ---------------------------
# Completion Message
# ---------------------------

echo "Ghostscript WASM build completed and files are in ${OUTPUT_DIR}"
