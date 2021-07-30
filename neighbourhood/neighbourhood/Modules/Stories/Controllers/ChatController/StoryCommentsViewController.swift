//
//  StoryCommentsViewController.swift
//  neighbourhood
//
//  Created by iphonovv on 26.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class StoryCommentsViewController: CommentsController, BottomMenuPresentable {
    
    var transitionManager: BottomMenuPresentationManager! = .init()
    
    var presentedViewHeight: CGFloat {
        return self.view.frame.height * 0.9
    }
    
    @IBOutlet var dateLabel: UILabel?
    
    override func viewDidLoad() {
        self.withPost = false
        super.viewDidLoad()
        self.chatView.attachmentButton.setImage(R.image.attach_stories_icon(), for: .normal)
        
        self.dateLabel?.text = Date().postDateTimeString
    }
}
