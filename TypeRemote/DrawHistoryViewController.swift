//
//  DrawHistoryViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/5/8.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import Photos

protocol SendDrawHistory {
    func sendDrawHistory(_ historyStr: String)
}

class DrawHistoryViewController: UITableViewController {
    
    var listData: [[String: String]]!
    var delegator: SendDrawHistory!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableView", for: indexPath)
        let index = indexPath.row
        for photoID in listData[index].keys {
            print(photoID)
            let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoID], options: nil)
            let asset = assetResult[0]
            let options = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = { (adjustmeta: PHAdjustmentData)->Bool in
                return true
            }
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { (image, _:[AnyHashable : Any]?) in
                DispatchQueue.main.async {
                    cell.imageView?.image = image
                    cell.textLabel?.text = "123"
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        for historyStr in listData[index].values {
            delegator.sendDrawHistory(historyStr)
        }
        dismiss(animated: true, completion: nil)
    }
}
