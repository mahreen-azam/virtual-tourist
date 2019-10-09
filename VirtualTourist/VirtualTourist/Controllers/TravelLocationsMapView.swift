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
    
    // Persistence Code
    var dataController: DataController!
   // var fetchedResultsController:NSFetchedResultsController<Pin>!
    var pinToSend: Pin!
    
    //Question: what is the value of sort descriptors if I don't care about the sort order? What do they really do?
    
    
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
    
    // MARK: - MKMapViewDelegate
    
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
        
        if self.isEditTapped {
            
            // Add code to delete from data model
            
            var pin: Pin?
//            let latitude = Double((view.annotation?.coordinate.latitude)!)
//           // let longitude = Double((view.annotation?.coordinate.longitude)!)
//            //AND longitude == %@
//            let predicate = NSPredicate(format: "latitude == %@", latitude) // Why does this return no results? There are pins stored with this latitude (?) **
//
//            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
//            fetchRequest.predicate = predicate
//            if let result = try? dataController.viewContext.fetch(fetchRequest) {
//                pin = try? result[0]
//            }
            
            do {
                let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
                let latitude = Double((view.annotation?.coordinate.latitude)!)
                let longitude = Double((view.annotation?.coordinate.longitude)!)
                var predicate: NSPredicate?
                fetchRequest.predicate = predicate
                predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
                let result = try dataController.viewContext.fetch(fetchRequest)
                pin = result[0]
                pinToSend = result[0]
                print("Pin successfully saved")
            } catch {
                print("Error saving selected pin")
            }
        
           // let pinToDelete = view.annotation as! Pin    Can't figure out how to reference the pinToDelete here**
            if let pin = pin {
                dataController.viewContext.delete(pin)
                try? dataController.viewContext.save()
            }
            
            mapView.removeAnnotation(view.annotation!)
            
        } else {
            // Outside of this if statement, you should set the global "pin" to be the one that is tapped, then in the segue, you can pass over the correct pin
           // var pin2: Pin?
            do {
                let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
                let latitude = Double((view.annotation?.coordinate.latitude)!)
                let longitude = Double((view.annotation?.coordinate.longitude)!)
                var predicate: NSPredicate?
                fetchRequest.predicate = predicate
                predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
                let result = try dataController.viewContext.fetch(fetchRequest)
               // pin2 = result[0]
                pinToSend = result[0]
                print("Pin successfully saved")
            } catch {
                print("Error saving selected pin")
            }
            
            
            
            let pin = view.annotation?.coordinate
            performSegue(withIdentifier: "showPhotoAlbumView", sender: pin)
            mapView.deselectAnnotation(view.annotation, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoAlbumView" {
            let photoAlbumVC = segue.destination as! PhotoAlbumView
            photoAlbumVC.centerCoordinate =  sender as? (CLLocationCoordinate2D)
            photoAlbumVC.dataController = dataController
            photoAlbumVC.pin = pinToSend //This needs to be the tapped pin **
        }
    }
}

