//
//  ViewController.swift
//  AlefTask
//
//  Created by Leonid Safronov on 31.03.2021.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    static let ages = Array<Int>(0...127).map({ value -> String in
        var result = String(value)
        switch value {
        case 1, 21, 31, 41, 51, 61, 71, 81, 91, 101, 121:
            result += " год"
        case 2...4, 22...24, 32...34, 42...44, 52...54, 62...64, 72...74, 82...84, 92...94, 122...124:
            result += " года"
        case 0, 5...20, 25...30, 35...40, 45...50, 55...60, 65...70, 75...80, 85...90, 95...100, 105...120, 125...127:
            result += " лет"
        default:
            result += ""
        }
        return result
    })

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var surnameField: UITextField!
    @IBOutlet weak var patronymicField: UITextField!
    @IBOutlet weak var agePicker: UIPickerView!
    @IBOutlet weak var childrenTable: UITableView!
    @IBOutlet weak var childrenCountLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    var childrenData: [Child] = []
    
    override func viewDidLoad() { 
        super.viewDidLoad()
        
        pickerSetup()
        
        fieldSetup(field: nameField, key: "name")
        fieldSetup(field: surnameField, key: "surname")
        fieldSetup(field: patronymicField, key: "patronymic")
        
        buttonSetup()
        
        loadData()
        
        updateChildrenCount()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ViewController.ages.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ViewController.ages[row]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 71
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return childrenData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChildCell", for: indexPath) as! ChildrenTableViewCell
        let child = childrenData[indexPath.row]
        
        cell.nameLabel?.text = child.name
        cell.surnameLabel?.text = child.surname
        cell.patronymicLabel?.text = child.patronymic
        cell.ageLabel?.text = ViewController.ages[child.age]
        
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    @IBAction func removeChild(_ sender: UIButton) {
        let point = sender.convert(CGPoint.zero, to: childrenTable)
        if let indexPath = childrenTable.indexPathForRow(at: point) {
            childrenData.remove(at: indexPath.row)
            childrenTable.beginUpdates()
            childrenTable.deleteRows(at: [indexPath], with: .top)
            childrenTable.endUpdates()
            updateChildrenCount()
        }
    }
    
    private func loadData() {
        nameField.text = UserDefaults.standard.string(forKey: "name")
        surnameField.text = UserDefaults.standard.string(forKey: "surname")
        patronymicField.text = UserDefaults.standard.string(forKey: "patronymic")
        agePicker.selectRow(UserDefaults.standard.integer(forKey: "age"), inComponent: 0, animated: true)
        
        let jsonDecoder = JSONDecoder()
        childrenData = try! jsonDecoder.decode([Child].self, from: (UserDefaults.standard.string(forKey: "children")?.data(using: .utf8)! ?? "[]".data(using: .utf8))!)
        
    }
    
    private func fieldSetup(field: UITextField, key: String) {
        field.rx
            .controlEvent([.editingChanged])
            .asObservable()
            .debounce(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .subscribe({ _ in
                UserDefaults.standard.setValue(field.text, forKey: key)
            })
            .disposed(by: disposeBag)
        field.delegate = self
    }
    
    private func pickerSetup() {
        agePicker.delegate = self
        agePicker.dataSource = self
        agePicker.rx
            .itemSelected
            .debounce(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .subscribe({ [weak self] _ in
                UserDefaults.standard.setValue(self?.agePicker.selectedRow(inComponent: 0), forKey: "age")
            })
            .disposed(by: disposeBag)
    }
    
    private func buttonSetup() {
        addButton.rx
            .tap
            .subscribe({ [weak self] _ in
                self?.addNewChild()
            })
            .disposed(by: disposeBag)
    }
    
    func addNewChild() {
        if childrenData.count < 5 {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let inputViewController = storyBoard.instantiateViewController(withIdentifier: "InputViewController") as? InputViewController {
                self.present(inputViewController, animated: true, completion: nil)
                inputViewController.mainController = self
            }
        }
    }
    
    func updateChildrenCount() {
        childrenCountLabel.text = "(\(childrenData.count)/5)"
        if childrenData.count == 5 {
            addButton.tintColor = .gray
        } else {
            addButton.tintColor = .systemBlue
        }
        saveChildren()
    }
    
    func saveChildren() {
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(childrenData)
        let json = String(data: jsonData, encoding: .utf8)
        UserDefaults.standard.setValue(json, forKey: "children")
    }
}

struct Child: Equatable, Codable {
    var name: String = ""
    var surname: String = ""
    var patronymic: String = ""
    var age: Int = 0
    
    static func == (lhs: Child, rhs: Child) -> Bool {
        return
            lhs.name == rhs.name &&
            lhs.surname == rhs.surname &&
            lhs.patronymic == rhs.patronymic &&
            lhs.age == rhs.age
    }
    
    init(name: String, surname: String, patronymic: String, age: Int) {
        self.name = name
        self.surname = surname
        self.patronymic = patronymic
        self.age = age
    }
}

class ChildrenTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var surnameLabel: UILabel!
    @IBOutlet weak var patronymicLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
}
