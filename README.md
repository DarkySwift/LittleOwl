# LittleOwl

[![Language: Swift](https://img.shields.io/badge/Swift-4.1-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Build Status](https://travis-ci.org/DarkySwift/LittleOwl.svg?branch=master)](https://travis-ci.org/DarkySwift/LittleOwl)
[![Cocoa Pod](https://img.shields.io/cocoapods/v/Pod-1.0-blue.svg?style=flat)](https://cocoapods.org/pods/LittleOwl)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/DarkySwift/LittleOwl/develop/LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS-orange.svg?style=flat)]()
[![Author: carlos21](https://img.shields.io/badge/author-carlos21-blue.svg?style=flat)](https://www.linkedin.com/in/carlos-duclos-caballero-5b1aa520/)

## Requirements

- Swift 3.2 or later
- iOS 8.0 or later

#### [Carthage](https://github.com/Carthage/Carthage)

- Insert `github "DarkySwift/LittleOwl" ~> 1.0` to your Cartfile.
- Run `carthage update`.
- Link your app with `LittleOwl` in `Carthage/Build`.

#### [CocoaPods](https://github.com/cocoapods/cocoapods)

- Insert `pod 'LittleOwl', '~> 1.0'` to your Podfile.
- Run `pod install`.

### Prerequisites:

As of iOS 10, Apple requires the additon of the `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` strings to the info.plist of your application. Example:

```xml
<key>NSCameraUsageDescription</key>
<string>To Take Photos and Video</string>
<key>NSMicrophoneUsageDescription</key>
<string>To Record Audio With Video</string>
```

### Getting Started:

If you install SwiftyCam from Cocoapods, be sure to import the module into your View Controller:

```swift
import LittleOwl
```

LittleOwl is a drop-in convenience framework. To create a Camera instance, just add this:

```swift
let cameraController = CameraViewController(type: .video(10))
cameraController.didSelectVideo = { url in
    cameraController.dismiss(animated: true, completion: nil)
}
```
or

```swift
let cameraController = CameraViewController(type: .photo)
cameraController.didSelectPhoto = { image in
    cameraController.dismiss(animated: true, completion: nil)
}
```

That is all that is required to setup the AVSession for photo and video capture. LittleOwl will prompt the user for permission to use the camera/microphone, and configure both the device inputs and outputs.

## Author

Carlos Duclós

## License

LittleOwl is available under the MIT license. See the LICENSE file for more info.
