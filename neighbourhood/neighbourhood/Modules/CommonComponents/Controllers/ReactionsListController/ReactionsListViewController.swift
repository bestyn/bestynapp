//
//  ReactionsListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol ReactionsListDelegate: class {
    func openProfile(_ profile: PostProfileModel)
    func openChat(with profile: PostProfileModel)
}

class ReactionsListViewController: BaseViewController, BottomMenuPresentable {

    @IBOutlet weak var buttonsScrollView: UIScrollView!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var listsScrollView: UIScrollView!

    var transitionManager: BottomMenuPresentationManager! = .init()
    var presentedViewHeight: CGFloat { 460 }
    let viewModel: ReactionsListViewModel
    var allReactionsTableView = UITableView()
    var reactionTableViews: [Reaction: UITableView] = [:]

    weak var delegate: ReactionsListDelegate?

    init(post: PostModel) {
        self.viewModel = ReactionsListViewModel(post: post)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContentSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateContentSize()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableViews()
        setupButtons()
        setupViewModel()
    }
}

// MARK: - Private functions

extension ReactionsListViewController {

    private func setupTableViews() {
        setupTableView(allReactionsTableView)
        viewModel.availableReactions.forEach { (reaction, _) in
            let tableView = UITableView()
            self.reactionTableViews[reaction] = tableView
            self.setupTableView(tableView)
        }
    }

    private func setupTableView(_ tableView: UITableView) {
        tableView.register(R.nib.reactionCell)
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        listsScrollView.addSubview(tableView)
    }

    private func setupButtons() {
        let allButton = self.allReactionsFilterButton()
        self.buttonsStackView.addArrangedSubview(allButton)
        allButton.isSelected = true
        viewModel.availableReactions.forEach { (reaction) in
            self.buttonsStackView.addArrangedSubview(self.filterButton(for: reaction.key))
        }
    }

    private func allReactionsFilterButton() -> UIButton {
        let button = PagingButton()
        button.setTitle("All \(viewModel.post.reactionsCount)", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 7)
        button.addTarget(self, action: #selector(didTapReactionFilter(sender:)), for: .touchUpInside)
        return button
    }

    private func filterButton(for reaction: Reaction) -> UIButton {
        let button = PagingButton()
        button.setImage(reaction.image, for: .normal)
        let count = viewModel.post.reactions[reaction] ?? 0
        button.setTitle("\(count)", for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 7)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(didTapReactionFilter(sender:)), for: .touchUpInside)
        return button
    }

    private func setupViewModel() {
        viewModel.$unfilteredReactions.bind { (_) in
            self.activityIndicator.isHidden = true
            self.contentView.isHidden = false
            self.allReactionsTableView.reloadData()
        }
        viewModel.$filteredReactions.bind { (_) in
            self.reactionTableViews.values.forEach({$0.reloadData()})
        }
        viewModel.$error.bind { (error) in
            if let error = error {
                self.handleError(error)
            }
        }
        viewModel.fetchMoreReactions()
    }

    @objc private func didTapReactionFilter(sender: UIButton) {
        guard let index = buttonsStackView.arrangedSubviews.firstIndex(of: sender) else {
            return
        }
        buttonsStackView.arrangedSubviews.compactMap({$0 as? PagingButton}).forEach({$0.isSelected = false})
        sender.isSelected = true
        listsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * listsScrollView.bounds.width, y: 0), animated: true)
        if index == 0 {
            viewModel.changeFilter(selectedReaction: nil)
            return
        }
        let reaction = viewModel.availableReactions[index - 1].key
        viewModel.changeFilter(selectedReaction: reaction)
    }

    private func reactionsForTableView(_ tableView: UITableView) -> [PostReactionModel] {
        if tableView == allReactionsTableView {
            return viewModel.unfilteredReactions
        }
        guard let reaction = reactionTableViews.first(where: {$1 == tableView})?.key else {
            return []
        }
        return viewModel.filteredReactions[reaction] ?? []
    }

    private func updateContentSize() {
        for (index, tableView) in listsScrollView.subviews.enumerated() {
            let origin = CGPoint(x: listsScrollView.bounds.width * CGFloat(index), y: 0)
            tableView.frame = CGRect(origin: origin, size: listsScrollView.bounds.size)
        }
        listsScrollView.contentSize = CGSize(
            width: listsScrollView.bounds.width * CGFloat(listsScrollView.subviews.count),
            height: listsScrollView.bounds.height)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ReactionsListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reactionsForTableView(tableView).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.reactionCell, for: indexPath)!
        cell.reaction = reactionsForTableView(tableView)[indexPath.row]
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let profile = reactionsForTableView(tableView)[indexPath.row].profile else {
            return
        }
        dismiss(animated: true) {
            if profile.id == ArchiveService.shared.currentProfile?.id {
                MainScreenRouter(in: RootRouter.shared.rootNavigationController).openMyProfile()
                return
            }
            switch profile.type {
            case .basic:
                BasicProfileRouter(in: RootRouter.shared.rootNavigationController).openPublicProfileViewController(profileId: profile.id)
            case .business:
                BusinessProfileRouter(in: RootRouter.shared.rootNavigationController).openPublicProfileController(id: profile.id)
            }
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == reactionsForTableView(tableView).count - 1 {
            viewModel.fetchMoreReactions()
        }
    }
}

// MARK: - ReactionCellDelegate

extension ReactionsListViewController: ReactionCellDelegate {
    func openChat(with profile: PostProfileModel) {
        dismiss(animated: true) {
            ChatRouter(in: RootRouter.shared.rootNavigationController).opeChatDetailsViewController(with: profile.chatProfile)
        }
    }
}
