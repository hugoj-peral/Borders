//
//  BordersViewModel.swift
//  Borders
//
//  Created by Guillermo Gonzalez on 24/01/16.
//  Copyright © 2016 Guillermo Gonzalez. All rights reserved.
//

import Foundation
import RxSwift

typealias Border = (name: String, nativeName: String)

protocol BordersViewModelType: class {
    
    /// The name of the country
    var countryName: String { get }
    
    /// The corresponding borders
    var borders: Observable<[Border]> { get }
    
    init(countryName: String)
}

class BordersViewModel: BordersViewModelType {
    
    let countryName: String
    let borders: Observable<[Border]>
    
    private let countriesClient = APIClient.countriesAPIClient()
    
    required init(countryName: String) {
        self.countryName = countryName
        
        // Create a copy of the client to avoid referencing
        // self in the closure
        let client = countriesClient
        
        self.borders = client.countryWithName(countryName)
            // Get the countries corresponding to the alpha codes
            // specified in the `borders` property
            .flatMap { country in
                client.countriesWithCodes(country.borders)
            }
            // Catch any error and print it in the console
            .catchError { error in
                print("Error: \(error)")
                return Observable.just([])
            }
            // Transform the resulting countries into [Border]
            .map { countries in
                countries.map { (name: $0.name, nativeName: $0.nativeName) }
            }
            // Make sure events are delivered in the main thread
            .observeOn(MainScheduler.instance)
            // Make sure multiple subscriptions share the side effects
            .shareReplay(1)
    }
}

class BordersClientWithoutRxViewModel: BordersViewModelType {

    let countryName: String
    let borders: Observable<[Border]>
    
    private let countriesClient = APIClientWithoutRx.countriesAPIClient()
    
    required init(countryName: String) {
        self.countryName = countryName
        
        let client = countriesClient
        
        self.borders = Observable.create({ observer -> Disposable in
            
            client.countryWithName(countryName, completion: { (result: APIClientResult<Country, APIClientError>) -> Void in
                switch result {
                case let .Success(country):
                    client.countriesWithCodes(country.borders, completion: { (result: APIClientResult<[Country], APIClientError>) -> Void in
                        switch result {
                        case let .Success(countries):
                            observer.onNext(countries.map { (name: $0.name, nativeName: $0.nativeName) })
                            observer.onCompleted()
                        case let .Failure(error):
                            print("Error: \(error)")
                            observer.onNext([])
                            observer.onCompleted()
                        }
                    })
                case let .Failure(error):
                    print("Error: \(error)")
                    observer.onNext([])
                    observer.onCompleted()
                }
            })
            
            return AnonymousDisposable {}
        })
    }
}