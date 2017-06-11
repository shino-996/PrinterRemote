//
//  ImagePoints+CoreDataProperties.swift
//  TypeRemote
//
//  Created by shino on 2017/6/11.
//  Copyright © 2017年 shino. All rights reserved.
//

import Foundation
import CoreData
import CoreImage


extension ImagePoints {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImagePoints> {
        return NSFetchRequest<ImagePoints>(entityName: "ImagePoints")
    }

    @NSManaged public var id: String?
    @NSManaged public var points: [[CGPoint]]?
    @NSManaged public var image: NSData?

}
