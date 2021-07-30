//
//  ChatsListViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ChatsListViewController: BaseViewController {
    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var searchView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var backgroundButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private lazy var emptyView: EmptyView = {
        let view = EmptyView(frame: .zero)
        view.frame = CGRect(x: 16, y: 4, width: view.frame.width - 32, height: 80)
        view.setAttributesForEmptyScreen(text: R.string.localizable.noChatsYet(), image: R.image.empty_screen_for_chat())
        return view
    }()
    
    private var isOnThePage = false

    private var viewModel: ChatListViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupLayout()
        setupSearchField()
        setupViewModel()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshChats()
        AnalyticsService.logOpenChats()
    }
    
    // MARK: - Private actions

    @objc private func refreshData(_ sender: Any) {
        DispatchQueue.main.async {
            self.viewModel.refreshChats()
        }
    }

    @IBAction func didTapBackground(_ sender: Any) {
        ChatRouter(in: navigationController).openChatBackgroundViewController()
    }

    @IBAction func didTapCancel(_ sender: Any) {
        view.endEditing(true)
        searchTextField.text = nil
        viewModel.search(query: nil)
    }

    private func handleStateChange(state: ChatListViewModel.State) {
        self.tableView.reloadData()
        if let error = state.lastError {
            self.handleError(error)
            return
        }
        if state.loading, state.chats.count == 0 {
            self.refreshControl.beginRefreshing()
        } else {
            self.refreshControl.endRefreshing()
        }
        if !state.loading, state.chats.count == 0 {
            self.emptyView.setAttributesForEmptyScreen(text: state.currentSearch == nil ? R.string.localizable.noChatsYet() : R.string.localizable.noChatMatches())
            self.tableView.backgroundView = self.emptyView
            return
        }
        self.tableView.backgroundView = nil
    }

    private func confirmChatDeleting(chat: PrivateChatListModel) {
        Alert(title: Alert.Title.deleteChat, message: Alert.Message.deleteChat)
            .configure(doneText: Alert.Action.yes)
            .configure(cancelText: Alert.Action.no)
            .show { (status) in
                if status == .done {
                    self.viewModel.deleteChat(chat)
                }
            }
    }
}

// MARK: - Setup

extension ChatsListViewController {
    private func setupSearchField() {
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: R.string.localizable.searchTitle(),
            attributes: [.foregroundColor: R.color.whiteBackground()!])
        searchTextField.delegate = self
    }

    private func setupViewModel() {
        viewModel = ChatListViewModel()
        viewModel.$state.bind { [weak self] (state) in
            self?.handleStateChange(state: state)
        }
    }

    private func setupTableView() {
        tableView.register(R.nib.chatListCell)
        tableView.refreshControl = refreshControl
        tableView.rowHeight = 78
        tableView.roundCorners(corners: [.topLeft, .topRight], radius: 12)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    private func setupLocalizables() {
        cancelButton.setTitle(R.string.localizable.cancelTitle(), for: .normal)
    }

    private func setupLayout() {
        searchView.layer.cornerRadius = searchView.frame.height / 2
        searchView.clipsToBounds = true

        backgroundButton.layer.cornerRadius = backgroundButton.frame.height / 2
        backgroundButton.clipsToBounds = true
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ChatsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.chatListCell, for: indexPath)!
        let chat = viewModel.state.chats[indexPath.row]
        cell.updateCell(with: chat)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = viewModel.state.chats[indexPath.row]
        ChatRouter(in: navigationController).opeChatDetailsViewController(chat: chat)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.state.chats.count - 1 {
            viewModel.fetchMoreChats()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
            let chat = self.viewModel.state.chats[indexPath.row]
            self.confirmChatDeleting(chat: chat)
            completion(true)
        }
        if #available(iOS 13.0, *) {
            delete.image = R.image.delete_icon()
            delete.backgroundColor = R.color.greyBackground()
        } else {
            delete.image = R.image.delete_outline_icon()
            delete.backgroundColor = R.color.accentRed()
        }
        let config = UISwipeActionsConfiguration(actions: [delete])
        return config
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension ChatsListViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        backgroundButton.isHidden = true
        cancelButton.isHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            viewModel.search(query: nil)
            return true
        }
        let newString = (text as NSString).replacingCharacters(in: range, with: string)
        if newString.count > 1 {
            viewModel.search(query: newString)
            return true
        }
        if text.count > 1 {
            viewModel.search(query: nil)
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        backgroundButton.isHidden = false
        cancelButton.isHidden = true
    }
}
