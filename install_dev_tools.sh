#!/bin/bash
# ============================================================
# install_dev_tools.sh
# A script to install Docker, Docker Compose, Python, and Django
# Works on macOS (brew) and Ubuntu/Debian (apt)
# ============================================================

set -e  # stop on error

echo "=== Installing tools... ==="

# --- Detect Operating System ---
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"

    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Installing Docker Desktop..."
    brew install --cask docker || echo "Docker already installed or skipped."

    echo "Installing Python 3..."
    brew install python@3.11 || echo "Python already installed."

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux"

    echo "Updating packages..."
    sudo apt update -y

    echo "Installing Docker..."
    sudo apt install -y docker.io

    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose

    echo "Installing Python 3.9+ and pip..."
    sudo apt install -y python3 python3-pip
else
    echo "Unsupported OS. Only macOS and Ubuntu/Debian are supported."
    exit 1
fi

# --- Install Django ---
echo "Installing Django via pip..."
pip3 install --upgrade pip
pip3 install django

echo "Done! Installed Docker, Docker Compose, Python, and Django."
echo "Versions installed:"
docker --version || echo "Docker not found in PATH."
docker-compose --version || echo "Docker Compose not found in PATH."
python3 --version
django-admin --version

