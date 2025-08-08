#!/bin/bash

# Set Flutter installation directory to a writable location
FLUTTER_HOME="$HOME/flutter"

# Install Flutter if not already present
if [ ! -d "$FLUTTER_HOME" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_HOME"
fi

# Add Flutter to PATH
export PATH="$PATH:$FLUTTER_HOME/bin"

# Flutter doctor (skip for faster builds)
echo "Flutter version:"
flutter --version

# Enable web
flutter config --enable-web --no-analytics

# Clean and get dependencies
flutter clean
flutter pub get

# Build for web
echo "Building Flutter web app..."
flutter build web --release

echo "Build completed successfully!"
