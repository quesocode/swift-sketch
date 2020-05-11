//
//  SketchView.swift
//  Mystic
//
//  Created by Travis A. Weerts on 3/20/16.
//  Copyright © 2016 Blackpulp. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


let π3 = CGFloat(Double.pi)

struct LineInfo {
    var width:CGFloat
    var opacity:CGFloat
}

@objc class SketchView: UIView {

    // Undo
    var canUndo:Bool { return paths?.count > 0 }
    var undoSteps:Int { return (buffer?.count)! }
    var canRedo:Bool { return buffer?.count > 0 }
    
    // Tool & Line
    var lineOpacity: CGFloat = 1
    var lineFeather: CGFloat = 0
    var lineScale: CGFloat = 0.2
    
    var image:UIImage?
    
    
    var useStylus: Bool = false
    var isErasing: Bool = false
    var applyPressure: Bool = true
    var fingerErases: Bool = false
    var defaultLineWidth: CGFloat = 6
    var color:UIColor? {
        get { return tool?.color }
        set(newColor) { tool?.color = newColor }
    }
    
    fileprivate let minLineWidth: CGFloat = 1
    fileprivate let forceSensitivity: CGFloat = 4.0
    fileprivate let tiltThreshold = π3/6  // 30º
    fileprivate var buffer:NSMutableArray?
    fileprivate var paths:NSMutableArray?
    fileprivate var _tool:SketchTool?
    fileprivate var pointPreviousLast:CGPoint = CGPoint.zero
    fileprivate var pointPrevious:CGPoint = CGPoint.zero
    fileprivate var pointCurrent:CGPoint = CGPoint.zero
    fileprivate var _toolType:SketchToolType = SketchToolType.brush
    var toolType:Int {
        get {
            switch _toolType {
                case .brush: return 0
                case .pen: return 1
                case .eraser: return 0
            }
        }
        set(value)
        {
            switch value
            {
                case 0: _toolType = .brush
                case 1: _toolType = .pen
                case 2: _toolType = .eraser
                default: _toolType = .brush
            }
        }
    }
    
