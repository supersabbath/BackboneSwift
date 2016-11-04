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
    public var query:String?
    public var body:[String:AnyObject]?
    public var relativePath:String?
    
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
    
    public subscript(queryValues:String) -> String {
        get {
            return query ?? ""
        }
        set {
            query = queryValues
        }
    }
    
    
    
   public func stringifyBody()->String? {
       
        guard let requestBody = body else { return nil}
        
       let stringify = JSONUtils().JSONStringifyCommand(requestBody);
        
        return stringify
    }
    
    
}


public enum BackboneError: Error {
    case invalidURL
    case httpError(description:String)
    case errorWithJSON(parameters:JSONUtils.JSONDictionary)
    case parsingError
    case invalidHTTPMethod
    case failedPOST
}

public protocol  ResponseAsociatedData  {

    var response: HTTPURLResponse? { get set }
    var isCacheResult:Bool { get set }
}

public struct ResponseMetadata  : ResponseAsociatedData{
    
    public var response: HTTPURLResponse?
    public var isCacheResult = false
    
    init(fromCache:Bool){
 
        isCacheResult = fromCache
    }
    
    init(httpResponse:HTTPURLResponse, fromCache:Bool){
    
        response = httpResponse
        isCacheResult = fromCache
    }
}


public enum RESTMethod {
    case  get,post,put,delete
}




open class Collection <GenericModel: BackboneModel>  :NSObject{
    
    open var models = [GenericModel]()
    public typealias CollectionResponse = (models:[GenericModel], response:ResponseMetadata)
    var url:String?
    open var delegate:BackboneDelegate?
    
    public init( withUrl:String) {
        url = withUrl
    }

   
    // MARK: - PUBLIC BACKBONE METHODS 🅿️
    
    /**
    Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
    */
    open func fetch(_ options:HttpOptions?=nil, onSuccess: (CollectionResponse)->Void , onError:(BackboneError)->Void){
        
        guard let feedURL = url  else {
            debugPrint("Collections must have an URL, fetch cancelled")
            onError(.invalidURL)
            return 
        }
       
        if let query = options?.query{
            
            var urlComponents = URLComponents(string: feedURL)
            debugPrint(urlComponents?.URLString)
            urlComponents?.query = query
            
            synch(urlComponents!, method: "GET", options: options,onSuccess: onSuccess, onError: onError)
        
        }else{
            
            synch(feedURL, method: "GET", options: options,onSuccess: onSuccess, onError: onError)
        }

    }
    
    // TODO create() POST
    
    internal func synch(_ collectionURL:URLStringConvertible , method:String , options:HttpOptions? = nil, onSuccess: @escaping (CollectionResponse)->Void , onError:@escaping (BackboneError)->Void ){
        
        let json =  getJSONFromCache(collectionURL.URLString)
      
        guard json == nil else {
            self.parse(json!)
            let response = ResponseMetadata(fromCache: true)
            let result = (self.models,response)
            onSuccess(result)
            return
        }

        Alamofire.request(Alamofire.Method(rawValue: method)!, collectionURL , headers:options?.headers )
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .success:
                    if let jsonValue = response.result.value {
                        
                        self.parse(jsonValue)
                        self.addResponseToCache(jsonValue, cacheID: collectionURL.URLString)
                        
                        if let httpResponse = response.response {
                   
                            let result = ResponseMetadata(httpResponse:httpResponse,fromCache: false)
                            onSuccess((self.models , result))
                            return
                        }
                    }
                    onError(.httpError(description:"Unable to create Collection models"))
                    
                case .failure(let error):
                    print(error)
                    onError(.httpError(description: error.description))
                }
        }

    
    }
    
    
   internal func processResponse(_ response: Response<AnyObject,NSError> , onSuccess: @escaping (CollectionResponse)->Void , onError:(BackboneError)->Void ){
    
     //debugPrint(response.response) // URL response

        if let d = self.delegate {
            
            switch response.result {
            case .success:
            d.concurrentOperationQueue().async(execute: { () -> Void in
                if let jsonValue = response.result.value {
                    
                    self.parse(jsonValue)
            
                }

                DispatchQueue.main.async(execute: { () -> Void in
                    
                    let result = (models: self.models,ResponseMetadata(fromCache: false ))
                    onSuccess(result)
                    
                })
                
            })
            case .failure(let error):
                debugPrint(error)
                onError(.httpError(description: error.description))
            }
            
        } else {
            
            switch response.result {
            case .success:
                if let jsonValue = response.result.value {
                    
                    self.parse(jsonValue)
                    let result = (models: self.models,ResponseMetadata(fromCache: false ))
                    onSuccess(result)
                }
            case .failure(let error):
                print(error)
                onError(.httpError(description: error.description))
            }
            
        }
    }
   
    /**
     Promisify Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
   open func fetch(_ options:HttpOptions?=nil) -> Promise < CollectionResponse >  {
        
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
    
    open func parse(_ response: AnyObject) {
        
        let json = JSON(response)
        
        if let array =  json.arrayObject {
            //    print("The collection response contained and Array: \(array)")
            populateModelsArray(array as [AnyObject])
            
        } else if let dic = json.dictionaryObject {
            
            //  print("The collection response contained and Dictionary. Backbone will parse the firs JsonDitionary")
            for (_, value ) in dic {
                if let validArray = value as? [JSONUtils.JSONDictionary]{
                    populateModelsArray(validArray as [AnyObject]);
                    break
                }
            }
        }
    }
    
    
    
    internal func populateModelsArray( _ unParsedArray:[AnyObject]) {

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
    open  func push(_ item: GenericModel) {
        models.append(item)
    }
    
    
    /**
     Remove and return the last model from a collection. TODO: [Takes the same options as remove.]
     */
    open  func pop() -> GenericModel? {
        if (models.count > 0) {
            return models.removeLast()
        } else {
            return nil
        }
    }

    // MARK: Collections Cache
    
    fileprivate func addResponseToCache(_ json :AnyObject, cacheID:String) {
        
        if let d = delegate {
            d.requestCache().setObject(json, forKey: cacheID)
        }
    }
    
    
    fileprivate func getJSONFromCache(_ cacheID:String) -> AnyObject? {
    
        if let d = delegate {
            let json = d.requestCache().object(forKey: cacheID)
            if let j = json {
          
                return j
            }
        }
        return nil
    }
}




