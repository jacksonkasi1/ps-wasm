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
EMSDK_FOLDER="${HOME}/emsdk"  # Corrected path

# Paths to scripts
INSTALL_SCRIPT="${PROJECT_ROOT}/install.sh"
PERMIT_SCRIPT="${PROJECT_ROOT}/permit.sh"

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
# Run install.sh
# ---------------------------

echo "Starting Emscripten SDK installation..."
if [ -f "$INSTALL_SCRIPT" ]; then
    chmod +x "$INSTALL_SCRIPT"
    "$INSTALL_SCRIPT"
    # Source the Emscripten environment to update PATH
    source "${EMSDK_FOLDER}/emsdk_env.sh"
else
    echo "Error: install.sh not found in $PROJECT_ROOT."
    exit 1
fi

# ---------------------------
# Download and Extract Ghostscript
# ---------------------------

if [ ! -d "$GHOSTSCRIPT_FOLDER" ]; then
    echo "Downloading Ghostscript version ${GHOSTSCRIPT_VERSION}..."
    wget "${GHOSTSCRIPT_DOWNLOAD_URL}"
    echo "Extracting Ghostscript..."
    tar -xzf "ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"
else
    echo "Ghostscript source code already exists. Skipping download and extraction."
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
# Compile Auxiliary Tools with Host Compiler
# ---------------------------

echo "Compiling auxiliary tools with host compiler..."

# Detect available host compiler
if command_exists gcc; then
    HOST_CC=gcc
    HOST_CXX=g++
elif command_exists clang; then
    HOST_CC=clang
    HOST_CXX=clang++
else
    echo "No suitable host compiler found (gcc or clang). Please install one."
    exit 1
fi

echo "Using host compiler: $HOST_CC and $HOST_CXX"

# Temporarily set CC and CXX to host compiler
export OLD_CC="$CC"
export OLD_CXX="$CXX"
export CC="$HOST_CC"
export CXX="$HOST_CXX"

# Navigate to Ghostscript directory
cd "${GHOSTSCRIPT_FOLDER}"

# Configure Ghostscript for building auxiliary tools
echo "Configuring Ghostscript with host compiler for auxiliary tools..."
./configure \
    --disable-threading \
    --disable-cups \
    --disable-dbus \
    --disable-gtk \
    --with-drivers=PS \
    --without-tesseract \
    --with-arch_h="${GHOSTSCRIPT_FOLDER}/arch/wasm.h"

echo "Building auxiliary tools..."
# Specify full paths for all auxiliary tool targets
make obj/aux/genarch obj/aux/genconf obj/aux/echogs

# Restore CC and CXX to Emscripten compilers
export CC="$OLD_CC"
export CXX="$OLD_CXX"

# ---------------------------
# Set CC_FOR_BUILD and CXX_FOR_BUILD
# ---------------------------

export CC_FOR_BUILD="$HOST_CC"
export CXX_FOR_BUILD="$HOST_CXX"

# ---------------------------
# Run permit.sh
# ---------------------------

echo "Checking and setting permissions for auxiliary tools..."
if [ -f "$PERMIT_SCRIPT" ]; then
    chmod +x "$PERMIT_SCRIPT"
    "$PERMIT_SCRIPT" "${GHOSTSCRIPT_FOLDER}"  # Pass Ghostscript directory as argument
else
    echo "Error: permit.sh not found in $PROJECT_ROOT."
    exit 1
fi

# ---------------------------
# Configure Ghostscript for WASM
# ---------------------------

echo "Configuring Ghostscript for WebAssembly..."

# Set the correct build flags to prevent runtime exit
GS_LDFLAGS="-s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=1"

# Get the build system triplet
BUILD=$(./config.guess)

# Set host to Emscripten target
HOST=wasm32-unknown-emscripten

# Re-configure with Emscripten compilers
emconfigure ./configure \
    --build="$BUILD" \
    --host="$HOST" \
    --disable-threading \
    --disable-cups \
    --disable-dbus \
    --disable-gtk \
    --with-drivers=PS \
    --without-tesseract \
    --with-arch_h="${GHOSTSCRIPT_FOLDER}/arch/wasm.h" \
    LDFLAGS="${GS_LDFLAGS}"

echo "Configuration for WASM completed successfully."

# ---------------------------
# Compile Ghostscript to WebAssembly
# ---------------------------

echo "Compiling Ghostscript to WebAssembly..."
emmake make XE=".html" GS_LDFLAGS="-s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=1"
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
