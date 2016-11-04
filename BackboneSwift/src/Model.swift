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
destroy
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

enum SerializationError: Error {
    // We only support structs
    case structRequired
    // The entity does not exist in the Core Data Model
    case unknownEntity(name: String)
    // The provided type cannot be stored in core data
    case unsupportedSubType(label: String?)
}



public protocol BackboneConcurrencyDelegate {
    func concurrentOperationQueue() -> DispatchQueue
}


public protocol BackboneCacheDelegate {
    func requestCache() -> NSCache<AnyObject, AnyObject>
}

public typealias BackboneDelegate = BackboneCacheDelegate & BackboneConcurrencyDelegate

// MARK: -
// MARK:  Protocols

protocol Deletable {
    
    func delete(_ options:HttpOptions?) -> Promise < ResponseTuple >
    func delete(_ options:HttpOptions? , onSuccess: (ResponseTuple) ->Void , onError:(BackboneError)->Void);
    
}

protocol Saveable {
    
    func save(_ options:HttpOptions?) -> Promise <ResponseTuple>
    func save(_ options:HttpOptions? , onSuccess: (ResponseTuple) ->Void , onError:(BackboneError)->Void);
    
}

protocol Fetchable {
    
    func fetch(_ options:HttpOptions? , onSuccess: (ResponseTuple) ->Void , onError:(BackboneError)->Void)
    func fetch(_ options:HttpOptions?) -> Promise <ResponseTuple>
    
}


protocol Createable {
    
    func create(_ options:HttpOptions?) -> Promise <ResponseTuple>
    func create(_ options:HttpOptions? , onSuccess: (ResponseTuple) ->Void , onError:(BackboneError)->Void);
    
}



public protocol BackboneModel
{

    /**
      - *url*  the relative URL where the model's resource would be located on the server. If your models are located somewhere else, override this method with the correct logic. Generates URLs of the form: "[collection.url]/[id]" by default, but you may override by specifying an explicit urlRoot if the model's collection shouldn't be taken into account.
    */
    var url:String?{ get set }
    // Functions
    /**
        parse() handles the plain Swift JSON object parsing.
     */
    func parse(_ response: JSONUtils.JSONDictionary)
    func toJSON() -> String
    func validate(_ attributes:[String]?) -> Bool
    
    init()
}

public typealias ResponseTuple =  (model:BackboneModel,response: HTTPURLResponse?)
// MARK: -
// MARK:  BackboneModel

open class Model: NSObject , BackboneModel {
    
    open var url:String?
    
    required override public init() {
        
    }
    
