//
//  TGLParallaxCarousel.swift
//  CarouselViewExample
//
//  Created by Matteo Tagliafico on 03/04/16.
//  Copyright © 2016 Matteo Tagliafico. All rights reserved.
//

import UIKit

@objc public protocol TGLParallaxCarouselDelegate {
    func didMovetoPageAtIndex(index: Int)
    optional func didTapOnItemAtIndex(index: Int, carousel: TGLParallaxCarousel)
}


@objc public protocol TGLParallaxCarouselDatasource {
    func numberOfItemsInCarousel(carousel: TGLParallaxCarousel) ->Int
    func viewForItemAtIndex(index: Int, carousel: TGLParallaxCarousel) ->TGLParallaxCarouselItem
    
}

public enum CarouselType {
    case Normal
    case ThreeDimensional
}

public class TGLParallaxCarouselItem: UIView {
    var xDisp: CGFloat = 0
    var zDisp: CGFloat = 0
}

public class TGLParallaxCarousel: UIView {
    
    @IBOutlet weak  var upperView: UIView!
    @IBOutlet weak  var pageControl: UIPageControl!
    
    // MARK: - delegate & datasource
    public weak var delegate: TGLParallaxCarouselDelegate?
    public weak var datasource: TGLParallaxCarouselDatasource? {
        didSet {
            reloadData()
        }
    }
    
    // MARK: - properties
    private var containerView: UIView!
    private let ISPCarouselViewNibName = "TGLParallaxCarousel"
    private var carouselItems = [TGLParallaxCarouselItem]()
    
    public var itemMargin: CGFloat = 0
    public var bounceMargin: CGFloat = 10
    public var selectedIndex = -1 {
        didSet {
            if selectedIndex < 0 { selectedIndex = 0 }
            else if selectedIndex > (datasource!.numberOfItemsInCarousel(self) - 1 ) { selectedIndex = datasource!.numberOfItemsInCarousel(self) - 1 }
            updatePageControl(selectedIndex)
            self.delegate?.didMovetoPageAtIndex(selectedIndex)
        }
    }
    
    public var type: CarouselType = .ThreeDimensional {
        didSet {
            reloadData()
        }
    }
    
    private var itemWidth: CGFloat?
    private var itemHeight: CGFloat?
    
    private var isDecelerating = false
    private var parallaxFactor: CGFloat {
        
        if let _ = itemWidth { return ((itemWidth! + itemMargin) / xDisplacement ) }
        else { return 1}
    }
    
    var xDisplacement: CGFloat {
        if type == .Normal {
            if let _ = itemWidth { return itemWidth! }
            else { return 0 }
        }
        else if type == .ThreeDimensional { return 50 }        // TODO
        else { return 0 }
    }
    
    var zDisplacementFactor: CGFloat {
        if type == .Normal { return 0 }
        else if type == .ThreeDimensional { return 1 }
        else { return 0 }
    }
    
    // MARK: - gesture handling
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
    
    
    
    // MARK: init methods
    
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
        let nib = UINib(nibName: ISPCarouselViewNibName, bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    override public func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action:#selector(detectPan(_:)))
        upperView.addGestureRecognizer(panGesture)
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(detectTap(_:)))
        upperView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: setup
    func reloadData() {
        guard let datasource = datasource else { return }

        pageControl.numberOfPages = datasource.numberOfItemsInCarousel(self)
        
        for i in 0..<datasource.numberOfItemsInCarousel(self) {
            addItem(datasource.viewForItemAtIndex(i, carousel: self))
        }
        layoutIfNeeded()
    }
    
    
    
    // MARK: add item logic
    
    func addItem(item: TGLParallaxCarouselItem) {
        
        if selectedIndex == -1 { selectedIndex = 0 }
        
        if itemWidth == nil { itemWidth = item.frame.size.width }
        if itemHeight == nil { itemHeight = item.frame.size.height }
        
        // center item
        item.center = CGPointMake(upperView.center.x, upperView.center.y + (upperView.frame.size.height - itemHeight!) / 2)
        
        dispatch_async(dispatch_get_main_queue()){
            
            self.upperView.layer.insertSublayer(item.layer, atIndex: UInt32(self.carouselItems.count))
            
            self.carouselItems.append(item)
            
            self.refreshItemsPosition(animated: true)
        }
    }
    
    
    
    // MARK: refresh logic
    
    func refreshItemsPosition(animated animated: Bool) {
        if carouselItems.count == 0 { return }
        
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationCurve(.Linear)
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.setAnimationDuration(0.2)
        }
        
