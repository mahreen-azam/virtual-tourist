//
//  PhotoAlbumView.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 9/20/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import UIKit
import MapKit
import CoreData

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
    var displayActivityIndicator: Bool = false
    
    // Persistence Code
    var pin: Pin! //This needs to be set in the previous view controller
    var dataController: DataController!
    var photosToBeImages: [Photo] = []

    // MARK: View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        guard centerCoordinate != nil else {
            self.dismiss(animated: true, completion: nil)
            self.showErrorAlert(title: "Data Error", message: "Could not get map coordinate")
            return
        }
        
        createPin(centerCoordinate: centerCoordinate)
        
        // Questions: How do we get Photo, a binary type, to save the information saved from flicker? Do we still parse it like normal, convert to images, and then save it? What is a binary type even? 
        
        // Setting up data model for pins
//        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
//        // Predicates allow us to filter the fetch request, %@ gets replaced by "pin" during run time
//        let predicate = NSPredicate(format: "pin == %@", pin)
//        fetchRequest.predicate = predicate
//        // Add sort descriptors?
//
//        if let result = try? dataController.viewContext.fetch(fetchRequest) {
//            photosToBeImages = result
//        }
//
        
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
        toolBarButton.isEnabled = false
        
        getPhotoData { result in
            guard case .success(let photoDataResponse) = result else {
                self.showErrorAlert(title: "Data Error", message: "Failure to retrieve photo data")
                return
            }
            self.imageArray = self.convertPhotoResponseIntoImages()
            self.photoAlbumView.reloadData()
            self.toolBarButton.isEnabled = true
        }
    }
    
    func getPhotoData(completion: @escaping (Result<PhotoA?>) -> Void) {
        FlickerClient.getPhotos(latitude: self.centerCoordinate.latitude, longitude: self.centerCoordinate.longitude, pages: self.pageNumber) { photoDataResponse, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showErrorAlert(title: "Data Error", message: "Failure to retrieve photo data")
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
            if let image = try? (UIImage(data: data!)!) {
                imageArray.append(image)
            } else {
                self.showErrorAlert(title: "Data Error", message: "There are no images in data")
            }
        }
        return imageArray
    }
    
    //MARK: Button Action Functions
    @IBAction func tapToolBarButton(_ sender: Any) {
        if toolBarButton.currentTitle == "New Collection" {
            if totalPages > pageNumber {
                pageNumber = pageNumber + 1
                loadCollectionViewData()
            } else {
                self.showErrorAlert(title: "No More Photos", message: "There are no more photos in this collection")
            }
        } else {
            for x in selectedIndices {
                imageArray.remove(at: x.row)
            }
            selectedIndices.removeAll()
            
            photoAlbumView.reloadData()
        }
    }
    
    // MARK: Error Handling Functions
    func showErrorAlert(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
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
            DispatchQueue.main.async {
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


