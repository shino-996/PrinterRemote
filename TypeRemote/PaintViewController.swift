//
//  PaintViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/3/9.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class PaintViewController: UIViewController, GCDAsyncUdpSocketDelegate {
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var operateButtons: UIStackView!
    // 记录程序是否第一次打开，保证在程序刚打开时会弹出连接界面
    var isFirstAppear = true
    // UDP对象
    var locationSender: GCDAsyncUdpSocket!
    //上一次触摸的位置
    var lastLocation: CGPoint!

    @IBOutlet weak var paintView: PaintView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 显示界面后，如果是第一次打开程序，弹出连接界面
        if isFirstAppear {
            performSegue(withIdentifier: "ChangeIP", sender: self)
            isFirstAppear = false
        }
    }
    
    // 分别跳转至连接界面和历史记录界面
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "ChangeIP" {
            let controller = segue.destination as! IPConnectViewController
            controller.delegator = self
            if isFirstAppear {
                controller.isFirstLoad = true
            } else {
                controller.isFirstLoad = false
            }
        } else if segue.identifier! == "DrawHistory" {
            let controller = segue.destination as! DrawHistoryViewController
            controller.delegator = self
        }
    }
    
    @IBAction func move(_ sender: Any) {
        let moveSender = sender as! UIPanGestureRecognizer
        switch moveSender.state {
        case .possible:
            print("Touch possible")
        case .began:
            let location = moveSender.location(in: paintView)
            if paintView.frame.contains(location) {
                lastLocation = location
            } else {
                lastLocation = nil
            }
        case .changed:
            if lastLocation == nil {
                break
            }
            let location = moveSender.location(in: paintView)
            if paintView.frame.contains(location) {
                lastLocation = location
                paintView.draw(location)
                sendControlInfo(ofPoint: location, WithPenUp: false)
            }
        case .ended:
            fallthrough
        case .cancelled:
            paintView.finishCurrentDraw()
            sendControlInfo(ofPoint: lastLocation, WithPenUp: true)
        default:
            print("Failed!")
        }
    }
    
    @IBAction func clearDraw() {
        paintView.clearDraw()
    }
    
    @IBAction func saveImage() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let imagePoints = ImagePoints(context: context)
        imagePoints.image = UIImagePNGRepresentation(paintView.image())!
        imagePoints.points = paintView.pointToDraw
        imagePoints.id = Date()
        appDelegate.saveContext()
        let alertcontroller = UIAlertController(title: "保存成功！", message: nil, preferredStyle: .alert)
        self.present(alertcontroller, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.presentedViewController?.dismiss(animated: true)
            self.paintView.clearDraw()
        }
    }
    
    internal func sendControlInfo(ofPoint point: CGPoint, WithPenUp isUp: Bool) {
        var penUpStr: String
        if isUp {
            penUpStr = "0"
        } else {
            penUpStr = "9"
        }
        let scale = 3000 / max(paintView.frame.height, paintView.frame.width)
        point.applying(CGAffineTransform(scaleX: scale, y: scale))
        let controlStr = String(format: "%04d %04d " + penUpStr, Int(point.x), Int(point.y))
        print(controlStr)
        locationSender.send(controlStr.data(using: .ascii)!, withTimeout: -1, tag: 1)
    }
}

// DrawHistoryViewController 委托扩展
extension PaintViewController: SendDrawHistory {
    func drawHistory(_ lines: [[CGPoint]]) {
        for line in lines {
            for point in line {
                sendControlInfo(ofPoint: point, WithPenUp: false)
            }
            if let endOfLine = line.last {
                sendControlInfo(ofPoint: endOfLine, WithPenUp: true)
            }
        }
        paintView.drawLines(lines)
    }
}

// IPConnectViewController委托扩展，回调设置连接IP端口
extension PaintViewController: AddressDelegate {
    func set(host: String, AndPort port: UInt16) {
        addressButton.titleLabel?.text = host + ": \(port)"
        addressButton.setTitle(host + ":\(port)", for: .normal)
        locationSender = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        do {
            try locationSender.connect(toHost: host, onPort: port)
        } catch(let error) {
            print("UDP连接失败")
            print(error)
        }
    }
}
