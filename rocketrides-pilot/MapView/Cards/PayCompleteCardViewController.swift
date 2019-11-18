//
//  PayCardViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

class PayCompleteCardViewController: UIViewController {
    
    let outerStackView = UIStackView()
    let paymentSucceededLabel = UILabel()
    let paymentAmount = UILabel()
    let cardAdvanceButton = CardAdvanceButton()
    let ratingController = RatingViewController()
    
    var cardCycleDelegate: CardCycleDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        paymentSucceededLabel.text = "Payment succeeded"
        paymentSucceededLabel.textColor = .secondaryLabel
        paymentSucceededLabel.textAlignment = .center
        
        paymentAmount.textColor = .label
        paymentAmount.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        paymentAmount.textAlignment = .center
        
        cardAdvanceButton.setTitle("Pick up new rider", for: .normal)
        cardAdvanceButton.addTarget(self, action: #selector(advanceCard), for: .touchUpInside)
        
        addChild(ratingController)
        ratingController.didMove(toParent: self)
        
        outerStackView.addArrangedSubview(paymentSucceededLabel)
        outerStackView.addArrangedSubview(paymentAmount)
        outerStackView.addArrangedSubview(ratingController.view)
        outerStackView.addArrangedSubview(cardAdvanceButton)
        
        outerStackView.axis = .vertical
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.spacing = 8
        view.addSubview(outerStackView)
        outerStackView.anchorToSuperviewAnchors(withInsets: UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let fullString = NSMutableAttributedString(string: Ride.progress.priceString ?? "$12.80")
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = UIImage(named: "checkmark")
        let image1String = NSMutableAttributedString(attachment: image1Attachment)
        fullString.append(NSAttributedString(string: " "))
        fullString.append(image1String)

        paymentAmount.attributedText = fullString
        
        paymentSucceededLabel.text = "Payment succeeded"
    }
    
    @objc
    func advanceCard() {
        guard let delegate = cardCycleDelegate else {
            return
        }
        
        Ride.iterate()
        
        delegate.cycle()
        ratingController.reset()
    }
}

class RatingViewController: UIViewController {
    let stackView = UIStackView()
    let starStackView = UIStackView()
    let profileImage = UIImageView()
    
    let ratingTitleLabel = UILabel()
    let thanksLabel = UILabel()
    
    let starImages = [
        UIImage(named: "star")?.withRenderingMode(.alwaysOriginal),
        UIImage(named: "star")?.withRenderingMode(.alwaysOriginal),
        UIImage(named: "star")?.withRenderingMode(.alwaysOriginal),
        UIImage(named: "star")?.withRenderingMode(.alwaysOriginal),
        UIImage(named: "star")?.withRenderingMode(.alwaysOriginal),
    ]
    
    var starButtons: [RatingButton] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        for (index, image) in starImages.enumerated() {
            let button = RatingButton(type: .system)
            button.setImage(image, for: .normal)
            button.ratingValue = index + 1
            button.addTarget(self, action: #selector(rateRide(_:)), for: .touchUpInside)
            starButtons.append(button)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        starButtons.forEach {
            starStackView.addArrangedSubview($0)
        }
        
        ratingTitleLabel.text = "How was the ride?"
        if #available(iOS 13.0, *) {
            ratingTitleLabel.textColor = .label
        } else {
            // Fallback on earlier versions
        }
        ratingTitleLabel.textAlignment = .center
        
        if #available(iOS 13.0, *) {
            thanksLabel.textColor = .secondaryLabel
        } else {
            // Fallback on earlier versions
        }
        thanksLabel.numberOfLines = 0
        thanksLabel.textAlignment = .center
        thanksLabel.text = " "
        
        starStackView.distribution = .equalCentering
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.anchorToSuperviewAnchors(withInsets: UIEdgeInsets(top: 36, left: 48, bottom: 24, right: 48))
        
        stackView.addArrangedSubview(ratingTitleLabel)
        stackView.addArrangedSubview(starStackView)
        stackView.addArrangedSubview(thanksLabel)
        
    }
    
    @objc
    func rateRide(_ sender: UIButton) {
        guard let rating = (sender as? RatingButton)?.ratingValue else { return }
        for (index, button) in starButtons.enumerated() {
            if(index < rating) {
                button.setImage(UIImage(named: "star-filled")?.withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                button.setImage(UIImage(named: "star")?.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
        
        
        switch rating {
        case 1:
            thanksLabel.text = "Bummer!"
        case 2:
            thanksLabel.text = "At least it's not 1!"
        case 3:
            thanksLabel.text = "Solidly mediocre."
        case 4:
            thanksLabel.text = "Good, but it was chilly."
        case 5:
            thanksLabel.text = "Literally the best!"
        default:
            fatalError()
        }
    }
    
    func reset() {
        for button in starButtons {
            button.setImage(UIImage(named: "star")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        thanksLabel.text = " "
    }
}

class RatingButton: UIButton {
    var ratingValue: Int = 0
}
