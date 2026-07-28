#!/usr/bin/env ruby
# Adds FavoritesWidget WidgetKit extension to the Runner Xcode project.
require 'xcodeproj'
require 'pathname'

ROOT = Pathname.new(__dir__).parent
PROJECT_PATH = ROOT + 'Runner.xcodeproj'
GROUP_ID = 'group.com.kamranibrahim.onetoolkit'
WIDGET_BUNDLE = 'com.kamranibrahim.onetoolkit.FavoritesWidget'

project = Xcodeproj::Project.open(PROJECT_PATH.to_s)

if project.targets.any? { |t| t.name == 'FavoritesWidget' }
  puts 'FavoritesWidget target already exists — skipping.'
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target missing' unless runner

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

widget = project.new_target(:app_extension, 'FavoritesWidget', :ios, '17.0', nil, :swift)

widget_group = project.main_group.find_subpath('FavoritesWidget', true)
widget_group.set_source_tree('<group>')
widget_group.set_path('FavoritesWidget')

swift_ref = widget_group.new_reference('FavoritesWidget.swift')
widget_group.new_reference('Info.plist')
widget_group.new_reference('FavoritesWidget.entitlements')

widget.source_build_phase.clear
widget.add_file_references([swift_ref])

widget.build_configurations.each do |config|
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => WIDGET_BUNDLE,
    'INFOPLIST_FILE' => 'FavoritesWidget/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'FavoritesWidget/FavoritesWidget.entitlements',
    'CODE_SIGN_STYLE' => 'Automatic',
    'CURRENT_PROJECT_VERSION' => '1',
    'MARKETING_VERSION' => '1.0',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'LD_RUNPATH_SEARCH_PATHS' => [
      '$(inherited)',
      '@executable_path/Frameworks',
      '@executable_path/../../Frameworks'
    ],
    'SKIP_INSTALL' => 'YES',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SWIFT_VERSION' => '5.0',
    'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'CLANG_ENABLE_MODULES' => 'YES'
  )
end

embed_phase = runner.copy_files_build_phases.find { |p| p.dst_subfolder_spec == '13' || p.name == 'Embed Foundation Extensions' }
unless embed_phase
  embed_phase = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins # 13
end

runner.add_dependency(widget) unless runner.dependencies.any? { |d| d.target == widget }

already = embed_phase.files_references.include?(widget.product_reference)
unless already
  build_file = embed_phase.add_file_reference(widget.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts "Added FavoritesWidget extension (App Group: #{GROUP_ID})."
puts 'In Xcode: enable App Groups capability on Runner + FavoritesWidget with that group id.'