    var tool: SketchTool? {
        get { if (_tool == nil) { _tool = SketchTool.tool(_toolType) }; return _tool }
        set(value) { _tool = value }
    }
    // Blocks
    var started: ((SketchView?) -> Void)?
    var changed: ((SketchView?) -> Void)?
    var ended: ((SketchView?) -> Void)?
    var updated: ((UIImage?, String?, SketchView?) -> Void)?
    var endedTool: ((SketchTool?, SketchView?) -> Void)?
    var cancelled: ((SketchView?) -> Void)?
    var filled: ((SketchView?) -> Void)?
    var cleared: ((SketchView?) -> Void)?
    var debug: ((UIImage?, NSString?, SketchView?) -> Void)?
    var changedBrush: ((SketchView?) -> Void)?
    var didUndo:((SketchView?) -> Void)?
    var didRedo:((SketchView?) -> Void)?
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        setup()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setup()
    }
    fileprivate func setup()
    {
        paths = NSMutableArray()
        buffer = NSMutableArray()
        backgroundColor = UIColor.clear
        _toolType = .brush
    }
    
    override func draw(_ rect: CGRect) {
//        super.drawRect(rect)
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        let ctx = UIGraphicsGetCurrentContext()
//        UIColor.blackColor().setFill()
//        CGContextFillRect(ctx, bounds)
        image?.draw(at: CGPoint.zero)
        tool?.draw(rect, context: ctx!)
        updated?(UIGraphicsGetImageFromCurrentImageContext(), "drawRect", self)
        UIGraphicsEndImageContext()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        pointPrevious = touch.previousLocation(in: self)
        pointCurrent = touch.location(in: self)
        self.tool?.line = line(touch)
        self.tool?.feather = lineFeather
        self.tool?.pointStart = pointCurrent
        paths?.add(self.tool!)
        started?(self)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelled?(self)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finished()
        ended?(self)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        pointPreviousLast = pointPrevious
        pointPrevious = touch.previousLocation(in: self)
        pointCurrent = touch.location(in: self)
        self.tool?.line = line(touch)
        switch _toolType {
            
            case .brush:
                setNeedsDisplay((self.tool?.addPoint(pointPreviousLast, previous: pointPrevious, current: pointCurrent))!)
                break
//            case .Pen: setNeedsDisplayInRect((self.tool?.addPoint(pointPreviousLast, previous: pointPrevious, current: pointCurrent))!)
//            case .Eraser: self.tool?.movePoint(pointPrevious, to: pointCurrent); setNeedsDisplay()
            
            default:
                setNeedsDisplay((self.tool?.addPoint(pointPreviousLast, previous: pointPrevious, current: pointCurrent))!)
                break
        }
        changed?(self)
    }
    func finished()
    {
        update(false)
        buffer?.removeAllObjects()
        endedTool?(tool,self)
        tool = nil
    }
    func update(_ redraw: Bool)
    {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        let ctx = UIGraphicsGetCurrentContext()

        if(redraw)
        {
            image = nil
            for pathTool in paths! { (pathTool as AnyObject).draw(bounds, context: ctx!) }
        }
        else
        {
            image?.draw(at: CGPoint.zero)
            tool?.draw(bounds, context: ctx!)
        }
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        updated?(image, "updated", self)
    }
    
    
    func undo()
    {
        if canUndo == false { return }
        buffer?.add((paths?.lastObject)!)
        paths?.removeLastObject()
        update(true)
        setNeedsDisplay()
        didUndo?(self)
    }
    func redo()
    {
        if canRedo == false { return }
        paths?.add((buffer?.lastObject)!)
        buffer?.removeLastObject()
        update(true)
        setNeedsDisplay()
        didRedo?(self)
    }
    
    func clear()
    {
        tool = nil
        buffer?.removeAllObjects()
        paths?.removeAllObjects()
        update(true)
        setNeedsDisplay()
        cleared?(self)
    }
    
    func fill()
    {
        
    }
    func empty()
    {
        clear()
    }
    
    
    fileprivate func line(_ touch: UITouch) -> LineInfo {
        if #available(iOS 9.1, *) {
            if touch.type == .stylus && useStylus {
                return touch.altitudeAngle < tiltThreshold ? lineForShading(touch) : lineForDrawing(touch);
            }
        }
        return LineInfo(width:max(minLineWidth, (transform.isIdentity ? max(touch.majorRadius / 2, minLineWidth) : max(touch.majorRadius / 2, minLineWidth)*(1/transform.a) * (max(0.001,lineScale/2) * 100))), opacity: lineOpacity)
    }
    fileprivate func lineForShading(_ touch: UITouch) -> LineInfo {
        let __prev = touch.previousLocation(in: self)
        let location = touch.location(in: self)
        var vector1 = CGVector(dx: location.x, dy: location.y)
        if #available(iOS 9.1, *) {

            vector1 = touch.azimuthUnitVector(in: self)
        }
        let vector2 = CGPoint(x: location.x - __prev.x, y: location.y - __prev.y)
        var angle = abs(atan2(vector2.y, vector2.x) - atan2(vector1.dy, vector1.dx))
        if angle > π2 { angle = 2 * π2 - angle }
        if angle > π2 / 2 { angle = π2 - angle }
        let minAngle: CGFloat = 0
        let maxAngle = π2 / 2
        let normalizedAngle = (angle - minAngle) / (maxAngle - minAngle)
        let maxLineWidth: CGFloat = 60
        var lineWidth = maxLineWidth * normalizedAngle
        let minAltitudeAngle: CGFloat = 0.25
        let maxAltitudeAngle = tiltThreshold
        if #available(iOS 9.1, *) {
            let altitudeAngle = touch.altitudeAngle < minAltitudeAngle ? minAltitudeAngle : touch.altitudeAngle
            let normalizedAltitude = 1 - ((altitudeAngle - minAltitudeAngle) / (maxAltitudeAngle - minAltitudeAngle))
            lineWidth = lineWidth * normalizedAltitude + minLineWidth
            return  LineInfo(width:lineWidth * lineScale, opacity:(touch.force - 0) / (5 - 0))
        }
        return  LineInfo(width:lineWidth * lineScale, opacity:1)
    }
    fileprivate func lineForDrawing(_ touch: UITouch) -> LineInfo {
        if #available(iOS 9.1, *) {
            if touch.force > 0 { return LineInfo(width:(touch.force * forceSensitivity), opacity: 1) }
        }
        return LineInfo(width:defaultLineWidth, opacity: 1)
    }

}
