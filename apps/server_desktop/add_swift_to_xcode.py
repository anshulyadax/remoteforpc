#!/usr/bin/env python3
"""
Automatically add Swift files to Xcode project.pbxproj
"""
import re
import uuid

pbxproj_path = 'macos/Runner.xcodeproj/project.pbxproj'

# Read the project file
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Swift files to add
swift_files = [
    'NativeInputController.swift',
    'ScreenInfoProvider.swift', 
    'AccessibilityManager.swift'
]

# Check if already added
if 'NativeInputController.swift' in content:
    print("✓ Swift files already in project!")
    exit(0)

# Generate UUIDs for new entries
file_refs = {}
build_files = {}
for filename in swift_files:
    file_refs[filename] = str(uuid.uuid4()).replace('-', '').upper()[:24]
    build_files[filename] = str(uuid.uuid4()).replace('-', '').upper()[:24]

print(f"Adding {len(swift_files)} Swift files to Xcode project...")

# Find the PBXFileReference section
file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)', content, re.DOTALL)
if file_ref_section:
    insert_pos = file_ref_section.end() - len('/* End PBXFileReference section */')
    
    # Generate PBXFileReference entries
    new_refs = ""
    for filename in swift_files:
        new_refs += f"\t\t{file_refs[filename]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
    
    content = content[:insert_pos] + new_refs + content[insert_pos:]
    print(f"✓ Added {len(swift_files)} PBXFileReference entries")

# Find the PBXBuildFile section
build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)', content, re.DOTALL)
if build_file_section:
    insert_pos = build_file_section.end() - len('/* End PBXBuildFile section */')
    
    # Generate PBXBuildFile entries
    new_builds = ""
    for filename in swift_files:
        new_builds += f"\t\t{build_files[filename]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[filename]} /* {filename} */; }};\n"
    
    content = content[:insert_pos] + new_builds + content[insert_pos:]
    print(f"✓ Added {len(swift_files)} PBXBuildFile entries")

# Find the Runner group (where files are listed)
runner_group_match = re.search(r'(33CC10E92044A3C60003C045 /\* Runner \*/ = \{.*?children = \((.*?)\);)', content, re.DOTALL)
if runner_group_match:
    children_section = runner_group_match.group(2)
    
    # Add file references to children
    new_children = children_section
    for filename in swift_files:
        new_children += f"\n\t\t\t\t{file_refs[filename]} /* {filename} */,"
    
    content = content.replace(runner_group_match.group(2), new_children)
    print(f"✓ Added files to Runner group")

# Find the PBXSourcesBuildPhase (compile sources)
sources_phase_match = re.search(r'(/\* Sources \*/ = \{.*?isa = PBXSourcesBuildPhase;.*?files = \((.*?)\);)', content, re.DOTALL)
if sources_phase_match:
    files_section = sources_phase_match.group(2)
    
    # Add build files to sources phase
    new_files = files_section
    for filename in swift_files:
        new_files += f"\n\t\t\t\t{build_files[filename]} /* {filename} in Sources */,"
    
    content = content.replace(files_section, new_files)
    print(f"✓ Added files to compile sources")

# Write back
with open(pbxproj_path, 'w') as f:
    f.write(content)

print("\n✅ Successfully added Swift files to Xcode project!")
print("You can now run: flutter run -d macos")
