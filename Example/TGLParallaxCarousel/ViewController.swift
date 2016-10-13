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
    
    
    // MARK: - methods
    fileprivate func setupCarousel() {
        carouselView.delegate = self
        carouselView.margin = 10
        carouselView.selectedIndex = 2
        carouselView.type = .threeDimensional
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}


// MARK: - TGLParallaxCarouselDelegate
extension ViewController: TGLParallaxCarouselDelegate {
    
    func numberOfItemsInCarouselView(_ carouselView: TGLParallaxCarousel) -> Int {
        return 5
    }
    
    func carouselView(_ carouselView: TGLParallaxCarousel, itemForRowAtIndex index: Int) -> TGLParallaxCarouselItem {
        return CustomView(frame: CGRect(x: 0, y: 0, width: 300, height: 150) , number: index)
    }

    func carouselView(_ carouselView: TGLParallaxCarousel, didSelectItemAtIndex index: Int) {
        print("Tap on item at index \(index)")
    }
    
    func carouselView(_ carouselView: TGLParallaxCarousel, willDisplayItem item: TGLParallaxCarouselItem, forIndex index: Int) {
        print("")
    }
}
