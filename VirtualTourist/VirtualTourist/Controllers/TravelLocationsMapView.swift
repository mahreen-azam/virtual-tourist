//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 9/8/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapView: UIViewController, MKMapViewDelegate {

    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    //MARK: Global Variables
    var isEditTapped:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
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
        print("Edit Tapped")
        
        if isEditTapped == false {
            //update Edit to say Done
            //update flag for is edit to be true
            //move vc up and have Tap Pins to Delete tool bar (?) displayed
            //remove annotations when tapped
        }
        if isEditTapped == true {
            //update Done to say Edit
            //update flag for is edit to be false
            //move vc down and hide Tap Pins to Delete tool bar (?)
            //go to next vc when annotations tapped -> will need to update map annotations selected method to check for this flag
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
        let pin = view.annotation?.coordinate
        performSegue(withIdentifier: "showPhotoAlbumView", sender: pin)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoAlbumView" {
            let photoAlbumVC = segue.destination as! PhotoAlbumView
            photoAlbumVC.centerCoordinate =  sender as? (CLLocationCoordinate2D)
        }
    }
}

