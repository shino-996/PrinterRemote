//
//  ViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/3/9.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit

protocol AddressDelegate {
    func set(host: String, AndPort port: UInt16);
}

class IPConnectViewController: UIViewController {
    @IBOutlet weak var ipText: UITextField!
    @IBOutlet weak var portText: UITextField!
    var delegator: AddressDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func changeIP() {
        guard let ip = ipText.text, let portStr = portText.text else {
            adressErrorAlert()
            return
        }
        guard let port = UInt16(portStr) else {
            adressErrorAlert()
            return
        }
        let pattern = "^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let matchNum = regex.numberOfMatches(in: ip, options: .reportProgress, range: NSMakeRange(0, ip.characters.count))
        if matchNum == 0 || port < 0 || port > 65534 {
            adressErrorAlert()
            return
        }
        delegator.set(host: ip, AndPort: port)
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func adressErrorAlert() {
        let alert = UIAlertController(title: "提示", message: "地址格式错误！", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "确定", style: .default) { _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
    
}

