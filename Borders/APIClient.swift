//
//  APIClient.swift
//  Borders
//
//  Created by Guillermo Gonzalez on 24/01/16.
//  Copyright © 2016 Guillermo Gonzalez. All rights reserved.
//

import Foundation
import RxSwift

enum APIClientError: ErrorType {
    case CouldNotDecodeJSON
    case BadStatus(status: Int)
    case Other(NSError)
}

extension APIClientError: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .CouldNotDecodeJSON:
            return "Could not decode JSON"
        case let .BadStatus(status):
            return "Bad status \(status)"
        case let .Other(error):
            return "\(error)"
        }
    }
}

final class APIClient {
    
    init(baseURL: NSURL, configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()) {
        self.baseURL = baseURL
        self.session = NSURLSession(configuration: configuration)
    }
    
    func objects<T: JSONDecodable>(resource: Resource) -> Observable<[T]> {
        return data(resource).map { data in
            guard let objects: [T] = decode(data) else {
                throw APIClientError.CouldNotDecodeJSON
            }
            
            return objects
        }
    }
    
    // MARK: - Private
    
    private let baseURL: NSURL
    private let session: NSURLSession
    
    private func data(resource: Resource) -> Observable<NSData> {
        
        let request = resource.requestWithBaseURL(baseURL)
        
        return Observable.create { observer in
            let task = self.session.dataTaskWithRequest(request) { data, response, error in
                
                if let error = error {
                    observer.onError(APIClientError.Other(error))
                } else {
                    guard let HTTPResponse = response as? NSHTTPURLResponse else {
                        fatalError("Couldn't get HTTP response")
                    }
                    
                    if 200 ..< 300 ~= HTTPResponse.statusCode {
                        observer.onNext(data ?? NSData())
                        observer.onCompleted()
                    }
                    else {
                        observer.onError(APIClientError.BadStatus(status: HTTPResponse.statusCode))
                    }
                }
            }
            
            task.resume()
            
            return AnonymousDisposable {
                task.cancel()
            }
        }
    }
}

enum APIClientResult<T, U> {
    case Success(T)
    case Failure(U)
}

final class APIClientWithoutRx {
    
    init(baseURL: NSURL, configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(), onQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        self.baseURL = baseURL
        self.session = NSURLSession(configuration: configuration)
        self.queue = onQueue
    }
    
    func objects<T: JSONDecodable>(resource: Resource, completion: (APIClientResult<[T], APIClientError>) -> Void) -> NSURLSessionDataTask {

        
        return data(resource, completion: { result in
            var clientResult: APIClientResult<[T], APIClientError>;
            
            switch result {
            case let .Success(data):
                if let objects: [T] = decode(data) {
                    clientResult = APIClientResult.Success(objects)
                } else {
                    clientResult = APIClientResult.Failure(APIClientError.CouldNotDecodeJSON)
                }
                
            case let .Failure(error):
                clientResult = APIClientResult.Failure(error)
            }
            
            dispatch_async(self.queue, {
                completion(clientResult)
            })
        })
    }
    
    // MARK: - Private
    
    private let baseURL: NSURL
    private let session: NSURLSession
    private let queue: dispatch_queue_t
    
    private func data(resource: Resource, completion: (APIClientResult<NSData, APIClientError>) -> Void) -> NSURLSessionDataTask {
        
        let request = resource.requestWithBaseURL(baseURL)
        
        let task = self.session.dataTaskWithRequest(request) { data, response, error in
            
            if let error = error {
                completion(APIClientResult.Failure(APIClientError.Other(error)))
            } else {
                guard let HTTPResponse = response as? NSHTTPURLResponse else {
                    fatalError("Couldn't get HTTP response")
                }
                
                if 200 ..< 300 ~= HTTPResponse.statusCode {
                    completion(APIClientResult.Success(data ?? NSData()))
                }
                else {
                    completion(APIClientResult.Failure(APIClientError.BadStatus(status: HTTPResponse.statusCode)))
                }
            }
        }
        
        task.resume()
        return task
    }
}
