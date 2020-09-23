//
//  PagarMeService.swift
//  Scanner
//
//  Created by Pedro Ortiz on 24/01/20.
//  Copyright © 2020 Occipital. All rights reserved.
//

import Foundation

enum APIError:Error {
    case responseProblem
    case decodingProblem
    case encodingProblem
}

class PagarMeService {
    
    func postPayment(payment: Payment, completion: @escaping(Result<Payment?, APIError>) -> Void) {
        
        let urlString = "https://api.pagar.me/1/transactions"
        guard let url = URL(string: urlString) else { return }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "content-Type")
            
            let amountInCents = (payment.amount ?? 0) * 100
            
            let json: [String:Any] = ["api_key": "ak_live_npwuP0l51o7dRajZIcI6isKJOzQ7jS",
                                      "amount": amountInCents as Any,
                                      "card_number": payment.cardNumber as Any,
                                      "card_cvv": payment.cvv as Any,
                                      "card_expiration_date": payment.expirationDate as Any,
                                      "card_holder_name": payment.cardHolderName as Any,
            "customer": [
                "external_id": payment.customer?.externalId as Any,
                "name": payment.customer?.name as Any,
                "type": payment.customer?.type as Any,
                "country": payment.customer?.country as Any,
                "email": payment.customer?.email as Any,
              "documents": [
                [
                    "type": payment.customer?.documents?.type,
                    "number": payment.customer?.documents?.number
                ]
              ],
              "phone_numbers": payment.customer?.phoneNumbers as Any
            ],
            "billing": [
                "name": payment.billing?.name as Any,
              "address": [
                "country": payment.billing?.address?.country,
                "state": payment.billing?.address?.state,
                "city": payment.billing?.address?.city,
                "neighborhood": payment.billing?.address?.neighborhood,
                "street": payment.billing?.address?.street,
                "street_number": payment.billing?.address?.streetNumber,
                "zipcode": payment.billing?.address?.zipcode
              ]
            ],
            "items": [
              [
                "id": "r123",
                "title": "Red pill",
                "unit_price": 10000,
                "quantity": 1,
                "tangible": true
              ]
            ]]
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            request.httpBody = jsonData
            
            let dataTask = URLSession.shared.dataTask(with: request) {data, response, _ in
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let jsonData = data else {
                    completion(.failure(.responseProblem))
                    return
                }
                
                do {
                    //let paymentData = try JSONDecoder().decode(Payment.self, from: jsonData)
                    // check if payment was refused -> status: "refused" in the response
                    completion(.success(nil))
                } catch {
                    completion(.failure(.decodingProblem))
                }
            }
            
            dataTask.resume()
        } catch {
            completion(.failure(.encodingProblem))
        }
        
    }
}
