//
//  Billing.swift
//  Scanner
//
//  Created by Pedro Ortiz on 25/01/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import Foundation

struct Address {
    var country: String?
    var state: String?
    var city: String?
    var neighborhood: String?
    var street: String?
    var streetNumber: String?
    var zipcode: String
}

class Billing {
    var name: String?
    var address: Address?
    
//    enum CodingKeys: String, CodingKey {
//        case name
//        case address
//    }
    
    init(name: String, address: Address) {
        self.name = name
        self.address = address
    }
}
