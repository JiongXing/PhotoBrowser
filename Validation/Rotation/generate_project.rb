require 'xcodeproj'
require 'fileutils'
root = File.expand_path('../..', __dir__)
out = File.expand_path(ARGV.fetch(0))
FileUtils.mkdir_p(out)
project = Xcodeproj::Project.new(File.join(out, 'Rotation.xcodeproj'))
app = project.new_target(:application, 'RotationHost', :ios, '15.0')
tests = project.new_target(:unit_test_bundle, 'RotationTests', :ios, '15.0')
ui = project.new_target(:ui_test_bundle, 'RotationUITests', :ios, '15.0')
[app, tests, ui].each do |target|
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION' => '5.0', 'GENERATE_INFOPLIST_FILE' => 'YES',
      'PRODUCT_BUNDLE_IDENTIFIER' => "com.jxphotobrowser.#{target.name}",
      'CODE_SIGNING_ALLOWED' => 'NO', 'TARGETED_DEVICE_FAMILY' => '1,2'
    })
  end
end
app.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIRequiresFullScreen'] = 'YES'
  config.build_settings['INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription'] = 'Verify demo video saving.'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
end
sources = Dir[File.join(ENV.fetch('ROTATION_SOURCE_ROOT', root), 'Sources/*.swift')]
sources << File.join(__dir__, 'RotationHost.swift')
sources << File.join(__dir__, 'LifecycleHost.swift')
sources << File.join(root, 'Demo-UIKit/Demo/HomePage/VideoSaveService.swift')
app.add_file_references(sources.map { |path| project.main_group.new_file(path) })
test_files = ENV['ROTATION_ONLY'] == '1' ? ['RotationTests.swift'] : ['RotationTests.swift', 'LifecycleTests.swift', 'VideoSaveTests.swift']
tests.add_file_references(test_files.map { |name| project.main_group.new_file(File.join(__dir__, name)) })
ui.add_file_references(['RotationUITests.swift', 'LifecycleUITests.swift'].map { |name| project.main_group.new_file(File.join(__dir__, name)) })
tests.add_dependency(app)
ui.add_dependency(app)
tests.build_configurations.each do |config|
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/RotationHost.app/RotationHost'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end
ui.build_configurations.each { |config| config.build_settings['TEST_TARGET_NAME'] = 'RotationHost' }
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.add_test_target(ui)
scheme.set_launch_target(app)
scheme.save_as(project.path, 'Rotation')
puts project.path