    /**
     Use subscripts for ascessing only String values
     */
    subscript(propertyName: String) -> AnyObject?{
        
        get {
            
            if self.responds(to: NSSelectorFromString("propertyName")){
                
                return value(forKey: propertyName) as AnyObject?
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
    open func parse(_ response: JSONUtils.JSONDictionary) {
        
        let mirror = Mirror(reflecting: self)
        reflexion(response, mirror: mirror)
        reflectSuperChildren(response, superMirror: mirror.superclassMirror)
        
    }
    
    
    internal func reflectSuperChildren(_ response: JSONUtils.JSONDictionary , superMirror:Mirror?)
    {
        if let m = superMirror {
            reflexion(response, mirror: m)
            reflectSuperChildren(response, superMirror: m.superclassMirror)
            //print("R")
        }
    }
    
    
    internal func reflexion(_ response: JSONUtils.JSONDictionary , mirror:Mirror) {
        
        for case let (label?, _) in mirror.children {
            
            if let _ = response[label] as? String {
                
                self.assignToClassVariable(label, payload: response)
                
            }else if let numericValue = response[label] as? Int {
                
                self[label] = "\(numericValue)" as AnyObject?
                
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
    open func toJSON() -> String
    {
        return ""
    }
    
    
    fileprivate func  assignToClassVariable (_ varName:String , payload :[String:AnyObject])
    {
        if let value = payload[varName] >>> unWrapString {
            
            //print("--->>> \(varName)"
            self[varName] = value as AnyObject?
            
        }
    }
    
    fileprivate func unWrapString(_ object: AnyObject) -> String {
        return (object as? String) ?? ""
    }
    
    
    
    internal func synch(_ modelURL:URLStringConvertible , method:String , options:HttpOptions? = nil, onSuccess: @escaping (ResponseTuple)->Void , onError:@escaping (BackboneError)->Void ){
        
        guard let m = Alamofire.Method(rawValue: method ) else { onError(BackboneError.invalidHTTPMethod); return }
        
        var isProcessed  = false
    
        Alamofire.request(m, modelURL ,parameters:options?.body,  encoding: .json,headers:options?.headers)
            .validate(statusCode:200..<500).responseJSON {  response in
                
                switch response.result {
                case .success:
                   
                    if let jsonValue = response.result.value {
                        
                        if let dic = jsonValue as? JSONUtils.JSONDictionary {
                
                            let statusCode = (response.response?.statusCode)!
                            switch statusCode {
                            case 200..<299:
                                self.parse(dic)
                                let result = (self as BackboneModel, response.response)
                                onSuccess(result)
                                isProcessed = true
                                return
                                
                                
                            case 400..<499:
                                onError(.errorWithJSON(parameters:dic))
                                isProcessed = true
                                return
                            default:
                                break
                            }
                        } else {
                            return
                        }
                    }
                    onError(.parsingError)
                    return
                case .failure(let error):

                    debugPrint("No Json \(error)")
                }
      
            }.response {   request, response, data, error in
                
                guard !isProcessed else { return }
                guard let statusCode = response?.statusCode  else {
                
                    onError(BackboneError.httpError(description: "No status code"))
                    return
                }
                switch statusCode {
                case 200..<399:
                        onSuccess((self, response))
                    
                default:
                    onError(.httpError(description: "\(statusCode)"))
                    
                }
        }
    }
    /**
     This method is left undefined and you're encouraged to override it with any custom validation logic you have that can be performed in Swift. By default save checks validate before setting any attributes but you may also tell set to validate the new attributes by passing {validate: true} as an option.
     The validate method receives the model attributes as well as any options passed to set or save. If the attributes are valid, don't return anything from validate; if they are invalid return an error of your choosing. It can be as simple as a string error message to be displayed, or a complete error object that describes the error programmatically. If validate returns an error, save will not continue, and the model attributes will not be modified on the server. Failed validations trigger an "invalid" event, and set the validationError property on the model with the value returned by this method.
     */
    open func validate(_ attributes:[String]?=nil) -> Bool{
        // TODO:  improve this. We will have to add atttributes array .
        return true
    }
    
    fileprivate func processOptions(_ baseUrl:String , inOptions:HttpOptions?, complete: (_ options:HttpOptions? , _ url: URLStringConvertible) -> Void) {
    
        
        var urlComponents = URLComponents(string:baseUrl)!
        
        if let query = inOptions?.query{
         
            urlComponents.query = query
        }
        if let path = inOptions?.relativePath  {
            
            if let componnent = urlComponents.path {
                   urlComponents.path = "\(componnent)/\(path)"
            }else {
                urlComponents.path = "/\(path)"
            }
        }
        
        complete(options: inOptions , url: urlComponents)
        
    }
    
    // MARK:
    // MARK: GET
    
    /**
     Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
    open func fetch(_ options:HttpOptions? , onSuccess: @escaping (ResponseTuple) ->Void , onError:@escaping (BackboneError)->Void){
        
        guard let feedURL = url  else {
            debugPrint("Collections must have an URL, fetch cancelled")
            onError(.invalidURL)
            return
        }
        
        
        processOptions(feedURL, inOptions: options  , complete: { (options, url) in
            
            self.synch(url, method: "GET", options: options,onSuccess: onSuccess, onError: onError)
            
        })
        
    }
    
    
    
    /**
     Promisify Fetch the default set of models for this collection from the server, setting them on the collection when they arrive. The options hash takes success and error callbacks which will both be passed (collection, response, options) as arguments. When the model data returns from the server, it uses set to (intelligently) merge the fetched models, unless you pass {reset: true}, in which case the collection will be (efficiently) reset. Delegates to Backbone.sync under the covers for custom persistence strategies and returns a jqXHR. The server handler for fetch requests should return a JSON array of models.
     */
    
    
    open func fetch(_ options:HttpOptions?=nil) -> Promise <ResponseTuple>  {
        
        return Promise(resolvers: { (fulfill, reject) in
            
            fetch(options, onSuccess: { (response) in
                
                fulfill(response)
                
                }, onError: { (error) in
                    
                    reject(error)
            })
        })
    }

    // MARK:
    // MARK:  PUT
    
    /**
     Saves a model to your database (or alternative persistence layer), by delegating to Backbone.sync. If the model has a validate method, and validation fails, the model will not be saved. If the model isNew, the save will be a "create" (HTTP PUT),
     
     Put does not affect the state of the object
     */
    
    open func save(_ options:HttpOptions? , onSuccess: @escaping (ResponseTuple) ->Void , onError:@escaping (BackboneError)->Void){
        // TODO:  improve this. We will have to add the attributes array
        // TODO : check if the attribute is new to do an put or a create
        guard validate() else { onError(.failedPOST); return}
        
        guard let feedURL = url  else {
            print("Models must have an URL, fetch cancelled")
            onError(.invalidURL)
            return
        }
        
        processOptions(feedURL, inOptions: options  , complete: { (options, url) in
            
            self.synch(url, method: "PUT", options: options,onSuccess: onSuccess, onError: onError)
            
        })
        
    }
    
    /**
     Promisefy version of Save
     - seeAlso save()
     
     */
    
    open func save(_ options:HttpOptions?=nil) -> Promise <ResponseTuple>  {
        
        return Promise(resolvers: {  fulfill, reject in
            
            save(options, onSuccess: { (result) -> Void in
                
                fulfill(result)
                
                }, onError: { (error) -> Void in
                    reject (error )
            })
            
        })
        
    }
    
    // MARK:
    // MARK: DELETE
    open func delete(_ options:HttpOptions?=nil) -> Promise <ResponseTuple> {
        
        return Promise{ (fulfill, reject ) in
            
            delete(options, onSuccess: { (result) -> Void in
                
                fulfill(result)
                
                }, onError: { (error) in
                    reject(error)
            })
        }
    }
    
    
    open func delete(_ options:HttpOptions? = nil, onSuccess: @escaping (ResponseTuple) ->Void , onError:@escaping (BackboneError)->Void) {
        
        guard let feedURL = url  else {
            print("Models must have an URL, DELETE cancelled")
            onError(.invalidURL)
            return
        }
        processOptions(feedURL, inOptions: options  , complete: { (options, url) in
            
            self.synch(url, method: "DELETE", options: options,onSuccess: onSuccess, onError: onError)
        })
    }

    // MARK:
    // MARK:  POST
    
    /**
     Saves a model to your database (or alternative persistence layer), by delegating to Backbone.sync. If the model has a validate method, and validation fails, the model will not be saved. If the model isNew, the save will be a "create" (HTTP PUT),
     
     Put does not affect the state of the object
     */
    
    open func create(_ options:HttpOptions? , onSuccess: @escaping (ResponseTuple) ->Void , onError:@escaping (BackboneError)->Void){
        // TODO:  improve this. We will have to add the attributes array
        // TODO : check if the attribute is new to do an put or a create
        guard validate() else { onError(.failedPOST); return}
        
        guard let feedURL = url  else {
            print("Models must have an URL, fetch cancelled")
            onError(.invalidURL)
            return
        }

        
        processOptions(feedURL, inOptions: options  , complete: { (options, url) in
            
            self.synch(url, method: "POST", options: options,onSuccess: onSuccess, onError: onError)
        })
        
    }
    
    /**
     Promisefy version of Save
     - seeAlso save()
     
     */
    
    open func create(_ options:HttpOptions?=nil) -> Promise <ResponseTuple>  {
        
        return Promise(resolvers: {  fulfill, reject in
            
            create(options, onSuccess: { (result) -> Void in
                
                fulfill(result)
                
                }, onError: { (error) -> Void in
                    reject (error )
            })
            
        })
        
    }
    
}





