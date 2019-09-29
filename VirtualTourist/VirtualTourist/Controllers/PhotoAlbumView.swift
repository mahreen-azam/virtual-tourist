//
//  PhotoAlbumView.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 9/20/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import UIKit
import MapKit

enum Result<T> {
    case success(T)
    case failure(Error)
}

class PhotoAlbumView: UIViewController, MKMapViewDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbumView: UICollectionView!
    
    // MARK: Global Variables
    var centerCoordinate: CLLocationCoordinate2D!
    var photoData:[PhotoC] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        getPhotoData { result in
            guard case .success(let photoDataResponse) = result else {
                print("Failed to retrieve photos")
                //self.showDataRetrievalFailure(message: "Failure to retrieve location data")
                return
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard centerCoordinate != nil else {
            self.dismiss(animated: true, completion: nil)
            //self.showFailure(title: "Failed to Find Location", message: "Please try again with a valid location")
            print("Failed to get coordinate")
            return
        }
        createPin(centerCoordinate: centerCoordinate)
    }
    
    func createPin(centerCoordinate: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = centerCoordinate
        
        let mapArea = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(mapArea, animated: true)
        }
    }
    
    func getPhotoData(completion: @escaping (Result<PhotoA?>) -> Void) {
        FlickerClient.getPhotos() { photoDataResponse, error in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                     completion(.failure(error))
                } else {
                    self.photoData = photoDataResponse?.photos.photo ?? []
                    completion(.success(photoDataResponse))
                    print("success?")
                  //  print(photoDataResponse?.photos.photo)
                }
            }
        }
    }
    
    func convertPhotoResponseIntoImages() -> [UIImage] {
        var imageArray: [UIImage] = []
        
        for dataEntries in photoData {
            let url = URL(string: "https://farm\(dataEntries.farm).staticflickr.com/\(dataEntries.server)/\(dataEntries.id)_\(dataEntries.secret).jpg")
            let data = try? Data(contentsOf: url!)
            let image = (UIImage(data: data!)!)
            
           imageArray.append(image)
        }
        return imageArray
    }
}

//MARK: UICollectionViewDelegate
extension PhotoAlbumView: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if photoData.count > 0 {
            return photoData.count
        } else {
            return 20
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickerImageCell", for: indexPath)
        
        // Code for creating an image view and setting the image for each cell
        var imageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 115, height: 115))
        cell.contentView.addSubview(imageView)
        imageView.image = UIImage(named: "VirtualTourist_120") //Change this to placeholsder image
        
        if photoData.count > 0 {
            var imageArray = self.convertPhotoResponseIntoImages()
            if imageArray.count > 0 {
                DispatchQueue.main.async {
                    imageView.image = imageArray[indexPath.row]
                }
            }
           
        }
        
        return cell
        
        
        
        //   let image =  photoData[indexPath.row]
        
        //        let url = URL(string: "https://farm66.staticflickr.com/65535/48062994033_7c59ee4741.jpg")
        //        let data = try? Data(contentsOf: url!)
        //        imageView.image = UIImage(data: data!)
        // imageView.image = UIImage(named: "VirtualTourist_120")
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

////MARK: UICollectionViewDataSource
//extension PhotoAlbumView: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//    }
//}

////MARK: UICollectionViewDelegateFlowLayout
//extension PhotoAlbumView: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return collectionView.frame.size
//    }
//}


