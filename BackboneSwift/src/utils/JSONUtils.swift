//
//  JSONUtils.swift
//  Starz
//
//  Created by Fernando Canon on 16/11/15.
//  Copyright © 2015 Starzplay. All rights reserved.
//

import Foundation

public struct JSONUtils {
    
    public func JSONFromBytes(bytes: NSData ) -> AnyObject?
    {
        let options = NSJSONReadingOptions(rawValue: 0)
        
        do {
            let data =  try NSJSONSerialization.JSONObjectWithData(bytes, options: options)
            return data
            
        }catch {
            print("error JSONStringify")
            
        }
        return nil
        
    }

    
    
    
    func JSONStringifyCommand( messageDictionary : Dictionary <String, AnyObject>) -> String?
    {
        let options = NSJSONWritingOptions(rawValue: 0)
        
        if NSJSONSerialization.isValidJSONObject(messageDictionary) {
            
            do {
                let data =  try NSJSONSerialization.dataWithJSONObject(messageDictionary, options: options)
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
                
            }catch {
                print("error JSONStringify")
                
            }
        }
        return nil
    }
    
    
    func JSONSerialize( jsonSerializableObject : AnyObject ) -> NSData?
    {
        let options = NSJSONWritingOptions(rawValue: 0)
        
        if NSJSONSerialization.isValidJSONObject(jsonSerializableObject) {
            
            do {
                let data =  try NSJSONSerialization.dataWithJSONObject(jsonSerializableObject, options: options)
                return data
                
            }catch {
                print("error JSONStringify")
                
            }
        }
        return nil
        
        
    }
    
    

    
    public typealias JSON = AnyObject
    public typealias JSONDictionary = [String:JSONUtils.JSON]
    public typealias JSONArray = Array<JSONUtils.JSON>
    
    
    func JSONString(object: JSONUtils.JSON?) -> String? {
        return object as? String
    }
    
    func JSONInt(object: JSONUtils.JSON?) -> Int? {
        return object as? Int
    }
    
    func JSONObject(object: JSONUtils.JSON?) -> JSONDictionary? {
        return object as? JSONDictionary
    }
    
    
}