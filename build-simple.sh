#!/bin/bash
set -e

echo "Starting Flutter web build..."

# Download Flutter if not present
if [ ! -d "$HOME/flutter" ]; then
    echo "Downloading Flutter..."
    cd $HOME
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.2-stable.tar.xz
    tar xf flutter_linux_3.32.2-stable.tar.xz
    rm flutter_linux_3.32.2-stable.tar.xz
fi

# Set Flutter path
export PATH="$HOME/flutter/bin:$PATH"

# Verify Flutter installation
flutter --version

# Configure Flutter for web
flutter config --enable-web --no-analytics

# Return to project directory
cd $RENDER_SERVICE_SRC_DIR

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build web app
echo "Building Flutter web app..."
flutter build web --release

echo "Build completed successfully!"
echo "Build output is in: build/web/"
ls -la build/web/
