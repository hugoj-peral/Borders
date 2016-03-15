//
//  CountriesAPI.swift
//  Borders
//
//  Created by Guillermo Gonzalez on 24/01/16.
//  Copyright © 2016 Guillermo Gonzalez. All rights reserved.
//

import Foundation
import RxSwift

enum CountriesAPI {
    case Name(name: String)
    case AlphaCodes(codes: [String])
}

extension CountriesAPI: Resource {
    
    var path: String {
        switch self {
        case let .Name(name):
            return "name/\(name)"
        case .AlphaCodes:
            return "alpha"
        }
    }
    
    var parameters: [String: String] {
        switch self {
        case .Name:
            return ["fullText": "true"]
        case let .AlphaCodes(codes):
            return ["codes": codes.joinWithSeparator(";")]
        }
    }
}

extension NSURL {
    class func countriesURL() -> NSURL {
        return NSURL(string: "https://restcountries.eu/rest/v1")!
    }
}

extension APIClient {
    class func countriesAPIClient() -> APIClient {
        return APIClient(baseURL: NSURL.countriesURL())
    }
    
    func countryWithName(name: String) -> Observable<Country> {
        return objects(CountriesAPI.Name(name: name)).map { $0[0] }
    }
    
    func countriesWithCodes(codes: [String]) -> Observable<[Country]> {
        return objects(CountriesAPI.AlphaCodes(codes: codes))
    }
}

extension APIClientWithoutRx {
    class func countriesAPIClient() -> APIClientWithoutRx {
        return APIClientWithoutRx(baseURL: NSURL.countriesURL())
    }
    
    func countryWithName(name: String, completion: (APIClientResult<Country, APIClientError>) -> Void) {
        objects(CountriesAPI.Name(name: name)) { (result: APIClientResult<[Country], APIClientError>) -> Void in
            switch result {
            case let .Success(countries):
                completion(APIClientResult.Success(countries[0]))
            case let .Failure(error):
                completion(APIClientResult.Failure(error))
            }
        }
    }
    
    func countriesWithCodes(codes: [String], completion: (APIClientResult<[Country], APIClientError>) -> Void) {
        objects(CountriesAPI.AlphaCodes(codes: codes)) { (result: APIClientResult<[Country], APIClientError>) -> Void in
            completion(result)
        }
    }
}
