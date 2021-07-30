//
//  DoubleStrokedLabel.swift
//  neighbourhood
//
//  Created by iphonovv on 27.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class DoubleStrokedLabel: UIView {
    
    @IBOutlet var contentView: UIView?
    @IBOutlet var label: UILabel?
    @IBOutlet var secondStroke: UIView?
    
    var isActive = false {
        willSet {
            self.setActive(newValue)
        }
    }
        
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.contentView?.layer.masksToBounds = true
        self.secondStroke?.layer.masksToBounds = true
        self.contentView?.layer.cornerRadius = 16
        self.secondStroke?.layer.cornerRadius = 16
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        loadFromXib(R.nib.doubleStrokedLabel.name, contextOf: DoubleStrokedLabel.self)
    }
    
    func setActive(_ bool: Bool) {
        if bool {
            self.secondStroke?.layer.borderWidth = 1
            self.secondStroke?.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.2).cgColor
            self.contentView?.layer.borderWidth = 1
            self.contentView?.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        } else {
            self.secondStroke?.layer.borderWidth = 0
            self.secondStroke?.layer.borderColor = nil
            self.contentView?.layer.borderWidth = 0
            self.contentView?.layer.borderColor = nil
        }
    }
}
