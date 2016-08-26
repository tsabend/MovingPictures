# MovingPictures

[![CI Status](http://img.shields.io/travis/tsabend/MovingPictures.svg?style=flat)](https://travis-ci.org/tsabend/MovingPictures)
[![Version](https://img.shields.io/cocoapods/v/MovingPictures.svg?style=flat)](http://cocoapods.org/pods/MovingPictures)
[![License](https://img.shields.io/cocoapods/l/MovingPictures.svg?style=flat)](http://cocoapods.org/pods/MovingPictures)
[![Platform](https://img.shields.io/cocoapods/p/MovingPictures.svg?style=flat)](http://cocoapods.org/pods/MovingPictures)

MovingPictures is a flexible library for turning images into movies. 

## Usage

```swift
/// Create your imageTimes
let imageTimes: [ImageTime] = [(image1, 1.5), (image2, 0.3)]
/// Create the settings for your video
let settings = RenderSettings(size: images1.size, videoFilename: "foo")
/// Make a new instance of MovingPictures
let writer = MovingPictures(settings: settings)
/// Render your images
writer.render(imageTimes) { (result: Result<NSURL, NSError>) in
  do {
    let url = try result.dematerialize()
    /// You now have the video's url and can do whatever with it...
  } catch {
    /// Figure out what went wrong and react accordingly
  }
}   
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

MovingPictures is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MovingPictures"
```

## Author

tsabend, tsabend@gmail.com

This code was inspired by the answers in http://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie. Thanks to Scott Raposa and Praxiteles.

## License

MovingPictures is available under the MIT license. See the LICENSE file for more info.
