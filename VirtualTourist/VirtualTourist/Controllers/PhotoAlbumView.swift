//
//  PhotoAlbumView.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 9/20/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumView: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var photoAlbumView: UICollectionView!
    
    // MARK: Global Variables
    var centerCoordinate: CLLocationCoordinate2D!
    var photoData:[PhotoC]?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        getPhotoData{}
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
    
    func getPhotoData(completion: @escaping () -> Void) {
        FlickerClient.getPhotos() { photoDataResponse, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.photoData = photoDataResponse?.photos.photo
                print("success?")
            }
        }
    }
}

//MARK: UICollectionViewDelegate
extension PhotoAlbumView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoData!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickerImageCell", for: indexPath)
        return cell
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

//MARK: UICollectionViewDelegateFlowLayout
extension PhotoAlbumView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}


