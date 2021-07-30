//
//  FollowListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class FollowListViewController: BaseViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var basicFilterButton: UIButton!
    @IBOutlet weak var businessFilterButton: UIButton!
    @IBOutlet weak var topView: UIView!
    @IBOutlet var emptyView: UIView!
    

    private let viewModel: FollowListViewModel

    init(mode: FollowListViewModel.Mode) {
        self.viewModel = .init(mode: mode)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
        setupLayout()
        setupSearchField()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshProfilesList()
    }

    @IBAction func didTapBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func didTapBasicFilter(_ sender: Any) {
        viewModel.toggleFilter(.basic)
    }

    @IBAction func didTapBusinessFilter(_ sender: Any) {
        viewModel.toggleFilter(.business)
    }

    @IBAction func didTapSearch(_ sender: Any) {
        if let text = searchField.text, !text.isEmpty {
            viewModel.search(query: text)
        }
    }
}

// MARK: - Configuration

extension FollowListViewController {

    private func setupLayout() {
        topView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 16)
    }

    private func setupSearchField() {
        searchField.addTarget(self, action: #selector(onSearchFieldChanged), for: .editingChanged)
    }

    private func setupTableView() {
        usersTableView.register(R.nib.followUserCell)
        usersTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        emptyView.frame = CGRect(x: 16, y: usersTableView.contentOffset.y + 4, width: usersTableView.frame.width - 32, height: 80)
        usersTableView.backgroundView = emptyView
    }

    private func setupViewModel() {
        viewModel.$profiles.bind { [weak self] (profiles) in
            self?.updateEmptyState(isEmpty: profiles.count == 0)
            self?.usersTableView.reloadData()
        }
        viewModel.$totalProfiles.bind { [weak self] (count) in
            self?.updateTitle(count: count)
        }
        viewModel.$activeFilters.bind { [weak self] (filters) in
            self?.updateFilterButtons(filters: filters)
        }
    }
}

// MARK: - Private methods

extension FollowListViewController {

    private func openReport(profile: PostProfileModel) {
        BasicProfileRouter(in: navigationController).openReportViewController(for: profile)
    }

    private func unfollow(profile: PostProfileModel) {
        viewModel.unfollow(profile: profile)
    }

    private func follow(profile: PostProfileModel) {
        viewModel.follow(profile: profile)
    }

    private func removeFollower(profile: PostProfileModel) {
        viewModel.removeFollower(profile: profile)
    }

    private func updateEmptyState(isEmpty: Bool) {
        emptyView.isHidden = !isEmpty
    }

    private func updateTitle(count: Int) {
        titleLabel.text = viewModel.mode == .followers
            ? R.string.localizable.followersTitle(count)
            : R.string.localizable.followedTitle(count)
    }

    private func updateFilterButtons(filters: [ProfileType]) {
        updateFilterButtonState(button: basicFilterButton, isActive: filters.contains(.basic))
        updateFilterButtonState(button: businessFilterButton, isActive: filters.contains(.business))
    }

    private func updateFilterButtonState(button: UIButton, isActive: Bool) {
        button.backgroundColor = isActive ? R.color.blueButton() : R.color.greyBackground()
        button.setTitleColor(isActive ? .white : R.color.mainBlack(), for: .normal)
    }
}


// MARK: - UITableViewDataSource, UITableViewDelegate

extension FollowListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.profiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.followUserCell, for: indexPath)!
        cell.isFollowed = viewModel.mode == .followed
        cell.profile = viewModel.profiles[indexPath.row]
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.profiles.count - 1 {
            viewModel.loadMoreProfiles()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profile = viewModel.profiles[indexPath.row]
        switch  profile.type {
        case .basic:
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: profile.id)
        case .business:
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: profile.id)
        }
    }
}

// MARK: - FollowUserCellDelegate

extension FollowListViewController: FollowUserCellDelegate {
    func toggleFollow(profile: PostProfileModel) {
        profile.isFollowed ? unfollow(profile: profile) : follow(profile: profile)
    }

    func openMenu(profile: PostProfileModel) {
        let controller = EntityMenuController(entity: FollowProfileModel(profile: profile, inFollowersList: viewModel.mode == .followers))
        controller.onMenuSelected = { [weak self] (type, follow) in
            switch type {
            case .report:
                self?.openReport(profile: follow.profile)
            case .removeFollower:
                self?.removeFollower(profile: follow.profile)
            default:
                return
            }
        }
        present(controller.alertController, animated: true)
    }
}


extension FollowListViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        textField.resignFirstResponder()
        viewModel.search(query: "")
        return false
    }

    @objc private func onSearchFieldChanged() {
        if let text = searchField.text,
           text.isEmpty {
            viewModel.search(query: "")
        }
    }

}
