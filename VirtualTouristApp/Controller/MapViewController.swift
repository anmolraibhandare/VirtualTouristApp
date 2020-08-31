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

    var editButtonMode: Bool = false
    var gestureMode: Bool = false
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do{
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("the fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        deletePin.isHidden = true
        navigationItem.rightBarButtonItem = editButtonItem
        editButtonMode = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        setRegion()
        setAnnotations()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deletePin.isHidden = !editing
        editButtonMode = editing
    }
    
    // MARK: Annotations
    
    fileprivate func setAnnotations() {
        let pins = fetchedResultsController.fetchedObjects
        mapView.removeAnnotations(mapView.annotations)
        for pin in pins! {
            addAnnotations(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
        }
    }
    
    fileprivate func setRegion() {
        if let region = UserDefaults.standard.dictionary(forKey: "mapRegion"){
            let center = CLLocationCoordinate2DMake(region["latitude"] as! Double, region["longitude"] as! Double)
            let span = MKCoordinateSpan(latitudeDelta: region["latitudeDelta"] as! Double, longitudeDelta: region["longitudeDelta"] as! Double)
            
            let region = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: Segue to PhotoViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? PhotoViewController {
            let pin = sender as! Pin
            //viewController.pinTap = pin
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureMode = true
        return true
    }
    
    // MARK: Action on map when long pressed
    
    @IBAction func longPressResponse(_ sender: Any) {
        if gestureMode {
            let gestureRecognizer = sender as! UILongPressGestureRecognizer
            let gestureTouchLocation = gestureRecognizer.location(in: mapView)
            let gesturePinCoordinate = mapView.convert(gestureTouchLocation, toCoordinateFrom: mapView)
            addAnnotations(coordinate: gesturePinCoordinate)
            addPin(coordinate: gesturePinCoordinate)
            gestureMode = false
        }
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: DataController.shared.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        saveViewContext()
    }
    
    func addAnnotations(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }
    
    func getpin(latitude: Double, longitude: Double) -> Pin? {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        let predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", latitude,longitude)
        fetchRequest.predicate = predicate
        
        guard let pin = (try? DataController.shared.viewContext.fetch(fetchRequest))!.first else {
            return nil
        }
        return pin
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let pin = getpin(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!) else {
            return
        }
        if isEditing {
            DataController.shared.viewContext.delete(pin)
            saveViewContext()
            mapView.removeAnnotation(view.annotation!)
        } else {
            performSegue(withIdentifier: "PinPhotos", sender: view.annotation?.coordinate)
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
    }
}
