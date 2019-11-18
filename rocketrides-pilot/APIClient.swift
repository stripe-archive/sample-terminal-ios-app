//
//  APIClient.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/26/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import StripeTerminal

/**
 Example API client class for talking to your backend.
 For simplicity, this class is a singleton; access the shared instance via
 `APIClient.shared`.
 */
class APIClient {
    static let shared = APIClient()
    static let baseURL = URL(string: "https://example.herokuapp.com")
    
    func capturePaymentIntent(_ paymentIntentId: String, completion: @escaping ErrorCompletionBlock) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        guard let url = URL(string: "/capture_payment_intent", relativeTo: APIClient.baseURL) else {
            fatalError("Invalid backend URL")
        }
        
        let parameters = "payment_intent_id=\(paymentIntentId)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        
        let task = session.dataTask(with: request) {(data, response, error) in
            if let response = response as? HTTPURLResponse, let data = data {
                    switch response.statusCode {
                    case 200..<300:
                        completion(nil)
                    case 402:
                        let description = String(data: data, encoding: .utf8) ?? "Failed to capture payment intent"
                        completion(NSError(domain: "com.stripe-terminal-ios.example", code: 2, userInfo: [NSLocalizedDescriptionKey: description]))
                    default:
                        completion(error ?? NSError(domain: "com.stripe-terminal-ios.example", code: 0, userInfo: [NSLocalizedDescriptionKey: "Other networking error encountered."]))
                    }
            } else {
                completion(error)
            }
        }
        task.resume()
    }
    
    init() {
        if(APIClient.baseURL?.absoluteString == "https://example.herokuapp.com") {
            fatalError("\nPlease change the API client's base URL to be your backend URL.\n\n")
        }
    }
}

extension APIClient: ConnectionTokenProvider {
    func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        guard let url = URL(string: "/connection_token", relativeTo: APIClient.baseURL) else {
            fatalError("Invalid backend URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    // Warning: casting using `as? [String: String]` looks simpler, but isn't safe,
                    // so we cast using `as? [String: Any]` here instead.
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let secret = json?["secret"] as? String {
                        completion(secret, nil)
                    } else {
                        let error = NSError(domain: "com.stripe-terminal-ios.example",
                                            code: 2000,
                                            userInfo: [NSLocalizedDescriptionKey: "Missing `secret` in ConnectionToken JSON response"])
                        completion(nil, error)
                    }
                }
                catch {
                    completion(nil, error)
                }
            }
            else {
                let error = NSError(domain: "com.stripe-terminal-ios.example",
                                    code: 1000,
                                    userInfo: [NSLocalizedDescriptionKey: "No data in response from ConnectionToken endpoint"])
                completion(nil, error)
            }
        }
        task.resume()
    }
}
