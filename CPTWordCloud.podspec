#
# Be sure to run `pod lib lint CPTWordCloud.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CPTWordCloud'
  s.version          = '0.1.6'
  s.summary          = 'Framework used to create a word cloud graphic from an input of string content.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Framework used to create a word cloud graphic from an input of string content. Includes options for word rotation and variable fonts per word. The color and size of the words will vary based on the count of the word in the input text string. Builds on some of the work originally done by Gal Niv https://github.com/galniv/WordCloud'

  s.homepage         = 'https://github.com/ChronicStim/CPTWordCloud'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ChronicStim' => 'support@chronicstimulation.com' }
  s.source           = { :git => 'https://github.com/ChronicStim/CPTWordCloud.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'CPTWordCloud/Classes/**/*'
  
  s.resource_bundles = {
     'CPTWordCloud' => ['CPTWordCloud/Assets/*.csv']
  }

  s.public_header_files = 'CPTWordCloud/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
