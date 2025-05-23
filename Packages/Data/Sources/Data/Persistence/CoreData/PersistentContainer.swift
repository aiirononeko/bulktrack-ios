//
//  PersistentContainer.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import CoreData

public final class PersistentContainer: @unchecked Sendable {
    public static let shared = PersistentContainer()
    
    private init() {}
    
    public lazy var persistentContainer: NSPersistentContainer = {
        guard let modelURL = Bundle.module.url(forResource: "BulkTrack", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model")
        }
        
        let container = NSPersistentContainer(name: "BulkTrack", managedObjectModel: model)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    public var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
