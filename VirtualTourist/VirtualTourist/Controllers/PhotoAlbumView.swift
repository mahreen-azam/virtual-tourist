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
    var totalPages: Int = 1
    var pageNumber: Int = 1
    var selectedIndices = [IndexPath]()
    var pin: Pin!
    var dataController: DataController!
    var savedPhotos: [Photo] = []
    
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
        
        // Setting up data model for photos
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate: NSPredicate = NSPredicate(format: "pin == %@ AND id != nil", pin)
        fetchRequest.predicate = predicate
       
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            savedPhotos = result
        }
        
        if savedPhotos == [] {
            loadCollectionViewData()
            
        } else {
            getPhotoData { result in
                guard case .success(let photoDataResponse) = result else {
                    self.showErrorAlert(title: "Data Error", message: "Failure to retrieve photo data")
                    return
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        savedPhotos.removeAll()
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
            self.convertPhotoResponseIntoImages()
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
                }
            }
        }
    }
    
    func convertPhotoResponseIntoImages() {
        for dataEntries in photoData {
            let url = URL(string: "https://farm\(dataEntries.farm).staticflickr.com/\(dataEntries.server)/\(dataEntries.id)_\(dataEntries.secret).jpg")
            let data = try? Data(contentsOf: url!)
            
            // Saving photos to code data
            let photo = Photo(context: dataController.viewContext)
            photo.image = data
            photo.id = dataEntries.id
            photo.pin = self.pin
            try? dataController.viewContext.save()
            
            savedPhotos.append(photo)
        }
    }
    
    func deleteSavedPhotos() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate:NSPredicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        let result = try? dataController.viewContext.fetch(fetchRequest)
        
        for photo in result! {
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        }
        
        savedPhotos.removeAll()
    }
    
    //MARK: Button Action Functions
    @IBAction func tapToolBarButton(_ sender: Any) {
        if toolBarButton.currentTitle == "New Collection" {
            if totalPages > pageNumber {
                pageNumber = pageNumber + 1
                deleteSavedPhotos()
                loadCollectionViewData()
            } else {
                self.showErrorAlert(title: "No More Photos", message: "There are no more photos in this collection")
            }
        } else {
            for selectedPhoto in selectedIndices {
                
                // Deleting images from core data
                if savedPhotos != [] {
                    let imageId = savedPhotos[selectedPhoto.row].id
                    
                    if imageId != nil {
                        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                        let predicate = NSPredicate(format: "pin == %@ AND id == %@", pin, imageId!)
                        fetchRequest.predicate = predicate
                        
                        let result = try? dataController.viewContext.fetch(fetchRequest)
                        
                        for photo in result! {
                            dataController.viewContext.delete(photo)
                            try? dataController.viewContext.save()
                        }
                    }
                    savedPhotos.remove(at: selectedPhoto.row)
                }
            }
            selectedIndices.removeAll()
            
            self.toolBarButton.setTitle("New Collection", for: [])
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
        if savedPhotos.count > 0 {
            return savedPhotos.count
        } else {
            return 15
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickerImageCell", for: indexPath) as! FlickerImageCell
        var image = UIImage(named: "VirtualTourist_120")
        cell.setActivityIndicator(isStopped: false)
        
        if savedPhotos.count > 0 {
            if savedPhotos[indexPath.row].image != nil {
                image = UIImage(data: savedPhotos[indexPath.row].image!)
                cell.setActivityIndicator(isStopped: true)
            }
        }
        
        DispatchQueue.main.async {
            cell.ImageView?.image = image
        }
        cell.setSelected(isSelected: selectedIndices.contains(indexPath))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selected = selectedIndices.contains(indexPath)
        
        if !selected {
            selectedIndices.append(indexPath)
            self.toolBarButton.setTitle("Remove Selected Images", for: [])
        } else {
            selectedIndices.removeAll(where: { $0 == indexPath })
            if selectedIndices == [] {
                self.toolBarButton.setTitle("New Collection", for: [])
            }
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}


