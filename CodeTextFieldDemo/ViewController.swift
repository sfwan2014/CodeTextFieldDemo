//
//  ViewController.swift
//  CodeTextFieldDemo
//
//  Created by tezwez on 2020/3/30.
//  Copyright © 2020 tezwez. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DCTextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let textField = DCTextField(frame: CGRect(x: 40, y: 200, width: UIScreen.main.bounds.size.width-80, height: 55))
        view.addSubview(textField)
//        textField.isSecureTextEntry = true
        textField.delegate = self
        textField.font = UIFont(name: "PingFangSC-Semibold", size: 39)!
        textField.style = .border
        textField.keyboardType = UIKeyboardType.decimalPad
        textField.cursorColor = .red
    }

    func textFieldDidEndEdit(_ textField: DCTextField) {
        print(textField.text ?? "")
    }
    
    func textFieldReturn(_ textField: DCTextField) -> Bool {
        print(textField.text ?? "")
        return false
    }

}

