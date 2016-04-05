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

class BackBonner: Model{
    var name:String?
    var pegBaseUrl:String?
}

class ViewController: UIViewController {

    
    var model: BackBonner?
    
    func render(model:BackBonner?) {
    
    }
    
    override func viewDidLoad() {
     
        super.viewDidLoad()
        
        model = BackBonner();
        model?.url = "http://mena-cdn-lb.aws.playco.com/prd-peg-data/default/iOS/starz_config.json"
        model?.fetch(HttpOptions()).then { (model, string) -> Void in
            print((model as? BackBonner)!.name);
            self.render(model as? BackBonner)
        }
    }

}

