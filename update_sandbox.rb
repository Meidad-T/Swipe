require 'xcodeproj'

project_path = '/Users/meidadtroper/Documents/School/Swipe/Swipe.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

target.build_configurations.each do |config|
  # Disable App Sandbox on macOS so network/multipeer can work without strict entitlements
  config.build_settings['ENABLE_APP_SANDBOX'] = 'NO'
  
  # For iOS 14+ Multipeer Connectivity, NSBonjourServices MUST be an array.
  # In Xcode project build settings, you can define an array of strings by separating them by spaces, 
  # but sometimes it fails. To be perfectly safe, let's also make sure it has the right keys.
  # A space separated string usually works for INFOPLIST_KEY array types in modern Xcode.
  config.build_settings['INFOPLIST_KEY_NSBonjourServices'] = '_swipe-cont._tcp _swipe-cont._udp'
end

project.save
puts "Successfully updated Xcode project"
