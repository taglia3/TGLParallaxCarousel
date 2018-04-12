//
//  

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


open class TGLParallaxCarouselItem: UIView {
    var xDisp: CGFloat = 0
    var zDisp: CGFloat = 0
}


@objc public protocol TGLParallaxCarouselDelegate {
    func numberOfItemsInCarouselView(_ carouselView: TGLParallaxCarousel) -> Int
    func carouselView(_ carouselView: TGLParallaxCarousel, itemForRowAtIndex index: Int) -> TGLParallaxCarouselItem
    func carouselView(_ carouselView: TGLParallaxCarousel, didSelectItemAtIndex index: Int)
    func carouselView(_ carouselView: TGLParallaxCarousel, willDisplayItem item: TGLParallaxCarouselItem, forIndex index: Int)
}


@IBDesignable
open class TGLParallaxCarousel: UIView {
    
    // MARK: - outlets
    @IBOutlet fileprivate weak  var mainView: UIView!
    @IBOutlet fileprivate weak  var pageControl: UIPageControl!
    
    // MARK: - properties
    open weak var delegate: TGLParallaxCarouselDelegate? {
        didSet {
            reloadData()
        }
    }
    open var type: CarouselType = .threeDimensional {
        didSet {
            reloadData()
        }
    }
    open var margin: CGFloat = 0  {
        didSet {
            reloadData()
        }
    }
    open var bounceMargin: CGFloat = 10 {
        didSet {
            reloadData()
        }
    }
    fileprivate var backingSelectedIndex = -1
    open var selectedIndex: Int {
        get {
            return backingSelectedIndex
        }
        set{
            backingSelectedIndex =  min(delegate!.numberOfItemsInCarouselView(self) - 1, max(0, newValue))
            moveToIndex(selectedIndex)
        }
    }
    
    fileprivate var containerView: UIView!
    fileprivate let nibName = "TGLParallaxCarousel"
    open var items = [TGLParallaxCarouselItem]()
    fileprivate var itemWidth: CGFloat?
    fileprivate var itemHeight: CGFloat?
    fileprivate var isDecelerating = false
    fileprivate var parallaxFactor: CGFloat {
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
    
    fileprivate var startGesturePoint: CGPoint = .zero
    fileprivate var endGesturePoint: CGPoint = .zero
    fileprivate var startTapGesturePoint: CGPoint = .zero
    fileprivate var endTapGesturePoint: CGPoint = .zero
    fileprivate var currentGestureVelocity: CGFloat = 0
    fileprivate var decelerationMultiplier: CGFloat = 25
    fileprivate var loopFinished = false
    
    fileprivate var currentTargetLayer: CALayer?
    fileprivate var currentItem: TGLParallaxCarouselItem?
    fileprivate var currentFoundItem: TGLParallaxCarouselItem?
    
    
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
        containerView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(containerView)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: Swift.type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    
    // MARK: - view lifecycle
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        setupGestures()
    }
    
    
    // MARK: - setup
    fileprivate func setupGestures() {
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
    
    func addItem(_ item: TGLParallaxCarouselItem) {
        if itemWidth == nil { itemWidth = item.frame.width }
        if itemHeight == nil { itemHeight = item.frame.height }
        
        item.center = mainView.center
        
            self.mainView.layer.insertSublayer(item.layer, at: UInt32(self.items.count))
            self.items.append(item)
            self.resetItemsPosition(true)
    }
    
    
    fileprivate func resetItemsPosition(_ animated: Bool) {
        guard items.count != 0  else { return }
        
        for (index, item) in items.enumerated() {
            
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
            animationGroup.isRemovedOnCompletion = false
            animationGroup.fillMode = kCAFillModeRemoved
            animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            item.layer.add(animationGroup, forKey: "myAnimation")
            
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
    @objc func detectPan(_ recognizer:UIPanGestureRecognizer) {
        
        let targetView = recognizer.view
        
        switch recognizer.state {
        case .began:
            startGesturePoint = recognizer.location(in: targetView)
            currentGestureVelocity = 0
            
        case .changed:
            currentGestureVelocity = recognizer.velocity(in: targetView).x
            endGesturePoint = recognizer.location(in: targetView)
            
            let xOffset = (startGesturePoint.x - endGesturePoint.x ) * (1 / parallaxFactor)
            moveCarousel(xOffset)
                
            startGesturePoint = endGesturePoint
            
        case .ended, .cancelled, .failed:
            startDecelerating()
            
        case.possible:
            break
        }
    }
    
    @objc func detectTap(_ recognizer:UITapGestureRecognizer) {
        
        let targetPoint: CGPoint = recognizer.location(in: recognizer.view)
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
    fileprivate func findItemOnScreen() -> TGLParallaxCarouselItem? {
        currentFoundItem = nil

        for item in items {
            currentItem = item
            checkInSubviews(item)
        }
        return currentFoundItem
    }
    
    fileprivate func checkInSubviews(_ view: UIView) {
        let subviews = view.subviews
        if subviews.isEmpty { return }
        
        for subview : AnyObject in subviews {
            if checkView(subview as! UIView) { return }
            checkInSubviews(subview as! UIView)
        }
    }
    
    fileprivate func checkView(_ view: UIView) -> Bool {
        if view.layer.isEqual(currentTargetLayer) {
            currentFoundItem = currentItem
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: moving logic
    func moveCarousel(_ offset: CGFloat) {
        guard offset != 0 else { return }
        
        var detected = false
        
        for (index, item) in items.enumerated() {
            
            // check bondaries
            if (items.first?.xDisp)! >= bounceMargin {
                detected = true
                if offset < 0 {
                    if loopFinished { return }
                }
            }
            
            if (items.last?.xDisp)! <= -bounceMargin {
                detected = true
                if offset > 0 {
                    if loopFinished { return }
                }
            }
            
            
            item.xDisp = item.xDisp - offset
            item.zDisp =  -fabs(item.xDisp) * zDisplacementFactor
            
            let factor = factorForXDisp(item.zDisp)
            
            DispatchQueue.main.async() {
                UIView.animate(withDuration: 0.33, animations: { () -> Void in
                    var t = CATransform3DIdentity
                    t.m34 = -(1 / 500)
                    item.layer.transform = CATransform3DTranslate(t, item.xDisp * factor , 0.0, item.zDisp)
                })
            }
            
            loopFinished = (index == items.count - 1 && detected)
        }
    }
    
    fileprivate func moveToIndex(_ index: Int) {
        let offsetItems = items.first?.xDisp ?? 0
        let offsetToAdd = xDisplacement * -CGFloat(selectedIndex) - offsetItems
        moveCarousel(-offsetToAdd)
        updatePageControl(selectedIndex)
        delegate?.carouselView(self, didSelectItemAtIndex: selectedIndex)
    }
    
    fileprivate func factorForXDisp(_ x: CGFloat) -> CGFloat {
        
        let pA = CGPoint(x : xDisplacement / 2,y : parallaxFactor)
        let pB = CGPoint(x : xDisplacement,y: 1)
        
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
    
    fileprivate func decelerationDistance() ->CGFloat {
        let acceleration = -currentGestureVelocity * decelerationMultiplier
        return (acceleration == 0) ? 0 : (-pow(currentGestureVelocity, 2.0) / (2.0 * acceleration))
    }
    
    
    // MARK: - page control handler
    func updatePageControl(_ index: Int) {
        pageControl.currentPage = index
    }
}
