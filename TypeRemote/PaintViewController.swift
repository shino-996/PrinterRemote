//
//  PaintViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/3/9.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import Photos

class PaintViewController: UIViewController, GCDAsyncUdpSocketDelegate, AddressDelegate, SendDrawHistory {
    var ipAddress: String!
    var portAddress: UInt16!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var paintView: PaintView!
    var locationSender: GCDAsyncUdpSocket!
    var isFirstAppear: Bool!
    var lastLocation: CGPoint!
    var touchCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstAppear = true
        let path = NSHomeDirectory() + "/Documents/DrawHistory.plist"
        let arrayFromFile = NSArray(contentsOfFile: path)
        if let array = arrayFromFile {
            paintView.plistArray = array as! [[String : String]]
        } else {
            let emptyArray = [[String: String]]()
            NSArray(array: emptyArray).write(toFile: path, atomically: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppear {
            isFirstAppear = false
            performSegue(withIdentifier: "ChangeIP", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "ChangeIP" {
            let controller = segue.destination as! IPConnectViewController
            controller.delegator = self
//            controller.ipText.text = ipAddress
//            controller.portText.text =  "\(portAddress)"
        } else if segue.identifier! == "DrawHistory" {
            let controller = segue.destination as! DrawHistoryViewController
            controller.listData = paintView.plistArray
            controller.delegator = self
        }
    }
    
    func set(Host host: String, AndPort port: UInt16) {
        ipAddress = host
        portAddress = port
        addressLabel.text = "Unconnected"
        locationSender = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        do {
            try locationSender.connect(toHost: ipAddress, onPort: portAddress)
        } catch(let error) {
            print(error)
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        DispatchQueue.main.sync {
            addressLabel.text = ipAddress + ":  \(portAddress!)"
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
            touchCount += 1
            if touchCount != 2 {
                break
            } else {
                touchCount = 0
            }
            let screenLocation = moveSender.location(in: moveSender.view)
            let location = CGPoint(x: screenLocation.x / 300 * 1500, y: screenLocation.y / 200 * 1000)
            if CGRect(x: 0, y: 0, width: 1500, height: 1000).contains(location) {
                lastLocation = location
                let str = String(format: "%04d %04d 9", Int(location.x), Int(location.y))
                print(str)
                paintView.draw(screenLocation)
                locationSender.send(str.data(using: .ascii)!, withTimeout: -1, tag: 1)
            } else {
                let str = String(format: "%04d %04d 0", Int(lastLocation.x), Int(lastLocation.y))
                print(str)
                paintView.finishCurrentDraw()
                locationSender.send(str.data(using: .ascii)!, withTimeout: -1, tag: 1)
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
        PHPhotoLibrary.shared().performChanges({
            let result = PHAssetChangeRequest.creationRequestForAsset(from: self.paintView.image)
            let photoID = result.placeholderForCreatedAsset?.localIdentifier
            self.paintView.plistArray.append([photoID!: self.paintView.pointToDraw.description])
            let path = NSHomeDirectory() + "/Documents/DrawHistory.plist"
            NSArray(array: self.paintView.plistArray).write(toFile: path, atomically: true)
        }) { (ifSuccess: Bool, error: Error?) in
            if ifSuccess {
                print("Save sucessfully!")
            } else {
                print("Save failed!")
                print(error!.localizedDescription)
            }
        }
    }
    
    func sendDrawHistory(_ historyStr: String) {
        var lineSetStr = historyStr.substring(with: historyStr.index(historyStr.startIndex, offsetBy: 2) ..< historyStr.endIndex)
        lineSetStr.remove(at: lineSetStr.index(before: lineSetStr.endIndex))
        lineSetStr.remove(at: lineSetStr.index(before: lineSetStr.endIndex))
        print(lineSetStr)
        let lineStr = lineSetStr.components(separatedBy: "], [")
        for pointSetStr in lineStr {
            var points = pointSetStr.substring(with: pointSetStr.index(pointSetStr.startIndex, offsetBy: 1) ..< pointSetStr.endIndex)
            points.remove(at: points.index(before: points.endIndex))
            print(points)
            let point = points.components(separatedBy: "), (")
            for coordinate in point {
                let str = coordinate
                let coordinates = str.components(separatedBy: ", ")
                let x = Double(coordinates[0])! / 300 * 1500
                let y = Double(coordinates[1])! / 300 * 1500
                let udpStr = String(format: "%04d %04d 9", Int(x), Int(y)) as Optional
                locationSender.send((udpStr?.data(using: .ascii)!)!, withTimeout: -1, tag: 1)
            }
            let lastPointCoordinates = point.last?.components(separatedBy: ", ")
            let x = Double((lastPointCoordinates?[0])!)! / 300 * 1500
            let y = Double((lastPointCoordinates?[1])!)! / 200 * 1500
            let udpStr = String(format: "%04d %04d 0", Int(x), Int(y)) as Optional
            locationSender.send((udpStr?.data(using: .ascii)!)!, withTimeout: -1, tag: 1)
        }
    }
}
