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
sync
fetch
save
– destroy
– Underscore Methods (9)
validate
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

enum SerializationError: ErrorType {
    // We only support structs
    case StructRequired
    // The entity does not exist in the Core Data Model
    case UnknownEntity(name: String)
    // The provided type cannot be stored in core data
    case UnsupportedSubType(label: String?)
}



public protocol BackboneConcurrencyDelegate {
    
    func concurrentOperationQueue() -> dispatch_queue_t
}


public protocol BackboneCacheDelegate {
    
    func requestCache() -> NSCache
}

public typealias BackboneDelegate = protocol<BackboneCacheDelegate, BackboneConcurrencyDelegate>

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
    func validate(attributes:[String]?) -> Bool
    
    init()
    
}

public class Model: NSObject , BackboneModel {
    
    public var url:String?
    
    required override public init() {
        
    }
    
    /**
     Use subscripts for ascessing only String values
     */
    subscript(propertyName: String) -> AnyObject?{
        
        get {
            
            if self.respondsToSelector("propertyName"){
                
                return valueForKey(propertyName)
            }else{
                return nil
            }
            
        }
        set(newValue) {
            
            setValue(newValue, forKey: propertyName)
        }
        
    }
    // Mark: 100% Backbone funcs
    /**
    parse is called whenever a model's data is returned by the server, in fetch, and save. The function is passed the raw response object, and should return the attributes hash to be set on the model. The default implementation is a no-op, simply passing through the JSON response. Override this if you need to work with a preexisting API, or better namespace your responses.
    */
    public func parse(response: JSONUtils.JSONDictionary) {
        
        let mirror = Mirror(reflecting: self)
        reflexion(response, mirror: mirror)
        reflectSuperChildren(response, superMirror: mirror.superclassMirror())
        
    }
    
    
    internal func reflectSuperChildren(response: JSONUtils.JSONDictionary , superMirror:Mirror?)
    {
        if let m = superMirror {
            reflexion(response, mirror: m)
            reflectSuperChildren(response, superMirror: m.superclassMirror())
            //print("R")
        }
    }
    
    
    internal func reflexion(response: JSONUtils.JSONDictionary , mirror:Mirror) {
        
        for case let (label?, _) in mirror.children {
            
            if let _ = response[label] as? String {
                
                self.assignToClassVariable(label, payload: response)
                
            }else if let numericValue = response[label] as? Int {
                
                self[label] = "\(numericValue)"
                
            } else if let _ = response[label] as? [JSONUtils.JSONDictionary] {
                
                self[label] = response[label]
                
            } else if let _ = response[label] as? [String:String] {
                self[label] = response[label]
            }
            
        }
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
            
            //print("--->>> \(varName)"
            self[varName] = value
            
        }
    }
    
    private func unWrapString(object: AnyObject) -> String {
        return (object as? String) ?? ""
    }
    
    
    /**
     Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
    func fetch(options:HttpOptions? , onSuccess: (FetchResult<Model>) ->Void , onError:(BackboneError)->Void){
        
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
    
    
    
    /**
     Promisify Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
    
    public func fetch(options:HttpOptions?=nil) -> Promise <FetchResult<Model>>  {
        
        return Promise { fulfill, reject in
            
            fetch(options, onSuccess: { (result) -> Void in
                
                fulfill(result)
                
                }, onError: { (error) -> Void in
                    
                    reject(error)
            })
        }
    }
    
    
    internal func synch(modelURL:URLStringConvertible , method:String , options:HttpOptions? = nil, onSuccess: (FetchResult<Model>)->Void , onError:(BackboneError)->Void ){
        
        guard let m = Alamofire.Method(rawValue: method ) else { onError(BackboneError.InvalidHTTPMethod); return }
        
        
        Alamofire.request(m, modelURL ,parameters:options?.body,  encoding: .JSON,headers:options?.headers)
            .validate(statusCode:200..<500).responseJSON { [weak self] response in
                
                switch response.result {
                case .Success:
                    print("Save response \(response)")
                    if let jsonValue = response.result.value {
                        
                        if let dic = jsonValue as? JSONUtils.JSONDictionary {
                            
                            if let ws = self {
                                let statusCode = (response.response?.statusCode)!
                                switch statusCode {
                                case 200..<299:
                                    ws.parse(dic)
                                    
                                    if let httpResponse = response.response {
                                        
                                        let result = FetchResult(modelArray: [ws] , httpResponse:httpResponse)
                                        onSuccess(result)
                                        return
                                    }else{
                                        let result = FetchResult(modelArray:[ws] )
                                        onSuccess(result)
                                        return
                                    }
                                    
                                case 400..<499:
                                    onError(.ErrorWithJSON(parameters:dic))
                                    return
                                default:
                                    break
                                }
                                
                                
                            }
                        }
                        onError(.HttpError(description: "Failed procesing model request"))
                        return
                    }
                    onError(.ParsingError)
                    
                case .Failure(let error):
                    print("\(error)")
                   // onError(.HttpError(description: error.description))
                }
            }.response { [weak self] request, response, data, error in
                
                
                if let _ = self {
                    let statusCode = (response?.statusCode)!
     
                  
                    onError(.HttpError(description: "\(statusCode)"))
                    
                    
                }
                
                
        }
    }
    /**
     This method is left undefined and you're encouraged to override it with any custom validation logic you have that can be performed in Swift. By default save checks validate before setting any attributes but you may also tell set to validate the new attributes by passing {validate: true} as an option.
     The validate method receives the model attributes as well as any options passed to set or save. If the attributes are valid, don't return anything from validate; if they are invalid return an error of your choosing. It can be as simple as a string error message to be displayed, or a complete error object that describes the error programmatically. If validate returns an error, save will not continue, and the model attributes will not be modified on the server. Failed validations trigger an "invalid" event, and set the validationError property on the model with the value returned by this method.
     */
    public func validate(attributes:[String]?) -> Bool{
        // TODO:  improve this. We will have to add atttributes array .
        return true
    }
    
    
    
    
}

// MARK:  POST
extension Model {
    
    /**
     
     Save a model to your database (or alternative persistence layer), by delegating to Backbone.sync. If the model has a validate method, and validation fails, the model will not be saved. If the model isNew, the save will be a "create" (HTTP POST),
     //TODO: if the model already exists on the server, the save will be an "update" (HTTP PUT).
     
     */
    
    public func save(options:HttpOptions? , onSuccess: (FetchResult<Model>) ->Void , onError:(BackboneError)->Void){
        // TODO:  improve this. We will have to add the attributes array
        // TODO : check if the attribute is new to do an put or a create
        guard validate(nil) else { onError(.FailedPOST); return}
        
        guard let feedURL = url  else {
            print("Models must have an URL, fetch cancelled")
            onError(.InvalidURL)
            return
        }
        print("Save") // URL response
        synch(feedURL, method: "POST", options: options,onSuccess: onSuccess, onError: onError)
        
    }
    /**
     Promisefy version of Save
     @see save()
     
     */
    
    public func save(options:HttpOptions?=nil) -> Promise <FetchResult<Model>>  {
        
        return Promise { fulfill, reject in
            
            save(options, onSuccess: { (result) -> Void in
                
                fulfill(result)
                
                }, onError: { (error) -> Void in
                    reject (error )
            })
            
        }
        
    }
    
    
    
}



