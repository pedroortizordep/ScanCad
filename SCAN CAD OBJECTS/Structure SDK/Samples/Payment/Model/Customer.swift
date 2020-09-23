//
//  Customer.swift
//  Scanner
//
//  Created by Pedro Ortiz on 25/01/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import Foundation

struct Documents {
    var type: String?
    var number: String?
}

class Customer {
    var externalId: String?
    var name: String?
    var type: String?
    var country: String?
    var email: String?
    var documents: Documents?
    var phoneNumbers: [String]?
    
//    enum CodingKeys: String, CodingKey {
//        case externalId = "external_id"
//        case name
//        case type
//        case country
//        case email
//        case documents
//        case phoneNumbers = "phone_numbers"
//        case birthday
//    }
    
    init(externalId: String, name: String, type: String, country: String, email: String, documents: Documents, phoneNumbers: [String]) {
        self.externalId = externalId
        self.name = name
        self.type = type
        self.country = country
        self.email = email
        self.documents = documents
        self.phoneNumbers = phoneNumbers
    }
}
