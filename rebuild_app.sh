#!/bin/bash
cd "$(dirname "$0")/ametwereb"
echo "Cleaning Flutter build cache..."
flutter clean
echo "Getting dependencies..."
flutter pub get
echo "Done! Now run: flutter run"
