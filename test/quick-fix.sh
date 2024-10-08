#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# ---------------------------
# Configuration Variables
# ---------------------------

# Ensure Emscripten SDK is sourced
source "${HOME}/emsdk/emsdk_env.sh"

# Ghostscript version
GHOSTSCRIPT_VERSION="10.04.0"

# Project directories
PROJECT_ROOT=$(pwd)
GHOSTSCRIPT_FOLDER="${PROJECT_ROOT}/ghostscript-${GHOSTSCRIPT_VERSION}"
PATCH_FOLDER="${PROJECT_ROOT}/code_patch"

# Paths to files
WASM_H="${GHOSTSCRIPT_FOLDER}/arch/wasm.h"

# ---------------------------
# Function Definitions
# ---------------------------

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# ---------------------------
# Main Script Execution
# ---------------------------

echo "Starting quick fix for Ghostscript WebAssembly build..."

# ---------------------------
# Update wasm.h
# ---------------------------

echo "Updating wasm.h with necessary definitions..."

cat > "${WASM_H}" <<EOL
/* wasm.h - Architecture-specific definitions for WebAssembly */

/* Sizes of basic data types */
#define ARCH_SIZEOF_CHAR 1
#define ARCH_SIZEOF_SHORT 2
#define ARCH_SIZEOF_INT 4
#define ARCH_SIZEOF_LONG 4
#define ARCH_SIZEOF_LONGLONG 8
#define ARCH_SIZEOF_FLOAT 4
#define ARCH_SIZEOF_DOUBLE 8
#define ARCH_SIZEOF_PTR 4

/* Alignment requirements */
#define ARCH_ALIGN_SHORT_MOD 2
#define ARCH_ALIGN_INT_MOD 4
#define ARCH_ALIGN_LONG_MOD 4
#define ARCH_ALIGN_LONGLONG_MOD 8
#define ARCH_ALIGN_PTR_MOD 4
#define ARCH_ALIGN_FLOAT_MOD 4
#define ARCH_ALIGN_DOUBLE_MOD 8

/* Byte order */
#define ARCH_IS_BIG_ENDIAN 0

/* Architecture name */
#define ARCH_ARCH_NAME "wasm32"

/* Other definitions */
#define ARCH_FLOAT_MANTISSA_BITS 24
#define ARCH_FLOAT_EXPONENT_BITS 8
#define ARCH_DOUBLE_MANTISSA_BITS 53
#define ARCH_DOUBLE_EXPONENT_BITS 11
EOL

echo "wasm.h updated successfully."

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

# Navigate to Ghostscript directory
cd "${GHOSTSCRIPT_FOLDER}"

# Temporarily set CC and CXX to host compiler
export CC="$HOST_CC"
export CXX="$HOST_CXX"

# Configure Ghostscript for building auxiliary tools
echo "Configuring Ghostscript with host compiler for auxiliary tools..."
./configure \
    --disable-threading \
    --disable-cups \
    --disable-dbus \
    --disable-gtk \
    --with-drivers=PS \
    --without-tesseract \
    --with-arch_h="${WASM_H}"

echo "Building auxiliary tools..."
make -C base genarch genconf echogs

# Ensure auxiliary tools have execute permissions
echo "Setting execute permissions for auxiliary tools..."
chmod +x ./obj/aux/genarch
chmod +x ./obj/aux/genconf
chmod +x ./obj/aux/echogs

# Run genarch to generate arch.h
echo "Generating arch.h using genarch..."
./obj/aux/genarch ./obj/arch.h "${WASM_H}"

# Touch arch.h to prevent it from being regenerated
touch ./obj/arch.h

# Restore CC and CXX to Emscripten compilers
export CC="emcc"
export CXX="em++"

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

# Set BUILD_CC and BUILD_CXX to host compiler
export BUILD_CC="$HOST_CC"
export BUILD_CXX="$HOST_CXX"

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
    --with-arch_h="${WASM_H}" \
    CC="emcc" \
    CXX="em++" \
    BUILD_CC="$BUILD_CC" \
    BUILD_CXX="$BUILD_CXX" \
    LDFLAGS="${GS_LDFLAGS}"

echo "Configuration for WASM completed successfully."

# ---------------------------
# Compile Ghostscript to WebAssembly
# ---------------------------

echo "Compiling Ghostscript to WebAssembly..."
emmake make XE=".html" GS_LDFLAGS="${GS_LDFLAGS}"

echo "Compilation completed successfully."

# ---------------------------
# Completion Message
# ---------------------------

echo "Quick fix applied. Ghostscript WASM build should be successful now."
