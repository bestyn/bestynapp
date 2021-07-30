//
//  CategoriesViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 30.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol ChoseCategoryDelegate: AnyObject {
    func getCategory(by data: HashtagModel)
}

final class CategoriesViewController: BaseViewController {
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    
    weak var delegate: ChoseCategoryDelegate?
    
    private var categories: [HashtagModel] = []
    private lazy var categoriesManager: RestHashtagsManager = RestService.shared.createOperationsManager(from: self)
    private let emptyView = EmptyView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        definesPresentationContext = true
        searchBar.becomeFirstResponder()
        tableView.register(R.nib.categoryCell)
        configureBackgroundView()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
    }
    
    override var additionalBottomSpace: CGFloat {
        return GlobalConstants.Dimensions.defineAdditionalSpaceHeight()
    }

    private func configureBackgroundView() {
        emptyView.isHidden = true
        emptyView.frame = CGRect(x: 16, y: 4, width: view.frame.width - 32, height: 80)
        tableView.backgroundView = emptyView
        emptyView.setAttributesForEmptyScreen(text: R.string.localizable.noCategoryTitle())
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CategoriesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.categoryCell, for: indexPath) else {
            NSLog("🔥 Error occurred while creating CategoriesViewController")
            return UITableViewCell() }

        cell.updateCell(with: categories[indexPath.row].name)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        dismiss(animated: true) {
            self.delegate?.getCategory(by: self.categories[indexPath.row])
        }
    }
}

// MARK: - UISearchBarDelegate
extension CategoriesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            categoriesManager.searchHashtags(search: searchText, page: 1)
                .onComplete { [weak self] (result) in
                    guard let self = self else {
                        return
                    }
                    if let categories = result.result {
                        self.categories = categories
                    }
                    self.emptyView.isHidden = !self.categories.isEmpty
                    self.tableView.reloadData()
            } .run()
        } else {
            categories = []
            searchBar.text = nil
            tableView.reloadData()
        }
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        emptyView.isHidden = true
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
}
