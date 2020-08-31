//
//  MapViewController.swift
//  VirtualTouristApp
//
//  Created by Anmol Raibhandare on 8/31/20.
//  Copyright © 2020 Anmol Raibhandare. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePin: UILabel!

    var currentPins:[Pin] = []
    var editButtonMode: Bool = false
    var gestureMode: Bool = false
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    fileprivate func setUpFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do{
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("the fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Preload the saved pins
    
    func loadSavedPins() -> [Pin]? {
        do {
            var pinArray:[Pin] = []
            let fetchedResultsController = setUpFetchedResultsController()
            try fetchedResultsController.performFetch()
            let pinNumber = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)

            for index in 0..<pinNumber {
                pinArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)) as! Pin)
            }
            return pinArray

        } catch {
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        deletePin.isHidden = true
        navigationItem.rightBarButtonItem = editButtonItem
        editButtonMode = false
        
        let savedPins = loadSavedPins()

        if savedPins != nil {
            currentPins = savedPins!

            for pin in currentPins {
                let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                addAnnotations(fromCoordinate: coordinates)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        //set
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    
    // MARK: Segue to PhotoViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PinPhotos" {
            if let destination = segue.destination as? PhotoViewController {
                let pin = sender as! Pin
                //destination.pinTapped = pin
            }
        }
    }
    
    // MARK: Action on map when long pressed
    
    @IBAction func longPressResponse(_ sender: Any) {
        if gestureMode {
            let gestureRecognizer = sender as! UILongPressGestureRecognizer
            let gestureTouchLocation = gestureRecognizer.location(in: mapView)
            addAnnotations(fromPoint: gestureTouchLocation)
            gestureMode = false
        }
    }
    
    func addAnnotations(fromPoint: CGPoint) {
        let coordinate = Pin(context: DataController.shared.viewContext)
        coordinate.latitude = coordinate.latitude
        coordinate.longitude = coordinate.longitude
        saveContext()
    }

    func addAnnotations(fromCoordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = fromCoordinate
        mapView.addAnnotation(annotation)
    }
    


}
