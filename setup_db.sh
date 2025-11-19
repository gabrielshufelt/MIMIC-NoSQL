#!/bin/bash

# MIMIC-III Database Setup Script (Mac/Linux)
# This script automates Phase 1 of the database setup

set -e  # Exit on error

echo "========================================="
echo "MIMIC-III Database Setup Script"
echo "========================================="
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    PLATFORM=Mac;;
    Linux*)     PLATFORM=Linux;;
    *)          echo "Unsupported OS: ${OS}"; exit 1;;
esac

echo "Detected platform: ${PLATFORM}"
echo ""

# Step 1: Download MIMIC-III dataset
echo "Step 1: Checking for MIMIC-III dataset..."
MIMIC_PATH="${HOME}/Downloads/mimic-iii"

if [ -d "${MIMIC_PATH}" ]; then
    echo "✓ MIMIC-III dataset already exists at ${MIMIC_PATH}"
else
    echo "MIMIC-III dataset not found. You have two options:"
    echo "  1. Download via curl (requires Kaggle API credentials)"
    echo "  2. Manual download from https://www.kaggle.com/datasets/bilal1907/mimic-iii-10k"
    echo ""
    read -p "Do you want to download via curl? (y/n): " download_choice

    if [[ "$download_choice" =~ ^[Yy]$ ]]; then
        echo "Downloading MIMIC-III dataset..."
        curl -L -o ~/Downloads/mimic-iii-10k.zip \
          https://www.kaggle.com/api/v1/datasets/download/bilal1907/mimic-iii-10k

        echo "Extracting dataset..."
        unzip ~/Downloads/mimic-iii-10k.zip -d ~/Downloads/

        # Rename the folder if needed
        if [ -d ~/Downloads/mimic-iii-10k ]; then
            mv ~/Downloads/mimic-iii-10k "${MIMIC_PATH}"
        fi

        echo "✓ Dataset downloaded and extracted"
    else
        echo "Please download the dataset manually from:"
        echo "https://www.kaggle.com/datasets/bilal1907/mimic-iii-10k"
        echo "Extract it to: ${MIMIC_PATH}"
        echo ""
        read -p "Press Enter once you've completed the manual download..."

        if [ ! -d "${MIMIC_PATH}" ]; then
            echo "Error: Dataset not found at ${MIMIC_PATH}"
            exit 1
        fi
    fi
fi
echo ""

# Step 2: Install PostgreSQL
echo "Step 2: Checking for PostgreSQL..."
if command -v psql &> /dev/null; then
    echo "✓ PostgreSQL is already installed"
    psql --version
else
    if [ "${PLATFORM}" = "Mac" ]; then
        echo "Installing PostgreSQL via Homebrew..."
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew is not installed. Please install it from https://brew.sh"
            exit 1
        fi
        brew install postgresql@17
        brew services start postgresql@17
        echo "✓ PostgreSQL installed and started"
    else
        echo "Please install PostgreSQL manually:"
        echo "  Ubuntu/Debian: sudo apt-get install postgresql"
        echo "  Fedora/RHEL: sudo dnf install postgresql-server"
        exit 1
    fi
fi
echo ""

# Step 3: Install Python
echo "Step 3: Checking for Python..."
if command -v python3 &> /dev/null; then
    echo "✓ Python is already installed"
    python3 --version
else
    if [ "${PLATFORM}" = "Mac" ]; then
        echo "Installing Python via Homebrew..."
        brew install python
        echo "✓ Python installed"
    else
        echo "Please install Python manually"
        exit 1
    fi
fi
echo ""

# Step 4: Install Python dependencies
echo "Step 4: Installing Python dependencies..."
pip3 install --upgrade pandas sqlalchemy psycopg2-binary pymongo
echo "✓ Python dependencies installed"
echo ""

# Step 5: Create database
echo "Step 5: Creating 'mimic' database..."
if psql -U postgres -lqt | cut -d \| -f 1 | grep -qw mimic; then
    echo "Database 'mimic' already exists."
    read -p "Do you want to drop and recreate it? (y/n): " recreate_choice

    if [[ "$recreate_choice" =~ ^[Yy]$ ]]; then
        dropdb -U postgres mimic
        createdb -U postgres mimic
        echo "✓ Database recreated"
    else
        echo "Using existing database"
    fi
else
    createdb -U postgres mimic
    echo "✓ Database created"
fi
echo ""

# Step 6: Apply schema
echo "Step 6: Applying schema to database..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "${SCRIPT_DIR}/schema.sql" ]; then
    echo "Error: schema.sql not found in ${SCRIPT_DIR}"
    exit 1
fi

psql -U postgres mimic < "${SCRIPT_DIR}/schema.sql"
echo "✓ Schema applied successfully"
echo ""

# Step 7: Populate database
echo "Step 7: Populating database..."
read -p "Do you want to populate the database now? This may take several minutes. (y/n): " populate_choice

if [[ "$populate_choice" =~ ^[Yy]$ ]]; then
    if [ ! -f "${SCRIPT_DIR}/populate_db.py" ]; then
        echo "Error: populate_db.py not found in ${SCRIPT_DIR}"
        exit 1
    fi

    python3 "${SCRIPT_DIR}/populate_db.py"
    echo "✓ Database populated successfully"
else
    echo "Skipping database population. You can run it later with:"
    echo "  python3 populate_db.py"
fi
echo ""

echo "========================================="
echo "✓ Database setup complete!"
echo "========================================="
echo ""
echo "To verify the installation, run:"
echo "  psql -U postgres mimic -c '\\dt'"
echo ""
