//
//  UIApplication+CurrentViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/30/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

extension UIApplication {
    var currentViewController: UIViewController? {
        return UIApplication.shared.windows[0].rootViewController?.presentedViewController ?? UIApplication.shared.windows[0].rootViewController
    }
    
    func presentTerminalError(title: String, description: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
        UIApplication.shared.currentViewController?.present(alert, animated: true, completion: nil)
        print("\n\(title)\n\(description)")
    }
}
