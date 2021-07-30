//
//  StoriesMenuView.swift
//  neighbourhood
//
//  Created by iphonovv on 01.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum StoriesMenuEvent {
    case search
}

class StoriesMenuView: UIView {
    
    @IBOutlet var allLabel: DoubleStrokedLabel!
    @IBOutlet var myInterestsLabel: DoubleStrokedLabel!
    @IBOutlet var myLabel: DoubleStrokedLabel!
    
    var eventHandler: ((StoriesMenuEvent) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    deinit {
        self.eventHandler = nil
    }
    
    @IBAction func searchAction(_ sender: Any) {
        self.eventHandler?(.search)
    }
    
    func setActiveLabel(index: Int) {
        let strokedViews = [self.allLabel, self.myInterestsLabel, self.myLabel]
        strokedViews.forEach({$0?.isActive = false})
    
        strokedViews[index]?.isActive = true
    }

    private func initView() {
        loadFromXib(R.nib.storiesMenuView.name, contextOf: StoriesMenuView.self)
        
        self.allLabel.isActive = true
        self.myInterestsLabel.isActive = false
        self.myLabel.isActive = false
        
        self.prepareFilterLabels()
    }
    
    private func prepareFilterLabels() {
        let font = UIFont(name: "Poppins-Bold", size: 12) ?? .boldSystemFont(ofSize: 12)
        let strokeWidth: Float = 8
        let strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        
        self.allLabel?.label?.setStrokeText("All", font: font, color: .white, strokeWidth: strokeWidth, strokeColor: strokeColor)
        self.myInterestsLabel?.label?.setStrokeText("For You", font: font, color: .white, strokeWidth: strokeWidth, strokeColor: strokeColor)
        self.myLabel?.label?.setStrokeText("Created", font: font, color: .white, strokeWidth: strokeWidth, strokeColor: strokeColor)
    }
}
