//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Oludemilade Raji on 8/19/17.
//  Copyright © 2017 donrajon. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longtitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    var location: CLLocation? // Store users coordinates in this location. Can be nil
    //Adding some Error handling
    var updatingLocation = false
    var lastLocationError: Error?
    
    let locationManager = CLLocationManager()
    
    // Adding Geocoder functionality
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark? = nil
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateLabels()
        configureGetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getLocation() {
        // Checks current authorization status. If not deremined ask and get
        // Permissjon to check location when in use. 
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            // Clear out variables.
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for thie app in settings.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        
        if(error as NSError).code == CLError.locationUnknown.rawValue{
            return
        }
        
        lastLocationError = error
        stopLocationManager()
        lastLocationError = nil
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
       
        // If the time is less than 5 seconds since last update ignore update
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        // Use horizontal accuracy to determine overall accuracy. If less than zero ignore.
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            // Check that the new location is more accurate than the last.
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print( "*** We are Done!" )
                stopLocationManager()
                configureGetButton()
            }
            
            if !performingReverseGeocoding {
                print ("*** Going to geocode")
                performingReverseGeocoding = true
                
                geocoder.reverseGeocodeLocation(newLocation, completionHandler:
                    {
                        placemarks, error in
                        print("*** Found Placemarks: \(placemarks), error:\(error)")
                        self.lastGeocodingError = error
                        if error == nil, let p = placemarks, !p.isEmpty {
                            self.placemark = p.last!
                        } else {
                            self.placemark = nil
                        }
                        
                        self.performingReverseGeocoding = false
                        self.updateLabels()
                    })
            }
        }
    }
    
    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longtitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
        } else {
            latitudeLabel.text = ""
            longtitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            messageLabel.text = "Tap 'Get my Location' to Start"
            
            let statusMessage: String
            if let error = lastLocationError as? NSError {
                if error.domain  == kCLErrorDomain &&
                    error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            }
            else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            }
            else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get my Location' to Start"
            }
            
            messageLabel.text = statusMessage
            }
        }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        } else {
           getButton.setTitle("Get My Location", for: .normal)
        }
    }
    
    func string (from placemark: CLPlacemark) -> String {
        var line1 = ""
        
        if let s = placemark.subThoroughfare { //subthouroughfare == House number
            line1 += s + ""
        }
        
        if let s = placemark.thoroughfare { // Additional street level info
            line1 += s
        }
        
        var line2 = ""
        if let s = placemark.locality { // City
            line2 += s + " "
        }
        if let s = placemark.administrativeArea { // State
            line2 += s + " "
        }
        if let s = placemark.postalCode { // Zip code
            line2 += s
        }
        return  line1 + "\n" + line2
    }
}

