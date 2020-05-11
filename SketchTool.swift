//
//  SketchTool.swift
//  Mystic
//
//  Created by Travis A. Weerts on 3/20/16.
//  Copyright © 2016 Blackpulp. All rights reserved.
//

import UIKit

func midPoint(_ p1: CGPoint, p2: CGPoint) -> CGPoint
{
    return CGPoint (x: (p1.x + p2.x) * 0.5,y: (p1.y + p2.y) * 0.5);
}

func adjustPathRect(_ rect: CGRect, stroke: CGFloat) -> CGRect
{
    var r:CGRect = rect
    r.origin.x    -= stroke * 2.0
    r.origin.y    -= stroke * 2.0
    r.size.width  += stroke * 4.0
    r.size.height += stroke * 4.0
    return r
}

enum SketchToolType {
    case brush
    case eraser
    case pen
    
}

@objc class SketchTool: NSObject
{
    static func tool(_ type: SketchToolType) -> SketchTool
    {
        var t:SketchTool
        switch type {
            case .brush:    t = SketchToolBrush.init()
            case .pen:      t = SketchToolPen.init()
            case .eraser:   t = SketchToolEraser.init()
        }
        return t
    }
    var color:UIColor? = UIColor.white
    var stroke:CGFloat = 1
    var opacity:CGFloat = 1
    var feather:CGFloat = 0
    var pointStart:CGPoint = CGPoint.zero
    var line:LineInfo {
        get { return LineInfo(width:stroke,opacity: opacity) }
        set(value) { stroke = value.width; opacity = value.opacity; }
    }
    
    override init() {
        super.init()
    }
    func addPoint(_ last: CGPoint, previous: CGPoint, current: CGPoint) -> CGRect
    {
//        var rect:CGRect = CGRectZero
        
        return CGRect.zero
    }
    func movePoint(_ from: CGPoint, to: CGPoint)
    {
        
    }
    func draw(_ rect: CGRect, context: CGContext)
    {
//        let context = UIGraphicsGetCurrentContext()

    }
}

@objc class SketchToolPen: SketchTool
{
    var path:CGMutablePath
    
    override init() {
        path = CGMutablePath()
        super.init()
//        self.color = UIColor.clear
    }
    override func draw(_ rect: CGRect, context: CGContext) {
        context.setStrokeColor((color?.cgColor)!)
        context.addPath(path);
        context.setLineCap(.round);
        context.setLineWidth(stroke);
        context.setBlendMode(.normal);
        context.setAlpha(opacity);
        context.strokePath()
    }
    override func addPoint(_ last: CGPoint, previous: CGPoint, current: CGPoint) -> CGRect {
        let mid1 = midPoint(previous, p2: last)
        let mid2 = midPoint(current, p2: previous)
        let subpath = CGMutablePath()
        subpath.move(to: CGPoint(x: mid1.x, y: mid1.y))
        subpath.addQuadCurve(to: mid2, control: previous)
        path.addPath(subpath)
        return adjustPathRect(subpath.boundingBox, stroke: self.stroke)
    }
}

@objc class SketchToolBrush: SketchToolPen
{
    override init() {
        super.init()
    }
    override func draw(_ rect: CGRect, context: CGContext) {
        super.draw(rect, context: context)
    }
}



@objc class SketchToolEraser: SketchToolPen
{
    override init() {
        super.init()
    }
    override func draw(_ rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.clear.cgColor)
        context.addPath(path);
        context.setLineCap(.round);
        context.setLineWidth(stroke);
        context.setBlendMode(.clear);
        context.setAlpha(opacity);
        context.strokePath()
//        super.draw(rect, context: context)
    }
}
