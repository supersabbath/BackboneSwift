//
//  Router.swift
//  StarzTV
//
//  Created by Fernando Canon on 26/01/16.
//  Copyright © 2016 Starzplay. All rights reserved.
//

import UIKit


public struct Router {
    
    let baseUrl = "https://peg-dev-public-api.eu.cloudhub.io/api/v0.2/"
    var login : String  {
        get{
            return self.baseUrl + "login"
        }
    }
}
