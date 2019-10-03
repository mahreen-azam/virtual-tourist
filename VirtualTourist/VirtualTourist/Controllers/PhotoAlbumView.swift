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
    @IBOutlet weak var toolBarButton: UIButton!
    
    // MARK: Global Variables
    var centerCoordinate: CLLocationCoordinate2D!
    var photoData:[PhotoC] = []
    var imageArray: [UIImage] = []
    var totalPages: Int = 1
    var pageNumber: Int = 1
    private var selectedIndices = [IndexPath]()
   // var isPhotoSelected: [Bool] = [false]

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        guard centerCoordinate != nil else {
            self.dismiss(animated: true, completion: nil)
            //self.showFailure(title: "Failed to Find Location", message: "Please try again with a valid location")
            print("Failed to get coordinate")
            return
        }
        
        createPin(centerCoordinate: centerCoordinate)
        loadCollectionViewData()
    }
    
    //Mark: Functions for setting up the Map view
    func createPin(centerCoordinate: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = centerCoordinate
        
        let mapArea = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(mapArea, animated: true)
        }
    }
    //MARK: Functions for getting, converting, and laoding photo data
    func loadCollectionViewData() {
        getPhotoData { result in
            guard case .success(let photoDataResponse) = result else {
                print("Failed to retrieve photos")
                //self.showDataRetrievalFailure(message: "Failure to retrieve location data")
                return
            }
            self.imageArray = self.convertPhotoResponseIntoImages()
            self.photoAlbumView.reloadData()
        }
    }
    
    func getPhotoData(completion: @escaping (Result<PhotoA?>) -> Void) {
        FlickerClient.getPhotos(latitude: self.centerCoordinate.latitude, longitude: self.centerCoordinate.longitude, pages: self.pageNumber) { photoDataResponse, error in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                     completion(.failure(error))
                } else {
                    self.photoData = photoDataResponse?.photos.photo ?? []
                    self.totalPages = photoDataResponse?.photos.pages ?? 1
                    completion(.success(photoDataResponse))
                    print("success?")
                }
            }
        }
    }
    
    func convertPhotoResponseIntoImages() -> [UIImage] {
        var imageArray: [UIImage] = []
        
        for dataEntries in photoData {
            let url = URL(string: "https://farm\(dataEntries.farm).staticflickr.com/\(dataEntries.server)/\(dataEntries.id)_\(dataEntries.secret).jpg")
            let data = try? Data(contentsOf: url!)
            // Add a gaurd for nil data or ?? if optional
            let image = (UIImage(data: data!)!)
            
           imageArray.append(image)
        }
        return imageArray
    }
    
    //MARK: Button Action Functions
    @IBAction func tapToolBarButton(_ sender: Any) {
        //Disable button when images are loading
        
        if toolBarButton.currentTitle == "New Collection" {
             print("New Collection")
            
            if totalPages > pageNumber {
                pageNumber = pageNumber + 1
                loadCollectionViewData()
            } else {
                print("There are no more photos in this collection") // Pop an error onto the screen
            }
            
        } else {
            print("Remove Photos")
            print(selectedIndices)
            
            for x in selectedIndices {
                imageArray.remove(at: x.row)
            }
            selectedIndices.removeAll()
            
            photoAlbumView.reloadData()
        }
    }
}

//MARK: UICollectionViewDelegate
extension PhotoAlbumView: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if imageArray.count > 0 {
            return imageArray.count
        } else {
            return 15
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickerImageCell", for: indexPath) as! FlickerImageCell
        
        if imageArray.count > 0 {
            DispatchQueue.main.async { // Remove main queue?
                cell.ImageView?.image = self.imageArray[indexPath.row]
            }
        }
        
        cell.setSelected(isSelected: selectedIndices.contains(indexPath))
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selected = selectedIndices.contains(indexPath)
        
        if !selected {
            selectedIndices.append(indexPath)
            self.toolBarButton.setTitle("Remove Selected Images", for: [])
            print("added to array")
        } else {
            selectedIndices.removeAll(where: { $0 == indexPath })
            if selectedIndices == [] {
                self.toolBarButton.setTitle("New Collection", for: [])
            }
            print("removed from array")
        }
        
        collectionView.reloadItems(at: [indexPath])

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


