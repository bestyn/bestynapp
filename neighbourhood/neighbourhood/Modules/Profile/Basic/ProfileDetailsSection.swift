//
//  ProfileDetailsSection.swift
//  neighbourhood
//
//  Created by Administrator on 16.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

enum ProfileDetailsSection {
    case interests
    case publicInterests
    case images
    
    var title: String {
        switch self {
        case .interests:        return R.string.localizable.myInterestsTitle()
        case .images:           return R.string.localizable.myImagesTitle()
        case .publicInterests:  return R.string.localizable.interestsTitle()
        }
    }
    
    func view(delegatedBy delegate: UIViewController?) -> UIView {
        switch self {
        case .interests:
            let view = MyInterestsView()
            view.screenDelegate = delegate as? MyInterestsViewDelegate
            return view
        case .images:
            let view = PhotoGridView()
            view.delegate = delegate as? PhotoGridViewDelegate
            return view
        case .publicInterests:
            return PublicInterestsView()
        }
    }
}
