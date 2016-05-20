//
//  LocationService.swift
//
//  Created by MPELLUS on 1/11/16.
//  Copyright © 2016 meetme. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

@objc protocol LocationServiceDelegate: class {
    optional func LocationServiceisReporting(sender: LocationService, location: CLLocation)
}

class LocationService: NSObject, CLLocationManagerDelegate {
    
    // Public properties
    var reportingInterval: Double = 30 // seconds
    
    // Private properties
    private var locationManager = CLLocationManager()
    private var lastReport = NSDate()
    private var backGroundTask: UIBackgroundTaskIdentifier?
    
    // Delegate Properties
    var delegate: LocationServiceDelegate?
    
    var isLocationServiceDenied: Bool {
        return CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied
    }
    
    deinit {
        self.stopLocationService()
    }
    
    func checkAuthorization() {
        if (!CLLocationManager.locationServicesEnabled()) {
            locationManager.requestAlwaysAuthorization()
        }

        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways)  {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func startLocationService(config: [String: AnyObject]) {
        self.checkAuthorization()
        lastReport = NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: -1, toDate: NSDate(), options: NSCalendarOptions(rawValue: 0))!
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowDeferredLocationUpdatesUntilTraveled(10, timeout: 60000)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        print("tracking started")
    }
    
    func stopLocationService() {
        locationManager.stopUpdatingLocation()
        print("tracking stopped")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        print("Received locations: \(timestamp) \(locations)")
        let elapsedTime = NSDate().timeIntervalSinceDate(lastReport)
        let duration = Int(elapsedTime)
        if duration >= Int(reportingInterval) {
            lastReport = NSDate()
            let newLocation: CLLocation = locations.last!
            print("Sending location: \(timestamp) \(newLocation)")
            self.delegate?.LocationServiceisReporting!(self, location: newLocation)
        }
        runBackgroundTask(reportingInterval)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("\(error)")
        runBackgroundTask(reportingInterval)
    }
    
    private func runBackgroundTask(time: Double) {
        backGroundTask = beginBackgroundUpdateTask()
        dispatch_async(dispatch_get_main_queue()) {
            let timer = NSTimer(timeInterval: time, target: self, selector: #selector(LocationService.startTrackingBg), userInfo: nil, repeats: false)
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
        }
    }
    
    func requestLocation() {
        self.checkAuthorization()
        lastReport = NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: -1, toDate: NSDate(), options: NSCalendarOptions(rawValue: 0))!
        locationManager.requestLocation()
    }
    
    @objc private func startTrackingBg() {
        self.checkAuthorization()
        locationManager.requestLocation()
    }
    
    private func beginBackgroundUpdateTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ })
    }
    
    private func endBackgroundUpdateTask(taskID: UIBackgroundTaskIdentifier) {
        UIApplication.sharedApplication().endBackgroundTask(taskID)
    }

}