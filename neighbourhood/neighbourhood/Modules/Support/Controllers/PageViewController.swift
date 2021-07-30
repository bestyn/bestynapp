//
//  PageViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum PageType: String {
    case about
    case terms
    case policy
    
    var slug: String {
        switch self {
        case .about:
            return "about"
        case .terms:
            return "terms-and-conditions"
        case .policy:
            return "privacy-policy"
        }
    }
    
    var title: String {
        switch self {
        case .policy:
            return R.string.localizable.privacyTitle()
        case .terms:
            return R.string.localizable.termsConditionsTitle()
        case .about:
            return R.string.localizable.aboutTitle()
        }
    }
}

final class PageViewController: BaseViewController {
    
    @IBOutlet private weak var textView: UITextView!
    
    private let type: PageType
    private lazy var supportManager: RestSupportManager = RestService.shared.createOperationsManager(from: self, type: RestSupportManager.self)
    
    init(type: PageType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restGetContent()
    }
    
    override func setupViewUI() {
        textView.contentInset = UIEdgeInsets(top: 30, left: 40, bottom: 30, right: 40)
        title = type.title
    }
    
    override var isNavigationBarVisible: Bool {
        return false
    }
}

// MARK: - REST requests
extension PageViewController {
    private func restGetContent() {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        
        supportManager.page(type: type)
            .onComplete { [weak self] (result) in
                guard let self = self else {
                    return
                }
                
                if let page = result.result {
                    self.textView.attributedText = page.content.htmlAttributed(using: R.font.poppinsRegular(size: 15)!,
                                                                               textColor: R.color.mainBlack()!,
                                                                               accentColor: R.color.mainBlack()!)
                }
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
}
