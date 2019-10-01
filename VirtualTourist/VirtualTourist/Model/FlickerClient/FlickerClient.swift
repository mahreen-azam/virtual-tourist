//
//  FlickerClient.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 9/25/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import Foundation

class FlickerClient {
    
    //MARK: Global Variables
    static let apiKey = "1058b6fb9fbb08d1d1fa226fa9793384"

    enum Endpoints {
        case getPhotos
        
        var stringValue: String {
            switch self {
            case .getPhotos: return "https://www.flickr.com/services/rest/?method=flickr.photos.search" + "&api_key=\(apiKey)" + "&format=json&nojsoncallback=1" + "&per_page=15"
            }
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
        
        return task
    }
    
    class func getPhotos(latitude: Double, longitude: Double, pages: Int, completion: @escaping (PhotoA?, Error?) -> Void) {
        let photoURL = Endpoints.getPhotos.stringValue + "&lat=\(latitude)" + "&lon=\(longitude)" + "&page=\(pages)"
        
        taskForGETRequest(url: URL(string: photoURL)!, responseType: PhotoA.self) { response, error in
            if let response = response {
                print("successfully decoded photos")
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
}
