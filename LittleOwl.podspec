#
# Be sure to run `pod lib lint LittleOwl.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'LittleOwl'
    s.version          = '1.0'
    s.summary          = 'A customized camera controller using AVFoundation'
    s.resources        = 'LittleOwl/Assets/*'
    s.swift_version    = '4.1'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

    s.description      = <<-DESC
    A customized camera controller using AVFoundation with a cool button animation as Snapchat has.
    DESC

    s.homepage         = 'https://github.com/DarkySwift/LittleOwl'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Carlos Duclos' => 'darkzeratul64@gmail.com' }
    s.source           = { :git => 'https://github.com/DarkySwift/LittleOwl.git', :tag => s.version.to_s }

    s.ios.deployment_target = '8.0'

    s.source_files = 'LittleOwl/Classes/**/*'

    s.resource_bundles = {
    'Owl' => ['LittleOwl/Assets/**/*.{storyboard,xib,xcassets,imageset,png,jpg}']
    }
end
