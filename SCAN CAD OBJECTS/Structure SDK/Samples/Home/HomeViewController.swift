//
//  HomeViewController.swift
//  Scanner
//
//  Created by Pedro Del Rio Ortiz on 05/03/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import UIKit
import MessageUI
import AVFoundation

@objc class HomeViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    public var showBundle = false
    
    @IBOutlet weak var fade: UIImageView!
    @IBOutlet weak var logo: UIImageView!
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["support@scancad.tech"])
            //mail.setMessageBody("<p>You're so awesome!</p>", isHTML: true)

            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    @IBAction func scan(_ sender: UIButton) {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                let app: AppDelegate = AppDelegate()
                app.showScanner(self)
            
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            let app: AppDelegate = AppDelegate()
                            app.showScanner(self)
                        }
                    }
                }
            
            case .denied: // The user has previously denied access.
                return

            case .restricted: // The user can't grant access due to restrictions.
                return
            
        @unknown default:
            return
        }
    }
    
    @IBAction func about(_ sender: Any) {
        self.sendEmail()
//        if !openAbout {
//            openAbout = !openAbout
//            let width = view.frame.width
//            let height = view.frame.height
//
//            var finalWidth = width * 0.6
//            var closeHeight = height * 0.07
//
//            let modelName = UIDevice.current.userInterfaceIdiom
//            if modelName == .pad {
//                finalWidth = width * 0.85
//                closeHeight = height * 0.04
//            }
//
//            let aboutRect = CGRect(x: 0, y: 0, width: finalWidth, height: height * 0.7)
//            aboutView = UIView(frame: aboutRect)
//            aboutView.backgroundColor = #colorLiteral(red: 0.5411649346, green: 0.537951529, blue: 0.5436373949, alpha: 1)
//            aboutView.center = view.center
//            aboutView.layer.zPosition = 1000
//
//            let closeRect = CGRect(x: -8, y: -8, width: closeHeight, height: closeHeight)
//            let closeBtn = UIButton(frame: closeRect)
//            closeBtn.setImage(UIImage(named: "close"), for: .normal)
//            closeBtn.contentMode = .center
//            closeBtn.addTarget(self, action: #selector(closeAbout), for: .touchUpInside)
//            closeBtn.backgroundColor = UIColor.white
//            closeBtn.layer.cornerRadius = closeBtn.bounds.width / 2
//            closeBtn.layer.masksToBounds = true
//            closeBtn.clipsToBounds = true
//            closeBtn.imageEdgeInsets = UIEdgeInsets(top: 4,left: 4,bottom: 6,right: 6)
//            closeBtn.layer.zPosition = 10000000
//
//            let textRect = CGRect(x: width * 0.05, y: height * 0.1, width: finalWidth * 0.8, height: height * 0.55)
//            let textView = UITextView(frame: textRect)
//            textView.isUserInteractionEnabled = false
//            textView.backgroundColor = #colorLiteral(red: 0.5411649346, green: 0.537951529, blue: 0.5436373949, alpha: 1)
//            textView.textColor = UIColor.white
//            textView.font = UIFont(name: "Helvetica", size: 20.0)
//            textView.text = "support@scancad.tech"
//
//            aboutView.addSubview(closeBtn)
//            aboutView.addSubview(textView)
//            view.addSubview(aboutView)
//        }
    }
    
    @IBAction func tutorial(_ sender: Any) {
        if !openAbout {
            openAbout = !openAbout
            let width = view.frame.width
            let height = view.frame.height
            
            var finalWidth = width * 0.6
            var closeHeight = height * 0.07
            
            let modelName = UIDevice.current.userInterfaceIdiom
            if modelName == .pad {
                finalWidth = width * 0.85
                closeHeight = height * 0.04
            }
            
            let aboutRect = CGRect(x: 0, y: 0, width: finalWidth, height: height * 0.7)
            aboutView = UIView(frame: aboutRect)
            aboutView.backgroundColor = #colorLiteral(red: 0.5411649346, green: 0.537951529, blue: 0.5436373949, alpha: 1)
            aboutView.center = view.center
            aboutView.layer.zPosition = 1000
            
            let closeRect = CGRect(x: -8, y: -8, width: closeHeight, height: closeHeight)
            let closeBtn = UIButton(frame: closeRect)
            closeBtn.setImage(UIImage(named: "close"), for: .normal)
            closeBtn.contentMode = .center
            closeBtn.addTarget(self, action: #selector(closeAbout), for: .touchUpInside)
            closeBtn.backgroundColor = UIColor.white
            closeBtn.layer.cornerRadius = closeBtn.bounds.width / 2
            closeBtn.layer.masksToBounds = true
            closeBtn.clipsToBounds = true
            closeBtn.imageEdgeInsets = UIEdgeInsets(top: 4,left: 4,bottom: 6,right: 6)
            closeBtn.layer.zPosition = 10000000
            
//            let textRect = CGRect(x: width * 0.05, y: height * 0.1, width: width * 0.6, height: height * 0.55)
//            let textView = UITextView(frame: textRect)
//            textView.isUserInteractionEnabled = false
//            textView.backgroundColor = #colorLiteral(red: 0.5411649346, green: 0.537951529, blue: 0.5436373949, alpha: 1)
//            textView.textColor = UIColor.white
//            textView.font = UIFont(name: "Helvetica", size: 20.0)
//            textView.text = "Texto tutorial..."
            
            let contentSize = CGRect(x: 0, y: 0, width: finalWidth, height: aboutRect.height * 5).size
            
            let scroll = UIScrollView(frame: .zero)
            scroll.frame = aboutRect
            scroll.contentSize = contentSize
            scroll.backgroundColor = UIColor.white
            scroll.showsVerticalScrollIndicator = true
            
            let container = UIView()
            container.backgroundColor = .yellow
            container.frame.size = contentSize
            
            let img1 = UIImageView(frame: CGRect(x: 0, y: 0, width: aboutRect.width, height: aboutRect.height))
            img1.image = UIImage(named: "1")
            
            let img2 = UIImageView(frame: CGRect(x: 0, y: aboutRect.height, width: aboutRect.width, height: aboutRect.height))
                       img2.image = UIImage(named: "2")
            
            let img3 = UIImageView(frame: CGRect(x: 0, y: aboutRect.height * 2, width: aboutRect.width, height: aboutRect.height))
                       img3.image = UIImage(named: "3")
            
            let img4 = UIImageView(frame: CGRect(x: 0, y: aboutRect.height * 3, width: aboutRect.width, height: aboutRect.height))
                       img4.image = UIImage(named: "4")
            
            let img5 = UIImageView(frame: CGRect(x: 0, y: aboutRect.height * 4, width: aboutRect.width, height: aboutRect.height))
                       img5.image = UIImage(named: "5")
            
            //scroll.addSubview(img1)
            
            aboutView.addSubview(scroll)
            scroll.addSubview(container)
            container.addSubview(img1)
            container.addSubview(img2)
            container.addSubview(img3)
            container.addSubview(img4)
            container.addSubview(img5)
            
            aboutView.addSubview(closeBtn)
            view.addSubview(aboutView)
        }
    }
    
//    @IBAction func back(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
//    }
    
    var aboutView: UIView = UIView()
    var openAbout = false
    
    @objc func closeAbout() {
        openAbout = !openAbout
        aboutView.removeFromSuperview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if let _ = defaults.object(forKey: "sensorBought") { } else {
            defaults.set(false, forKey: "sensorBought")
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .landscape
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 1, delay: 1, options: .curveEaseIn, animations: {
            self.fade?.alpha = 0
            self.logo.alpha = 0
        }) { _ in
            self.fade?.removeFromSuperview()
            self.logo.removeFromSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if showBundle {
            showBundle = false
            let width = view.frame.width
            let height = view.frame.height
            
            let aboutRect = CGRect(x: 0, y: 0, width: width * 0.9, height: height * 0.6)
            aboutView = UIView(frame: aboutRect)
            aboutView.backgroundColor = #colorLiteral(red: 0.5411649346, green: 0.537951529, blue: 0.5436373949, alpha: 1)
            aboutView.center = view.center
            aboutView.layer.zPosition = 1000
            
            let closeRect = CGRect(x: -5, y: -5, width: width * 0.08, height: width * 0.08)
            let closeBtn = UIButton(frame: closeRect)
            closeBtn.setImage(UIImage(named: "close"), for: .normal)
            closeBtn.contentMode = .center
            closeBtn.addTarget(self, action: #selector(closeAbout), for: .touchUpInside)
            closeBtn.backgroundColor = UIColor.white
            closeBtn.layer.cornerRadius = width * 0.04
            closeBtn.layer.masksToBounds = true
            closeBtn.clipsToBounds = true
            closeBtn.imageEdgeInsets = UIEdgeInsets(top: 4,left: 4,bottom: 6,right: 6)
            closeBtn.layer.zPosition = 10000000
            
            let textRect = CGRect(x: width * 0.05, y: width * 0.1, width: width * 0.8, height: height * 0.5)
            let textView = UITextView(frame: textRect)
            textView.isUserInteractionEnabled = false
            textView.backgroundColor = #colorLiteral(red: 0.5411649346, green: 0.537951529, blue: 0.5436373949, alpha: 1)
            textView.textColor = UIColor.white
            textView.font = UIFont(name: "Helvetica", size: 20.0)
            textView.text = "Texto bundle..."
            
            aboutView.addSubview(closeBtn)
            aboutView.addSubview(textView)
            view.addSubview(aboutView)
        }
    }

}
