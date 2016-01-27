//
//  CollectionTest.swift
//  BackboneSwift
//
//  Created by Fernando Canon on 21/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

import XCTest

import PromiseKit

class CollectionTest: XCTestCase {
    
    
    var collection = Collection<Model>()
    
    override func setUp() {
        super.setUp()
        let m = Model()
 
        collection.push(m)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPush(){
        XCTAssertTrue(collection.models.count == 1, "should  have one and has: \(collection.models.count)")
    }
    
    func testPop() {
        collection.pop()
        collection.pop()
        XCTAssertTrue(collection.models.count == 0, "should  have one and has: \(collection.models.count)")
    }
    
   
    func testFecth() {
        
            //NSBundle *testTargetBundle = [NSBundle bundleWithIdentifier:@"com.parsifal.Starz-Test"];
      let bundle = NSBundle(identifier: "com.alphabit.BackboneSwiftTests")
      
      let jsonPath = bundle?.pathForResource("videos", ofType: "json")
      
        let data = NSData(contentsOfFile: jsonPath!)
      
        let anyObject = JSONUtils().JSONFromBytes(data!)
        
        class Video : Model {
            
         public var contentType : String?
         public var uri : String?
        }
        
        let sutCollection = Collection<Video>()
        
        sutCollection.parse(anyObject!)
        
        XCTAssertEqual(sutCollection.models.count , 1)
        
        XCTAssertEqual(sutCollection.pop()?.contentType , "video")
        
    }
    
    
    func testGithubAPI_Promisefy (){
        
        
        let asyncExpectation = expectationWithDescription("longRunningFunction")
        
        
        class Project : Model {
            
            public  var full_name:String?
            public  var name:String?
            
        }
        
        let sutCollection = Collection <Project>()
        
        sutCollection.url = "https://api.github.com/users/google/repos?page=1&per_page=7"
    
        
        
        sutCollection.fetch(Options()).then {
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
    
        
        let asyncExpectation = expectationWithDescription("longRunningFunction")
        

         class Project : Model {
            
           public  var full_name:String?
           public  var name:String?
            
        }
        
        let sutCollection = Collection <Project>()
        
        sutCollection.url = "https://api.github.com/users/google/repos?page=1&per_page=7"
        
        sutCollection.fetch(Options(), onSuccess: { (objs) -> Void in
          
            XCTAssertTrue((sutCollection.pop()?.full_name!.containsString("google")) == true)
            
            XCTAssertTrue(sutCollection.models.count !=  7, "should have the same number")
            
            //asyncExpectation.fulfill()
            
            }, onError:{ (error) -> Void in
                
       
                XCTFail()
        })
        
        
        sutCollection.fetch(Options()).then {
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