        for (index, item) in carouselItems.enumerate() {
            
            item.xDisp = xDisplacement * CGFloat(index)
            item.zDisp = round(-fabs(item.xDisp) * zDisplacementFactor)
            
            item.layer.anchorPoint = CGPointMake(0.5, 0.5)
            item.layer.doubleSided = true
            
            var t = CATransform3DIdentity;
            t.m34 = -(1/500)
            t = CATransform3DTranslate(t, item.xDisp, 0.0, item.zDisp);
            item.layer.transform = t;
        }
        
        if animated {
            UIView.commitAnimations()
        }
    }
    
    
    
    // MARK : handle gestures
    
    func detectPan(recognizer:UIPanGestureRecognizer) {
        
        switch recognizer.state {
        case .Began:
            startGesturePoint = recognizer.locationInView(recognizer.view)
            currentGestureVelocity = 0
            
        case .Changed:
            currentGestureVelocity = recognizer.velocityInView(recognizer.view).x
            endGesturePoint = recognizer.locationInView(recognizer.view)
            
            let xOffset = (startGesturePoint.x - endGesturePoint.x ) * (1/parallaxFactor)

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
        currentTargetLayer = upperView.layer.hitTest(targetPoint)!
        let targetItem = findItemOnScreen()
        
        if targetItem != nil {
            
            let firstItemOffset = carouselItems[0].xDisp - targetItem!.xDisp
            let tappedIndex = -Int(round(firstItemOffset / xDisplacement))
            
            if targetItem!.xDisp == 0 {
                self.delegate?.didTapOnItemAtIndex!(tappedIndex, carousel: self)
            } else {
                // a seconda del valore di targetItem!.xDisp cambio l'offset e centro sull'item
                let offsetToAdd = xDisplacement * -CGFloat(tappedIndex - selectedIndex)
                selectedIndex = tappedIndex
                moveCarousel(-offsetToAdd)
            }
        }
    }
    
    
    // MARK: find item
    func findItemOnScreen() ->TGLParallaxCarouselItem? {
        currentFoundItem = nil

        for i in 0..<carouselItems.count {
            currentItem = carouselItems[i]
            checkInSubviews(currentItem!)
        }
        return currentFoundItem
    }
    
    func checkInSubviews(view:UIView){
        let subviews = view.subviews
        if subviews.count == 0 { return }
        
        for subview : AnyObject in subviews{
            if checkView(subview as! UIView) { return }
            checkInSubviews(subview as! UIView)
        }
    }
    
    func checkView(view: UIView) ->Bool {
        if view.layer.isEqual(currentTargetLayer) {
            currentFoundItem = currentItem
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: moving logic
    func moveCarousel(offset: CGFloat) {
        
        if (offset == 0) { return }
        
        var detected = false
        
        for i in 0..<carouselItems.count {
            
            let item: TGLParallaxCarouselItem = carouselItems[i]
            
            // check bondaries
            if carouselItems[0].xDisp >= bounceMargin {
                detected = true
                if offset < 0 {
                    if loopFinished { return }
                }
            }
            
            let lastItemIndex = datasource!.numberOfItemsInCarousel(self) - 1
            if carouselItems[lastItemIndex].xDisp <= -bounceMargin {
                detected = true
                if offset > 0 {
                    if loopFinished { return }
                }
            }
            
            
            item.xDisp = item.xDisp - offset
            item.zDisp =  -fabs(item.xDisp) * zDisplacementFactor
            
            let factor = self.factorForXDisp(item.zDisp)
            
            dispatch_async(dispatch_get_main_queue(), {
                
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    
                    var t = CATransform3DIdentity;
                    t.m34 = -(1/500)
                    t = CATransform3DTranslate(t, item.xDisp * factor , 0.0, item.zDisp);
                    item.layer.transform = t;
                    
                })
            })
            
            if i == carouselItems.count - 1 && detected { loopFinished = true }
            else { loopFinished = false }
        }
    }
    
    func factorForXDisp(x: CGFloat) -> CGFloat {
        
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
    
    
    // MARK: helper functions
    func startDecelerating() {
        
        isDecelerating = true
        
        let distance = decelerationDistance()
        let offsetItems = carouselItems[0].xDisp
        let endOffsetItems = offsetItems + distance
        
        selectedIndex = -Int(round(endOffsetItems / xDisplacement))
        
        let offsetToAdd = xDisplacement * -CGFloat(selectedIndex) - offsetItems
        moveCarousel(-offsetToAdd)
        isDecelerating = false
    }
    
    
    func decelerationDistance() ->CGFloat {
        let acceleration = -currentGestureVelocity * decelerationMultiplier;
        
        if acceleration == 0 { return 0 }
        else { return -pow(currentGestureVelocity, 2.0) / (2.0 * acceleration); }
    }
    
    
    // MARK: page control update
    func updatePageControl(index: Int) {
        pageControl.currentPage = index
    }
    
}
