#!/bin/bash
set -e

echo "Building desktop-cleaner..."
swiftc -O -o desktop-cleaner Sources/DesktopCleaner/*.swift

echo "Installing to /usr/local/bin..."
sudo cp desktop-cleaner /usr/local/bin/
sudo chmod +x /usr/local/bin/desktop-cleaner

echo "Installing LaunchAgent..."
cp LaunchAgent/com.user.desktop-cleaner.plist ~/Library/LaunchAgents/

echo "Loading LaunchAgent..."
launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist

echo ""
echo "Installation complete!"
echo ""
echo "IMPORTANT: You need to grant Full Disk Access to /usr/local/bin/desktop-cleaner"
echo "1. Open System Settings > Privacy & Security > Full Disk Access"
echo "2. Click '+' and add /usr/local/bin/desktop-cleaner"
echo "3. Enable the toggle"
