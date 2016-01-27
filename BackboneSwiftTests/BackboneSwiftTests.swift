//
//  BackboneSwiftTests.swift
//  BackboneSwiftTests
//
//  Created by Fernando Canon on 20/01/16.
//  Copyright © 2016 alphabit. All rights reserved.
//

import XCTest
@testable import BackboneSwift

public class testClass : Model {
    public var dd:String?
    public var juancarlos:String?
}

class BackboneSwiftTests: XCTestCase {
    
    let model = testClass();
    
    override func setUp() {
        super.setUp()
      
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
    
    func testPerformanceExample() {
      
        self.measureBlock { [unowned self] in
            
            self.model.parse(["dd":"hola", "juancarlos":"nothing","hoasd":"adfasdf","h2":"adfasdf"])
        }
    }
    
}
