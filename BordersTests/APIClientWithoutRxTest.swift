//
//  APIClientWithoutRxTest.swift
//  Borders
//
//  Created by Hugo Peral on 13/3/16.
//  Copyright © 2016 Guillermo Gonzalez. All rights reserved.
//

import XCTest
import OHHTTPStubs


@testable import Borders

class APIClientWithoutRxTest: XCTestCase {
    
    struct TestModel: JSONDecodable {
        let foo: String
        
        init?(dictionary: JSONDictionary) {
            guard let foo = dictionary["foo"] as? String else {
                return nil
            }
            
            self.foo = foo
        }
    }
    
    struct TestResource: Resource {
        let path: String = "object"
        let parameters: [String: String] = ["testing": "true"]
    }
    
    let client = APIClientWithoutRx(baseURL: NSURL(string: "http://test.com")!)

    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testValidResponse() {
        stub(isHost("test.com")) { request in
            XCTAssertEqual("http://test.com/object?testing=true", request.URL!.absoluteString)
            
            let path = OHPathForFile("test.json", self.dynamicType)!
            return fixture(path, headers: nil)
        }
        
        let completed = self.expectationWithDescription("completed")
        client.objects(TestResource()) { (result: APIClientResult<[TestModel], APIClientError>) -> Void in
            switch result {
            case let .Success(models):
                XCTAssertEqual(1, models.count)
                XCTAssertEqual("bar", models[0].foo)
                
                completed.fulfill()
            default:
                XCTFail()
            }
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testBadStatus() {
        stub(isHost("test.com")) { request in
            return OHHTTPStubsResponse(data: NSData(), statusCode: 404, headers: nil)
        }
        
        let errored = self.expectationWithDescription("errored")

        
        client.objects(TestResource()) { (result: APIClientResult<[TestModel], APIClientError>) -> Void in
            switch result {
            case let .Failure(error):
                switch error {
                case let .BadStatus(status):
                    XCTAssertEqual(404, status)
                default:
                    XCTFail()
                }
                errored.fulfill()
            default:
                XCTFail()
            }
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
}
