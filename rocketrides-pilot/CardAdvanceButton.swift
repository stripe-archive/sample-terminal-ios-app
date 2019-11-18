//
//  CardAdvanceButton.swift
//  rocketrides-pilot
//
//  Created by James Little on 9/19/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

class CardAdvanceButton: UIButton {
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor(named: "RRGreen")
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
