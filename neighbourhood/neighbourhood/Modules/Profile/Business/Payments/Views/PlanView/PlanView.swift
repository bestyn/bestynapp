//
//  PlanView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@objc protocol PlanViewDelegate: class {
    func planViewSelected(_ planView: PlanView)
}

@IBDesignable
class PlanView: UIView {

    @IBOutlet weak var milesLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var checkImageView: UIImageView!

    @IBOutlet weak var delegate: PlanViewDelegate?

    private let selectedColors: [CGColor] = [UIColor(red: 0.467, green: 0.325, blue: 0.918, alpha: 1).cgColor,
                                             UIColor(red: 0.863, green: 0.553, blue: 0.753, alpha: 1).cgColor]

    private let unselectedColors: [CGColor] = [UIColor(red: 0.902, green: 0.894, blue: 0.988, alpha: 1).cgColor,
                                               UIColor(red: 0.996, green: 0.929, blue: 0.945, alpha: 1).cgColor]

    private let selectedTransform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 1, c: -1, d: 9.11, tx: 0.5, ty: -4.55))
    private let unselectedTransform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 0.92, c: -0.92, d: 9.11, tx: 0.46, ty: -4.47))

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0.25, y: 0.5)
        layer.endPoint = CGPoint(x: 0.75, y: 0.5)
        return layer
    }()

    @IBInspectable var title: String? = nil {
        didSet { milesLabel.text = title }
    }

    @IBInspectable var price: String? = nil {
        didSet { priceLabel.text = price }
    }

    @IBInspectable var isSelected: Bool = false {
        didSet { updateState() }
    }

    @IBInspectable var isDisabled: Bool = false {
        didSet { updateState() }
    }

    @IBInspectable var isChecked: Bool = false {
        didSet { checkImageView.isHidden = !isChecked }
    }

    public var planProduct: IAPProductModel? {
        didSet { fillFromPlan() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        loadFromXib(PlanView.identifier, contextOf: PlanView.self)
        cornerRadius = 10
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateState()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        updateState()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
    }

    @IBAction func didTapView(_ sender: Any) {
        delegate?.planViewSelected(self)
    }

    private func updateState() {
        if isDisabled {
            gradientLayer.removeFromSuperlayer()
            backgroundView.backgroundColor = R.color.greyBackground()
            checkImageView.isHidden = true
            milesLabel.textColor = R.color.darkGrey()
            priceLabel.textColor = R.color.darkGrey()
        } else {
            backgroundView.layer.insertSublayer(gradientLayer, at: 0)
            backgroundView.backgroundColor = .clear
            if isSelected {
                gradientLayer.isHidden = true
                backgroundColor = R.color.blueButton()
            } else {
                backgroundColor = .clear
                gradientLayer.isHidden = false
                gradientLayer.colors = unselectedColors
            }
            gradientLayer.transform = isSelected ? selectedTransform : unselectedTransform
            milesLabel.textColor = isSelected ? .white : R.color.mainBlack()
            priceLabel.textColor = isSelected ? .white : R.color.accentBlue()
            updateGradient()
        }
    }

    private func updateGradient() {
        guard gradientLayer.superlayer != nil else {
            return
        }
        gradientLayer.position = backgroundView.center
        gradientLayer.frame = backgroundView.bounds.insetBy(dx: -0.5 * backgroundView.bounds.size.width,
                                                            dy: -0.5 * backgroundView.bounds.size.height)
    }

    private func fillFromPlan() {
        guard let planProduct = planProduct else {
            return
        }
        title = planProduct.name
        price = R.string.localizable.planPricePerMonth(planProduct.priceString ?? "")
    }
}
