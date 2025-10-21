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
    echo "Updating system packages..."
    sudo apt update -y

    # --- Install Docker ---
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt install -y docker.io
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo "Docker is already installed."
    fi

    # --- Install Docker Compose ---
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo apt install -y docker-compose
    else
        echo "Docker Compose is already installed."
    fi

    # --- Install Python 3.9+ and pip ---
    if ! command -v python3 &> /dev/null; then
        echo "Installing Python 3 and pip..."
        sudo apt install -y python3 python3-pip
    else
        echo "Python is already installed."
    fi

    # --- Install Django ---
    if ! python3 -m django --version &> /dev/null; then
        echo "Installing Django..."
        pip3 install --upgrade pip
        pip3 install django
    else
        echo "Django is already installed."
    fi

else
    echo "Unsupported OS. Only macOS and Ubuntu/Debian are supported."
    exit 1
fi

echo "Done! Installed Docker, Docker Compose, Python, and Django."
echo "Versions installed:"
docker --version || echo "Docker not found in PATH."
docker-compose --version || echo "Docker Compose not found in PATH."
python3 --version
django-admin --version
