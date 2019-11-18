//
//  UIView+Layout.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

extension UIView {
    @discardableResult
    public func anchorToSuperviewAnchors(withInsets insets: UIEdgeInsets = UIEdgeInsets.zero) -> (top: NSLayoutConstraint, leading: NSLayoutConstraint, trailing: NSLayoutConstraint, bottom: NSLayoutConstraint) {
        guard let superview = superview else {
            fatalError("must have a superview to anchor to")
        }
        
        let top = topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top)
        let leading = leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left)
        let trailing = superview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.right)
        let bottom = superview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom)
        
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
        return (top, leading, trailing, bottom)
    }
}
