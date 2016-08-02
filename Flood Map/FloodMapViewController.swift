//
//  FloodMapViewController
//  Flood Map
//
//  Created by Ryan Cortez on 7/28/16.
//  Copyright © 2016 Ryan Cortez. All rights reserved.
//

import UIKit
import MapKit
import CloudKit

class FloodMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var reportButtonStackView: UIStackView!
    @IBOutlet weak var reportFloodingButton: UIButton!
    @IBOutlet weak var underReportFloodingView: BlurView!
    @IBOutlet weak var underStatusBarView: BlurView!
    @IBOutlet weak var mapView: MKMapView!
    
    // MapKit
    var locationManager :CLLocationManager!
    var floodingAnnotationDetailView: UIView!
    
    // CloudKit
    var container :CKContainer!
    var publicDB :CKDatabase!
    var privateDB :CKDatabase!
    let floodingReportRecordType:String = "FloodingReport"
    let floodingReportLocationFieldName = "location"
    
    // Map Annotations
    var floodingLocations: Array<CLLocation> = []
    var selectedAnnotation: MKAnnotation?
    
    // MARK: - Setup Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupReportButton()
        setupStatusButton()
        setupCloudKit()
        setupMapView()
        setupLocationManager()
        getAllFloodingLocations()
    }
    
    func setupLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()

    }
    
    func setupCloudKit() {
        self.container = CKContainer.defaultContainer()
        self.publicDB = self.container.publicCloudDatabase
        self.privateDB = self.container.privateCloudDatabase
    }
    
    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true

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
    
    func roundCornerOfView(view: UIView) {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10.0
    }
    
    func addAllPublicAnnotations() {
        for location in floodingLocations {
            addAnnotation(toMap: self.mapView, withTitle: "Flooding near location", andLocation: location.coordinate, saveToCloudKit: false)
        }
    }
    
    
    // MARK: - Cloud Kit
    
    func getAllFloodingLocations() {
        let query = CKQuery(recordType: self.floodingReportRecordType, predicate: NSPredicate(value: true))
        self.publicDB.performQuery(query, inZoneWithID: nil) { (records :[CKRecord]?, error :NSError?) in
            for record in records! {
                guard let location = record.valueForKey(self.floodingReportLocationFieldName) as? CLLocation else {
                    print("Did not find CLLocation in CKRecord with key: \(self.floodingReportLocationFieldName)")
                    return
                }
                self.floodingLocations.append(location)
                if ((error) != nil) {
                    print("Did not get all locations from CloudKit due to error: \(error)")
                }
            }
            dispatch_async(dispatch_get_main_queue(), { 
                self.addAllPublicAnnotations()
            })
        }
    }
    
    func saveFloodingLocationToPublicCloudKit(coordinate: CLLocationCoordinate2D) {
        let floodingReportRecord = CKRecord(recordType: self.floodingReportRecordType)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        floodingReportRecord[self.floodingReportLocationFieldName] = location
        self.publicDB.saveRecord(floodingReportRecord) { (record :CKRecord?, error :NSError?) in
            if ((error) != nil) {
                print("Did not save to CloudKit due to error: \(error)")
            }
        }
    }
    
    func removeFloodingLocationFromPublicCloudKit() {
        
        let predicate = NSPredicate(
        let query = CKQuery(recordType: floodingReportRecordType, predicate: <#T##NSPredicate#>)
        self.publicDB.performQuery(<#T##query: CKQuery##CKQuery#>, inZoneWithID: <#T##CKRecordZoneID?#>, completionHandler: <#T##([CKRecord]?, NSError?) -> Void#>)
    }
    
    
    // MARK: - MapView Delegate
    
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
            // Return nil so the MapView draws a "blue dot" for the standard user location
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("FloodingAnnotationView")
        if annotationView == nil {
            annotationView = FloodingAnnotationView(annotation: annotation, reuseIdentifier: "FloodingAnnotationView")
            
            // Add detail button to right callout
            annotationView!.canShowCallout = true
            let calloutButton = UIButton(type: .DetailDisclosure)
            calloutButton.addTarget(self, action: #selector(removeAnnotationButtonPressed), forControlEvents: .TouchUpInside)
            annotationView!.rightCalloutAccessoryView = calloutButton
        }
        else {
            annotationView!.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        selectedAnnotation = view.annotation
    }
    
    // MARK: - MapView - Annotaions
    
    func addAnnotation(toMap map: MKMapView, withTitle title: String, andLocation coordinate: CLLocationCoordinate2D, saveToCloudKit: Bool) {
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
        if (saveToCloudKit) {
            saveFloodingLocationToPublicCloudKit(annotation.coordinate)
        }
    }
    
    func removeSelectedAnnotation() {
        guard let annotation = selectedAnnotation else {
            print("Did not find annotation in MKAnnotationView")
            return
        }
        self.mapView.removeAnnotation(annotation)
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

    // MARK: - Detect iPhone Shake 
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            self.addAnnotation(toMap: self.mapView, withTitle: "Flooding near this area", andLocation: self.mapView.userLocation.coordinate, saveToCloudKit: true)
        }
    }
    
    // MARK: - Actions
    
    func removeAnnotationButtonPressed() {
        removeSelectedAnnotation()
    }
    
    @IBAction func reportFloodingButtonPressed(sender: AnyObject) {
        self.addAnnotation(toMap: self.mapView, withTitle: "Flooding near this area", andLocation: self.mapView.userLocation.coordinate, saveToCloudKit: true)
    }
    @IBAction func cautionButtonPressed(sender: AnyObject) {
        
    }
}

