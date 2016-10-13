
Pod::Spec.new do |s|
  s.name             = 'TGLParallaxCarousel'
  s.version          = '1.0.0'
  s.summary          = 'A lightweight 3D Linear Carousel with parallax effect.'
  s.description      = <<-DESC
A lightweight 3D Linear Carousel with parallax effect. Use this custom View to create beatiful effects.
                       DESC

  s.homepage         = 'https://github.com/taglia3/TGLParallaxCarousel'
  s.license          = 'MIT'
  s.author           = { "taglia3" => "the.taglia3@gmail.com" }
  s.source           = { :git => "https://github.com/taglia3/TGLParallaxCarousel.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/taglia3'
  s.source_files      = 'TGLParallaxCarousel/Classes/**/*'
  s.frameworks        = 'UIKit'
  s.ios.deployment_target = '8.0'
end
