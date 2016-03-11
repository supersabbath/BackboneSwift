//
//  BackboneSwiftTests.swift
//  BackboneSwiftTests
//
//  Created by Fernando Canon on 20/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

import XCTest
import SwiftyJSON

@testable import BackboneSwift

public class testClass : Model {
    public var dd:String?
    public var juancarlos:String?
    
}

class BackboneSwiftTests: XCTestCase {
    
    let model = testClass();
    
    
    override func setUp() {
        super.setUp()
        model.url = "www.google.com"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParse() {
        
        model.parse(["dd":"hola", "juancarlos":"dadfasdf"])

      
        XCTAssertEqual(model.dd, "hola")
        XCTAssertEqual(model.juancarlos, "dadfasdf")
        
    }
    
    func testPerformanceParse() {
      
        self.measureBlock { [unowned self] in
            
            self.model.parse(["dd":"hola", "juancarlos":"nothing","hoasd":"adfasdf","h2":"adfasdf"])
        }
    }

    func testModelFecth()
    {
        let asyncExpectation = expectationWithDescription("modelFetchAsynchTest")
        
        class VideoSUT : Model {
            public var uri:String?
            public var language:String?
            
            override func parse(response: JSONUtils.JSONDictionary) {
                
                let json = JSON(response)
                if let videdDic = json["page"]["items"].arrayObject?.first {
                   
                    if let JSOnItem = videdDic as? JSONUtils.JSONDictionary{
                    
                        super.parse(JSOnItem)
                    }
                }
            }
        }
        
        let sut = VideoSUT();
        
        sut.url  = "http://www.rtve.es/api/videos.json?size=1"
        
        sut.fetch(HttpOptions()).then {  x -> Void in
            
            XCTAssertTrue(sut.uri!.hasPrefix("http://www.rtve.es/api/videos"),"should have the same prefix"  )
            asyncExpectation.fulfill()
        }.error { (error) -> Void in
                 XCTFail()
        }
        
        self.waitForExpectationsWithTimeout(10, handler:{ (error) in
            
            print("time out")
        });
    
        
    }
    
    func testSynchReturnsErrorWithJSONIfResponseReturnsJSON() {
        
        //url that returns error and JSON
        let url = "http://link.theplatform.eu/s"
        model.url = url
        let asyncExpectation = expectationWithDescription("modelFetchAsynchTest")
        model.synch(model.url!, method: "GET", onSuccess: { (result) -> Void in
            XCTFail()
        }) { (error) -> Void in
            switch error {
                case .ErrorWithJSON(let parameters):
                    XCTAssertTrue(parameters.count > 0)
                    asyncExpectation.fulfill()
                    break
                default:
                    XCTFail()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler:{ (error) in
            
            print("time out")
        });

    }
    
    func testSynchReturnsHTTPErrorIfResponseNotReturningJSON() {
        let url = "http://www.google.e"
        model.url = url
        let asyncExpectation = expectationWithDescription("modelFetchAsynchTest")
        model.synch(model.url!, method: "GET", onSuccess: { (result) -> Void in
            XCTFail()
            }) { (error) -> Void in
                switch error {
                case .HttpError:
                    XCTAssertNotNil(error)
                    asyncExpectation.fulfill()
                    break
                default:
                    XCTFail()
                }
        }
        self.waitForExpectationsWithTimeout(10, handler:{ (error) in
            
            print("time out")
        });

    }
}
