//
//  ToolsViewController.swift
//  CPres
//
//  Created by Antonio Carranza on 12/1/18.
//  Copyright © 2018 Antonio Carranza. All rights reserved.
//

import UIKit
import CoreData

class ToolsViewController: UIViewController, NSFetchedResultsControllerDelegate {
    var managedObjectContext: NSManagedObjectContext!
    var _fetchedResultsController: NSFetchedResultsController<Expense>? = nil
    
    var fetchedResultsController: NSFetchedResultsController<Expense> {
        if _fetchedResultsController != nil { return _fetchedResultsController! }
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.fetchBatchSize = 20
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

    @IBOutlet weak var showTotalExpensesSwitchInfo: UILabel!
    
    
    @IBAction func exportData(_ sender: UIButton) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        managedObjectContext = appDelegate.persistentContainer.viewContext

        let fileName = "expenses.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Fecha,Categoria,Descripcion,Cantidad\n"
        let expenses: [Expense] = fetchedResultsController.fetchedObjects!
        
        for expense in expenses {
            let localExpense: String = String(expense.amount).replacingOccurrences(of: ".", with: ",")
            let expenseDescription = expense.name!.trimmingCharacters(in: .whitespacesAndNewlines)
            let newLine = "\"\(expense.date!)\",\"\(expense.category!.name!)\",\"\(expenseDescription)\",\"\(localExpense)\"\n"
            csvText.append(newLine)
        }
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        
        let vc = UIActivityViewController(activityItems: [path as Any], applicationActivities: [])
        present(vc, animated: true, completion: nil)
        
        vc.excludedActivityTypes = [
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo,
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.openInIBooks]
        
    }
    
    @IBAction func showAmountExpenses(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        defaults.set(sender.isOn, forKey: "showTotalExpenses")
        updateLabels()
    }
    
    @IBOutlet weak var showTotalExpensesSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let defaults = UserDefaults.standard
        self.showTotalExpensesSwitch.setOn(defaults.bool(forKey: "showTotalExpenses"), animated: true)
        updateLabels()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateLabels() {
        if showTotalExpensesSwitch.isOn {
            showTotalExpensesSwitchInfo.text = "Mostrando el importe consumido"
        } else {
            showTotalExpensesSwitchInfo.text = "Mostrando el importe disponible"
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
