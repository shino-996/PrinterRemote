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
import MobileCoreServices

class PaintViewController: UIViewController, GCDAsyncUdpSocketDelegate, AddressDelegate, SendDrawHistory, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var paintView: PaintView!
    @IBOutlet weak var loadingSign: UIActivityIndicatorView!
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
        // 加载历史记录文件，如果没有记录，新建一个文件
        let path = NSHomeDirectory() + "/Documents/DrawHistory.plist"
        let arrayFromFile = NSArray(contentsOfFile: path)
        if let array = arrayFromFile {
            paintView.plistArray = array as! [[String : String]]
        } else {
            let emptyArray = [[String: String]]()
            NSArray(array: emptyArray).write(toFile: path, atomically: true)
        }
        loadingSign.hidesWhenStopped = true
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
            controller.listData = paintView.plistArray
            controller.delegator = self
        }
    }
    
    // IPConnectViewController委托方法，回调设置连接IPt端口
    func set(Host host: String, AndPort port: UInt16) {
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
    
    // CocoaAsyncSocket委托方法，连接上UDP时在地址栏显示连接上的IP和端口
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
        DispatchQueue.global().async {
            DispatchQueue.main.sync {
                self.loadingSign.startAnimating()
            }
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
            DispatchQueue.main.sync {
                self.loadingSign.stopAnimating()
                let alert = UIAlertController(title: <#T##String?#>, message: <#T##String?#>, preferredStyle: <#T##UIAlertControllerStyle#>)
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
    
    @IBAction func imageRecognize() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.modalTransitionStyle = .coverVertical
        imagePickerController.sourceType = .camera
        imagePickerController.cameraCaptureMode = .photo
        present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        if mediaType == kUTTypeImage as String {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            dismiss(animated: true)
            DispatchQueue.global().async {
                DispatchQueue.main.sync {
                    self.loadingSign.startAnimating()
                }
                self.recognize(Image: image)
                DispatchQueue.main.sync {
                    self.loadingSign.stopAnimating()
                }
            }
        } else {
            print("拍的不是不是图片？")
        }
        self.dismiss(animated: true)
    }
    
    
    func recognize(Image image: UIImage) {
        let cgimage = image.cgImage
        let width = cgimage?.width
        let height = cgimage?.height
        let point = malloc(MemoryLayout<UInt32>.size * width! * height!)
        let context = CGContext(data: point, width: width!, height: height!, bitsPerComponent: 8, bytesPerRow: width! * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: 1)
        context?.draw(cgimage!, in: CGRect(x: 0, y: 0, width: Double(width!), height: Double(height!)))
        let opaquePtr = OpaquePointer(point)
        let pixel = UnsafeMutablePointer<UInt32>(opaquePtr)
        var imageArray = [Int32]()
        for h in 0 ..< height! {
            if h % 8 != 0 {
                continue
            }
            for w in 0 ..< width! {
                if w % 8 != 0 {
                    continue
                }
                let currentPixel = pixel! + width! * h + w
                let a = OpaquePointer(currentPixel)
                let b = UnsafeMutablePointer<UInt8>(a)
                imageArray.append(Int32(b[0]))
                imageArray.append(Int32(b[1]))
                imageArray.append(Int32(b[2]))
            }
        }
        let recognizer = ImageRecognizer()
        recognizer.getMatrix(imageArray as! NSMutableArray, withWidth: Int32(width! / 8), andHeight: Int32(height! / 8))
        recognizer.thinImage()
        recognizer.findKeyPoint()
        let strokeArray = recognizer.getStrokes() as! [[String]]
        print(strokeArray)
    }
}
