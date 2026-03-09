#!/bin/bash

# GiftOso Setup Script
# This script installs Node dependencies for all sub-repositories and starts the Docker environment.

echo "🚀 Starting GiftOso Setup... 🚀"
echo ""

# --- Node.js Version Check ---
echo "🔍 Checking Node.js version..."
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed. Please install Node.js 20+ and try again."
    exit 1
fi

NODE_VERSION=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "❌ Error: Node.js version 20+ is required. Found v$NODE_VERSION."
    exit 1
fi
echo "✅ Node.js version $NODE_VERSION is sufficient."
echo ""

# --- Install Dependencies ---
echo "📦 Installing dependencies for store-backend..."
if [ -d "store-backend" ]; then
    (cd store-backend && npm install)
else
    echo "⚠️ store-backend directory not found. Did you run init.sh?"
fi
echo ""

echo "📦 Installing dependencies for storefront..."
if [ -d "storefront" ]; then
    (cd storefront && npm install)
else
    echo "⚠️ storefront directory not found. Did you run init.sh?"
fi
echo ""

# --- Docker Compose ---
echo "🐳 Lifting project using Docker Compose..."
# You should ideally ensure your .env files are configured before doing this!
docker compose up -d --build

echo ""
echo "🎉 Setup complete! The application is starting in the background."
echo "Check the Docker logs with 'docker compose logs -f' if you run into any issues."
