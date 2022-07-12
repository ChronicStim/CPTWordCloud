#
# Be sure to run `pod lib lint CPTWordCloud.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CPTWordCloud'
  s.version          = '1.0.3'
  s.summary          = 'Framework used to create a word cloud graphic from an input of string content.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Framework used to create a word cloud graphic from an input of string content. Includes options for several word rotation variations. The color and size of the words will vary based on the count of the word in the input text string and offer multiple algorithms for determining font sizing per word. You can define a single font for the cloud or go crazy and define an array of fonts to use randomly across the cloud. The example project gives a good demonstration of most of the major features and options. This project builds on some of the work originally done by Gal Niv https://github.com/galniv/WordCloud'

  s.homepage         = 'https://github.com/ChronicStim/CPTWordCloud'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ChronicStim' => 'support@chronicstimulation.com' }
  s.source           = { :git => 'https://github.com/ChronicStim/CPTWordCloud.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'CPTWordCloud/Classes/**/*'
  
  s.resource_bundles = {
     'CPTWordCloud' => ['CPTWordCloud/Assets/*.csv','CPTWordCloud/Classes/*.xib']
  }

  s.public_header_files = 'CPTWordCloud/Classes/**/*.h'
  s.frameworks = 'UIKit', 'SpriteKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
