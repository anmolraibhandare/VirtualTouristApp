//
//  PhotoViewController.swift
//  VirtualTouristApp
//
//  Created by Anmol Raibhandare on 8/31/20.
//  Copyright © 2020 Anmol Raibhandare. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PhotoViewController: UIViewController, UICollectionViewDelegate ,UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noPhotos: UILabel!
    
    var coordinate: CLLocationCoordinate2D!
    let spacing:CGFloat = 5
    let totalCells:Int = 25
    var currentPin: Pin!
    
    var photos: [Photo] = []
    var toDelete: [Int] = []{

        didSet {
            if toDelete.count > 0 {
                newCollection.setTitle("Remove Pictures", for: .normal)
            } else {
                newCollection.setTitle("New Collection", for: .normal)
            }
        }
    }
    
    func setUpFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", currentPin)

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Flowlayout
        
        let gap = 2.0
        let dimension = (Double(self.view.frame.size.width) - (2 * gap)) / 3.0

        flowLayout.minimumLineSpacing = spacing
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)

        // Collection view delegate and data source assigned to self
        collectionView.delegate = self
        collectionView.dataSource = self

        // new collection button is displayed
        newCollection.isHidden = false
        noPhotos.isHidden = true

        collectionView.allowsMultipleSelection = true
        addAnnotation()

        // display results
        let savedPhoto = loadSavedPhotos()
        if savedPhoto != nil && savedPhoto?.count != 0 {
            photos = savedPhoto!
            displaySavedResult()
        } else {
            displayNewResult()
        }
    }
    
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        noPhotos.isHidden = !editing
    }
    
    // MARK: Action when new collection button is pressed
    
    @IBAction func newCollectionButtonResult(_ sender: Any) {

        if toDelete.count > 0 {
            removePhotos()
            unselectAll()
            photos = loadSavedPhotos()!
            displaySavedResult()
        } else {
            displayNewResult()
        }
    }
    
    // MARK: Preload the saved pins

    func loadSavedPhotos() -> [Photo]? {
        do {
            var photoArray:[Photo] = []
            let fetchedResultsController = setUpFetchedResultsController()
            try fetchedResultsController.performFetch()
            let photoNumber = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)

            for index in 0..<photoNumber {
                photoArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)) as! Photo)
            }
            return photoArray
        } catch {
            return nil
        }
    }
    
    // unselelect all the selected pins
    
    func unselectAll() {
        for index in collectionView.indexPathsForSelectedItems! {
            collectionView.deselectItem(at: index, animated: false)
            collectionView.cellForItem(at: index)?.contentView.alpha = 1
        }
    }
    
    // remove photos

    func removePhotos() {
        for index in 0..<photos.count {
            if toDelete.contains(index) {
                DataController.shared.viewContext.delete(photos[index])
            }
        }
        do {
            try DataController.shared.saveContext()
        } catch {
            print("Remove Failed")
        }
        toDelete.removeAll()
    }
    
    // display results
    
    func displaySavedResult() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    // display new results after new collection button is tapped
    
    func displayNewResult(){
        newCollection.isEnabled = false
        deleteExisting()
        photos.removeAll()
        collectionView.reloadData()

        
        getFlickrImages{ (images) in
            if images != nil {
                DispatchQueue.main.async {
                    self.addData(flickrImages: images!, coreDataPin: self.currentPin)
                    self.photos = self.loadSavedPhotos()!
                    self.displaySavedResult()
                    self.newCollection.isEnabled = true
                }
            }
        }
    }
    
    func deleteExisting() {
        for photo in photos {
            DataController.shared.viewContext.delete(photo)
        }
    }
    
    // MARK: Get flickr images for the location
    
    func getFlickrImages(completion: @escaping (_ result: [FlickrImage]?) -> Void) {
        
        var resultImages:[FlickrImage] = []
        FlickrAPI.getImage(latitude: coordinate.latitude, longitude: coordinate.longitude) { (success, flickrImages) in
            if success {
                if flickrImages!.count > self.totalCells {
                    var temp:[Int] = []

                    while temp.count < self.totalCells {
                        let random = arc4random_uniform(UInt32(flickrImages!.count))
                        if !temp.contains(Int(random)) {
                            temp.append(Int(random))
                        }
                    }
                    for random in temp {
                        resultImages.append(flickrImages![random])
                    }
                    completion(resultImages)
                } else {
                    completion(flickrImages!)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func addData(flickrImages: [FlickrImage], coreDataPin: Pin){
        for image in flickrImages {
            do{
                let index = flickrImages.firstIndex{$0 === image}!
                let photo = photos[index] as! [String:AnyObject]
                
                guard let imageurl = photo[image.imageURL()] as? String else {
                    return
                }
                
                let addPhoto = Photo(context: DataController.shared.viewContext)
                addPhoto.pin = coreDataPin
                addPhoto.imageURL = imageurl
                try DataController.shared.saveContext()
            } catch {
                print("Add Failed")
            }
        }
    }

    // add annotation on map
    
    func addAnnotation() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: true)
    }
    
        // MARK: Collection view Delegate functions
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return photos.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
            cell.initPhotos(photos[indexPath.row])
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            toDelete = selectToDelete(indexPath: collectionView.indexPathsForSelectedItems!)
            let cell = collectionView.cellForItem(at: indexPath)
            DispatchQueue.main.async {
                cell?.contentView.alpha = 0.5
            }
        }

        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            toDelete = selectToDelete(indexPath: collectionView.indexPathsForSelectedItems!)
            let cell = collectionView.cellForItem(at: indexPath)
            DispatchQueue.main.async {
                cell?.contentView.alpha = 1
            }
        }

        func selectToDelete(indexPath: [IndexPath]) -> [Int] {
            var selected:[Int] = []
            for index in indexPath {
                selected.append(index.row)
            }
            return selected
        }
        
        // MARK: Collection view flow layout Delegate functions

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return spacing
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let bounds = collectionView.bounds
    //        let width = UIScreen.main.bounds.width / 3 - spacing
    //        let height = width
            return CGSize(width: bounds.width / 2 , height: bounds.height / 4)
        }
    
}
