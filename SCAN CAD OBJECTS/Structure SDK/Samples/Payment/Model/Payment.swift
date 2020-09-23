//
//  Payment.swift
//  Scanner
//
//  Created by Pedro Ortiz on 24/01/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import Foundation

class Payment {
    var apiKey: String?
    var amount: Int?
    var cardNumber: String?
    var cvv: String?
    var expirationDate: String?
    var cardHolderName: String?
    var customer: Customer?
    var billing: Billing?
    
//    enum CodingKeys: String, CodingKey {
//        case apiKey = "api_key"
//        case amount
//        case cardNumber = "card_number"
//        case cvv = "card_cvv"
//        case expirationDate = "card_expiration_date"
//        case cardHolderName = "card_holder_name"
//        case customer
//        case billing
//    }
    
    init(apiKey: String, amount: Int, cardNumber: String, cvv: String, expirationDate: String, cardHolderName: String, customer: Customer, billing: Billing) {
        self.apiKey = apiKey
        self.amount = amount
        self.cardNumber = cardNumber
        self.cvv = cvv
        self.expirationDate = expirationDate
        self.cardHolderName = cardHolderName
        self.customer = customer
        self.billing = billing
    }
}
