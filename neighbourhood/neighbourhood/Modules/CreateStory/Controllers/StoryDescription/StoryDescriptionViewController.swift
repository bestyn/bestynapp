//
//  StoryDescriptionViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

class StoryDescriptionViewController: BaseViewController {


    @IBOutlet weak var descriptionTextView: HashtagsTextView!
    @IBOutlet weak var addressTextField: CustomTextField!
    @IBOutlet weak var thumbnailLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var thumbnailView: UIStackView!
    @IBOutlet weak var nonHashtagsView: UIStackView!
    @IBOutlet weak var saveButton: LightButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editThumbnailButton: UIButton!
    @IBOutlet weak var allowCommentsSwitch: UISwitch!
    @IBOutlet weak var allowDuetSwitch: UISwitch!


    private let viewModel: StoryDescriptionViewModel

    init(postToEdit: PostModel? = nil) {
        viewModel = .init(postToEdit: postToEdit)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupAddressTextField()
        thumbnailLabel.text = R.string.localizable.storyCoverTitle()
        setupViewModel()
        fillData()
        titleLabel.text = viewModel.isEditMode
            ? R.string.localizable.editStoryDescriptionTitle()
            : R.string.localizable.addStoryDescriptionTitle()
        editThumbnailButton.isHidden = viewModel.isEditMode
    }

    @IBAction func didTapBack(_ sender: Any) {
        navigateBack()
    }

    @IBAction func didTapChangeThumbnail(_ sender: Any) {
        CreateStoryRouter(in: navigationController)
            .openThumbnailSelector(from: viewModel.storyCreator.resultClipParams, selectedSecond: viewModel.selectedSecond, delegate: viewModel)
    }
    
    @IBAction func didTapPost(_ sender: Any) {
        save()
    }
}

extension StoryDescriptionViewController {

    private func setupTextView() {
        descriptionTextView.delegate = self
        descriptionTextView.title = R.string.localizable.storyDescriptionTitle()
        descriptionTextView.placeholder = R.string.localizable.postDescriptionPlaceholder()
    }

    private func setupAddressTextField() {
        addressTextField.title = R.string.localizable.storyLocationTitle()
        addressTextField.placeholder = R.string.localizable.storyLocationPlaceholder()
        addressTextField.delegate = self
    }

    private func setupViewModel() {
        viewModel.$thumbnailImage.bind { [weak self] (image) in
            self?.thumbnailImageView.image = image
        }

        viewModel.$selectedAddress.bind { [weak self] (address) in
            self?.addressTextField.text = address
        }

        viewModel.$isSaving.bind { [weak self] (isSaving) in
            self?.saveButton.isLoading = isSaving
        }

        viewModel.$saveResult.bind { [weak self] (result) in
            guard let result = result else {
                return
            }
            switch result {
            case .success(_):
                guard let self = self else {
                    return
                }
                if self.viewModel.isEditMode {
                    let message = Alert.Message.objectUpdated(object: "Story")
                    Toast.show(message: message)
                }
                if self.viewModel.isEditMode {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    CreateStoryRouter(in: self.navigationController).backToList()
                }
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
}

extension StoryDescriptionViewController {

    private func isFormValid() -> Bool {
        let validation = ValidationManager()
        var valid = true
        if !descriptionTextView.textIsEmpty, let validationError = validation
            .validateStoryDescription(value: descriptionTextView.text)
            .errorMessage(field: descriptionTextView.title ?? "") {
            descriptionTextView.error = validationError.capitalizingFirstLetter()
            valid = false
        } else {
            descriptionTextView.error = nil
        }

        return valid
    }

    private func save() {
        guard isFormValid() else {
            return
        }
        viewModel.save(
            description: descriptionTextView.textIsEmpty ? "" : descriptionTextView.textWithMentions,
            allowComments: allowCommentsSwitch.isOn,
            allowDuet: allowDuetSwitch.isOn
        )
    }

    private func fillData() {
        guard let post = viewModel.postToEdit else {
            return
        }
        descriptionTextView.text = post.description ?? ""
        allowCommentsSwitch.isOn = post.allowedComment
        allowDuetSwitch.isOn = post.allowedDuet
    }

    private func navigateBack() {
        guard let postToEdit = viewModel.postToEdit else {
            navigationController?.popViewController(animated: true)
            return
        }
        if postToEdit.description == (descriptionTextView.textIsEmpty ? "" : descriptionTextView.text),
           viewModel.placeId == postToEdit.placeId {
            navigationController?.popViewController(animated: true)
            return
        }
        Alert(title: nil, message: Alert.Message.cancelChanges)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { (result) in
                if result == .done {
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }
}


extension StoryDescriptionViewController: HashtagsTextViewDelegate {
    func hashtagsListToggle(isShown: Bool) {
        nonHashtagsView.isHidden = isShown
    }
    
    func editingEnded() {
    }
}


// MARK: - GMSAutocompleteResultsViewControllerDelegate
extension StoryDescriptionViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: - Handle error
    }

    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        viewModel.setSelectedAddress(place: place)
        resultsController.dismiss(animated: true, completion: nil)
    }
}

extension StoryDescriptionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == addressTextField {
            openAddressPicker()
        }
    }

    private func openAddressPicker() {
        navigationController?.isNavigationBarHidden = true
        let bounds = GMSCoordinateBounds()

        let autocompleteController = GMSAutocompleteResultsViewController()
        autocompleteController.autocompleteBounds = bounds

        autocompleteController.secondaryTextColor = UIColor.white.withAlphaComponent(0.8)
        autocompleteController.primaryTextColor = UIColor.white.withAlphaComponent(0.6)
        autocompleteController.primaryTextHighlightColor = .white
        autocompleteController.tableCellBackgroundColor = .black
        autocompleteController.tableCellSeparatorColor = .white
        autocompleteController.tintColor = .white
        autocompleteController.autocompleteBoundsMode = .restrict
        autocompleteController.delegate = self

        let searchController = UISearchController(searchResultsController: autocompleteController)
        searchController.searchResultsUpdater = autocompleteController

        searchController.view.backgroundColor = .black
        searchController.searchBar.text = addressTextField.text
        searchController.searchBar.delegate = self

        let subView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 350.0, height: 45.0))

        subView.addSubview(searchController.searchBar)
        autocompleteController.view.addSubview(subView)
        autocompleteController.view.bringSubviewToFront(subView)
        searchController.searchBar.sizeToFit()
        searchController.hidesNavigationBarDuringPresentation = false

        definesPresentationContext = true
        present(searchController, animated: true, completion: nil)
    }
}

// MARK: - UISearchBarDelegate
extension StoryDescriptionViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}
