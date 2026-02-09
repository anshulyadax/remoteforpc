#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the Runner group
runner_group = project.main_group['Runner']

# Swift files to add
swift_files = [
  'NativeInputController.swift',
  'ScreenInfoProvider.swift',
  'AccessibilityManager.swift'
]

swift_files.each do |filename|
  file_path = "macos/Runner/#{filename}"
  
  # Check if file already exists in project
  existing_file = runner_group.files.find { |f| f.path == filename }
  
  if existing_file
    puts "#{filename} already in project"
  else
    # Add file reference
    file_ref = runner_group.new_file(file_path)
    
    # Add to compile sources build phase
    target.add_file_references([file_ref])
    
    puts "Added #{filename} to project"
  end
end

project.save
puts "Project saved successfully!"
