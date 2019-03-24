//
//  PhotoClient.swift
//  Virtual Tourist
//
//  Created by Matthew Gilman on 3/10/19.
//  Copyright © 2019 Matt Gilman. All rights reserved.
//

import Foundation

class PhotoClient: NSObject {
    // MARK: Make Network Request
    
    // MARK: Configure UI
    var session = URLSession.shared
    
    override init() {
        super.init()
    }
    
    func taskForGETMethod(lat: Double, lon: Double, completionHandlerForGET: @escaping (_ success: Bool, _ result: [[String:AnyObject]]?, _ error: String?) -> Void) -> URLSessionDataTask {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            "lat": "\(lat)",
            "lon": "\(lon)"
            
        ]
        
        // create url and request
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters as [String:AnyObject])
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(url)")
                completionHandlerForGET(false, [[:]], error)
                performUIUpdatesOnMain {
                    //self.setUIEnabled(true)
                    
                }
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                return
            }
            completionHandlerForGET(true, photoArray, nil)
            
           
//            /* GUARD: Does our photo have a key for 'url_m'? */
//            guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
//                displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
//                return
//            }
            
            // if an image exists at the url, set the image and title
//            let imageURL = URL(string: imageUrlString)
//            if let imageData = try? Data(contentsOf: imageURL!) {
//                performUIUpdatesOnMain {
//                    //self.setUIEnabled(true)
//                    //self.photoImageView.image = UIImage(data: imageData)
//                    //self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
//                }
//            } else {
//                displayError("Image does not exist at \(imageURL!)")
//            }
        }
        
        // start the task!
        task.resume()
        return task
    }
    
    // MARK: Helper for Escaping Parameters in URL
    
    private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> PhotoClient {
        struct Singleton {
            static var sharedInstance = PhotoClient()
        }
        return Singleton.sharedInstance
    }
}
