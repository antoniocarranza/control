//
//  ViewController.swift
//  CPres
//
//  Created by Antonio Carranza on 3/1/18.
//  Copyright © 2018 Antonio Carranza. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    let meses = ["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    let initialCategories = ["Alimentacion","Impuestos","Formacion","Labradores","Limpieza","Luz","Medicinas","Regalos","Restaurantes","Ropa","Seguros","Varios","Vivienda"]

    //TODO: Eliminar la categoría de Total de la base de datos o hacer un gestor de categorias
    
    var managedObjectContext: NSManagedObjectContext!
    var _fetchedResultsController: NSFetchedResultsController<Category>? = nil
    
    var fetchedResultsController: NSFetchedResultsController<Category> {
        if _fetchedResultsController != nil { return _fetchedResultsController! }
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        fetchRequest.predicate = NSPredicate(format: "month = %d AND year = %d", currentMonth, currentYear)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
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

    var currentYear: Int = 2018
    var currentMonth: Int = 0

    //MARK: - Application Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        managedObjectContext = appDelegate.persistentContainer.viewContext
        
        let today = Date()
        let calendar = Calendar.current
        
        currentYear = calendar.component(.year, from: today)
        currentMonth = calendar.component(.month, from: today) - 1
        
        updatePredicate()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        saveData()
    }

    //MARK: - CoreData Functions
    
    func saveData() {
        do {
            try managedObjectContext.save()
            print("Context saved")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        tableView.reloadData()
    }
    
    func updatePredicate() {
        self.navigationItem.title = "\(meses[currentMonth]), \(currentYear)"
        let predicate = NSPredicate(format: "month = %d AND year = %d", currentMonth, currentYear)
        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        if fetchedResultsController.fetchedObjects?.count != initialCategories.count {
            setInitialData(year: currentYear, month: currentMonth)
        }

        tableView.reloadData()
    }
    
    func setInitialData(year: Int, month: Int) {
        let categoryEntity = NSEntityDescription.entity(forEntityName: "Category", in: managedObjectContext)!
        var tmpCategories = initialCategories
        for category in fetchedResultsController.fetchedObjects! {
            let categoryName = category.name!
            if let categoryIndex = tmpCategories.index(of: categoryName) {
                tmpCategories.remove(at: categoryIndex)
            }
        }
        print("Categorias nuevas \(tmpCategories)")
        for initialCategory in tmpCategories {
            let category = NSManagedObject(entity: categoryEntity, insertInto: managedObjectContext)
            category.setValue(year, forKey: "year")
            category.setValue(month, forKey: "month")
            category.setValue(initialCategory, forKey: "name")
        }
        saveData()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    //MARK: - TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CategoryTableViewCell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! CategoryTableViewCell
        let category = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withCategory: category)
        return cell
    }
    
    func configureCell(_ cell: CategoryTableViewCell, withCategory category: Category) {
        if category.budget != 0 {
            cell.title.text = "\(category.name!.capitalized) (\(formatMoney(category.budget)))"
        } else {
            cell.title.text = "\(category.name!.capitalized)"
        }
        
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "showTotalExpenses") {
            cell.detail.text = formatMoney(category.totalExpenses())
        } else {
             cell.detail.text = formatMoney(category.avaliable())
        }
        var cellPercentaje: Float = 0
        if category.budget != 0 {
            cellPercentaje = Float(category.totalExpenses() / category.budget)
        }
        if cellPercentaje > 0.0 && cellPercentaje <= 0.5 {
            cell.percentaje.progressTintColor = UIColor(named: "percentajeLow")
        }
        if cellPercentaje >= 0.5 && cellPercentaje < 0.8 {
            cell.percentaje.progressTintColor = UIColor(named: "percentajeMid")
        }
        if cellPercentaje >= 0.8 {
            cell.percentaje.progressTintColor = UIColor(named: "percentajeHigh")
        }
        cell.percentaje.setProgress(cellPercentaje, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let category = fetchedResultsController.object(at: indexPath)
        let alert = UIAlertController(title: "Presupuesto de \(category.name!.capitalized) para \(meses[currentMonth]), \(currentYear)", message: "Introduce el importe en euros, cada categoria y para cada mes tiene un presupuesto distinto", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = String(category.budget)
            textField.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if let textValue = textField!.text {
                let amountToAdd = Double(textValue.replacingOccurrences(of: ",", with: "."))!
                category.setValue(amountToAdd, forKey: "budget")
                
                self.saveData()
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "categoryAdd" {
            let dvc = segue.destination as! addExpenseViewController
            let category = fetchedResultsController.object(at: tableView.indexPathForSelectedRow!)
            dvc.category = category
            dvc.managedObjectContext = fetchedResultsController.managedObjectContext
        }
    }
    
    @IBAction func previousMonth(_ sender: UIBarButtonItem) {
        currentMonth -= 1
        if currentMonth < 0 {
            currentMonth = 11
            currentYear -= 1
        }
        updatePredicate()
    }
    
    @IBAction func nextMonth(_ sender: UIBarButtonItem) {
        currentMonth += 1
        if currentMonth > 11 {
            currentMonth = 0
            currentYear += 1
        }
        updatePredicate()
    }
}

//MARK: - Auxiliary functions

func formatMoney(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    let number = amount as NSNumber
    formatter.numberStyle = .currency
    return formatter.string(from: number)!
    
}

func formatDate(dateToFormat: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter.string(from: dateToFormat)
}

//MARK: - Extensions


extension Category {
    func totalExpenses() -> Double {
        var totalExpenses = 0.0
        for expense in self.expenses! {
            let tmp = expense as! Expense
            totalExpenses += tmp.amount
        }
        return totalExpenses
    }
    
    func avaliable() -> Double {
        var totalExpenses = 0.0
        for expense in self.expenses! {
            let tmp = expense as! Expense
            totalExpenses += tmp.amount
        }
        return self.budget - totalExpenses
    }
}
