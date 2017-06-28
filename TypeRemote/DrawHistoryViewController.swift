//
//  DrawHistoryViewController.swift
//  TypeRemote
//
//  Created by shino on 2017/5/8.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import CoreData

protocol SendDrawHistory {
    func drawHistory(_ lines: [[CGPoint]])
}

class DrawHistoryViewController: UITableViewController {

    var delegator: SendDrawHistory!
    var data: [ImagePoints]!

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = ImagePoints.fetchRequest() as NSFetchRequest
        do {
            data = try context.fetch(fetchRequest) 
        } catch(let error) {
            print(error)
        }
    }
    
    @IBAction func returnView() {
        self.dismiss(animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableView", for: indexPath)
        let index = indexPath.row
        cell.imageView?.image = UIImage(data: data[index].image)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.hh.dd hh:mm"
        cell.textLabel?.text = dateFormatter.string(from: data[index].id)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        delegator.drawHistory(data[index].points)
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "删除"
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.row
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            context.delete(data[index])
            appDelegate.saveContext()
            data.remove(at: index)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
}
