//
//  PaintViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/3/9.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class PaintViewController: UIViewController, GCDAsyncUdpSocketDelegate, AddressDelegate {
    var ipAddress: String!
    var portAddress: UInt16!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var paintView: PaintView!
    var locationSender: GCDAsyncUdpSocket!
    var isFirstAppear: Bool!
    var lastLocation: CGPoint!

    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstAppear = true
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
            let screenLocation = moveSender.location(in: moveSender.view)
            let location = CGPoint(x: screenLocation.x / 288 * 800, y: screenLocation.y / 216 * 600)
            if CGRect(x: 0, y: 0, width: 800, height: 600).contains(location) {
                lastLocation = location
                let str = String(format: "%03d%03d9AB", Int(location.x), Int(location.y))
                print(str)
                paintView.draw(screenLocation)
                locationSender.send(str.data(using: .ascii)!, withTimeout: -1, tag: 1)
            } else {
                let str = String(format: "%03d%03d0AB", Int(lastLocation.x), Int(lastLocation.y))
                print(str)
                paintView.finishCurrentDraw()
                locationSender.send(str.data(using: .ascii)!, withTimeout: -1, tag: 1)
            }
        case .ended:
            fallthrough
        case .cancelled:
            let location = moveSender.location(in: moveSender.view)
            let str = String(format: "%03d%03d0AB", Int(location.x), Int(location.y))
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
        paintView.saveImage()
    }
}
