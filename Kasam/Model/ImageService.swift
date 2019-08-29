//
//  ImageService.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-24.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation

class ImageService {
    
    static func downloadImage(withURL url: URL, completion: @escaping (_ image: UIImage)->()) {
        let dataTask = URLSession.shared.dataTask(with: url) { data, url, error in
            var downloadedImage:UIImage?
            
            if let data = data {
                downloadedImage = UIImage(data: data)
            }
            
            DispatchQueue.main.async {
                 completion(downloadedImage!)
            }
           
        }
        
        dataTask.resume()
    }

}
