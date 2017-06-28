//
//  ImagePoints+CoreDataProperties.swift
//  TypeRemote
//
//  Created by shino on 2017/6/28.
//  Copyright © 2017年 shino. All rights reserved.
//

import Foundation
import CoreData
import CoreImage


extension ImagePoints {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImagePoints> {
        return NSFetchRequest<ImagePoints>(entityName: "ImagePoints")
    }

    @NSManaged public var id: Date
    @NSManaged public var image: Data
    @NSManaged public var points: [[CGPoint]]

}
