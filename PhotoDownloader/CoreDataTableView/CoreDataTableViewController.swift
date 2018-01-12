//
//  CoreDataTableViewController.swift
//  AuroraBrowser
//
//  Created by Jonny on 1/12/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit
import CoreData

class CoreDataTableViewController<ResultType : NSFetchRequestResult, Cell : UITableViewCell>: TableViewController {
    
    //    func updatePredicate(_ predicate: NSPredicate) {
    //        let provider = fetchedResultsProvider
    //        provider?.fetchedResultsController.fetchRequest.predicate = predicate
    //        self.fetchedResultsProvider = provider
    //    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForCellReuseIdentifier()
        updateSearchResults(for: searchController)
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        super.updateSearchResults(for: searchController)
        updateHintLabelVisibility()
    }
    
    private func updateHintLabelVisibility() {
        let fetchCount = fetchedResultsProvider?.fetchedResultsController.fetchedObjects?.count ?? 0
        hintLabel.isHidden = fetchCount > 0
        tableView.tableFooterView = fetchCount > 0 ? nil : UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.001))
    }
    
    /// Override to perform custom register.
    ///
    /// The default implementation is `tableView.register(Cell.self, forCellReuseIdentifier: "\(Cell.self)")`
    func registerForCellReuseIdentifier() {
        tableView.register(Cell.self, forCellReuseIdentifier: "\(Cell.self)")
    }
    
    override final func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsProvider?.fetchedResultsController.sections?[section].name
    }
    
    override final func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsProvider?.numberOfSections() ?? 0
    }
    
    override final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsProvider?.numberOfItems(in: section) ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(Cell.self)", for: indexPath) as! Cell
        bind(cell: cell, withObject: fetchedResultsProvider!.object(at: indexPath))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = fetchedResultsProvider!.object(at: indexPath)
        didSelect(object, at: indexPath)
    }
    
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        guard editingStyle == .delete else { return }
//        let objectToDelete = fetchedResultsProvider!.object(at: indexPath)
//        delete(objectToDelete)
//    }
    
    func bind(cell: Cell, withObject object: ResultType) {
        fatalError("Subclass must implement this method.")
    }
    
    func didSelect(_ object: ResultType, at indexPath: IndexPath) {
        fatalError("Subclass must implement this method.")
    }
    
//    func delete(_ object: ResultType) {
//        fatalError("Subclass must implement this method.")
//    }
    
    var fetchedResultsProvider: FetchedResultsProvider<ResultType>? {
        didSet {
            defer { tableView?.reloadData() }
            
            guard let fetchedResultsProvider = fetchedResultsProvider else { return }
            
            fetchedResultsProvider.resultsUpdateHandler = { [weak self] updates in
                guard let `self` = self,
                    let tableView = self.tableView else { return }
                
                self.updateHintLabelVisibility()
                
                guard let updates = updates, tableView.window != nil else {
                    tableView.reloadData()
                    return
                }
                
                func performUpdates() {
                    for update in updates {
                        switch update {
                        case .insert(let indexPath):
                            tableView.insertRows(at: [indexPath], with: .automatic)
                        case .move(let at, let to):
                            tableView.moveRow(at: at, to: to)
                        case .update(let indexPath):
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                        case .delete(let indexPath):
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        case .insertSection(let index):
                            tableView.insertSections(IndexSet(integer: index), with: .automatic)
                        case .deleteSection(let index):
                            tableView.deleteSections(IndexSet(integer: index), with: .automatic)
                        }
                    }
                }
                
                if #available(iOS 11.0, *) {
                    tableView.performBatchUpdates({
                        performUpdates()
                    }, completion: nil)
                } else {
                    tableView.beginUpdates()
                    performUpdates()
                    tableView.endUpdates()
                }
            }
        }
    }
}

