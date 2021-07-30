//
//  ProfileSwitcherViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol AccountSwitcherDelegate: AnyObject {
    func openAddBusinessProfile()
    func openMyProfile()
}

fileprivate enum Defaults {
    static let rowHeight: CGFloat = 78
}

final class ProfileSwitcherViewController: BaseViewController, BottomMenuPresentable {
    @IBOutlet private weak var tableView: UITableView!

    var transitionManager: BottomMenuPresentationManager! = .init()
    var presentedViewHeight: CGFloat {
        var height: CGFloat = 0
        for row in 0...tableView.numberOfRows(inSection: 0) {
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) {
                height += cell.frame.height
            }
        }
        return height
    }
    
    private lazy var profiles: [SelectorProfileModel] = []

    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    
    private var basicProfile: UserProfileModel?
    private var businessProfiles: [BusinessProfile] = []

    private var canAddBusinessProfile: Bool {
        return businessProfiles.count < 5
    }
    
    weak var delegate: AccountSwitcherDelegate?

    init(delegate: AccountSwitcherDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureUnreadMessage()
        updateProfiles()
        getProfiles()
    }
}

// MARK: - UI configurations

private extension ProfileSwitcherViewController {
    func configureUnreadMessage() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateHasUnreadMessages), name: .chatUnreadMessageServiceUpdateUnreadMessageNotification, object: nil)
    }
    
    func configureTableView() {
        tableView.register(R.nib.addBusinessProfileCell)
        tableView.register(R.nib.businessProfileCell)
        tableView.register(R.nib.currentProfileCell)
        tableView.estimatedRowHeight = Defaults.rowHeight
    }

    @objc func viewTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Private functions

extension ProfileSwitcherViewController {
    private func selectProfile(_ profile: SelectorProfileModel) {
        dismiss(animated: true) {
            UserModel.setActiveProfile(profile)
        }
    }

    private func openCurrentProfile() {
        dismiss(animated: true) {
            self.delegate?.openMyProfile()
        }
    }

    private func addBusinessProfile() {
        dismiss(animated: true) {
            self.delegate?.openAddBusinessProfile()
        }
    }

    @objc func updateHasUnreadMessages(_ notification: Notification) {
        guard let unreadMessageModel = UnreadMessageModel(data: notification.userInfo) else {
            return
        }
        if let index = profiles.firstIndex(where: { $0.id == unreadMessageModel.profileId }) {
            profiles[index].hasUnreadMessages = unreadMessageModel.hasUnreadMessages
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private func updateProfiles() {
        guard let currentProfile = ArchiveService.shared.currentProfile,
              let user = ArchiveService.shared.userModel else {
            return
        }
        self.profiles = user.profiles.filter({$0.id != currentProfile.id})
        self.tableView.reloadData()
    }
}

// MARK: - REST Requests

extension ProfileSwitcherViewController {
    private func getProfiles() {
        profileManager.getUser()
            .onComplete { [weak self] (response) in
                if let user = response.result {
                    ArchiveService.shared.userModel = user
                    self?.updateProfiles()
                }

            } .onError { [weak self] (error) in
                self?.handleError(error)
            } .run()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ProfileSwitcherViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        canAddBusinessProfile ? profiles.count + 2 : profiles.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.currentProfileCell, for: indexPath)!
            cell.profile = ArchiveService.shared.currentProfile
            return cell
        }
        if indexPath.row == 1, canAddBusinessProfile {
            let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.addBusinessProfileCell, for: indexPath)!
            return cell
        }

        let offset = canAddBusinessProfile ? 2 : 1

        let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.businessProfileCell, for: indexPath)!
        cell.profile = profiles[indexPath.row - offset]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            openCurrentProfile()
            return
        }
        if indexPath.row == 1, canAddBusinessProfile {
            addBusinessProfile()
            return
        }

        let offset = canAddBusinessProfile ? 2 : 1
        selectProfile(profiles[indexPath.row - offset])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? UITableView.automaticDimension : 78
    }
}
