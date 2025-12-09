#!/bin/bash
set -e

echo "Unloading LaunchAgent..."
launchctl unload ~/Library/LaunchAgents/com.user.desktop-cleaner.plist 2>/dev/null || true

echo "Removing LaunchAgent..."
rm -f ~/Library/LaunchAgents/com.user.desktop-cleaner.plist

echo "Removing executable..."
sudo rm -f /usr/local/bin/desktop-cleaner

echo "Uninstallation complete!"
