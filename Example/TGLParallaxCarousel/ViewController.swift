//
//  ViewController.swift
//  ParallaxCarouselExample
//
//  Created by Matteo Tagliafico on 03/04/16.
//  Copyright © 2016 Matteo Tagliafico. All rights reserved.
//

import UIKit
import TGLParallaxCarousel

class ViewController: UIViewController {
    
    // MARK: - outlets
    @IBOutlet weak var carouselView: TGLParallaxCarousel!
    
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCarousel()
    }
    
    private func setupCarousel() {
        carouselView.delegate = self
        carouselView.margin = 10
        carouselView.selectedIndex = 2
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}


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
