#!/usr/bin/env python3
"""
Quick fix: Adds Swift files to Xcode project.
Run this from the server_desktop directory.
"""
import os
import subprocess

# Swift files to add
swift_files = [
    'macos/Runner/NativeInputController.swift',
    'macos/Runner/ScreenInfoProvider.swift',
    'macos/Runner/AccessibilityManager.swift',
]

print("=== Adding Swift Files to Xcode Project ===\n")

# Use xcrun to add files to the project
for swift_file in swift_files:
    if os.path.exists(swift_file):
        print(f"✓ Found: {swift_file}")
    else:
        print(f"✗ Missing: {swift_file}")

print("\n⚠️  Manual Step Required:")
print("1. Xcode should be open")
print("2. In the Project Navigator, right-click 'Runner' folder")
print("3. Select 'Add Files to Runner...'")
print("4. Select these 3 files:")
for f in swift_files:
    print(f"   - {os.path.basename(f)}")
print("5. Ensure 'Runner' target is checked")
print("6. Click 'Add'")
print("\nAlternatively, close Xcode and I'll try flutter clean + rebuild.")
