//
//  BackboneSwiftTests.swift
//  BackboneSwiftTests
//
//  Created by Fernando Canon on 20/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

import XCTest
import SwiftyJSON
import PromiseKit

@testable import BackboneSwift

public class TestClass : Model {
    public var dd:String?
    public var juancarlos:String?
    
}



class BackboneSwiftTests: XCTestCase {
    
    let model = TestClass();
    
    
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
        let asyncExpectation = expectationWithDescription("testSynchReturnsErrorWithJSONIfResponseReturnsJSON")
      
        
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
        let url = "http://www.google.es"
        model.url = url
        let asyncExpectation = expectationWithDescription("testSynchReturnsHTTPErrorIfResponseNotReturningJSON")
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
    
    func testSyncShouldReturnHTTPErrorFor3xx () {
    
        let url = "http://httpstat.us/304"
        model.url = url
        let asyncExpectation = expectationWithDescription("testSyncShouldReturnHTTPErrorFor3xx")
        model.synch(model.url!, method: "GET", onSuccess: { (result) -> Void in
            XCTFail()
            }) { (error) -> Void in
                switch error {
                case .HttpError(let description):
                    XCTAssertNotNil(error)
                    XCTAssertEqual( description, "304")
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
    
    
    
    func testSyncShouldReturnHTTPErrorFor5xx () {
        
    
        let url = "http://httpstat.us/500"
        model.url = url
        let asyncExpectation = expectationWithDescription("testSyncShouldReturnHTTPErrorFor5xx")
        model.synch(model.url!, method: "GET", onSuccess: { (result) -> Void in
            XCTFail()
            }) { (error) -> Void in
                switch error {
                case .HttpError(let description):
                    XCTAssertNotNil(error)
                    XCTAssertEqual( description, "500")
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

    
    // MARK:  Delete
    
    /**
     Test naming convention for StarzPlay
     */
    func  testDeleteShouldSuccess() {
    
        let asyncExpectation = expectationWithDescription("testDeleteShouldSuccess")
        
        //given
        let sut = TestClass()
        sut.url = "http://httpbin.org/delete"
        //when
        sut.delete().then { (result) -> Void in
            //then
            XCTAssertTrue(result.response?.statusCode == 200);
            
            asyncExpectation.fulfill()
            
            }.error{ error  in
                
                XCTFail()
                asyncExpectation.fulfill()
        }
 
        self.waitForExpectationsWithTimeout(100, handler:{ (error) in
            print("test time out")
        });
    }

}
