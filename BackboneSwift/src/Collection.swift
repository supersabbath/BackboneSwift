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
fetch
– create
*/

import UIKit
import SwiftyJSON
import Alamofire
import PromiseKit

public struct HttpOptions {
   
    
    public var useCache = true
    public var headers:[String:String]?
    var query:String?
    var body:[String:AnyObject]?
    
    
    public init(){}
    
    public init (httpHeader:[String:String]){
        headers = httpHeader
    }
    
    public init(postBody:[String:AnyObject]){
        body = postBody
    }
    public init(queryString:String){
    
        query = queryString
    }
    
    subscript(queryValues:String) -> String {
        get {
            return query ?? ""
        }
        set {
            query = queryValues
        }
    }
    
    
    
    func stringifyBody()->String? {
       
        guard let requestBody = body else { return nil}
        
       let stringify = JSONUtils().JSONStringifyCommand(requestBody);
        
        return stringify
    }
    
    
}


public enum BackboneError: ErrorType {
    case InvalidURL
    case HttpError(description:String)
    case ErrorWithJSON(parameters:JSONUtils.JSONDictionary)
    case ParsingError
    case InvalidHTTPMethod
    case FailedPOST
}


public struct FetchResult <T: BackboneModel>  {
    
    public let models:[T]
    public var response: NSHTTPURLResponse?
    public var isCacheResult = false
    
    init( modelArray:[T]){
        models = modelArray
    }
    
    init( modelArray:[T] , fromCache:Bool){
        models = modelArray
        isCacheResult = fromCache
    }
    
    init( modelArray:[T] , httpResponse:NSHTTPURLResponse){
        models = modelArray
        response = httpResponse
    }
}


public enum RESTMethod {
    case  GET,POST,PUT,DELETE
}

public class BackboneBase: NSObject {
    

    
    public func sync (method:RESTMethod, model: Model , option:(callback:()->AnyObject,errorCallback:(ErrorType) ->Void ) ){}
}



public class Collection <GenericModel: BackboneModel>  :NSObject {
    
    public var models = [GenericModel]()
    
    var url:String?
    public var delegate:BackboneDelegate?
    
    public init( withUrl:String) {
        url = withUrl
    }
    
   
    // MARK: - PUBLIC BACKBONE METHODS 🅿️
    
    /**
    Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
    */
    public func fetch(options:HttpOptions?=nil, onSuccess: (FetchResult<GenericModel>)->Void , onError:(BackboneError)->Void){
        
        guard let feedURL = url  else {
            print("Collections must have an URL, fetch cancelled")
            onError(.InvalidURL)
            return 
        }
       
        if let query = options?.query{
            
            let urlComponents = NSURLComponents(string: feedURL)
           
            urlComponents?.query = query
            
            synch(urlComponents!, method: "GET", options: options,onSuccess: onSuccess, onError: onError)
        }
        else{
            synch(feedURL, method: "GET", options: options,onSuccess: onSuccess, onError: onError)
        
        }

    }
    
    internal func synch(collectionURL:URLStringConvertible , method:String , options:HttpOptions? = nil, onSuccess: (FetchResult<GenericModel>)->Void , onError:(BackboneError)->Void ){
        
        let json =  getJSONFromCache(collectionURL.URLString)
      
        guard json == nil else {
            self.parse(json!)
            let result = FetchResult(modelArray: self.models, fromCache: true)
            onSuccess(result)
            return
        }

        Alamofire.request(Alamofire.Method(rawValue: method)!, collectionURL , parameters:nil )
            .validate()
            .responseJSON { response in
                
               
                
                switch response.result {
                case .Success:
                    if let jsonValue = response.result.value {
                        
                        self.parse(jsonValue)
                        self.addResponseToCache(jsonValue, cacheID: collectionURL.URLString)
                        
                        if let httpResponse = response.response {
                         //   debugPrint(httpResponse)
                            let result = FetchResult(modelArray: self.models , httpResponse:httpResponse)
                            onSuccess(result)
                        }else{
                            let result = FetchResult(modelArray: self.models )
                            onSuccess(result)
                        }
                        
                      
                        
                    }
                case .Failure(let error):
                    print(error)
                    onError(.HttpError(description: error.description))
                }
        }

    
    }
    
    
   internal func processResponse(response: Response<AnyObject,NSError> , onSuccess: (FetchResult<GenericModel>)->Void , onError:(BackboneError)->Void ){
    
     //debugPrint(response.response) // URL response
        
        if let d = self.delegate {
            
            switch response.result {
            case .Success:
            dispatch_async(d.concurrentOperationQueue(), { () -> Void in
                if let jsonValue = response.result.value {
                    
                    self.parse(jsonValue)
            
                }

                dispatch_async(dispatch_get_main_queue() , { () -> Void in
                    
                    let result = FetchResult(modelArray: self.models )
                    onSuccess(result)
                    
                })
                
            })
            case .Failure(let error):
                print(error)
                onError(.HttpError(description: error.description))
            }
            
        } else {
            
            switch response.result {
            case .Success:
                if let jsonValue = response.result.value {
                    
                    self.parse(jsonValue)
                    let result = FetchResult(modelArray: self.models )
                    onSuccess(result)
                }
            case .Failure(let error):
                print(error)
                onError(.HttpError(description: error.description))
            }
            
        }
    }
   
    /**
     Promisify Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
   public func fetch(options:HttpOptions?=nil) -> Promise <FetchResult<GenericModel> >  {
        
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
    
    public func parse(response: AnyObject) {
        
        let json = JSON(response)
        
        if let array =  json.arrayObject {
            //    print("The collection response contained and Array: \(array)")
            populateModelsArray(array)
            
        } else if let dic = json.dictionaryObject {
            
            //  print("The collection response contained and Dictionary. Backbone will parse the firs JsonDitionary")
            for (_, value ) in dic {
                if let validArray = value as? [JSONUtils.JSONDictionary]{
                    populateModelsArray(validArray);
                    break
                }
            }
        }
    }
    
    
    
    internal func populateModelsArray( unParsedArray:[AnyObject]) {

        unParsedArray.forEach({ (item) -> () in
            
            let t = GenericModel.init()
            
            if let validItem = item as? JSONUtils.JSONDictionary{
                t.parse(validItem)
                
            }
            self.push(t)
        })
    }

    /**
    Add a model at the end of a collection. Takes the same options as add.
    */
    public  func push(item: GenericModel) {
        models.append(item)
    }
    
    
    /**
     Remove and return the last model from a collection. TODO: [Takes the same options as remove.]
     */
    public  func pop() -> GenericModel? {
        if (models.count > 0) {
            return models.removeLast()
        } else {
            return nil
        }
    }

    // MARK: Collections Cache
    
    private func addResponseToCache(json :AnyObject, cacheID:String) {
        
        if let d = delegate {
            d.requestCache().setObject(json, forKey: cacheID)
        }
    }
    
    
    private func getJSONFromCache(cacheID:String) -> AnyObject? {
    
        if let d = delegate {
            let json = d.requestCache().objectForKey(cacheID)
            if let j = json {
          
                return j
            }
        }
        return nil
    }
}

