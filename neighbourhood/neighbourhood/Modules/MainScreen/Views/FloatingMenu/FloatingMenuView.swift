//
//  FloatingMenuView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum FloatingMenuItem {
    case stories
    case profile
    case addPost
    case neighbourgs
    case chats
    case home
    case more
    case bestyn
}

protocol FloatingMenuViewDelegate: class {
    func didSelectedMenuItem(_ item: FloatingMenuItem)
    func canChangeMenuItem(_ item: FloatingMenuItem, completion: @escaping (Bool) -> Void)
}

class FloatingMenuView: UIView {

    @IBOutlet private weak var dimmingView: UIView!
    @IBOutlet weak var floatingStackView: UIStackView!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var avatarView: MediumAvatarView!
    @IBOutlet weak var collapsedStackView: UIStackView!
    @IBOutlet weak var unreadIndicatorView: UIView!
    @IBOutlet weak var chatUnreadIndicatorView: UIView!

    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var stories: UIButton!
    @IBOutlet weak var bestynButton: UIButton!
    @IBOutlet weak var authorizedMenuView: UIView!

    static var selectedItem: FloatingMenuItem = .stories

    var profilesWithUnreadMessages: [Int] = []
    
    private var isOpen: Bool = false {
        didSet {
            if isOpen == oldValue {
                return
            }
            DispatchQueue.main.async {
                self.updateOpenState(animated: true)
            }
        }
    }

    public weak var delegate: FloatingMenuViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    deinit {
        removeObservers()
    }

    private func initView() {
        loadFromXib(R.nib.floatingMenuView.name, contextOf: FloatingMenuView.self)
        updateOpenState(animated: false)
        setupObservers()
        updateIndicatorState()
        setupTouchHandlers()
        updateSelectedState()
        authorizedMenuView.isHidden = ArchiveService.shared.tokenModel == nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        update()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isOpen, !floatingStackView.frame.contains(point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    @IBAction func didTapToggle(_ sender: Any) {
        isOpen.toggle()
    }

    @IBAction func didTapAvatarView(_ sender: Any) {
        menuItemSelected(.profile)
    }

    @IBAction func didTapStories(_ sender: Any) {
        self.stories?.isHidden = true
        self.bestynButton?.isHidden = false
        
        menuItemSelected(.stories)
    }

    @IBAction func didTapBestyn(_ sender: Any) {
        menuItemSelected(.bestyn)
    }
    
    @IBAction func didTapAddPost(_ sender: Any) {
        menuItemSelected(.addPost)
    }

    @IBAction func didTapNeighbourgs(_ sender: Any) {
        menuItemSelected(.neighbourgs)
    }

    @IBAction func didTapChat(_ sender: Any) {
        menuItemSelected(.chats)
    }

    @IBAction func didTapHome(_ sender: Any) {
        menuItemSelected(.home)
    }

    @IBAction func didTapMore(_ sender: Any) {
        menuItemSelected(.more)
    }    
}

// MARK: - Logic

extension FloatingMenuView {
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateUnreadIndicator), name: .chatUnreadMessageServiceUpdateUnreadMessageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .profileDidChanged, object: nil)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupTouchHandlers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))
        dimmingView.addGestureRecognizer(tapRecognizer)
    }

    @objc private func dimmingViewTapped() {
        guard isOpen else {
            return
        }
        self.isOpen = false
    }

    private func updateOpenState(animated: Bool) {
        let toggle = {
            self.collapsedStackView.isHidden = !self.isOpen
            var image = R.image.menu_toggle_icon()
            if !self.isOpen {
                image = image?.rotate(radians: .pi)
            }
            self.toggleButton.setImage(image, for: .normal)
            self.dimmingView.alpha = self.isOpen ? 1 : 0
            self.floatingStackView.setNeedsLayout()
            self.updateSelectedState()
        }
        if let currentProfileID = ArchiveService.shared.currentProfile?.id {
            if isOpen {
                unreadIndicatorView.isHidden = profilesWithUnreadMessages.filter({$0 != currentProfileID}).count == 0
                chatUnreadIndicatorView.isHidden = !profilesWithUnreadMessages.contains(currentProfileID)
            } else {
                chatUnreadIndicatorView.isHidden = true
                unreadIndicatorView.isHidden = profilesWithUnreadMessages.count == 0
            }
        }

        guard animated else {
            toggle()
            return
        }

        self.toggleButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2) {
            toggle()
        } completion: { (_) in
            self.toggleButton.isUserInteractionEnabled = true
        }
    }

    @objc public func update() {
        guard let profile = ArchiveService.shared.currentProfile else {
            return
        }
        let avatarURL = profile.avatar?.formatted?.small
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: avatarURL, fullName: profile.fullName)
        avatarView.layoutSubviews()
    }

    public func didItemChanged(item: FloatingMenuItem) {
        if item == .profile || item == .addPost {
            return
        }
        if [.chats, .home, .neighbourgs, .bestyn].contains(item) {
            self.bestynButton?.isHidden = true
            self.stories?.isHidden = false
        } else {
            self.bestynButton?.isHidden = false
            self.stories?.isHidden = true
        }
    }

    @objc private func updateUnreadIndicator(_ notification: NSNotification) {
        updateIndicatorState()
    }

    private func updateIndicatorState() {
        profilesWithUnreadMessages = []
            if let profile = ArchiveService.shared.userModel?.profile,
               profile.hasUnreadMessages == true {
                profilesWithUnreadMessages.append(profile.id)
            }
        ArchiveService.shared.userModel?.businessProfiles?
            .filter({ $0.hasUnreadMessages ?? false })
            .forEach({ profilesWithUnreadMessages.append($0.id) })
        DispatchQueue.main.async {
            self.unreadIndicatorView.isHidden = self.profilesWithUnreadMessages.count == 0
        }
    }

    private func menuItemSelected(_ item: FloatingMenuItem) {
        delegate?.canChangeMenuItem(item, completion: { [weak self] (canChange) in
            guard canChange else {
                return
            }
            self?.isOpen = false

            self?.didItemChanged(item: item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.delegate?.didSelectedMenuItem(item)
            }
        })
    }


    private func updateSelectedState() {
        [homeButton, chatButton, mapButton].forEach({$0?.tintColor = R.color.greyMedium()})
        switch Self.selectedItem {
        case .home:
            homeButton.tintColor = R.color.blueButton()
        case .chats:
            chatButton.tintColor = R.color.blueButton()
        case .neighbourgs:
            mapButton.tintColor = R.color.blueButton()
        default:
            break
        }
    }
}
