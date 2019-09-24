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
    @IBOutlet weak var photoAlbum: UIImageView!
    
    // MARK: Global Variables
    var centerCoordinate: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
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
        
        let mapArea = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(mapArea, animated: true)
        }
    }

}
