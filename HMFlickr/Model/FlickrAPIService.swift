//
//  FlickrAPIService.swift
//  HMFlickr
//
//  Created by Hayden Malcomson on 2018-07-12.
//  Copyright © 2018 Hayden Malcomson. All rights reserved.
//

import Foundation

enum FlickrAPIError: Error {
    case invalidInputsError(msg: String)
    case urlSessionError(error: Error)
    case responseHandlingError(msg: String)
}

class FlickrAPIService {
    
    typealias FlickrResponse = (FlickrPublicFeed?, Error?) -> Void
    
    static let baseURL = "https://api.flickr.com/services/feeds/photos_public.gne?lang=en-us&format=json&nojsoncallback=1"
    static let flickrTimeFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    static func getFlickrPublicFeed(completion: @escaping FlickrResponse) -> Void {
        //let escapedSearchText: String = searchText.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed)!
        guard let url = URL(string: baseURL) else {
            completion(nil, FlickrAPIError.invalidInputsError(msg: "Could not initialise `\(baseURL)` as valid URL object"))
            return
        }
        let searchTask = URLSession.shared.dataTask(with: url as URL, completionHandler: {dataResponse, response, error -> Void in
            
            if let urlSessionError = error {
                completion(nil, FlickrAPIError.urlSessionError(error: urlSessionError))
                return
            }
            guard let data = dataResponse else {
                completion(nil,FlickrAPIError.responseHandlingError(msg: "nil `data` return from request"))
                return
            }
            
            do {
                
                // Fixing invalid json data from https://www.flickr.com/groups/51035612836@N01/discuss/72157622950514923/
                guard let invalidJSONString = String(data: data, encoding: .utf8) else {
                    throw(FlickrAPIError.responseHandlingError(msg: "Response could not be encoded with .utf8"))
                }
                // Corrected String: replace escaped single quotes \' which are invalid for json format with just single quotes '
                let correctedJSONFormatString = invalidJSONString.replacingOccurrences(of: "\\'", with: "'")
                guard let correctData = correctedJSONFormatString.data(using: .utf8) else {
                    throw(FlickrAPIError.responseHandlingError(msg: "Could not re-encode "))
                }
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = flickrTimeFormat
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let result = try decoder.decode(FlickrPublicFeed.self, from: correctData)
                completion(result,error)
            } catch let error {
                completion(nil, error)
            }
            
        })
        searchTask.resume()
    }
    
}
