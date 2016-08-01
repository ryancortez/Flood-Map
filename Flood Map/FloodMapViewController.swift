//
//  FloodMapViewController
//  Flood Map
//
//  Created by Ryan Cortez on 7/28/16.
//  Copyright © 2016 Ryan Cortez. All rights reserved.
//

import UIKit
import MapKit

class FloodMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var reportButtonStackView: UIStackView!
    @IBOutlet weak var reportFloodingButton: UIButton!
    @IBOutlet weak var underReportFloodingView: BlurView!
    @IBOutlet weak var underStatusBarView: BlurView!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager :CLLocationManager!
    var floodingAnnotationDetailView: UIView!


    override func viewDidLoad() {
        setupReportButton()
        setupStatusButton()
        
        
        super.viewDidLoad()
        
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.mapView.delegate = self
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
    }
    
    func roundCornerOfView(view: UIView) {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10.0
    }
    
    func setupReportButton() {
        roundCornerOfView(self.underReportFloodingView)
        roundCornerOfView(self.reportFloodingButton)
//        self.underReportFloodingView.blurBackground(withStyle: .Light)
        self.reportFloodingButton.backgroundColor = UIColor.whiteColor()
        self.reportFloodingButton.setTitle("Report Flooding", forState: .Normal)
        self.reportFloodingButton.setTitleColor(self.view.tintColor, forState: .Normal)
        
        
    }
    
    func setupStatusButton() {
        roundCornerOfView(underStatusBarView)
        self.underStatusBarView.blurBackground(withStyle: .Light)
        
    }
    
    private func createAccessoryView() -> UIView {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        view.backgroundColor = UIColor.redColor()
        
        let widthConstraint = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 300)
        view.addConstraint(widthConstraint)
        
        let heightConstraint = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 300)
        view.addConstraint(heightConstraint)
        
        return view
        
    }
    
    
    private func getDetailCalloutView() -> UIView {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        view.backgroundColor = UIColor.greenColor()
        
        let widthConstraint = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 300)
        view.addConstraint(widthConstraint)
        
        let heightConstraint = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 300)
        view.addConstraint(heightConstraint)
        
        return view
        
    }
    
    
    
    
    
    // MARK: MapView Delegate
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        if let annotationView = views.first {
            
            if let annotation = annotationView.annotation {
                if annotation is MKUserLocation {
                    
                    let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 250, 250)
                    self.mapView.setRegion(region, animated: true)
                    
                }
            }
        }
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        let floodingAnnoationViewReuseIdentifier = "FloodingAnnotationView"
        var floodingAnnotationView = self.mapView.dequeueReusableAnnotationViewWithIdentifier(floodingAnnoationViewReuseIdentifier)
        
        if floodingAnnotationView == nil {
            // create the annotation view
            floodingAnnotationView = FloodingAnnotationView(annotation: annotation, reuseIdentifier: floodingAnnoationViewReuseIdentifier)
        }
        
        floodingAnnotationView?.canShowCallout = true
        
//        let floodingImageView = UIImageView(image: UIImage(named: "Caution"))
        
          floodingAnnotationView?.detailCalloutAccessoryView = createAccessoryView()
        
        
//        floodingAnnotationView?.detailCalloutAccessoryView = self.floodingAnnotationDetailView
        
        return floodingAnnotationView
        
    }


    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }

    
    @IBAction func reportFloodingButtonPressed(sender: AnyObject) {
        
        let pinAnnotation = MKPointAnnotation()
        pinAnnotation.title = "This is a Pizza store"
        pinAnnotation.coordinate = self.mapView.userLocation.coordinate
//        pinAnnotation.coordinate = CLLocationCoordinate2D(latitude: 37.331210, longitude: -122.030522)
        
        self.mapView.addAnnotation(pinAnnotation)
    }
}

