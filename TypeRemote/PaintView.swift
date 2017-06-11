//
//  PaintView.swift
//  TypeRemote
//
//  Created by shino on 2017/5/8.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit

class PaintView: UIView {
    var pointToDraw = [[CGPoint]]()
    var currentPointToDraw = [CGPoint]()
    var cgContext: CGContext!
    
    override func draw(_ rect: CGRect) {
        cgContext = UIGraphicsGetCurrentContext()
        for pointArray in pointToDraw {
            let path = CGMutablePath()
            if pointArray.count > 0 {
                path.move(to: pointArray[0])
            }
            for point in pointArray {
                path.addLine(to: point)
            }
            cgContext?.setStrokeColor(UIColor.black.cgColor)
            cgContext?.setLineWidth(2)
            cgContext?.addPath(path)
            cgContext?.strokePath()
        }
        
        if currentPointToDraw.count > 0 {
            let path = CGMutablePath()
            path.move(to: currentPointToDraw[0])
            for point in currentPointToDraw {
                path.addLine(to: point)
            }
            cgContext?.setStrokeColor(UIColor.black.cgColor)
            cgContext?.setLineWidth(2)
            cgContext?.addPath(path)
            cgContext?.strokePath()
        }
    }
    
    func draw(_ point: CGPoint) {
        currentPointToDraw.append(point)
        self.setNeedsDisplay()
    }
    
    func drawLines(_ lines: [[CGPoint]]) {
        pointToDraw = lines
        self.setNeedsDisplay()
    }
    
    func finishCurrentDraw() {
        pointToDraw.append(currentPointToDraw)
        currentPointToDraw.removeAll()
        self.setNeedsDisplay()
    }
    
    func clearDraw() {
        pointToDraw.removeAll()
        currentPointToDraw.removeAll()
        self.setNeedsDisplay()
    }
    
    func saveImage() -> UIImage {
        let cgImage = cgContext.makeImage()
        return UIImage(cgImage: cgImage!)
    }
}
