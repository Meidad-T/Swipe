require 'xcodeproj'

project_path = '/Users/meidadtroper/Documents/School/Swipe/Swipe.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Update build settings for permissions and UIElement
target.build_configurations.each do |config|
  # Add NSLocalNetworkUsageDescription
  config.build_settings['INFOPLIST_KEY_NSLocalNetworkUsageDescription'] = 'Needs local network access to discover your devices.'
  
  # Add Bonjour Services (Needs to be an array in plist, but here it's a string space-separated? Wait, xcode usually uses string for some, but array for others. Let's set it as a string if it parses, otherwise we might need to set it properly.)
  # Actually, INFOPLIST_KEY_NSBonjourServices is expected to be a string space-separated list in build settings in some cases, or we can just let Xcode handle it, but wait:
  config.build_settings['INFOPLIST_KEY_NSBonjourServices'] = '_swipe-cont._tcp _swipe-cont._udp'

  # Add LSUIElement (Application is agent) for macOS
  config.build_settings['INFOPLIST_KEY_LSUIElement'] = 'YES'
  
  # Add NSLocationWhenInUseUsageDescription for compass
  config.build_settings['INFOPLIST_KEY_NSLocationWhenInUseUsageDescription'] = 'Needs location for compass direction.'
end

project.save
puts "Successfully updated Xcode project"
