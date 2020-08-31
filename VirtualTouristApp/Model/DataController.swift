//
//  DataController.swift
//  VirtualTouristApp
//
//  Created by Anmol Raibhandare on 8/31/20.
//  Copyright © 2020 Anmol Raibhandare. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    // Persistant Container
    let persistentContainer: NSPersistentContainer
    
    static let shared = DataController(modelName: "VirtualTouristApp")
    
    // Storing Context
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext!
    
    // Initializing Container
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        backgroundContext = persistentContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        
    }
    
    // Load Store
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else{
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }
}

// MARK: Auto save

extension DataController{
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        guard interval > 0 else {
            print("cannot set negative  autosave interval")
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
    
    func saveContext() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
}

