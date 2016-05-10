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
    
    @IBOutlet weak var carouselView: TGLParallaxCarousel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCarousel()
    }
    
    func setupCarousel() {
        carouselView.delegate = self
        carouselView.datasource = self
        carouselView.itemMargin = 10
//        carouselView.selectedIndex = 2
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

extension ViewController: TGLParallaxCarouselDatasource {
    func numberOfItemsInCarousel(carousel: TGLParallaxCarousel) ->Int {
        return 5
    }
    
    func viewForItemAtIndex(index: Int, carousel: TGLParallaxCarousel) -> TGLParallaxCarouselItem {
        let ratio: CGFloat = view.frame.width / 375.0
        return CustomView(frame: CGRectMake(0, 0, 300 * ratio, 150 * ratio), number: "\(index + 1)")
    }
}

extension ViewController: TGLParallaxCarouselDelegate {
    func didTapOnItemAtIndex(index: Int, carousel: TGLParallaxCarousel) {
        print("Tap on item at index \(index)")
    }
    
    func didMovetoPageAtIndex(index: Int) {
        print("Did move to index \(index)")
    }
}
