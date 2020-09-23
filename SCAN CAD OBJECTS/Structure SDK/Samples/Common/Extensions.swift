//
//  Extensions.swift
//  Scanner
//
//  Created by Pedro Del Rio Ortiz on 03/04/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import Foundation
import UIKit

public class CustomButton : UIButton {
    
    @IBInspectable public var buttonBorder: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = buttonBorder
            
            let modelName = UIDevice.current.userInterfaceIdiom
            
            if modelName == .pad {
                self.titleLabel?.font = UIFont(name: "System", size: 70.0)
            }
        }
    }
    
    @IBInspectable public var buttonBorderColor: UIColor = .white {
        didSet {
            layer.borderColor = buttonBorderColor.cgColor
        }
    }
}

extension UITextField {
    
    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction(){
        resignFirstResponder()
    }
}

