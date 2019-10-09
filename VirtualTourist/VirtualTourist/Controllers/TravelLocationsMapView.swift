//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 9/8/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapView: UIViewController, MKMapViewDelegate {
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    //MARK: Global Variables
    var isEditTapped:Bool = false
    var pinArray: [Pin] = []
    var dataController: DataController!
    var selectedPin: Pin!
    
    override func viewDidLoad() { 
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Setting up data model for pins
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pinArray = result
        }
        
        var annotations = [MKPointAnnotation]()
        
        for dictionary in pinArray {
            
            let lat = CLLocationDegrees(dictionary.latitude)
            let long = CLLocationDegrees(dictionary.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        
        self.mapView.addAnnotations(annotations)
        
        // Setting up map view based on persistant changes
        if let didMapChange = UserDefaults.standard.value(forKey: "mapChanges") {
            if didMapChange as! Bool {
                var updateMapView = UserDefaults.standard.value(forKey: "mapView") as! [Double]
                
                let centerCoordinates = CLLocationCoordinate2DMake(updateMapView[0],updateMapView[1])
                self.mapView.setRegion(MKCoordinateRegion(center: centerCoordinates, span: MKCoordinateSpan(latitudeDelta: updateMapView[2], longitudeDelta: updateMapView[3])), animated: true)
            }
        } else {
            UserDefaults.standard.setValue(false, forKey: "mapChanges")
        }
        
        // Adds long press recognizer which will add pins to the map when recognized
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
    }
    
    @IBAction func tapEditButton(_ sender: Any) {
        
        if isEditTapped == false {
            editButton.title = "Done"
            isEditTapped = true
        }
        else if isEditTapped == true {
            editButton.title = "Edit"
            isEditTapped = false
        }
    }
    
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        var pinArray = [MKPointAnnotation]()
        
        let location = sender.location(in: mapView)
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        
        let myPin: MKPointAnnotation = MKPointAnnotation()
        myPin.coordinate = myCoordinate
        
        mapView.addAnnotation(myPin)
        pinArray.append(myPin)
        
        // Add Pin to Data Model
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = myCoordinate.latitude
        pin.longitude = myCoordinate.longitude
        try? dataController.viewContext.save()
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.setValue(true, forKey: "mapChanges")
        
        let updateMapView = [Double(mapView.centerCoordinate.latitude), Double(mapView.centerCoordinate.longitude), Double(mapView.region.span.latitudeDelta), Double(mapView.region.span.longitudeDelta)]
        UserDefaults.standard.setValue(updateMapView, forKey: "mapView")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Saving selected annotation as a Pin
        do {
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            let latitude = Double((view.annotation?.coordinate.latitude)!)
            let longitude = Double((view.annotation?.coordinate.longitude)!)
            var predicate: NSPredicate?
            fetchRequest.predicate = predicate
            predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
            
            let result = try dataController.viewContext.fetch(fetchRequest)
            selectedPin = result[0]
        } catch {
            self.showErrorAlert(title: "Data Error", message: "Failed to find selected pin")
        }
        
        if self.isEditTapped {
            if let selectedPin = selectedPin {
                dataController.viewContext.delete(selectedPin)
                try? dataController.viewContext.save()
            }
            
            mapView.removeAnnotation(view.annotation!)
            
        } else {
            let pin = view.annotation?.coordinate
            performSegue(withIdentifier: "showPhotoAlbumView", sender: pin)
            mapView.deselectAnnotation(view.annotation, animated: true)
        }
    }
    
    //MARK: Helper Functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoAlbumView" {
            let photoAlbumVC = segue.destination as! PhotoAlbumView
            photoAlbumVC.centerCoordinate =  sender as? (CLLocationCoordinate2D)
            photoAlbumVC.dataController = dataController
            photoAlbumVC.pin = selectedPin
        }
    }
    
    func showErrorAlert(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }
}

