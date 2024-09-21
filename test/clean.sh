#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# ---------------------------
# Configuration Variables
# ---------------------------

# Ghostscript version and related paths
GHOSTSCRIPT_VERSION="10.04.0"
PROJECT_ROOT=$(pwd)
GHOSTSCRIPT_FOLDER="${PROJECT_ROOT}/ghostscript-${GHOSTSCRIPT_VERSION}"
GHOSTSCRIPT_TAR="ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz"
GHOSTSCRIPT_TAR_PATTERN="ghostscript-${GHOSTSCRIPT_VERSION}.tar.gz.*"

# Emscripten SDK directory
EMSDK_FOLDER="${PROJECT_ROOT}/emsdk"

# ---------------------------
# Function Definitions
# ---------------------------

# Function to remove a directory if it exists
remove_directory() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "Removing directory: $dir"
        rm -rf "$dir"
        echo "Directory $dir removed successfully."
    else
        echo "Directory $dir does not exist. Skipping."
    fi
}

# Function to remove a file if it exists
remove_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Removing file: $file"
        rm -f "$file"
        echo "File $file removed successfully."
    else
        echo "File $file does not exist. Skipping."
    fi
}

# Function to remove files matching a specific pattern
remove_files_matching_pattern() {
    local pattern="$1"
    # Use globbing to match files; suppress errors if no files match
    shopt -s nullglob
    files=($pattern)
    shopt -u nullglob

    if [ ${#files[@]} -gt 0 ]; then
        echo "Removing files matching pattern: $pattern"
        rm -f "${files[@]}"
        echo "Files matching pattern $pattern removed successfully."
    else
        echo "No files matching pattern $pattern found. Skipping."
    fi
}

# ---------------------------
# Start Clean-Up Process
# ---------------------------

echo "Starting clean-up process..."

# Remove emsdk directory
remove_directory "$EMSDK_FOLDER"

# Remove Ghostscript source directory
remove_directory "$GHOSTSCRIPT_FOLDER"

# Remove Ghostscript tar.gz file
remove_file "$GHOSTSCRIPT_TAR"

# Remove any additional Ghostscript tar.gz.* files
remove_files_matching_pattern "$GHOSTSCRIPT_TAR_PATTERN"

echo "Clean-up completed successfully."
