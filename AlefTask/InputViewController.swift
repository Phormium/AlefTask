//
//  InputViewController.swift
//  AlefTask
//
//  Created by Leonid Safronov on 01.04.2021.
//

import UIKit
import RxSwift
import RxCocoa

class InputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var surnameField: UITextField!
    @IBOutlet weak var patronymicField: UITextField!
    @IBOutlet weak var agePicker: UIPickerView!
    @IBOutlet weak var addButton: UIButton!
    
    var mainController: ViewController!
    
    var newChild:Child = Child(name: "", surname: "", patronymic: "", age: 0)
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerSetup()
		
		print("Я тут что-то добавил")
        
        nameField.rx
            .controlEvent([.editingChanged])
            .asObservable()
            .subscribe({ _ in
                self.newChild.name = self.nameField.text ?? ""
            })
            .disposed(by: disposeBag)
        surnameField.rx
            .controlEvent([.editingChanged])
            .asObservable()
            .subscribe({ _ in
                self.newChild.surname = self.surnameField.text ?? ""
            })
            .disposed(by: disposeBag)
        patronymicField.rx
            .controlEvent([.editingChanged])
            .asObservable()
            .subscribe({ _ in
                self.newChild.patronymic = self.patronymicField.text ?? ""
            })
            .disposed(by: disposeBag)
        
        nameField.delegate = self
        surnameField.delegate = self
        patronymicField.delegate = self
        
        buttonSetup()
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    private func pickerSetup() {
        agePicker.delegate = self
        agePicker.dataSource = self
        agePicker.rx
            .itemSelected
            .subscribe({ [weak self] _ in
                self?.newChild.age = self?.agePicker.selectedRow(inComponent: 0) ?? 0
            })
            .disposed(by: disposeBag)
    }
    
    private func buttonSetup() {
        addButton.rx
            .tap
            .subscribe({ [weak self] _ in
                if self?.nameField.text?.count != 0 && self?.surnameField.text?.count != 0 && self?.patronymicField.text?.count != 0 {
                    self?.mainController.childrenData.insert(self!.newChild, at: 0)
                    self?.mainController.childrenTable.beginUpdates()
                    self?.mainController.childrenTable.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                    self?.mainController.childrenTable.endUpdates()
                    self?.mainController.updateChildrenCount()
                    self?.dismiss(animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }
}
