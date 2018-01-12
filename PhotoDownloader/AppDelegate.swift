//
//  AppDelegate.swift
//  PhotoDownloader
//
//  Created by Jonny Kuang on 1/12/18.
//  Copyright © 2018 Jonny Kuang. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "PhotoDownloader")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}

var moc: NSManagedObjectContext {
    return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
}

public extension NSManagedObjectContext {
    
    /// Save context if has change.
    ///
    /// - Parameter isSynchronous: Default to true.
    func saveIfNeeded(isSynchronous: Bool = true) {
        func perform() {
            guard self.hasChanges else { return }
            do {
                try self.save()
            } catch {
                dprint("Save error:", error)
            }
        }
        if isSynchronous {
            moc.performAndWait {
                perform()
            }
        } else {
            moc.perform {
                perform()
            }
        }
    }
}
