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
    @IBOutlet private weak var viewWithCategories: UIView!
    @IBOutlet private weak var bottomShadowView: UIView!
    @IBOutlet private weak var saveButton: DarkButton!
    @IBOutlet private weak var skipButton: UIButton!
    @IBOutlet private weak var backButton: UIButton!

    @IBOutlet weak var selectedInterestsView: UIView!
    @IBOutlet weak var mostPopularLabel: UILabel!
    @IBOutlet weak var searchResultsTagView: TagListView!

    private let validation = ValidationManager()
    private lazy var hashtagsManager: RestHashtagsManager = RestService.shared.createOperationsManager(from: self)
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self)

    private var selectedHashtags: [HashtagModel] = []
    private var hashtags: [HashtagModel] = [] {
        didSet { updateResults() }
    }
    private var isChanged = false
    private let screenType: TypeOfScreenAction

    private var currentSearch: String?
    
    init(screenType: TypeOfScreenAction) {
        self.screenType = screenType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchBar()
        defineElementsVisibility()
        setScreenTitle()

        selectedHashtags = ArchiveService.shared.userModel?.profile.hashtags ?? []
        selectedTagsView.addTags(selectedHashtags.map({$0.name}))
        updateSelectedHashtags()

        selectedInterestsView.isHidden = selectedHashtags.isEmpty
        
        selectedTagsView.delegate = self
        selectedTagsView.textFont = R.font.poppinsMedium(size: 12)!
        searchResultsTagView.delegate = self
        selectedTagsView.textFont = R.font.poppinsMedium(size: 12)!
        
        bottomShadowView.dropShadow(color: R.color.greyStroke()!, opacity: 0.3, offSet: CGSize(width: 0, height: -5), radius: 3.0)
        restGetPopularHashtags()
    }
    
    // MARK: - Private actions
    @IBAction private func saveButtonDidTap(_ sender: UIButton) {
        saveHashtags()
    }
    
    @IBAction private func skipButtonDidTap(_ sender: Any) {
        RootRouter.shared.openApp(isSkiped: true)
    }
    
    
    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        close()
    }

    private func updateResults() {
        searchResultsTagView.removeAllTags()
        searchResultsTagView.addTags(hashtags.map({$0.name}))
        updateSelectedHashtags()
    }

    private func saveHashtags() {
        if let validationError = validation
            .validateAddedInterests(value: selectedHashtags)
            .errorMessage(field: R.string.localizable.selectedInterestsTitle()) {
            Toast.show(message: validationError.capitalizingFirstLetter())
            return
        }

        let hashtagsIds = selectedHashtags.map { $0.id }
        restSaveHashtags(hashtagsIds: hashtagsIds)
    }

    private func updateSelectedHashtags() {
        searchResultsTagView.tagViews.forEach { tagView in
            if let title = tagView.title(for: .normal), selectedHashtags.contains(where: {$0.name == title}) {
                tagView.tagBackgroundColor = R.color.aliceBlue()!
            } else {
                tagView.tagBackgroundColor = .white
            }
        }
        searchResultsTagView.setNeedsLayout()
    }
}

// MARK: - Configurations
private extension MyInterestsViewController {
    func configureSearchBar() {
        searchBar.delegate = self
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.font = R.font.poppinsRegular(size: 14)
            searchBar.searchTextField.textColor = R.color.mainBlack()
        } else {
            if let searchTextField = searchBar.subviews.first(where: {$0 is UITextField}) as? UITextField {
                searchTextField.font = R.font.poppinsRegular(size: 14)
                searchTextField.textColor = R.color.mainBlack()
            }
        }
    }
    
    func defineElementsVisibility() {
        skipButton.isHidden = screenType == .edit
        backButton.isHidden = screenType == .create
    }
    
    func setScreenTitle() {
        screenTitleLabel.text = screenType == .edit ? R.string.localizable.editInterestsScreenTitle() : R.string.localizable.myInterestsTitle()
    }

    private func close() {
        if isChanged {
            Alert(title: R.string.localizable.notSavedChanges(), message: R.string.localizable.confirmLeaveWithoutSaving())
                .configure(doneText: R.string.localizable.leaveButtonTitle())
                .configure(cancelText: R.string.localizable.saveButtonTitle())
                .show { (result) in
                    switch result {
                    case .done:
                        self.navigationController?.popViewController(animated: true)
                    case .cancel:
                        self.saveHashtags()
                    default:
                        break
                    }
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - REST requests
extension MyInterestsViewController {
    private func restGetPopularHashtags() {
        hashtagsManager.getPopularHastags()
            .onComplete { [weak self] (result) in
                if let hashtags = result.result {
                    self?.hashtags = hashtags
                }
                self?.mostPopularLabel.isHidden = false

        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }

    private func restSearchHashtags() {
        guard let currentSearch = currentSearch else {
            return
        }
        hashtagsManager.searchHashtags(search: currentSearch, page: 1)
            .onComplete { [weak self] (result) in
                guard let hashtags = result.result else {
                    return
                }
                if hashtags.count == 0 {
                    Toast.show(message: R.string.localizable.noCategoryInSystem())
                }
                self?.hashtags = hashtags
                self?.mostPopularLabel.isHidden = true
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }

    private func restSaveHashtags(hashtagsIds: [Int]) {
        profileManager.saveHashtags(hashtagsIds: hashtagsIds)
            .onComplete { [weak self] (response) in
                if !ArchiveService.shared.interestExist {
                    AnalyticsService.logInterestsSelected()
                }
                ArchiveService.shared.interestExist = true
                if let profile = response.result,
                   var user = ArchiveService.shared.userModel {
                    user.profile = profile
                    ArchiveService.shared.userModel = user
                    if ArchiveService.shared.currentProfile?.id == profile.id {
                        ArchiveService.shared.currentProfile = profile.selectorProfile
                    }
                }
                if self?.screenType == .edit {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    RootRouter.shared.openApp(isSkiped: false)
                }
                Toast.show(message: R.string.localizable.interestsUpdated())
            } .onError { [weak self] (error) in
                self?.handleError(error)
            } .run()
    }
}

// MARK: - TagListViewDelegate
extension MyInterestsViewController: TagListViewDelegate {
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {
        if let index = selectedHashtags.firstIndex(where: { $0.name == title }) {
            selectedHashtags.remove(at: index)
            selectedTagsView.removeTag(title)
            selectedTagsView.layoutSubviews()
            updateSelectedHashtags()
            selectedInterestsView.isHidden = selectedHashtags.isEmpty
            isChanged = true
        }
    }

    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        guard sender == searchResultsTagView else {
            return
        }
        if let selectedHashtag = hashtags.first(where: {$0.name == title}),
           !selectedHashtags.contains(where: {$0.id == selectedHashtag.id}) {
            selectedHashtags.append(selectedHashtag)
            selectedTagsView.addTag(selectedHashtag.name)
            updateSelectedHashtags()
            isChanged = true
        }
        selectedInterestsView.isHidden = selectedHashtags.isEmpty
    }

    
}

// MARK: - UISearchBarDelegate
extension MyInterestsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentSearch = searchText
        if searchText.count > 0 {
            restSearchHashtags()
            searchBar.showsCancelButton = true
        } else {
            restGetPopularHashtags()
            searchBar.showsCancelButton = false
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        searchBar.text = ""
        searchBar.showsCancelButton = false
        restGetPopularHashtags()
    }
}
