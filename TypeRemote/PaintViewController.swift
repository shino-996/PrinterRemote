//
//  PaintViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/3/9.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class PaintViewController: UIViewController, GCDAsyncUdpSocketDelegate, SendDrawHistory {
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var paintView: PaintView!
    // 记录程序是否第一次打开，保证在程序刚打开时会弹出连接界面
    var isFirstAppear: Bool!
    // UDP对象
    var locationSender: GCDAsyncUdpSocket!
    // 连接时使用的IP和端口
    var ipAddress: String!
    var portAddress: UInt16!
    var lastLocation: CGPoint!

    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstAppear = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 显示界面后，如果是第一次打开程序，弹出连接界面
        if isFirstAppear {
            isFirstAppear = false
            performSegue(withIdentifier: "ChangeIP", sender: self)
        }
    }
    
    // 分别跳转至连接界面和历史记录界面
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "ChangeIP" {
            let controller = segue.destination as! IPConnectViewController
            controller.delegator = self
        } else if segue.identifier! == "DrawHistory" {
            let controller = segue.destination as! DrawHistoryViewController
            controller.delegator = self
        }
    }
    
    // CocoaAsyncSocket委托方法，连接上UDP时在地址栏显示连接上的IP和端口
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        DispatchQueue.main.sync {
            addressLabel.text = ipAddress + ": \(portAddress!)"
        }
    }
    
    @IBAction func move(_ sender: Any) {
        let moveSender = sender as! UIPanGestureRecognizer
        switch moveSender.state {
        case .possible:
            print("Touch possible")
        case .began:
            lastLocation = moveSender.location(in: moveSender.view)
            fallthrough
        case .changed:
            let screenLocation = moveSender.location(in: moveSender.view)
            let location = CGPoint(x: screenLocation.x / 300 * 1500, y: screenLocation.y / 200 * 1000)
            if CGRect(x: 0, y: 0, width: 1500, height: 1000).contains(location) {
                lastLocation = location
                let udpStr = String(format: "%04d %04d 9", Int(location.x), Int(location.y))
                print(udpStr)
                paintView.draw(screenLocation)
                locationSender.send(udpStr.data(using: .ascii)!, withTimeout: -1, tag: 1)
            } else {
                let udpStr = String(format: "%04d %04d 0", Int(lastLocation.x), Int(lastLocation.y))
                print(udpStr)
                paintView.finishCurrentDraw()
                locationSender.send(udpStr.data(using: .ascii)!, withTimeout: -1, tag: 1)
            }
        case .ended:
            fallthrough
        case .cancelled:
            let str = String(format: "%04d %04d 0", Int(lastLocation.x), Int(lastLocation.y))
            print(str)
            paintView.finishCurrentDraw()
            locationSender.send(str.data(using: .ascii)!, withTimeout: -1, tag: 2)
        default:
            print("Failed!")
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print(tag)
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
    
    func drawHistory(_ lines: [[CGPoint]]) {
        for line in lines {
            for point in line {
                let x = point.x / 300 * 1500
                let y = point.y / 200 * 1000
                let udpStr = String(format: "%04d %04d 9", Int(x), Int(y))
                locationSender.send(udpStr.data(using: .ascii)!, withTimeout: -1, tag: 1)
                print(udpStr)
            }
            if let endOfLine = line.last {
                let x = endOfLine.x / 300 * 1500
                let y = endOfLine.y / 200 * 1000
                let udpStr = String(format: "%04d %04d 0", Int(x), Int(y))
                locationSender.send(udpStr.data(using: .ascii)!, withTimeout: -1, tag: 1)
                print(udpStr)
            }
        }
        paintView.drawLines(lines)
    }
}

// IPConnectViewController委托扩展
extension PaintViewController: AddressDelegate {
    // IPConnectViewController委托方法，回调设置连接IP端口
    func set(host: String, AndPort port: UInt16) {
        ipAddress = host
        portAddress = port
        // 连接前将地址栏状态设置为未连接
        addressLabel.text = "Unconnected"
        locationSender = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        do {
            try locationSender.connect(toHost: ipAddress, onPort: portAddress)
        } catch(let error) {
            print("UDP连接失败")
            print(error)
        }
    }
}
