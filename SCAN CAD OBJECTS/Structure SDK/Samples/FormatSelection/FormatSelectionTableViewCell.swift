//
//  FormatSelectionTableViewCell.swift
//  Scanner
//
//  Created by Pedro Ortiz on 13/01/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import UIKit

class FormatSelectionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var labelExtension: UILabel?
    @IBOutlet weak var labelProgram: UILabel?
    @IBOutlet weak var labelPriceTime: UILabel?
    @IBOutlet weak var viewContent: UIView?
    @IBOutlet weak var packageLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.accessoryType = selected ? .checkmark : .none
    }
    
    public func bind(format: Format) {
        if let extensionType = format.extensionType,
            let program = format.program,
            let price = format.price,
            let time = format.time {
            
            labelExtension?.text = program
            labelProgram?.text = "\(extensionType)"
            
            if price > 0 {
                labelPriceTime?.text = "US$ \(price) - \(time)H"
            } else if price == -1 {
                labelExtension?.isHidden = true
                labelProgram?.isHidden = true
                labelPriceTime?.isHidden = true
                
                packageLabel?.isHidden = false
            } else {
                labelPriceTime?.text = "GRATUITO"
                labelProgram?.text = " - "
            }
        }
    }
    
}
