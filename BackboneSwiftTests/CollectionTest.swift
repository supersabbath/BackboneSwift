//
//  CollectionTest.swift
//  BackboneSwift
//
//  Created by Fernando Canon on 21/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

import XCTest

import PromiseKit

/**
    SUT Classes
 */
public class Project : Model {
    
    var full_name:String?
    var name:String?
    
}

public class Video : Model {
    
    var contentType : String?
    var uri : String?
}

// End of  Classes

class CollectionTest: XCTestCase {
    
    
    var collection:Collection<Model>?
    
    override func setUp() {
        super.setUp()
        let m = Model()
        collection = Collection<Model>(withUrl: "")
        collection!.push(m)
    }
    
    override func tearDown() {
        collection = nil
        super.tearDown()
    }
    
    func testPush(){
        XCTAssertTrue(collection!.models.count == 1, "should  have one and has: \(collection!.models.count)")
    }
    
    func testPop() {
        collection?.pop()
        collection?.pop()
        XCTAssertTrue(collection!.models.count == 0, "should  have one and has: \(collection?.models.count)")
    }
    
   
    func testFecth() {
        
        let bundle = NSBundle(identifier: "com.alphabit.BackboneSwiftTests")
      
        let jsonPath = bundle?.pathForResource("videos", ofType: "json")
      
        let data = NSData(contentsOfFile: jsonPath!)
      
        let anyObject = JSONUtils().JSONFromBytes(data!)
        
        let sutCollection = Collection<Video>(withUrl: "")
        
        sutCollection.parse(anyObject!)
        
        XCTAssertEqual(sutCollection.models.count , 1)
        
        XCTAssertEqual(sutCollection.pop()?.contentType , "video")
        
    }
   

    
    func testGithubAPI_Promisefy (){
        
        
        let asyncExpectation = expectationWithDescription("testGithubAPI_Promisefy")
       
        let sutCollection = Collection <Project>(withUrl: "")
        
        sutCollection.url = "https://api.github.com/users/google/repos?page=1&per_page=7"
    
        
        
        sutCollection.fetch(HttpOptions()).then {
            x -> Void in
            XCTAssertTrue((sutCollection.pop()?.full_name!.containsString("google")) == true)
            
            XCTAssertTrue(sutCollection.models.count !=  7, "should have the same number")
            
            asyncExpectation.fulfill()
        }
        
        
        self.waitForExpectationsWithTimeout(10, handler:{ (error) in
            
            print("time out")
        });
    }

    
    func testGithubAPI (){
    
        
        let asyncExpectation = expectationWithDescription("testGithubAPI")
        
        let sutCollection = Collection <Project>(withUrl: "")
        
        sutCollection.url = "https://api.github.com/users/google/repos?page=1&per_page=7"
        
        sutCollection.fetch(HttpOptions(), onSuccess: { (objs) -> Void in
          
            XCTAssertTrue((sutCollection.pop()?.full_name!.containsString("google")) == true)
            
            XCTAssertTrue(sutCollection.models.count !=  7, "should have the same number")
            
            //asyncExpectation.fulfill()
            
            }, onError:{ (error) -> Void in
                
       
                XCTFail()
        })
        
        
        sutCollection.fetch(HttpOptions()).then {
            x -> Void in
            XCTAssertTrue((sutCollection.pop()?.full_name!.containsString("google")) == true)
            
            XCTAssertTrue(sutCollection.models.count !=  7, "should have the same number")
            
            asyncExpectation.fulfill()
        }
        
        
        self.waitForExpectationsWithTimeout(10, handler:{ (error) in
            
            print("time out")
        });
    }
}
