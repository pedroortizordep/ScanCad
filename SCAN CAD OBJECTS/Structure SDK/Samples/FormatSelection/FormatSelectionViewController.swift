//
//  FormatSelectionViewController.swift
//  Scanner
//
//  Created by Pedro Ortiz on 13/01/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import UIKit
import MessageUI

@objc class FormatSelectionViewController: UIViewController {
    
    @IBAction func doneFormatsPick(_ sender: UIBarButtonItem) {
        if !selectedFormats.isEmpty {
            
            var amount = 0
            for format in selectedFormats {
                amount += format.price ?? 0
            }
            
            if amount == 0 {
                guard let mailVC = mailVC else { return }
                self.present(mailVC, animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "payment", sender: self)
            }
        }
    }
    
    @IBOutlet weak var tableViewFormats: UITableView?
    @IBOutlet weak var textFieldArchiveName: UITextField!
    
    var mailVC: MFMailComposeViewController?
    var paidMailVC: MFMailComposeViewController?

    var sellingFormats : [Format] = []
    var selectedFormats: [Format] = []
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        textFieldArchiveName.attributedPlaceholder = NSAttributedString(string: "Ex:SKP_Project",
                                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        textFieldArchiveName.delegate = self
        tableViewFormats?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableViewFormats?.deselectAllItems(animated: false)
        self.selectedFormats = []
    }
    
    private func setupTableView() {
        tableViewFormats?.delegate = self
        tableViewFormats?.dataSource = self
        let nib = UINib(nibName: "FormatSelectionTableViewCell", bundle: nil)
        tableViewFormats?.register(nib, forCellReuseIdentifier: "formatCell")
        setFormats()
        tableViewFormats?.reloadData()
    }
    
    @objc func setMailVC(mailVC: MFMailComposeViewController, paidVC: MFMailComposeViewController) {
        self.mailVC = mailVC
        self.paidMailVC = paidVC
    }
    
    func setFormats() {
        
        let archiveName = ""
        
        //let format0 = Format(archiveName: archiveName, extensionType: "", program: "", price: -1, time: 0)
        //let format1 = Format(archiveName: archiveName, extensionType: ".OBJ", program: "MESH", price: 0, time: 0)
        //let format2 = Format(archiveName: archiveName, extensionType: ".STL", program: "", price: 0, time: 0)
        let format3 = Format(archiveName: archiveName, extensionType: ".dwg", program: ".AUTOCAD", price: 19, time: 24)
        //let format4 = Format(archiveName: archiveName, extensionType: ".DWG COR ", program: "Autocad", price: 1, time: 48)
        let format5 = Format(archiveName: archiveName, extensionType: ".skp", program: ".SKETCHUP", price: 19, time: 24)
        //let format6 = Format(archiveName: archiveName, extensionType: ".DWG P.B ", program: "Sketchup", price: 2, time: 48)
        
        //sellingFormats.append(format1)
        //sellingFormats.append(format2)
        sellingFormats.append(format3)
        //sellingFormats.append(format4)
        sellingFormats.append(format5)
        //sellingFormats.append(format0)
        //sellingFormats.append(format6)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "payment" {
            guard let destination = segue.destination as? PaymentViewController else { return }
            
            destination.mailVC = self.mailVC
            destination.paidMailVC = self.paidMailVC
            destination.formats = selectedFormats
            destination.archiveName = textFieldArchiveName.text ?? "Scanner_Sample"
            destination.modalPresentationStyle = .fullScreen
        }
    }

}

extension FormatSelectionViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFieldArchiveName.resignFirstResponder()
    }
}

extension FormatSelectionViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sellingFormats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "formatCell", for: indexPath) as? FormatSelectionTableViewCell else { return UITableViewCell() }
        
        cell.bind(format: sellingFormats[indexPath.row])
        cell.contentView.superview?.backgroundColor = UIColor.white
        cell.backgroundColor = UIColor.white
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.superview?.backgroundColor = UIColor.white
    }
    
}

extension FormatSelectionViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let formatSelected = sellingFormats[indexPath.row]
            selectedFormats.append(formatSelected)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        let formatSelected = sellingFormats[indexPath.row]
        selectedFormats.removeAll(where: { $0.extensionType == formatSelected.extensionType})
    }
}

extension UITableView {
    
    func deselectAllItems(animated: Bool) {
        guard let selectedRows = indexPathsForSelectedRows else { return }
        for indexPath in selectedRows { deselectRow(at: indexPath, animated: animated) }
    }
}
