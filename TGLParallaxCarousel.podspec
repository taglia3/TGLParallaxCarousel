#
# Be sure to run `pod lib lint TGLParallaxCarousel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "TGLParallaxCarousel"
  s.version          = “0.3”
  s.summary          = "A lightweight 3D Linear Carousel with parallax effect."
  s.description      = <<-DESC
A lightweight 3D Linear Carousel with parallax effect. Use this custom View to create beatiful effects.
                       DESC

  s.homepage         = "https://github.com/taglia3/TGLParallaxCarousel"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "taglia3" => "the.taglia3@gmail.com" }
  s.source           = { :git => "https://github.com/taglia/TGLParallaxCarousel.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/taglia3'

  s.ios.deployment_target = '8.0'

  s.source_files = 'TGLParallaxCarousel/Classes/**/*'


  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit'
end
