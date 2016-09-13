# TGLParallaxCarousel

[![CI Status](http://img.shields.io/travis/taglia3/TGLParallaxCarousel.svg?style=flat)](https://travis-ci.org/taglia3/TGLParallaxCarousel)
[![Version](https://img.shields.io/cocoapods/v/TGLParallaxCarousel.svg?style=flat)](http://cocoapods.org/pods/TGLParallaxCarousel)
[![License](https://img.shields.io/cocoapods/l/TGLParallaxCarousel.svg?style=flat)](http://cocoapods.org/pods/TGLParallaxCarousel)
[![Platform](https://img.shields.io/cocoapods/p/TGLParallaxCarousel.svg?style=flat)](http://cocoapods.org/pods/TGLParallaxCarousel)

A lightweight 3D Linear Carousel with parallax effect

### [GIF] Threedimensional & Normal mode

![Threedimensional demo](https://raw.githubusercontent.com/taglia3/ParallaxCarousel/master/gif/Threedimensional.gif)    ![Normal demo](https://raw.githubusercontent.com/taglia3/ParallaxCarousel/master/gif/Normal.gif)


## Installation

TGLParallaxCarousel is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TGLParallaxCarousel"
```


## Usage

1) Place one UIView object in your VC in the Storyboard and set it as subclass of `TGLParallaxCarousel`

2) Create an IBOutlet in your VC.swift file, connect it a connect delegate and datasource. 

```swift

@IBOutlet weak var carouselView: TGLParallaxCarousel!

override func viewDidLoad() {
super.viewDidLoad()

carouselView.delegate = self
carouselView.itemMargin = 10
}
```

3) Conform to delegate

```swift
// MARK: - TGLParallaxCarouselDelegate
extension ViewController: TGLParallaxCarouselDelegate {

func numberOfItemsInCarouselView(carouselView: TGLParallaxCarousel) -> Int {
return 5
}

func carouselView(carouselView: TGLParallaxCarousel, itemForRowAtIndex index: Int) -> TGLParallaxCarouselItem {
return CustomView(frame: CGRectMake(0, 0, 300, 150), number: index)
}

func carouselView(carouselView: TGLParallaxCarousel, didSelectItemAtIndex index: Int) {
print("Tap on item at index \(index)")
}

func carouselView(carouselView: TGLParallaxCarousel, willDisplayItem item: TGLParallaxCarouselItem, forIndex index: Int) {
print("")
}
}

```

4) Enjoy!


## Author

taglia3, the.taglia3@gmail.com

## License

TGLParallaxCarousel is available under the MIT license. See the LICENSE file for more info.
