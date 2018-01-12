//
//  FetchedResultsDataProvider.swift
//  Moody
//
//  Created by Florian on 31/08/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import CoreData

enum FetchedResultsUpdate<ResultType : NSFetchRequestResult> {
    
    case insert(IndexPath)
    case update(IndexPath)
    case move(IndexPath, IndexPath)
    case delete(IndexPath)
    
    case insertSection(Int)
    case deleteSection(Int)
}

class FetchedResultsProvider<ResultType : NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    
    let fetchedResultsController: NSFetchedResultsController<ResultType>
    
    var resultsUpdateHandler: (([FetchedResultsUpdate<ResultType>]?) -> Void)?
    
    private var updates: [FetchedResultsUpdate<ResultType>] = []
    
    init(fetchedResultsController: NSFetchedResultsController<ResultType>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()
    }
    
    func reconfigureFetchRequest(_ block: (NSFetchRequest<ResultType>) -> ()) {
        
        if let cacheName = fetchedResultsController.cacheName {
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: cacheName)
        }
        block(fetchedResultsController.fetchRequest)
        do { try fetchedResultsController.performFetch() } catch { fatalError("fetch request failed") }
        resultsUpdateHandler?(nil)
    }
    
    func object(at indexPath: IndexPath) -> ResultType {
        return fetchedResultsController.object(at: indexPath)
    }
    
    func numberOfSections() -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfItems(in section: Int) -> Int {
        guard let sections = fetchedResultsController.sections, section < sections.count else { return 0 }
        return sections[section].numberOfObjects
    }
    

    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updates.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert: updates.append(.insertSection(sectionIndex))
        case .delete: updates.append(.deleteSection(sectionIndex))
        default: break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            updates.append(.insert(newIndexPath!))
        case .update:
            updates.append(.update(indexPath!))
        case .move:
            updates.append(.move(indexPath!, newIndexPath!))
        case .delete:
            updates.append(.delete(indexPath!))
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        resultsUpdateHandler?(updates)
    }
}
