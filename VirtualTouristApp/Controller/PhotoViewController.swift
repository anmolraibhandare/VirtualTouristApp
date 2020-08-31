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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return
    }
    
    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noPhotos: UILabel!
    
//    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
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
    
//    fileprivate func setUpFetchedResultsController() {
//        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
//
//        let predicate = NSPredicate(format: "pin == %@", currentPin)
//        fetchRequest.predicate = predicate
//
//        fetchRequest.sortDescriptors = []
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
//        do{
//            try fetchedResultsController.performFetch()
//        } catch {
//            fatalError("the fetch could not be performed: \(error.localizedDescription)")
//        }
//    }
    
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
//        addAnnotation()

        // display results
        let savedPhoto = loadSavedPhotos()
        if savedPhoto != nil && savedPhoto?.count != 0 {
            photos = savedPhoto!
            displaySavedResult()
        } else {
            displayNewResult()
        }
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        setUpFetchedResultsController()
//
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        fetchedResultsController = nil
//    }
    
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
            return photoArray.sorted(by: {$0.index < $1.index})
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
//                    self.addData(flickrImages: images!, coreDataPin: self.corePin)
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
        
        
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
