//
//  FinanceModel.swift
//  Finance tracker
//
//  Created by Kurbatov Artem on 14.12.2022.
//

import UIKit
import Foundation


protocol FinaceModelDelegate {
    
    func filterTransactions()
}


class FinanceModel {
    
    var delegate: FinaceModelDelegate?
    
    static let identifier = "transactionCell"
    
    var transactions = [Transaction]()
    
    private let currencyList = [
        (currencyTitle: "Dollar", currencyImageName: "dollarsign", currencySign: "$"),
        (currencyTitle: "Euro", currencyImageName: "eurosign", currencySign: "€"),
        (currencyTitle: "Sterling", currencyImageName: "sterlingsign", currencySign: "£"),
        (currencyTitle: "Yen", currencyImageName: "yensign", currencySign: "¥"),
        (currencyTitle: "Rupee", currencyImageName: "indianrupeesign", currencySign: "₹"),
        (currencyTitle: "Lari", currencyImageName: "larisign", currencySign: "₾"),
        (currencyTitle: "Turkish lira", currencyImageName: "turkishlirasign", currencySign: "₺"),
        (currencyTitle: "Ruble", currencyImageName: "rublesign", currencySign: "₽")
    ]
    

    func createTransactionAlert() -> UIAlertController {
        
        let alert = UIAlertController(title: "New transaction", message: "", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.keyboardType = .numbersAndPunctuation
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            if alert.textFields?[0] != nil && alert.textFields?[0].text != nil {
                let amount = alert.textFields![0].text!
                if let number = Double(amount) {
                    let dateString = self.getDateString()
                    self.saveTransactions(amount: number.round(to: 2), day: dateString.0, month: dateString.1, year: dateString.2)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    func createClearAlert() -> UIAlertController {
     
        let alert = UIAlertController(title: "Clear history", message: "Are you sure you want to clear your history?", preferredStyle: .alert)
        
        let clearAction = UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.clearTransactions()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    func createButton(bgColor: UIColor, fgColor: UIColor, title: String) -> UIButton {
        
        let button = UIButton()
        
        button.configuration = .filled()
        button.configuration?.cornerStyle = .capsule
        button.configuration?.baseBackgroundColor = bgColor
        button.configuration?.baseForegroundColor = fgColor
        button.configuration?.title = title
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }
    
    func getDateString() -> (String, String, String) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        
        let date = Date()
        let dateString = formatter.string(from: date)
        let compontents = dateString.split(separator: "/")
        
        let day = String(compontents[0])
        let month = String(compontents[1])
        let year = String(compontents[2])
        
        return (day, month, year)
    }
    
    
    func calculateTotal(transactions: [Transaction]) -> Double {
        
        var total = 0.0
        
        for transaction in transactions {
            total += transaction.amount
        }
        
        return total.round(to: 2)
    }
    
    // MARK: - Currency section
    
    func setCurrencyImage(button: UIButton) {
        
        var imageName = ""
        
        switch AppSettings.currency {
        case "€":
            imageName = "eurosign"
        case "£":
            imageName = "sterlingsign"
        case "¥":
            imageName = "yensign"
        case "₽":
            imageName = "rublesign"
        case "₹":
            imageName = "indianrupeesign"
        case "₾":
            imageName = "larisign"
        case "₺":
            imageName = "turkishlirasign"
        default:
            imageName = "dollarsign"
        }
        
        button.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    func selectCurrencyMenu(button: UIButton) ->UIMenu {
        
        var actions = [UIAction]()
        
        for currency in currencyList {
            let action = UIAction(title: currency.currencyTitle, image: UIImage(systemName: currency.currencyImageName)) { _ in
                AppSettings.currency = currency.currencySign
                self.delegate?.filterTransactions()
                button.setImage(UIImage(systemName: currency.currencyImageName), for: .normal)
                self.saveCurrency()
            }
            
            actions.append(action)
        }
        
        let menu = UIMenu(title: "Select your currency", children: actions)
        
        return menu
    }
    
    
    // MARK: - User defaults functions
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: AppSettings.transactionsKey)
        }
    }
    
    func loadTransactions() {
        
        if let data = UserDefaults.standard.data(forKey: AppSettings.transactionsKey) {
            
            if let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
                
                transactions = decoded
            }
        }
        delegate?.filterTransactions()
    }
    
    func saveCurrency() {
        
        if let encoded = try? JSONEncoder().encode(AppSettings.currency) {
            UserDefaults.standard.set(encoded, forKey: AppSettings.currancyKey)
        }
    }
    
    func getUserCurrency() {
        
        if let data = UserDefaults.standard.data(forKey: AppSettings.currancyKey) {
            
            if let decoded = try? JSONDecoder().decode(String.self, from: data) {
                
                AppSettings.currency = decoded
            }
        }
    }
    
    //MARK: - Transactions section
    
    func saveTransactions(amount: Double, day: String, month: String, year: String) {
        
        transactions.append(Transaction(amount: amount, day: day, month: month, year: year))
        saveData()
        delegate?.filterTransactions()
    }
    
    func deleteTransaction(transactionID: UUID) {
        
        if let index = transactions.firstIndex(where: { transaction in
            transaction.id == transactionID
        }) {
            self.transactions.remove(at: index)
            saveData()
            delegate?.filterTransactions()
        }
    }
    
    func clearTransactions() {
        
        transactions.removeAll()
        saveData()
        delegate?.filterTransactions()
    }
    
    func sortTransactions() {
        
        transactions.reverse()
        delegate?.filterTransactions()
    }
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
