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
/**
   SUTs:  TestClass and VideoSUT
 */
open class TestClass : Model {
    open var dd:String?
    open var juancarlos:String?
    
    
}


open class VideoSUT : Model {
   
    var uri:String?
    var language:String?
    
    override open func parse(_ response: JSONUtils.JSONDictionary) {
        
        let json = JSON(response)
        if let videdDic = json["page"]["items"].arrayObject?.first {
            
            if let JSOnItem = videdDic as? JSONUtils.JSONDictionary{
                
                super.parse(JSOnItem)
            }
        }
    }
}


class BackboneSwiftTests: XCTestCase {
    
   
    var model:TestClass?
    
    override func setUp() {
        super.setUp()
         model = TestClass();
         model?.url = "www.google.com"
    }
    
    override func tearDown() {
        model = nil
        super.tearDown()
    }
    
    func testParse() {
        
        model?.parse(["dd":"hola", "juancarlos":"dadfasdf"])

      
        XCTAssertEqual(model?.dd, "hola")
        XCTAssertEqual(model?.juancarlos, "dadfasdf")
        
    }
    
    func testPerformanceParse() {
      
        self.measure { [unowned self] in
            
            self.model?.parse(["dd":"hola", "juancarlos":"nothing","hoasd":"adfasdf","h2":"adfasdf"])
        }
    }

    func testModelFecth()
    {
        let asyncExpectation = expectation(description: "modelFetchAsynchTest")
        
        let sut = VideoSUT();
        
        sut.url  = "http://www.rtve.es/api/videos.json?size=1"
        
        sut.fetch(HttpOptions()).then {  x -> Void in
            
            XCTAssertTrue(sut.uri!.hasPrefix("http://www.rtve.es/api/videos"),"should have the same prefix"  )
            asyncExpectation.fulfill()
        }.error { (error) -> Void in
                 XCTFail()
        }
        
        self.waitForExpectations(timeout: 10, handler:{ (error) in
            
            print("time out")
        });
    
        
    }
    
    func testSynchReturnsErrorWithJSONIfResponseReturnsJSON() {
        
        //url that returns error and JSON
        let url = "http://link.theplatform.eu/s"
        model?.url = url
        let asyncExpectation = expectation(description: "withJSONIfResponseReturnsJSON")
      
        
        model?.synch(model!.url!, method: "GET", onSuccess: { (result) -> Void in
            XCTFail()
        }) { (error) -> Void in
            switch error {
                case .errorWithJSON(let parameters):
                    XCTAssertTrue(parameters.count > 0)
                    asyncExpectation.fulfill()
                    print("*********************************")
                    break
                default:
                    XCTFail()
                break
            }
        }
        self.waitForExpectations(timeout: 10, handler:{ (error) in
            
            print("time out")
        });

    }
    
    func testSynchReturnsOKIfResponseNotReturningJSONAndStatusBetween200And399() {
        let url = "http://www.google.es" // Expected status 200
    
        model?.url = url
        let asyncExpectation = expectation(description: "ResponseNotReturningJSON")
        model?.synch(model!.url!, method: "GET", onSuccess: { (result) -> Void in
            asyncExpectation.fulfill()
            }) { (error) -> Void in
                switch error {
                case .parsingError:
                    XCTAssertNotNil(error)
                    asyncExpectation.fulfill()
                    break
                default:
                    XCTFail()
            }
        }
        self.waitForExpectations(timeout: 10, handler:{ (error) in
            
            print("time out")
        });
    }
    
    func testSynchReturnsHTTPErrorIfResponseNotReturningJSONAndStatusMoreThan400() {
        let url = "http://httpstat.us/404" // Expected status 200
        
        model?.url = url
        let asyncExpectation = expectation(description: "ResponseNotReturningJSON")
        model?.synch(model!.url!, method: "GET", onSuccess: { (result) -> Void in
            XCTFail()
        }) { (error) -> Void in
            XCTAssertNotNil(error)
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler:{ (error) in
            
            print("time out")
        });
    }
    
    func testSyncShouldReturnHTTPErrorFor3xx () {
    
        let url = "http://httpstat.us/304"
        model?.url = url
        let asyncExpectation = expectation(description: "testSyncShouldReturnHTTPErrorFor3xx")
        
        model?.synch(model!.url!, method: "GET", onSuccess: { (result) -> Void in
        
                XCTAssertNotNil(result.model)
                XCTAssertEqual( result.response!.statusCode , 304)
                asyncExpectation.fulfill()


            }) { (error) -> Void in
                   XCTFail()
        }
        self.waitForExpectations(timeout: 10, handler:{ (error) in
            
            print("time out")
        });

        
    }
    
    
    
    func testSyncShouldReturnHTTPErrorFor5xx () {
        
    
        let url = "http://httpstat.us/500"
        model?.url = url
        let asyncExpectation = expectation(description: "testSyncShouldReturnHTTPErrorFor5xx")
        model?.synch(model!.url!, method: "GET", onSuccess: { (result) -> Void in
            XCTFail()
            }) { (error) -> Void in
                switch error {
                case .httpError(let description):
                    XCTAssertNotNil(error)
                    XCTAssertEqual( description, "500")
                    asyncExpectation.fulfill()
                    break
                default:
                    XCTFail()
                }
        }
        self.waitForExpectations(timeout: 10, handler:{ (error) in
            
            print("time out")
        });
        
        
    }

    
    // MARK:  Delete
    
    /**
     Test naming convention for StarzPlay
     */
    func  testDeleteShouldSuccess() {
    
        let asyncExpectation = expectation(description: "testDeleteShouldSuccess")
        
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
 
        self.waitForExpectations(timeout: 100, handler:{ (error) in
            print("test time out")
        });
    }
}
