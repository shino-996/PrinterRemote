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
    var plistArray = [[String: String]]()
    var image: UIImage!
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        for pointArray in pointToDraw {
            let path = CGMutablePath()
            if pointArray.count > 0 {
                path.move(to: pointArray[0])
            }
            for point in pointArray {
                path.addLine(to: point)
            }
            context?.setStrokeColor(UIColor.black.cgColor)
            context?.setLineWidth(2)
            context?.addPath(path)
            context?.strokePath()
        }
        
        if currentPointToDraw.count > 0 {
            let path = CGMutablePath()
            path.move(to: currentPointToDraw[0])
            for point in currentPointToDraw {
                path.addLine(to: point)
            }
            context?.setStrokeColor(UIColor.black.cgColor)
            context?.setLineWidth(2)
            context?.addPath(path)
            context?.strokePath()
        }
        let cgImage = context?.makeImage()
        image = UIImage(cgImage: cgImage!)
    }
    
    func draw(_ point: CGPoint) {
        currentPointToDraw.append(point)
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
}
