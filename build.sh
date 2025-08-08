#!/bin/bash

# Install Flutter
if [ ! -d "/opt/flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
fi

# Add Flutter to PATH
export PATH="$PATH:/opt/flutter/bin"

# Flutter doctor
flutter doctor

# Enable web
flutter config --enable-web

# Clean and get dependencies
flutter clean
flutter pub get

# Build for web
echo "Building Flutter web app..."
flutter build web --release

echo "Build completed successfully!"
