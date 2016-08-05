#
# Be sure to run `pod lib lint MovingPictures.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MovingPictures'
  s.version          = '0.1.0'
  s.summary          = "Turn your images into videos."
  s.description      = <<-DESC
  Take an array of images and turn them into a video. Customize the duration of each frame
  and the exporting file format.
                       DESC

  s.homepage         = "https://github.com/tsabend/MovingPictures"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tsabend' => 'tsabend@gmail.com' }
  s.source           = { :git => 'https://github.com/<GITHUB_USERNAME>/MovingPictures.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MovingPictures/Classes/**/*'
  s.dependency 'Result', '~> 2.1.3'
end
