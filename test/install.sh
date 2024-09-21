#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# ---------------------------
# Configuration Variables
# ---------------------------

# Emscripten SDK directory
EMSDK_DIR="$HOME/emsdk"
EMSDK_REPO="https://github.com/emscripten-core/emsdk.git"
PROJECT_ROOT=$(pwd)

# ---------------------------
# Function Definitions
# ---------------------------

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install dependencies (Git and Python3 if necessary)
install_dependencies() {
    echo "Installing necessary dependencies (git, python3)..."

    if ! command_exists git; then
        echo "Installing Git..."
        sudo apt-get update && sudo apt-get install -y git
    else
        echo "Git is already installed."
    fi

    if ! command_exists python3; then
        echo "Installing Python3..."
        sudo apt-get update && sudo apt-get install -y python3
    else
        echo "Python3 is already installed."
    fi

    echo "Dependencies installed."
}

# Clone or update Emscripten SDK
install_emsdk() {
    echo "Setting up Emscripten SDK..."

    if [ ! -d "$EMSDK_DIR" ]; then
        echo "Cloning Emscripten SDK..."
        git clone "$EMSDK_REPO" "$EMSDK_DIR"
    else
        echo "Emscripten SDK already exists. Pulling latest changes..."
        cd "$EMSDK_DIR"
        git pull
        cd "$PROJECT_ROOT"
    fi

    cd "$EMSDK_DIR"
    echo "Installing Emscripten..."
    ./emsdk install latest
    echo "Activating Emscripten..."
    ./emsdk activate latest
    echo "Sourcing EMSDK environment..."
    # Use the absolute path to ensure sourcing works correctly
    source "$EMSDK_DIR/emsdk_env.sh"
    cd "$PROJECT_ROOT"
}

# Add Emscripten tools to PATH permanently
add_to_path() {
    if ! grep -q "$EMSDK_DIR" ~/.bashrc; then
        echo "Adding Emscripten tools to PATH..."
        echo "source $EMSDK_DIR/emsdk_env.sh" >> ~/.bashrc
        source ~/.bashrc
    else
        echo "Emscripten is already added to PATH."
    fi
}

# Verify Emscripten tools installation
verify_emsdk_installation() {
    echo "Verifying Emscripten installation..."
    if command_exists emcc && command_exists emmake && command_exists emconfigure; then
        echo "Emscripten tools (emcc, emmake, emconfigure) are correctly installed."
    else
        echo "Emscripten installation failed or tools not found in PATH."
        exit 1
    fi
}

# ---------------------------
# Main Script Execution
# ---------------------------

install_dependencies
install_emsdk
add_to_path
verify_emsdk_installation

echo "Emscripten SDK setup completed successfully."
