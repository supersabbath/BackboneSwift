//
//  ViewController.swift
//  BackboneSwift
//
//  Created by Fernando Canon on 20/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftyJSON

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        class CollectionSubClas: Collection<Model> {
            
//            override func parse(response: JSON) -> Promise<Array<Model>> {
//                return Promise()
//            }

        }
        
        let col =  Collection<Model>(withUrl: " hola ")
        col.fetch()
        
        
        // Dispose of any resources that can be recreated.
    }


}

