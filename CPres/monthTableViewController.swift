//
//  monthTableViewController.swift
//  CPres
//
//  Created by Antonio Carranza on 19/2/18.
//  Copyright © 2018 Antonio Carranza. All rights reserved.
//

import UIKit
import CoreData

class monthTableViewController: UITableViewController {

    let meses = ["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre","Total"]

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
        return meses.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MesCell", for: indexPath)

        // Configure the cell...

        var mesesPredicate: NSPredicate?
        
//        if indexPath.row < meses.count-1 {
//
//        }
        
        if meses[indexPath.row] != "Total" {
            mesesPredicate = NSPredicate(format: "month = %d AND year = %d", indexPath.row, 2018)
        } else {
            mesesPredicate = NSPredicate(format: "year = %d", 2018)
        }
        let mesesFetch = NSFetchRequest<Category>(entityName: "Category")
        mesesFetch.predicate = mesesPredicate
        let categories = try! managedObjectContext.fetch(mesesFetch)

        var total = 0.0
        for category in categories {
            total = total + category.totalExpenses()
        }
        
        let mesData = meses[indexPath.row]
        cell.textLabel?.text = mesData
        cell.detailTextLabel?.text = formatMoney(total)
        return cell
    }
 

}
