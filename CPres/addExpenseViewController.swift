//
//  addExpenseViewController.swift
//  CPres
//
//  Created by Antonio Carranza on 3/1/18.
//  Copyright © 2018 Antonio Carranza. All rights reserved.
//

import UIKit
import CoreData

class addExpenseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var amount: UITextField!
    @IBOutlet weak var expenseDescriptionText: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    
    var category: Category!
    var managedObjectContext: NSManagedObjectContext!
    var _fetchedResultsController: NSFetchedResultsController<Expense>? = nil
    
    var fetchedResultsController: NSFetchedResultsController<Expense> {
        if _fetchedResultsController != nil { return _fetchedResultsController! }
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        fetchRequest.predicate = NSPredicate(format: "category = %@", category)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        do {
            try _fetchedResultsController!.performFetch() }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        return _fetchedResultsController!
    }

    //MARK: - Application lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addButton.setTitle("Añadir a \(category.name!)", for: .normal)
        amount.becomeFirstResponder()
        self.tableView.keyboardDismissMode = .onDrag
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "expenseCell", for: indexPath)
        let expense = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withExpense: expense)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, withExpense expense: Expense) {
        let expenseName = expense.name!.capitalized.trimmingCharacters(in: .whitespaces)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm"
        let expenseDate = formatter.string(from: expense.date!)
        
        cell.textLabel?.text = "\(expenseDate) - \(expenseName)"
        cell.detailTextLabel?.text = formatMoney(expense.amount)
    }

    @IBAction func add(_ sender: UIButton) {
        if amount.text != "" {
            let amountToAdd = Double(amount.text!.replacingOccurrences(of: ",", with: "."))!
            if amountToAdd != 0 {
                if expenseDescriptionText.text == "" { expenseDescriptionText.text = category.name?.capitalized }
                let expenseEntity = NSEntityDescription.entity(forEntityName: "Expense", in: managedObjectContext)!
                let expense = NSManagedObject(entity: expenseEntity, insertInto: managedObjectContext)
                expense.setValue(amountToAdd, forKey: "amount")
                expense.setValue(Date(), forKey: "date")
                expense.setValue(expenseDescriptionText.text!.trimmingCharacters(in: .whitespacesAndNewlines).capitalized, forKey: "name")
                expense.setValue(self.category, forKey: "category")
                saveData()
            }
            amount.text = ""
            expenseDescriptionText.text = ""
            tableView.reloadData()
            amount.becomeFirstResponder()
        }
    }

    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            configureCell(tableView.cellForRow(at: indexPath!)!, withExpense: anObject as! Expense)
        case .move:
            configureCell(tableView.cellForRow(at: indexPath!)!, withExpense: anObject as! Expense)
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "expenseDetail" {
            let dvc = segue.destination as! DetailViewController
            let expense = fetchedResultsController.object(at: tableView.indexPathForSelectedRow!)
            dvc.expense = expense
            dvc.managedObjectContext = fetchedResultsController.managedObjectContext
        }
    }
    
    
    func saveData() {
        do {
            try managedObjectContext.save()
            print("Context saved")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        tableView.reloadData()
    }
    
}
