//
//  TGLParallaxCarousel.swift
//  CarouselViewExample
//
//  Created by Matteo Tagliafico on 03/04/16.
//  Copyright © 2016 Matteo Tagliafico. All rights reserved.
//

import UIKit

public enum CarouselType {
    case normal
    case threeDimensional
}


public class TGLParallaxCarouselItem: UIView {
    var xDisp: CGFloat = 0
    var zDisp: CGFloat = 0
}


@objc public protocol TGLParallaxCarouselDelegate {
    func numberOfItemsInCarouselView(carouselView: TGLParallaxCarousel) -> Int
    func carouselView(carouselView: TGLParallaxCarousel, itemForRowAtIndex index: Int) -> TGLParallaxCarouselItem
    func carouselView(carouselView: TGLParallaxCarousel, didSelectItemAtIndex index: Int)
    func carouselView(carouselView: TGLParallaxCarousel, willDisplayItem item: TGLParallaxCarouselItem, forIndex index: Int)
}


@IBDesignable
public class TGLParallaxCarousel: UIView {
    
    // MARK: - outlets
    @IBOutlet private weak  var mainView: UIView!
    @IBOutlet private weak  var pageControl: UIPageControl!
    
    // MARK: - properties
    public weak var delegate: TGLParallaxCarouselDelegate? {
        didSet {
            reloadData()
        }
    }
    public var type: CarouselType = .threeDimensional {
        didSet {
            reloadData()
        }
    }
    public var margin: CGFloat = 0  {
        didSet {
            reloadData()
        }
    }
    public var bounceMargin: CGFloat = 10 {
        didSet {
            reloadData()
        }
    }
    private var backingSelectedIndex = -1
    public var selectedIndex: Int {
        get {
            return backingSelectedIndex
        }
        set{
            backingSelectedIndex =  min(delegate!.numberOfItemsInCarouselView(self) - 1, max(0, newValue))
            moveToIndex(selectedIndex)
        }
    }
    
    private var containerView: UIView!
    private let nibName = "TGLParallaxCarousel"
    private var items = [TGLParallaxCarouselItem]()
    private var itemWidth: CGFloat?
    private var itemHeight: CGFloat?
    private var isDecelerating = false
    private var parallaxFactor: CGFloat {
        if let _ = itemWidth { return ((itemWidth! + margin) / xDisplacement ) }
        else { return 1}
    }
    
    var xDisplacement: CGFloat {
        if type == .normal {
            if let _ = itemWidth { return itemWidth! }
            else { return 0 }
        }
        else if type == .threeDimensional { return 50 }        // TODO
        else { return 0 }
    }
    
    var zDisplacementFactor: CGFloat {
        if type == .normal { return 0 }
        else if type == .threeDimensional { return 1 }
        else { return 0 }
    }
    
    private var startGesturePoint: CGPoint = CGPointZero
    private var endGesturePoint: CGPoint = CGPointZero
    private var startTapGesturePoint: CGPoint = CGPointZero
    private var endTapGesturePoint: CGPoint = CGPointZero
    private var currentGestureVelocity: CGFloat = 0
    private var decelerationMultiplier: CGFloat = 25
    private var loopFinished = false
    
