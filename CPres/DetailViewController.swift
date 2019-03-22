//
//  DetailViewController.swift
//  CPres
//
//  Created by Antonio Carranza on 15/1/18.
//  Copyright © 2018 Antonio Carranza. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var descriptionPicker: UIPickerView!
    
    let initialCategories = ["Alimentacion","Impuestos","Formacion","Labradores","Limpieza","Luz","Medicinas","Regalos","Restaurantes","Ropa","Seguros","Varios","Vivienda","Total"]

    var similarDescriptions: [String] = []
    
    var expense: Expense!
    var managedObjectContext: NSManagedObjectContext!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch pickerView.tag {
        case 0:
            return 1
        case 1:
            return 1
        default:
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return initialCategories.count
        case 1:
            return similarDescriptions.count
        default:
            return 0
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0:
            return initialCategories[row]
        case 1:
            return similarDescriptions.sorted()[row]
        default:
            return "Error..."
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 1:
            self.expense.name = similarDescriptions[row]
        default:
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        amountLabel.text = formatMoney(expense.amount)
        
        let rowCategory = initialCategories.index(of: expense.category!.name!)!
        categoryPicker.selectRow(rowCategory, inComponent: 0, animated: true)
        datePicker.setDate(expense.date!, animated: true)
        
        loadSimilarDescriptions()

        let rowDescriptionIndex = similarDescriptions.index(of: expense.name!.trimmingCharacters(in: .whitespaces).capitalized)
        print(rowDescriptionIndex!)
        descriptionPicker.selectRow(rowDescriptionIndex!, inComponent: 0, animated: true)
    }
    
    func loadSimilarDescriptions() {
        var expenseNames: Set<String> = []
        let startText: String = String(expense.name!.prefix(4)).trimmingCharacters(in: .whitespaces)
        let categoriesFetch = NSFetchRequest<Category>(entityName: "Category")
        categoriesFetch.predicate = NSPredicate(format: "name = %@", expense.category!.name!)
        let categories = try! managedObjectContext.fetch(categoriesFetch)
        similarDescriptions.removeAll()
        expenseNames.removeAll()
        for category in categories {
            let expensesFetch = NSFetchRequest<Expense>(entityName: "Expense")
            expensesFetch.predicate = NSPredicate(format: "category = %@ and name contains[c] %@", category, startText)
            let expenses = try! managedObjectContext.fetch(expensesFetch)
            for expense in expenses {
                expenseNames.insert(expense.name!.trimmingCharacters(in: .whitespaces).capitalized)
            }
        }
        for element in expenseNames.sorted(){
            similarDescriptions.append(element)
        }
        descriptionPicker.reloadAllComponents()
    }
    
    func changeCategoryTo(_ toCategory: String, currentMonth: Int, currentYear: Int) {
        let categoriesFetch = NSFetchRequest<Category>(entityName: "Category")
        categoriesFetch.predicate = NSPredicate(format: "name = %@ AND month = %d AND year = %d", toCategory, currentMonth, currentYear)
        let categories = try! managedObjectContext.fetch(categoriesFetch)
        if categories.count == 1 {
            expense.category = categories.first
        } else {
            print("La categoría no ha podido cambiarse, el número de registros encontrados es \(categories.count)")
        }
    }
    
    @IBAction func normalizeDescription(_ sender: Any) {
        var expenseNames: Set = [expense.name!.trimmingCharacters(in: .whitespacesAndNewlines).capitalized]
        let categoriesFetch = NSFetchRequest<Category>(entityName: "Category")
        categoriesFetch.predicate = NSPredicate(format: "name = %@", expense.category!.name!)
        let categories = try! managedObjectContext.fetch(categoriesFetch)
        for category in categories {
            let expensesFetch = NSFetchRequest<Expense>(entityName: "Expense")
            
            expensesFetch.predicate = NSPredicate(format: "category = %@", category)
            let expenses = try! managedObjectContext.fetch(expensesFetch)
            for expense in expenses {
                expenseNames.insert(expense.name!.trimmingCharacters(in: .whitespacesAndNewlines).capitalized)
            }
        }
        let alertController = UIAlertController(title: "Descripciones existentes actualmente en la categoría \(expense.category!.name!)", message: "Selecciona una descripción", preferredStyle: .actionSheet)
        for option in expenseNames.sorted() {
            let alertOption = UIAlertAction(title: option.capitalized, style: .default) { (action:UIAlertAction) in
                //self.expense.name = option
                self.similarDescriptions.append(option)
                self.similarDescriptions.sort()
                self.descriptionPicker.reloadAllComponents()
                let newDescriptionIndex = self.similarDescriptions.index(of: option)!
                self.descriptionPicker.selectRow(newDescriptionIndex, inComponent: 0, animated: true)
            }
            alertController.addAction(alertOption)
        }
        alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        let newCategory = initialCategories[categoryPicker.selectedRow(inComponent: 0)]
        let componentsNewExpenseDate = NSCalendar.current.dateComponents([.month, .year], from: datePicker.date)
        if (newCategory != expense.category!.name) || expense.date! != datePicker.date {
            changeCategoryTo(newCategory, currentMonth: componentsNewExpenseDate.month!-1, currentYear: componentsNewExpenseDate.year!)
            expense.date = datePicker.date
        }
        expense.name = similarDescriptions[descriptionPicker.selectedRow(inComponent: 0)]
        saveData()
        self.navigationController?.popViewController(animated: true)
    }
    
    func saveData() {
        do {
            try managedObjectContext.save()
            print("Context saved")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
