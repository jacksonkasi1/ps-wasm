#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# ---------------------------
# Configuration Variables
# ---------------------------

# Project directories
PROJECT_ROOT=$(pwd)
CODE_PATCH_DIR="${PROJECT_ROOT}/code_patch"
GHOSTSCRIPT_DIR="${PROJECT_ROOT}/ghostscript-9.26"  # Replace 'ghostscript-xxx' with your actual directory name

# ---------------------------
# Main Script Execution
# ---------------------------

echo "Starting to apply patches from ${CODE_PATCH_DIR} to ${GHOSTSCRIPT_DIR}..."

# Check if code_patch directory exists
if [ ! -d "${CODE_PATCH_DIR}" ]; then
    echo "Error: code_patch directory does not exist at ${CODE_PATCH_DIR}"
    exit 1
fi

# Check if ghostscript directory exists
if [ ! -d "${GHOSTSCRIPT_DIR}" ]; then
    echo "Error: ghostscript directory does not exist at ${GHOSTSCRIPT_DIR}"
    exit 1
fi

# Copy files from code_patch to ghostscript directory
echo "Copying files..."
cp -a "${CODE_PATCH_DIR}/." "${GHOSTSCRIPT_DIR}/"

echo "Patches applied successfully."
