//
//  MentionsView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol MentionsViewDelegate: class {
    func mentionedProfileSelected(_ profile: PostProfileModel)
}

class MentionsView: UIView {

    lazy var emptyView: UILabel = {
        let label = UILabel()
        label.text = "Sorry, there are no search results.\nPlease try a different search"
        label.font = R.font.poppinsMedium(size: 14)
        label.textColor = R.color.greyMedium()
        label.isHidden = true
        label.numberOfLines = 0
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15)
        ])
        return label
    }()

    lazy var mentionsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(R.nib.mentionCell)
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        return tableView
    }()

    private let viewModel = MentionsViewModel()

    private var emptyStateHeight: CGFloat = 72

    public weak var delegate: MentionsViewDelegate?
    @IBInspectable public var shouldChangeHeight = true
    @IBInspectable public var maxRows = 3

    init(shouldChangeHeight: Bool) {
        super.init(frame: .zero)
        self.shouldChangeHeight = shouldChangeHeight
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(mentionsTableView)
        mentionsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mentionsTableView.topAnchor.constraint(equalTo: topAnchor),
            mentionsTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mentionsTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mentionsTableView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        setupViewModel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mentionsTableView.separatorStyle = .none
    }
}

// MARK: - Public methods

extension MentionsView {
    func handleMention(name: String) {
        viewModel.searchProfiles(name: name)
    }

    func reset() {
        viewModel.searchProfiles(name: "")
    }
}

// MARK: - Private methods

extension MentionsView {
    private func setupViewModel() {
        viewModel.$profiles.bind { [weak self] (profiles) in
            self?.mentionsTableView.reloadData()
            self?.updateViewHeight(profilesCount: profiles.count)
            self?.updateEmptyState(isEmpty: profiles.count == 0)
        }
    }

    private func height(for rows: Int) -> CGFloat {
        return CGFloat(rows) * 40 + 12
    }

    private func updateViewHeight(profilesCount: Int) {
        guard shouldChangeHeight else {
            return
        }
        if let heightConstraint = self.constraints.first(where: {$0.firstAttribute == .height}) {
            removeConstraint(heightConstraint)
        }
        if profilesCount == 0 {
            heightAnchor.constraint(equalToConstant: emptyStateHeight).isActive = true
        } else {
            let height = self.height(for: min(maxRows, profilesCount))
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    private func updateEmptyState(isEmpty: Bool) {
        emptyView.isHidden = !isEmpty
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension MentionsView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.profiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.mentionCell, for: indexPath)!
        cell.profile = viewModel.profiles[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profile = viewModel.profiles[indexPath.row]
        delegate?.mentionedProfileSelected(profile)
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        print(indexPath.row)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}
