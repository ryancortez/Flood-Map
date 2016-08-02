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

    // Outlets
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
    var floodingLocations: Array<FloodingLocation> = []
    var floodingAnnotationViews: Array<FloodingAnnotationView> = []
    var selectedAnnotationView: FloodingAnnotationView?
    
    // MARK: - Setup Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Inital UI
        setupReportButton()
        setupStatusButton()
        setupCloudKit()
        setupMapView()
        setupLocationManager()
        
        // Fill Map with Information
        getAllFloodingLocations()
    }
    
    func setupLocationManager() {
        
        // Get the User's Location with as much accuracy as possible, as often as possible
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()

    }
    
    func setupCloudKit() {
        // Set up a public and private database for CloudKit
        self.container = CKContainer.defaultContainer()
        self.publicDB = self.container.publicCloudDatabase
        self.privateDB = self.container.privateCloudDatabase
    }
    
    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
    }
    
    func setupReportButton() {
        
        // Create a semi-transparent view to display under the Report Flooding Button, with a thin border line
        roundCornerOfView(self.underReportFloodingView)
        self.underReportFloodingView.blurBackground(withStyle: .ExtraLight)
        self.underReportFloodingView.layer.borderColor = self.view.tintColor.CGColor
        self.underReportFloodingView.layer.borderWidth = 0.1
        
        // Create the Report Flooding Button
        self.reportFloodingButton.backgroundColor = UIColor.clearColor()
        self.reportFloodingButton.setTitle("Report Flooding", forState: .Normal)
        self.reportFloodingButton.setTitleColor(self.view.tintColor, forState: .Normal)
    }
    
    func setupStatusButton() {
        
        // Place a semi-transparent view behind the status bar
        self.underStatusBarView.blurBackground(withStyle: .ExtraLight)
        self.underStatusBarView.layer.borderWidth = 0.2
        self.underStatusBarView.layer.borderColor = self.view.tintColor.CGColor
    }
    
    // Helper method that rounds the corner of views
    func roundCornerOfView(view: UIView) {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10.0
    }
    
    // Add all Flooding Locations found in the public CloudKit to the map
    func addAllPublicAnnotations() {
        for floodingLocation in self.floodingLocations {
            addAnnotation(toMap: self.mapView, withTitle: "Flooding near location", andCoordinate:floodingLocation.location.coordinate, saveToCloudKit: false)
        }
    }
    
    
    // MARK: - Cloud Kit
    
    // Pull Flooding Locations from the public CloudKit database
    func getAllFloodingLocations() {
        let query = CKQuery(recordType: self.floodingReportRecordType, predicate: NSPredicate(value: true))
        self.publicDB.performQuery(query, inZoneWithID: nil) { (records :[CKRecord]?, error :NSError?) in
            for record in records! {
                guard let location = record.valueForKey(self.floodingReportLocationFieldName) as? CLLocation else {
                    print("Did not find CLLocation in CKRecord with key: \(self.floodingReportLocationFieldName)")
                    return
                }
                let floodingLocation = FloodingLocation(withLocation: location, andCloudKitRecordID: record.recordID)
                self.floodingLocations.append(floodingLocation)
                if ((error) != nil) {
                    print("Did not get all locations from CloudKit due to error: \(error)")
                }
            }
            dispatch_async(dispatch_get_main_queue(), { 
                self.addAllPublicAnnotations()
            })
        }
    }
    
    // Save a single flooding location that the user has added to the public CloudKit database
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
    
    // Remove a single flooding location from the public CloudKit database
    func removePublicCloudKitRecord(withFloodingAnnotationView annotationView: FloodingAnnotationView) {
        guard annotationView.cloudKitID != nil else {
            print("Did not find cloudKitID"); return
        }
        
        self.publicDB.deleteRecordWithID(annotationView.cloudKitID) { (recordID: CKRecordID?, error: NSError?) in
            if (error != nil) {
                print(error)
            }
        }
    }
    
    
    // MARK: - MapView Delegate
    
    // Called when adding an annotaion
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
    
    // Called when loading annotations
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            
            // Return nil so the MapView draws a "blue dot" for the standard user location
            return nil
        }
        
        let floodingAnnotationViewReuseIdentifier = "FloodingAnnotationView"
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(floodingAnnotationViewReuseIdentifier)
        if annotationView == nil {
            
            let floodingAnnotationView = FloodingAnnotationView(annotation: annotation, reuseIdentifier: floodingAnnotationViewReuseIdentifier)
            
            for floodingLocation in self.floodingLocations {
                
                guard let annotation = floodingAnnotationView.annotation else {
                    print("Did not find location.coordinate in floodingLocation"); return nil
                }
                
                if (floodingLocation.location.coordinate.latitude == annotation.coordinate.latitude && floodingLocation.location.coordinate.longitude == floodingLocation.location.coordinate.longitude) {
                    floodingAnnotationView.cloudKitID = floodingLocation.cloudKitRecordID
                }
            }
            
            // Add detail button to right callout
            floodingAnnotationView.canShowCallout = true
            let calloutButton = UIButton(type: .DetailDisclosure)
            calloutButton.addTarget(self, action: #selector(removeAnnotationButtonPressed), forControlEvents: .TouchUpInside)
            floodingAnnotationView.rightCalloutAccessoryView = calloutButton
            return floodingAnnotationView
        }
        else {
            annotationView!.annotation = annotation
        }
        return annotationView
    }
    
    // Called when an annotation is selected
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let floodingAnnotationView = view as? FloodingAnnotationView else {
            print("Could not cast selected MKAnnotationView as FloodingAnnotationView, returned nil"); return
        }
        selectedAnnotationView = floodingAnnotationView
    }
    
    // MARK: - MapView - Annotaions
    
    // Add annotation to map, and public CloudKit database
    func addAnnotation(toMap map: MKMapView, withTitle title: String, andCoordinate coordinate: CLLocationCoordinate2D, saveToCloudKit: Bool) {
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
        if (saveToCloudKit) {
            saveFloodingLocationToPublicCloudKit(annotation.coordinate)
        }
    }
    
    // Remove annotation from the map
    func removeSelectedAnnotation() {
        guard let annotationView = selectedAnnotationView else {
            print("Did not find annotation in MKAnnotationView"); return
        }
        guard let annotation = annotationView.annotation else {
            print("Did not find annotation in selectedAnnotationView"); return
        }
        self.mapView.removeAnnotation(annotation)
    }

    // MARK: - Detect iPhone Shake 
    
    // When the phone is shaken add flooding location to the user's location
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            self.addAnnotation(toMap: self.mapView, withTitle: "Flooding near this area", andCoordinate: self.mapView.userLocation.coordinate, saveToCloudKit: true)
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // MARK: - Actions
    
    // When annotation remove button pressed remove the annotation
    func removeAnnotationButtonPressed() {
        guard let annotationView = selectedAnnotationView else {
            print("selectedAnnotationView is nil and cannot be used to remove a CloudKit record"); return
        }
        removePublicCloudKitRecord(withFloodingAnnotationView: annotationView)
        removeSelectedAnnotation()
    }
    
    // Add a flooding location when the Report Button is pressed
    @IBAction func reportFloodingButtonPressed(sender: AnyObject) {
        self.addAnnotation(toMap: self.mapView, withTitle: "Flooding near this area", andCoordinate: self.mapView.userLocation.coordinate, saveToCloudKit: true)
    }
}

