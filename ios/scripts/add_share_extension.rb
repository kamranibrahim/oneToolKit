#!/usr/bin/env ruby
# Adds ShareExtension to the Runner Xcode project.
require 'xcodeproj'
require 'pathname'

ROOT = Pathname.new(__dir__).parent
PROJECT_PATH = ROOT + 'Runner.xcodeproj'
GROUP_ID = 'group.com.kamranibrahim.onetoolkit'
EXT_BUNDLE = 'com.kamranibrahim.onetoolkit.ShareExtension'

project = Xcodeproj::Project.open(PROJECT_PATH.to_s)

if project.targets.any? { |t| t.name == 'ShareExtension' }
  puts 'ShareExtension target already exists — skipping.'
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target missing' unless runner

ext = project.new_target(:app_extension, 'ShareExtension', :ios, '17.0', nil, :swift)

ext_group = project.main_group.find_subpath('ShareExtension', true)
ext_group.set_source_tree('<group>')
ext_group.set_path('ShareExtension')

swift_ref = ext_group.new_reference('ShareViewController.swift')
ext_group.new_reference('Info.plist')
ext_group.new_reference('ShareExtension.entitlements')

ext.source_build_phase.clear
ext.add_file_references([swift_ref])

ext.build_configurations.each do |config|
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => EXT_BUNDLE,
    'INFOPLIST_FILE' => 'ShareExtension/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'ShareExtension/ShareExtension.entitlements',
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

runner.add_dependency(ext) unless runner.dependencies.any? { |d| d.target == ext }

already = embed_phase.files_references.include?(ext.product_reference)
unless already
  build_file = embed_phase.add_file_reference(ext.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts "Added ShareExtension (App Group: #{GROUP_ID})."
puts 'In Xcode: enable App Groups capability on Runner + ShareExtension with that group id.'
