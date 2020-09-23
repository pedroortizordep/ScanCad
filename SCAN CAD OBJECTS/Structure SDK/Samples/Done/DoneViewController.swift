//
//  DoneViewController.swift
//  Scanner
//
//  Created by Pedro Ortiz on 06/02/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import UIKit

class DoneViewController: UIViewController {
    
    @IBOutlet weak var labelOne: UILabel?
    @IBOutlet weak var labelTwo: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backToScanner()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    private func backToScanner() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.performSegue(withIdentifier: "finish", sender: self)
        }
    }

}
