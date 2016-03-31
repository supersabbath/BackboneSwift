//
//  BackboneParser.swift
//  BackboneSwift
//
//  Created by Fernando Canon on 22/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

import UIKit
import SwiftyJSON


public protocol ViewControllerBack {
   
    associatedtype ModelType
    var model:ModelType? {get set}
    func render(model:ModelType?);
}
