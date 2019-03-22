//
//  CategoriesTableViewController.swift
//  CPres
//
//  Created by Antonio Carranza on 20/2/18.
//  Copyright © 2018 Antonio Carranza. All rights reserved.
//

import UIKit
import CoreData

class CategoriesTableViewController: UITableViewController {

    let initialCategories = ["Alimentacion","Impuestos","Formacion","Labradores","Limpieza","Luz","Medicinas","Regalos","Restaurantes","Ropa","Seguros","Varios","Vivienda","Total"]

    var managedObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        managedObjectContext = appDelegate.persistentContainer.viewContext
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return initialCategories.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        
        // Configure the cell...
        
        let categoryName = initialCategories[indexPath.row]
        var categoriesPredicate: NSPredicate?
        if initialCategories[indexPath.row] != "Total" {
            categoriesPredicate = NSPredicate(format: "name = %@ AND year = %d", categoryName, 2018)
        } else {
            categoriesPredicate = NSPredicate(format: "year = %d", 2018)
        }
        let categoriesFetch = NSFetchRequest<Category>(entityName: "Category")
        categoriesFetch.predicate = categoriesPredicate
        let categories = try! managedObjectContext.fetch(categoriesFetch)

        var total = 0.0
        for category in categories {
            total = total + category.totalExpenses()
        }
        
        let category = initialCategories[indexPath.row]
        cell.textLabel?.text = category
        cell.detailTextLabel?.text = formatMoney(total)
        return cell
    }

}
