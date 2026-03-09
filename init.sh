#!/bin/bash

# GiftOso Initialization Script
# This script prepares the local development environment by cloning the required sub-repositories.

# --- Configuration ---
# Update these URLs with your actual Git repository URLs.
BACKEND_REPO="git@github.com:your-organization/store-backend.git"
STOREFRONT_REPO="git@github.com:your-organization/storefront.git"
# ---------------------

echo "🐻 Initializing GiftOso Project... 🐻"
echo ""

# --- System Checks ---
echo "🔍 Checking system dependencies..."

if ! command -v git &> /dev/null; then
    echo "❌ Error: git is not installed. Please install git and try again."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Error: docker is not installed. Please install docker and try again."
    exit 1
fi

echo "✅ All dependencies are installed."
echo ""

# 1. Clone Store Backend
if [ ! -d "store-backend" ]; then
    echo "📦 Cloning store-backend..."
    git clone "$BACKEND_REPO" store-backend
else
    echo "✅ store-backend already exists. Skipping."
fi

# 2. Clone Storefront
if [ ! -d "storefront" ]; then
    echo "📦 Cloning storefront..."
    git clone "$STOREFRONT_REPO" storefront
else
    echo "✅ storefront already exists. Skipping."
fi

echo ""
echo "🎉 Repositories cloned successfully!"
echo "👉 Note: Ensure you configure your .env and .env.local files if needed before starting."
echo ""
echo "⚙️  Calling setup.sh to install dependencies and start the project..."

if [ -f "./setup.sh" ]; then
    ./setup.sh
else
    echo "❌ Error: setup.sh not found."
fi
