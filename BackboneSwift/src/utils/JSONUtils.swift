//
//  JSONUtils.swift
//  Starz
//
//  Created by Fernando Canon on 16/11/15.
//  Copyright © 2015 Starzplay. All rights reserved.
//

import Foundation

public struct JSONUtils {
    
    public func JSONFromBytes(_ bytes: Data ) -> AnyObject?
    {
        let options = JSONSerialization.ReadingOptions(rawValue: 0)
        
        do {
            let data =  try JSONSerialization.jsonObject(with: bytes, options: options)
            return data as AnyObject?
            
        }catch {
            print("error JSONStringify")
            
        }
        return nil
        
    }

    
    
    
   public func JSONStringifyCommand( _ messageDictionary : Dictionary <String, AnyObject>) -> String?
    {
        let options = JSONSerialization.WritingOptions(rawValue: 0)
        
        if JSONSerialization.isValidJSONObject(messageDictionary) {
            
            do {
                let data =  try JSONSerialization.data(withJSONObject: messageDictionary, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
                
            }catch {
                print("error JSONStringify")
                
            }
        }
        return nil
    }
    
    
    func JSONSerialize( _ jsonSerializableObject : AnyObject ) -> Data?
    {
        let options = JSONSerialization.WritingOptions(rawValue: 0)
        
        if JSONSerialization.isValidJSONObject(jsonSerializableObject) {
            
            do {
                let data =  try JSONSerialization.data(withJSONObject: jsonSerializableObject, options: options)
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
    
    
    func JSONString(_ object: JSONUtils.JSON?) -> String? {
        return object as? String
    }
    
    func JSONInt(_ object: JSONUtils.JSON?) -> Int? {
        return object as? Int
    }
    
    func JSONObject(_ object: JSONUtils.JSON?) -> JSONDictionary? {
        return object as? JSONDictionary
    }
    
    
}
