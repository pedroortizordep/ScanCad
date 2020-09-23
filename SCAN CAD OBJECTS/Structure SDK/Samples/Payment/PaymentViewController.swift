//
//  PaymentViewController.swift
//  Scanner
//
//  Created by Pedro Ortiz on 19/01/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import UIKit
import WebKit
import MessageUI

class PaymentViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var paypalWebView: UIWebView?
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        paypalWebView?.stringByEvaluatingJavaScript(from: "setAmount(\"\(self.amount * 100)\")")
        paypalWebView?.stringByEvaluatingJavaScript(from: "setDescription(\"\(self.desc)\")")
        
        if let scheme = request.url?.scheme {
            if scheme == "scanner" {
                DispatchQueue.main.async {
                    self.paymentDone()
                }
            }
        }
        return true
    }
    
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var formatsNames: UILabel!
    @IBOutlet weak var estimatedTime: UILabel!
    @IBOutlet weak var totalPrice: UILabel!
    @IBOutlet weak var cardNumber: UITextField!
    @IBOutlet weak var expDate: UITextField!
    @IBOutlet weak var cvv: UITextField!
    @IBOutlet weak var holderName: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var document: UITextField!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var country: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var neighborhood: UITextField!
    @IBOutlet weak var street: UITextField!
    @IBOutlet weak var number: UITextField!
    @IBOutlet weak var zipcode: UITextField!
    
    var archiveName = "Scanner_Sample"
    var desc: String = ""
    var formats: [Format] = []
    var time: Int = 0
    var amount: Double = 0.0
    var mailVC: MFMailComposeViewController?
    var paidMailVC: MFMailComposeViewController?
    
    let service = PagarMeService()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        // Adding webView content
        do {
            guard let filePath = Bundle.main.path(forResource: "paypal", ofType: "html")
                else {
                    // File Error
                    print ("File reading error")
                    return
            }

            //let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            let baseUrl = URL(fileURLWithPath: filePath)
            let request = URLRequest(url: baseUrl)
            paypalWebView?.delegate = self
            paypalWebView?.loadRequest(request)
            //paypalWebView?.loadHTMLString(contents as String, baseURL: baseUrl)
            //self.view.addSubview(paypalWebView ?? UIWebView())
        }
        catch {
            print ("File HTML error")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for format in formats {
            if format.price == 0 {
                guard let mailVC = mailVC else { return }
                self.present(mailVC, animated: true, completion: nil)
            }
        }
    }
    
    private func setup() {
        
        cardNumber.delegate = self
        expDate.delegate = self
        cvv.delegate = self
        phone.delegate = self
        number.delegate = self
        zipcode.delegate = self
        holderName.delegate = self
        name.delegate = self
        city.delegate = self
        neighborhood.delegate = self
        street.delegate = self
        state.delegate = self
        email.delegate = self
        document.delegate = self
        country.delegate = self
        
        
        cardNumber.keyboardType = .numberPad
        cardNumber.addDoneButtonOnKeyboard()
        
        expDate.keyboardType = .numberPad
        expDate.addDoneButtonOnKeyboard()
        
        cvv.keyboardType = .numberPad
        cvv.addDoneButtonOnKeyboard()
        
        phone.keyboardType = .numberPad
        phone.addDoneButtonOnKeyboard()
        
        number.keyboardType = .numberPad
        number.addDoneButtonOnKeyboard()
        
        zipcode.keyboardType = .numberPad
        zipcode.addDoneButtonOnKeyboard()
        
        fileName.text = "File Name: \(archiveName)"
        formatsNames.text = "Formats: "
        estimatedTime.text = "Estimated Time: "
        totalPrice.text = "Total: $ "
        
        for format in formats {
            formatsNames.text?.append(" \(format.extensionType ?? "") ")
            desc.append("\(format.extensionType ?? "")")
            time += format.time ?? 0
            amount += Double(format.price ?? 0)
        }
        
        estimatedTime.text?.append(" \(time)")
        totalPrice.text?.append(" \(amount)")
        
        if let expDate = UserDefaults.standard.object(forKey: "expDate") as? String,
            let cardNumber = UserDefaults.standard.object(forKey: "cardNumber") as? String,
            let holderName = UserDefaults.standard.object(forKey: "holderName") as? String,
            let name = UserDefaults.standard.object(forKey: "name") as? String,
            let email = UserDefaults.standard.object(forKey: "email") as? String,
            let document = UserDefaults.standard.object(forKey: "document") as? String,
            let phone = UserDefaults.standard.object(forKey: "phone") as? String,
            let country = UserDefaults.standard.object(forKey: "country") as? String,
            let state = UserDefaults.standard.object(forKey: "state") as? String,
            let city = UserDefaults.standard.object(forKey: "city") as? String,
            let neighborhood = UserDefaults.standard.object(forKey: "neighborhood") as? String,
            let street = UserDefaults.standard.object(forKey: "street") as? String,
            let number = UserDefaults.standard.object(forKey: "number") as? String,
            let zipcode = UserDefaults.standard.object(forKey: "zipcode") as? String {
            
            self.cardNumber.text = cardNumber
            self.expDate.text = expDate
            self.holderName.text = holderName
            self.name.text = name
            self.email.text = email
            self.document.text = document
            self.phone.text = phone
            self.country.text = country
            self.state.text = state
            self.city.text = city
            self.neighborhood.text = neighborhood
            self.street.text = street
            self.number.text = number
            self.zipcode.text = zipcode
        }
    }
    
    private func paymentDone() {
        let alert = UIAlertController(title: "Success", message: "Your payment is done.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Ok", style: .default) { _ in
            
            guard let paidMail = self.paidMailVC else { return }
            paidMail.setSubject("PAID 3D MODEL, PLEASE, SEND IT TO US!")
            paidMail.setMessageBody("Teste", isHTML: false)
            paidMail.setToRecipients(["sensorcanvas@gmail.com"])
            paidMail.mailComposeDelegate = self
            self.present(paidMail, animated: true, completion: nil)
            
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func paymentFail() {
        let alert = UIAlertController(title: "Failed!", message: "Your payment was not completed. Check your credit card data and try again.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Ok", style: .default) { _ in
            
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }

}

extension PaymentViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

extension PaymentViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            self.performSegue(withIdentifier: "done", sender: self)
        }
    }
}
