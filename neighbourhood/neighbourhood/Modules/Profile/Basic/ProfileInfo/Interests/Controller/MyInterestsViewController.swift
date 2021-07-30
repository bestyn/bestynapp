//
//  MyInterestsViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 11.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

struct AllCategories {
    let title: String
    let array: [CategoriesData]
}

struct SubcategoryItem: Equatable {
    let name: String
    let id: Int
}

private let staticRowHeight: CGFloat = 28.0
private let maxRowCount: CGFloat = 5.0

final class MyInterestsViewController: BaseViewController {
    @IBOutlet private weak var screenTitleLabel: UILabel!
    @IBOutlet private weak var selectedInterestsTitleLabel: UILabel!
    @IBOutlet private weak var selectedTagsView: TagListView!
    @IBOutlet private weak var viewWithTags: UIView!
    @IBOutlet private weak var searchBarTitleLabel: UILabel!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var viewWithCategories: UIView!
    @IBOutlet private weak var bottomShadowView: UIView!
    @IBOutlet private weak var saveButton: DarkButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var currentProfile: UserProfile?
    
    private let validation = ValidationManager()
    
    private var selectedCategories = [SubcategoryItem]()
    private var arrayOfCategories = [AllCategories]()
    private var categories: [CategoriesData]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureSearchBar()
        hideViewWhenTappedAround()
        
        currentProfile?.interests.forEach {
            selectedCategories.append(SubcategoryItem(name: $0.title, id: $0.id))
            selectedTagsView.addTag($0.title)
        }
        
        selectedTagsView.delegate = self
        selectedTagsView.textFont = R.font.poppinsMedium(size: 13)!
        
        bottomShadowView.dropShadow(color: R.color.greyStroke()!, opacity: 0.3, offSet: CGSize(width: 0, height: -5), radius: 3.0)
        fetchCategories()
    }
    
    override var isNavigationBarVisible: Bool {
        return false
    }
    
    // MARK: - Private actions
    @IBAction private func saveButtonDidTap(_ sender: UIButton) {
        if let validationError = validation
            .validateAddedInterests(value: selectedCategories)
            .errorMessage(field: R.string.localizable.selectedInterestsTitle()) {
            Toast.show(message: validationError.capitalizingFirstLetter())
        } else {
            saveNewInterests()
        }
    }
    
    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Configurations
private extension MyInterestsViewController {
    func configureSearchBar() {
        searchBar.delegate = self
        searchBar.searchTextField.font = R.font.poppinsRegular(size: 14)
        searchBar.searchTextField.textColor = R.color.mainBlack()
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        if !tableView.bounds.contains(sender.location(in: tableView)) {
            hideTableView()
        }
    }
    
    @objc func hideTableView() {
        animate(toogle: false)
        view.endEditing(true)
    }
    
    func configureTableView() {
        tableView.register(R.nib.dropDownInterestsCell)
        tableView.isHidden = true
        tableView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
    }
    
    func defineTableViewHeight() {
        let maxHeight: CGFloat = staticRowHeight * maxRowCount
        let fullTableViewHeight = staticRowHeight * CGFloat(categories?.count ?? 0)
        
        if fullTableViewHeight < maxHeight {
            tableViewHeightConstraint.constant = fullTableViewHeight
        } else {
            tableViewHeightConstraint.constant = maxHeight
        }
    }
    
    func animate(toogle: Bool) {
        if toogle {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.tableView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.tableView.isHidden = true
            }
        }
    }
    
    func hideViewWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

// MARK: - REST requests
extension MyInterestsViewController {
    private func fetchCategories() {
        RestCategories(requestIdentifier: name).getAllCategories() { [weak self] (result) in
            switch result {
            case .success(let model):
                
                var groups: [String: [CategoriesData]] = [:]
                model.0?.forEach { (category) in
                    var group: [CategoriesData] = groups[category.categoryName] ?? []
                    group.append(category)
                    groups[category.categoryName] = group
                }
                
                self?.arrayOfCategories = groups.map { (key, group) -> AllCategories in
                    return AllCategories(title: key, array: group)
                }
                
                self?.arrayOfCategories.sorted(by: { $0.title < $1.title } ).forEach {
                    let view = CategoryScrollView()
                    view.addCategoryTags(title: $0.title, items: $0.array, userInterests: self?.currentProfile?.interests)
                    view.itemDelegate = self
                    self?.stackView.addArrangedSubview(view)
                }
                
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func saveNewInterests() {
        let myInterests = selectedCategories.map { $0.id }
        RestProfile(requestIdentifier: name).addInterests(myInterests: myInterests) { [weak self] (result) in
            switch result {
            case .success(_):
                self?.navigationController?.popViewController(animated: true)
                Toast.show(message: R.string.localizable.interestsUpdated())
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
}

// MARK: - CategoryItemDelegate
extension MyInterestsViewController: CategoryItemDelegate {
    func addNewItem(with title: String, and id: Int) {
        if selectedCategories.contains(where: { $0.id == id } ) {
            Toast.show(message: R.string.localizable.categoryWasAddedError())
        } else {
            selectedTagsView.addTag(title)
            selectedCategories.append(SubcategoryItem(name: title, id: id))
        }
    }
}

// MARK: - TagListViewDelegate
extension MyInterestsViewController: TagListViewDelegate {
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {
        if let index = selectedCategories.firstIndex(where: { $0.name == title }) {
            selectedCategories.remove(at: index)
            selectedTagsView.removeTag(title)
            selectedTagsView.layoutSubviews()
            
            stackView.arrangedSubviews.forEach {
                ($0 as? CategoryScrollView)?.changeColorAfterRemove(tagTitle: title)
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MyInterestsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.dropDownInterestsCell, for: indexPath) else {
            assertionFailure("🔥 Error occurred while creating DropDownInterestsCell")
            return UITableViewCell() }
        
        if let categories = categories, !categories.isEmpty {
            cell.updateCell(title: categories[indexPath.row].title)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let  categories = categories, !categories.isEmpty else {
            assertionFailure("🔥 Array with categories is empty or nil")
            return
        }
        
        let tappedItem = SubcategoryItem(name: categories[indexPath.row].title, id: categories[indexPath.row].id)
        
        if !selectedCategories.contains(tappedItem) {
            selectedCategories.append(tappedItem)
            selectedTagsView.addTag(categories[indexPath.row].title)
            
            stackView.arrangedSubviews.forEach {
                ($0 as? CategoryScrollView)?.changeToInactiveColor(tagTitle: categories[indexPath.row].title)
            }
            
            hideTableView()
        } else {
            Toast.show(message: R.string.localizable.categoryWasAddedError())
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 28.0
    }
}

// MARK: - UISearchBarDelegate
extension MyInterestsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            RestCategories(requestIdentifier: name).getCategories(title: searchText) { [weak self] (result) in
                guard let self = self else {
                    return
                }
                
                switch result {
                case .success(let model):
                    self.categories = model.0
                    self.tableView.reloadData()
                    self.defineTableViewHeight()
                    self.animate(toogle: true)
                case .failure(let error):
                    self.hideTableView()
                    self.handleError(error)
                }
            }
        } else {
            animate(toogle: false)
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.text = nil
        hideTableView()
        searchBar.endEditing(true)
    }
}
