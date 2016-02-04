//
//  Model.swift
//  BackboneSwift
//
//  Created by Fernando Canon on 20/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

/*
– extend
– constructor / initialize
– get
– set
– escape
– has
– unset
– clear
– id
– idAttribute
– cid
– attributes
– changed
– defaults
– sync
– fetch
– save
– destroy
– Underscore Methods (9)
– validate
– validationError
– isValid
url
– urlRoot
parse
– clone
– isNew
– hasChanged
– changedAttributes
– previous
– previousAttributes

*/

import UIKit
import SwiftyJSON
import Alamofire
import PromiseKit

public protocol BackboneConcurrencyDelegate {

    func concurrentOperationQueue() -> dispatch_queue_t

}

public protocol BackboneModel
{
    // Variables
    /**
    Returns the relative URL where the model's resource would be located on the server. If your models are located somewhere else, override this method with the correct logic. Generates URLs of the form: "[collection.url]/[id]" by default, but you may override by specifying an explicit urlRoot if the model's collection shouldn't be taken into account.
    */
    
    var url:String?{ get set }
    // Functions
    func parse(response: JSONUtils.JSONDictionary)
    func toJSON() -> String
  
    init()
}

public class Model: NSObject , BackboneModel {
    
    public var url:String?
    
    required override public init() {
        
    }
    
    // Mark: 100% Backbone funcs
    /**
    parse is called whenever a model's data is returned by the server, in fetch, and save. The function is passed the raw response object, and should return the attributes hash to be set on the model. The default implementation is a no-op, simply passing through the JSON response. Override this if you need to work with a preexisting API, or better namespace your responses.
    */
    public func parse(response: JSONUtils.JSONDictionary) {
        
        let mirror = Mirror(reflecting: self)
        
        mirror.children.forEach({ [unowned self] (label, value) -> ()  in
            
            self.assignToClassVariable(label!, payload: response)
        })
        
    }
    
    /**
     Return a shallow copy of the model's attributes for JSON stringification. This can be used for persistence, serialization, or for augmentation before being sent to the server. The name of this method is a bit confusing, as it doesn't actually return a JSON string
     
     */
    public func toJSON() -> String
    {
        return ""
    }
    
    
    private func  assignToClassVariable (varName:String , payload :[String:AnyObject])
    {
  
        
        if let value = payload[varName] >>> unWrapString {
           //   print("--->>> \(varName)")
           //   print(value)
            self.setValue(value, forKey: varName)
        }
    }
    
    private func unWrapString(object: AnyObject) -> String {
        return (object as? String) ?? ""
    }
    
    
    /**
     Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
    func fetch(options:HttpOptions? , onSuccess: () ->Void , onError:(BackboneError)->Void){
        
        guard var feedURL = url  else {
            print("Models must have an URL, fetch cancelled")
            onError(.InvalidURL)
            return
        }
        
        if let queryURL =  options?.processParametters(feedURL) {
            feedURL = queryURL
        }
        
        Alamofire.request(.GET, feedURL , parameters:options?.body )
            .validate()
            .responseJSON { [unowned self] response in
                
                switch response.result {
                case .Success:
                    
                    if let jsonValue = response.result.value {
                        if let dic = jsonValue as? JSONUtils.JSONDictionary {
                            self.parse(dic)
                            onSuccess()
                            return
                        }
                    }
                onError(.ParsingError)
                
                case .Failure(let error):
                print(error)
                onError(.HttpError(description: error.description))
        }
    }
}



/**
 Promisify Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
 */

    public func fetch(options:HttpOptions?=nil) -> Promise <Void>  {
    
    return Promise { fulfill, reject in
        
        fetch(options, onSuccess: { () -> Void in
            
            fulfill()
            
            }, onError: { (error) -> Void in
                
                reject(error)
        })
    }
}
}