    private var currentTargetLayer: CALayer?
    private var currentItem: TGLParallaxCarouselItem?
    private var currentFoundItem: TGLParallaxCarouselItem?
    
    
    
    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
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
    
    
    // MARK: - view lifecycle
    override public func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        setupGestures()
    }
    
    
    // MARK: - setup
    private func setupGestures() {
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action:#selector(detectPan(_:)))
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(detectTap(_:)))
        mainView.addGestureRecognizer(panGesture)
        mainView.addGestureRecognizer(tapGesture)
    }
    
    func reloadData() {
        guard let delegate = delegate else { return }
    
        layoutIfNeeded()

        pageControl.numberOfPages = delegate.numberOfItemsInCarouselView(self)
        
        for index in 0..<delegate.numberOfItemsInCarouselView(self) {
            addItem(delegate.carouselView(self, itemForRowAtIndex: index))
        }
    }
    
    func addItem(item: TGLParallaxCarouselItem) {
        if itemWidth == nil { itemWidth = CGRectGetWidth(item.frame) }
        if itemHeight == nil { itemHeight = CGRectGetHeight(item.frame) }
        
        item.center = mainView.center
        
            self.mainView.layer.insertSublayer(item.layer, atIndex: UInt32(self.items.count))
            self.items.append(item)
            self.resetItemsPosition(animated: true)
    }
    
    private func resetItemsPosition(animated animated: Bool) {
        guard items.count != 0  else { return }
        
        for (index, item) in items.enumerate() {
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            
            let xDispNew = xDisplacement * CGFloat(index)
            let zDispNew = round(-fabs(xDispNew) * zDisplacementFactor)
            
            let translationX = CABasicAnimation(keyPath: "transform.translation.x")
            translationX.fromValue = item.xDisp
            translationX.toValue = xDispNew
            
            let translationZ = CABasicAnimation(keyPath: "transform.translation.z")
            translationZ.fromValue = item.zDisp
            translationZ.toValue = zDispNew
            
            let animationGroup = CAAnimationGroup()
            animationGroup.duration = animated ? 0.33 : 0
            animationGroup.repeatCount = 1
            animationGroup.animations = [translationX, translationZ]
            animationGroup.removedOnCompletion = false
            animationGroup.fillMode = kCAFillModeRemoved
            animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            item.layer.addAnimation(animationGroup, forKey: "myAnimation")
            
            var t = CATransform3DIdentity
            t.m34 = -(1 / 500)
            t = CATransform3DTranslate(t, xDispNew, 0.0, zDispNew)
            item.layer.transform = t;
            
            item.xDisp = xDispNew
            item.zDisp = zDispNew
            
            CATransaction.commit()
        }
    }
    
    
    // MARK: - gestures handler
    func detectPan(recognizer:UIPanGestureRecognizer) {
        
        let targetView = recognizer.view
        
        switch recognizer.state {
        case .Began:
            startGesturePoint = recognizer.locationInView(targetView)
            currentGestureVelocity = 0
            
        case .Changed:
            currentGestureVelocity = recognizer.velocityInView(targetView).x
            endGesturePoint = recognizer.locationInView(targetView)
            
            let xOffset = (startGesturePoint.x - endGesturePoint.x ) * (1 / parallaxFactor)
            moveCarousel(xOffset)
                
            startGesturePoint = endGesturePoint
            
        case .Ended, .Cancelled, .Failed:
            startDecelerating()
            
        case.Possible:
            break
        }
    }
    
    func detectTap(recognizer:UITapGestureRecognizer) {
        
        let targetPoint: CGPoint = recognizer.locationInView(recognizer.view)
        currentTargetLayer = mainView.layer.hitTest(targetPoint)!
        
        guard let targetItem = findItemOnScreen() else { return }
            
        let firstItemOffset = (items.first?.xDisp ?? 0) - targetItem.xDisp
        let tappedIndex = -Int(round(firstItemOffset / xDisplacement))
        
        if targetItem.xDisp == 0 {
            self.delegate?.carouselView(self, didSelectItemAtIndex: tappedIndex)
        }
        else {
            selectedIndex = tappedIndex
        }
    }
    
    
    // MARK: - find item
    private func findItemOnScreen() -> TGLParallaxCarouselItem? {
        currentFoundItem = nil

        for item in items {
            currentItem = item
            checkInSubviews(item)
        }
        return currentFoundItem
    }
    
    private func checkInSubviews(view: UIView) {
        let subviews = view.subviews
        if subviews.isEmpty { return }
        
        for subview : AnyObject in subviews {
            if checkView(subview as! UIView) { return }
            checkInSubviews(subview as! UIView)
        }
    }
    
    private func checkView(view: UIView) -> Bool {
        if view.layer.isEqual(currentTargetLayer) {
            currentFoundItem = currentItem
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: moving logic
    func moveCarousel(offset: CGFloat) {
        guard offset != 0 else { return }
        
        var detected = false
        
        for (index, item) in items.enumerate() {
            
            // check bondaries
            if items.first?.xDisp >= bounceMargin {
                detected = true
                if offset < 0 {
                    if loopFinished { return }
                }
            }
            
            if items.last?.xDisp <= -bounceMargin {
                detected = true
                if offset > 0 {
                    if loopFinished { return }
                }
            }
            
            
            item.xDisp = item.xDisp - offset
            item.zDisp =  -fabs(item.xDisp) * zDisplacementFactor
            
            let factor = factorForXDisp(item.zDisp)
            
            dispatch_async(dispatch_get_main_queue()) {
                UIView.animateWithDuration(0.33, animations: { () -> Void in
                    var t = CATransform3DIdentity
                    t.m34 = -(1 / 500)
                    item.layer.transform = CATransform3DTranslate(t, item.xDisp * factor , 0.0, item.zDisp)
                })
            }
            
            loopFinished = (index == items.count - 1 && detected)
        }
    }
    
    private func moveToIndex(index: Int) {
        let offsetItems = items.first?.xDisp ?? 0
        let offsetToAdd = xDisplacement * -CGFloat(selectedIndex) - offsetItems
        moveCarousel(-offsetToAdd)
        updatePageControl(selectedIndex)
        delegate?.carouselView(self, didSelectItemAtIndex: selectedIndex)
    }
    
    private func factorForXDisp(x: CGFloat) -> CGFloat {
        
        let pA = CGPointMake(xDisplacement / 2, parallaxFactor)
        let pB = CGPointMake(xDisplacement, 1)
        
        let m = (pB.y - pA.y) / (pB.x - pA.x)
        let y = (pA.y - m * pA.x) + m * fabs(x)
        
        switch fabs(x) {
        case (xDisplacement / 2)..<xDisplacement:
            return y
        case 0..<(xDisplacement / 2):
            return parallaxFactor
        default:
            return 1
        }
    }
    
    
    // MARK: - utils
    func startDecelerating() {
        isDecelerating = true
        
        let distance = decelerationDistance()
        let offsetItems = items.first?.xDisp ?? 0
        let endOffsetItems = offsetItems + distance
        
        selectedIndex = -Int(round(endOffsetItems / xDisplacement))
        isDecelerating = false
    }
    
    private func decelerationDistance() ->CGFloat {
        let acceleration = -currentGestureVelocity * decelerationMultiplier
        return (acceleration == 0) ? 0 : (-pow(currentGestureVelocity, 2.0) / (2.0 * acceleration))
    }
    
    
    // MARK: - page control handler
    func updatePageControl(index: Int) {
        pageControl.currentPage = index
    }
}
