//
//  MapHeaderGradientView.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

class MapHeaderGradientView: UIView {
    let gradientLayer = CAGradientLayer()
    let flatLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let initialValue = 0.9
        flatLayer.backgroundColor = UIColor.black.withAlphaComponent(CGFloat(initialValue)).cgColor
        
        // Building up an "eased" linear gradient to give a smoother scrim transition.
        // For more information, see: https://css-tricks.com/easing-linear-gradients/
        // The curve here used here is y = -0.9x^{0.3}+0.9 where
        //      x = color alpha value
        //      y = position along gradient
        
        var strideValues = Array(stride(from: 0.0, to: initialValue, by: 0.1))
        strideValues.append(initialValue)
        strideValues.reverse()
        
        gradientLayer.colors = strideValues.map {
            return UIColor.black.withAlphaComponent(CGFloat($0)).cgColor
        }
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.type = .axial
        
        gradientLayer.locations = strideValues.map {
            let alteredValue = -0.9*pow($0, 0.5)+0.9
            return NSNumber(value: alteredValue)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        gradientLayer.removeFromSuperlayer()
        gradientLayer.frame = rect
        layer.addSublayer(gradientLayer)
    }
}
