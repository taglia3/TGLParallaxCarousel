//
//  CustomView.swift
//  CarouselViewExample
//
//  Created by Matteo Tagliafico on 03/04/16.
//  Copyright © 2016 Matteo Tagliafico. All rights reserved.
//

import UIKit
import TGLParallaxCarousel

@IBDesignable
class CustomView: TGLParallaxCarouselItem {
    
    // MARK: - outlets
    @IBOutlet private weak var numberLabel: UILabel!
    
    // MARK: - properties
    private var containerView: UIView!
    private let nibName = "CustomView"
    
    @IBInspectable
    var number: Int = 0 {
        didSet{
           numberLabel.text = "\(number)"
        }
    }
    
    
    // MARK: - init
    convenience init(frame: CGRect, number: Int) {
        self.init(frame: frame)
        numberLabel.text = "\(number)"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
        setup()
    }
    
    func xibSetup() {
        containerView = loadViewFromNib()
        containerView.frame = bounds
        containerView.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        addSubview(containerView)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }

    
    // MARK: - methods
    private func setup() {
        layer.masksToBounds = false
        layer.shadowRadius = 30
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 0.65
    }
}
