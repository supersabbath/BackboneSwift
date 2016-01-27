//
//  Collection.swift
//  BackboneSwift
//
//  Created by Fernando Canon on 21/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

/*

model
– modelId
– constructor / initialize
models
– toJSON
– sync
– Underscore Methods (46)
– add
– remove
– reset
– set
– get
– at
push
pop
– unshift
– shift
– slice
– length
– comparator
– sort
– pluck
– where
– findWhere
– url
parse
– clone
– fetch
– create
*/

import UIKit
import SwiftyJSON
import Alamofire
import PromiseKit

struct Options {
    
}

public class Collection <GenericModel: BackboneModel> :NSObject {
    
    var models = [GenericModel]()
    var url:String?
    
    // MARK: - PUBLIC BACKBONE METHODS 🅿️
    
    /**
    Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
    */
    func fetch(options:Options , onSuccess: (Array<GenericModel>)->Void , onError:(ErrorType)->Void){
        
        guard let feedURL = url  else {
            print("Collections must have an URL, fetch cancelled")
            return
        }
        
        
        Alamofire.request(.GET, feedURL , parameters:nil )
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
              
                switch response.result {
                case .Success:
                    if let jsonValue = response.result.value {
                        
                         self.parse(jsonValue)
                        
                         onSuccess(self.models)
                    }
                case .Failure(let error):
                    print(error)
                    onError(error)
                }
        }
    }
    
    
    
    /**
    Promisify Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
    func fetch(options:Options ) -> Promise <Array<GenericModel> >  {
        
        return Promise { fulfill, reject in
            
            fetch(options, onSuccess: { (response) -> Void in
                
                    fulfill(response)
                
                }, onError: { (error) -> Void in
                    
                    reject(error)
            })
        }
    }
    /**
     
     parse is called by Backbone whenever a collection's models are returned by the server, in fetch. The function is passed the raw response object, and should return the array of model attributes to be added to the collection. The default implementation is a no-op, simply passing through the JSON response. Override this if you need to work with a preexisting API, or better namespace your responses.
     */
    
    func parse(response: AnyObject) {
        
        let json = JSON(response)
        
        if let array =  json.arrayObject {
            
            print("The collection response contained and Array: \(array)")
            
            array.forEach({ (item) -> () in
                
                let t = GenericModel.init()
                //push()
                t.parse(item)
                self.push(t)
            })
            
        } else if let dic = json.dictionaryObject {
            
            print("The collection response contained and Dictionary: \(dic)")
        }
        
        
    }
    
    
//    private func parseAsync(response: AnyObject) -> Promise<Array<GenericModel>>  {
//        
//        return Promise { fulfill, reject in
//            
//            let objects = self.parse(response)
//            
//            fulfill(objects)
//            //TODO: reject
//        }
//    }
    /**
     Add a model at the end of a collection. Takes the same options as add.
     */
    func push(item: GenericModel) {
        models.append(item)
    }
    
    
    /**
     Remove and return the last model from a collection. TODO: [Takes the same options as remove.]
     */
    func pop() -> GenericModel? {
        if (models.count > 0) {
            return models.removeLast()
        } else {
            return nil
        }
    }
    
}

