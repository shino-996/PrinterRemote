//
//  ViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/3/9.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit

protocol AddressDelegate {
    func set(Host host: String, AndPort port: UInt16);
}

class IPConnectViewController: UIViewController {
    @IBOutlet weak var ipText: UITextField!
    @IBOutlet weak var portText: UITextField!
    var delegator: AddressDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func changeIP() {
        delegator.set(Host: ipText.text!, AndPort: UInt16(portText.text!)!)
        dismiss(animated: true, completion: nil)
    }
}

