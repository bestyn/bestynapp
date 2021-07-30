//
//  BaseViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 21.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

class BaseViewController: UIViewController, ErrorHandling {
    
    /// Bottom view constraint for keyboard
    @IBOutlet private weak var bottomViewConstraint: NSLayoutConstraint?
    @IBOutlet var navigationBar: UINavigationBar?

    var isNavigationBarVisible: Bool {
        return true
    }
    
    var isBackButtonVisible: Bool {
        return true
    }
    
    var isBottomPaddingNeeded: Bool {
        return true
    }
    
    var additionalBottomSpace: CGFloat {
        return 0.0
    }
    
    override var navigationController: UINavigationController? {
        return super.navigationController
    }
        
    var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = R.color.blueButton()
        return control
    }()

    lazy var profileNavigationResolver = ProfileNavigationResolver(navigationController: navigationController)
    
    func setupViewUI() { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        setupViewUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        if let navigationBar = navigationBar {
            navigationItem.rightBarButtonItems = navigationBar.topItem?.rightBarButtonItems
            navigationItem.leftBarButtonItems = navigationBar.topItem?.leftBarButtonItems
        }
        navigationController?.setNavigationBarHidden(isNavigationBarVisible, animated: animated)
        navigationItem.setHidesBackButton(!isBackButtonVisible, animated: animated)
        setupNavbar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        navigationItem.rightBarButtonItems = nil
        navigationItem.leftBarButtonItems = nil
        navigationItem.setHidesBackButton(false, animated: animated)
    }
    
    deinit {
        debugPrint("deinit \(name)")
        removeAllGestures(view)
        NotificationCenter.default.removeObserver(self)
    }
}

extension BaseViewController {
    
    func removeAllGestures(_ newView: UIView?) {
        for view in newView?.subviews ?? [] {
            removeAllGestures(view)
        }
        for gesture in newView?.gestureRecognizers ?? [] {
            newView?.removeGestureRecognizer(gesture)
            gesture.removeTarget(self, action: nil)
        }
        newView?.gestureRecognizers = nil
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if bottomViewConstraint != nil {
            bottomViewConstraint!.constant = 0
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if bottomViewConstraint != nil,
            let info = notification.userInfo,
            let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let bottomPadding: CGFloat = {
                if let tabBarHieght: CGFloat = tabBarController?.tabBar.frame.size.height {
                    return tabBarHieght
                }
                return UIApplication.shared.currentWindow?.safeAreaInsets.bottom ?? 0
            }()

            bottomViewConstraint?.constant = keyboardFrame.size.height - bottomPadding
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
}

extension BaseViewController {
    func setupNavbar() {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.tintColor = R.color.mainBlack()
        
        navigationController?.view.backgroundColor = R.color.greyBackground()
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: R.color.mainBlack()!,
            NSAttributedString.Key.font: R.font.poppinsMedium(size: 16)!
        ]
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
