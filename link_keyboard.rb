require 'xcodeproj'
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Create the iOS Extension Target
target = project.new_target(:app_extension, 'SalesKeyboard', :ios, '12.0')

# Link the physical folder
group = project.main_group.find_subpath(File.join('SalesKeyboard'), true)
group.set_source_tree('<group>')
group.set_path('SalesKeyboard')

# Register the files
swift_file = group.new_reference('KeyboardViewController.swift')
plist_file = group.new_reference('Info.plist')
target.add_file_references([swift_file])

# Update Xcode settings
target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'SalesKeyboard/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.salesSurveyHero.SalesKeyboard'
end

project.save
puts "Successfully linked SalesKeyboard to Xcode project!"
