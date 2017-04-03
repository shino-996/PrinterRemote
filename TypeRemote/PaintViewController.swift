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
    var locationSender: GCDAsyncUdpSocket!
    var isFirstAppear: Bool!
    
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
        }
    }
    
    func set(Host host: String, AndPort port: UInt16) {
        ipAddress = host
        portAddress = port
        addressLabel.text = ipAddress + "\(portAddress)"
        locationSender = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        do {
            try locationSender.connect(toHost: ipAddress, onPort: portAddress)
        } catch(let error) {
            print(error)
        }
    }
    
    @IBAction func move(_ sender: Any) {
        let moveSender = sender as! UIPanGestureRecognizer
        if moveSender.state != .ended && moveSender.state != .cancelled {
            let location = moveSender.location(in: moveSender.view)
            let str = "\(location.x),\(location.y)"
            print("\(location.x), \(location.y)")
            locationSender.send(str.data(using: .utf8)!, withTimeout: -1, tag: 0)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print(tag)
    }
}
