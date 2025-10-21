#!/bin/bash
# ============================================================
# install_dev_tools.sh
# A script to install Docker, Docker Compose, Python, and Django
# Works on macOS (brew) and Ubuntu/Debian (apt)
# Compatible with Ubuntu 24.04+ (PEP 668 safe)
# ============================================================

set -e  # Exit immediately if a command fails

echo "=== Installing development tools... ==="

# --- Detect Operating System ---
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"

    # --- Homebrew ---
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # --- Docker Desktop ---
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker Desktop..."
        brew install --cask docker
    else
        echo "Docker is already installed."
    fi

    # --- Python ---
    if ! command -v python3 &> /dev/null; then
        echo "Installing Python 3..."
        brew install python@3.11
    else
        echo "Python is already installed."
    fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux"

    echo "Updating packages..."
    sudo apt update -y

    # --- Docker ---
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt install -y docker.io
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo "Docker is already installed."
    fi

    # --- Docker Compose ---
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo apt install -y docker-compose
    else
        echo "Docker Compose is already installed."
    fi

    # --- Python + pip ---
    if ! command -v python3 &> /dev/null; then
        echo "Installing Python 3 and pip..."
        sudo apt install -y python3 python3-pip
    else
        echo "Python is already installed."
    fi

    # --- Django (with Ubuntu 24.04 PEP-668 fix) ---
    echo "Installing Django..."
    if python3 -m django --version &> /dev/null; then
        echo "Django is already installed."
    else
        # Try virtual environment first
        if python3 -m venv venv_django &> /dev/null; then
            source venv_django/bin/activate
            pip install --upgrade pip
            pip install django
            deactivate
            echo "Django installed in venv_django (virtual environment)."
        else
            # Fallback: install system-wide with PEP 668 override
            echo "Installing Django system-wide..."
            sudo pip install --break-system-packages --upgrade pip
            sudo pip install --break-system-packages django
        fi
    fi

else
    echo "Unsupported OS. Only macOS and Ubuntu/Debian are supported."
    exit 1
fi

echo "=== Installation complete! ==="
echo "Versions installed:"
docker --version || echo "Docker not found in PATH."
docker-compose --version || echo "Docker Compose not found in PATH."
python3 --version
python3 -m django --version || echo "Django not found in PATH."
