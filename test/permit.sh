#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# ---------------------------
# Function Definitions
# ---------------------------

# Function to check if a file exists
file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check and set execute permissions
ensure_executable() {
    local file="$1"
    if file_exists "$file"; then
        if [ ! -x "$file" ]; then
            echo "Setting execute permissions for $file..."
            chmod +x "$file"
            echo "Execute permissions set for $file."
        else
            echo "$file already has execute permissions."
        fi
    else
        echo "Error: $file does not exist."
        exit 1
    fi
}

# Function to verify auxiliary tools
verify_auxiliary_tools() {
    local ghostscript_folder="$1"
    local aux_dir="${ghostscript_folder}/obj/aux"
    local auxiliary_tools=("genarch" "genconf" "echogs")

    echo "Verifying auxiliary tools in ${aux_dir}..."
    for tool in "${auxiliary_tools[@]}"; do
        TOOL_PATH="${aux_dir}/${tool}"
        ensure_executable "$TOOL_PATH"
    done
    echo "All auxiliary tools have correct permissions."
}

# ---------------------------
# Main Script Execution
# ---------------------------

# Check if ghostscript_folder argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <ghostscript_folder>"
    exit 1
fi

GHOSTSCRIPT_FOLDER="$1"

# Verify the provided path exists
if [ ! -d "$GHOSTSCRIPT_FOLDER" ]; then
    echo "Error: Ghostscript folder '$GHOSTSCRIPT_FOLDER' does not exist."
    exit 1
fi

# Run verification
verify_auxiliary_tools "$GHOSTSCRIPT_FOLDER"
