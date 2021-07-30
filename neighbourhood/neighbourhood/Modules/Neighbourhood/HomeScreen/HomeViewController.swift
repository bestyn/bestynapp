//
//  HomeViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Firebase

protocol SearchFieldUpdatable: AnyObject {
    func clearTextField()
}

final class HomeViewController: BaseViewController {
    @IBOutlet private weak var tagsCollectionView: UICollectionView!
    @IBOutlet private weak var containerView: UIView!

    @IBOutlet private weak var allPostsButton: UIButton!
    @IBOutlet private weak var recommendedPostsButton: UIButton!
    @IBOutlet private weak var myNeighborsButton: UIButton!

    @IBOutlet private weak var allBottomView: UIView!
    @IBOutlet private weak var recommendedBottomView: UIView!
    @IBOutlet private weak var myNeighborsBottomView: UIView!

    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet weak var searchContainerView: UIView!

    private let floatyButton = FloatyButton()
    private let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    private let allPostsController = HomeListViewController()
    private let recommendedPostsController = HomeListViewController()
    private let myNeighboursViewController = MyNeighborsViewController()

    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    private lazy var businessManager: RestBusinessProfileManager = RestService.shared.createOperationsManager(from: self, type: RestBusinessProfileManager.self)
    private lazy var chatManager: RestPrivateChatManager = RestService.shared.createOperationsManager(from: self, type: RestPrivateChatManager.self)

    private var newPrivateMessages: PrivateChatListModel?

    private var filterArray: [String] = [R.string.localizable.allFilter(),
        TypeOfPost.general.filterTitle,
        TypeOfPost.news.filterTitle,
        TypeOfPost.crime.filterTitle,
        TypeOfPost.event.filterTitle,
        TypeOfPost.offer.filterTitle,
        TypeOfPost.media.filterTitle]

    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        setupPageViewController()
        tagsCollectionView.register(R.nib.filterItemCollectionCell)
        configureColors()
        configureFabButton()

        if let viewLayout = tagsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            viewLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackgroundMain), name: UIApplication.didEnterBackgroundNotification, object: nil)


        if let currentListController = pageController.viewControllers?.first as? HomeListViewController {
            currentListController.delegate = self
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFilter()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        floatyButton.close()
    }

    private func setupPageViewController() {
        addChild(pageController)
        containerView.addSubview(pageController.view)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints([
            pageController.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            pageController.view.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0),
            pageController.view.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0),
            pageController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
            ])

        pageController.didMove(toParent: self)
        pageController.dataSource = self
        pageController.delegate = self
        pageController.setViewControllers([allPostsController], direction: .forward, animated: false, completion: nil)
        updateButtonState()
    }

    // MARK: - Private actions
    @IBAction private func didTapAllPosts(_ sender: Any) {
        pageController.setViewControllers([allPostsController], direction: .reverse, animated: true, completion: nil)
        allPostsController.searchPostsByString = ""
        allPostsController.refreshPostsList()
        searchTextField.text = ""
        updateButtonState()
        updateFiltersState()
        tagsCollectionView.isHidden = false
        floatyButton.isHidden = false
        searchContainerView.isHidden = false
    }

    @IBAction private func searchButtonDidTap(_ sender: UIButton) {
        guard let currentListController = pageController.viewControllers?.first as? HomeListViewController,
            let text = searchTextField.text,
            text.count >= 1 else {
                return
        }

        currentListController.searchPostsByString = text
    }

    @IBAction private func didTapRecommendenPosts(_ sender: Any) {
        if pageController.viewControllers?.first is MyNeighborsViewController {
            pageController.setViewControllers([recommendedPostsController], direction: .reverse, animated: true, completion: nil)
        } else {
            pageController.setViewControllers([recommendedPostsController], direction: .forward, animated: true, completion: nil)
        }

        searchTextField.text = ""
        recommendedPostsController.searchPostsByString = ""
        recommendedPostsController.refreshPostsList()
        updateButtonState()
        updateFiltersState()
        tagsCollectionView.isHidden = false
        floatyButton.isHidden = false
        searchContainerView.isHidden = false
    }

    @IBAction private func didTapMyNeighbors(_ sender: UIButton) {
        pageController.setViewControllers([myNeighboursViewController], direction: .forward, animated: true, completion: nil)
        myNeighboursViewController.updateMap()
        updateButtonState()
        updateFiltersState()
        tagsCollectionView.isHidden = true
        floatyButton.isHidden = true
        searchContainerView.isHidden = true
    }

    @objc private func profileChanged() {
        updateFiltersState()
        configureFabButton()
        (pageController.viewControllers?.first as? HomeListViewController)?.refreshPostsList()
        myNeighboursViewController.updateMap()
        updateFilter()
    }

    @objc private func appMovedToBackgroundMain() {
        floatyButton.close()
    }
}

// MARK: - UI configurations
private extension HomeViewController {
    func configureFabButton() {
        view.addSubview(floatyButton)
        view.bringSubviewToFront(floatyButton)

        floatyButton.close()
        floatyButton.configureFloatyButton()
        floatyButton.configureFabAction()
    }

    func updateButtonState() {
        allPostsButton.isEnabled = pageController.viewControllers?.first != allPostsController
        recommendedPostsButton.isEnabled = pageController.viewControllers?.first != recommendedPostsController
        myNeighborsButton.isEnabled = pageController.viewControllers?.first != myNeighboursViewController

        defineButtonColorForState(button: allPostsButton, bottomView: allBottomView)
        defineButtonColorForState(button: recommendedPostsButton, bottomView: recommendedBottomView)
        defineButtonColorForState(button: myNeighborsButton, bottomView: myNeighborsBottomView)
    }

    func defineButtonColorForState(button: UIButton, bottomView: UIView) {
        if !button.isEnabled {
            button.setTitleColor(R.color.blueButton(), for: .normal)
            bottomView.backgroundColor = R.color.blueButton()
        } else {
            button.setTitleColor(R.color.greyMedium(), for: .normal)
            bottomView.backgroundColor = R.color.greyBackground()
        }
    }

    func configureColors() {
        allPostsButton.setTitleColor(R.color.blueButton(), for: .normal)
        recommendedPostsButton.setTitleColor(R.color.greyMedium(), for: .normal)
        myNeighborsButton.setTitleColor(R.color.greyMedium(), for: .normal)

        allBottomView.backgroundColor = R.color.blueButton()
        recommendedBottomView.backgroundColor = R.color.greyBackground()
        myNeighborsBottomView.backgroundColor = R.color.greyBackground()
    }
}

// MARK: - Filter actions
private extension HomeViewController {
    func updateFiltersState() {
        guard let currentListController = pageController.viewControllers?.first as? HomeListViewController else {
            return
        }

        currentListController.filters = []
        tagsCollectionView.indexPathsForSelectedItems?.filter({ $0.row != 0 }).forEach({ tagsCollectionView.deselectItem(at: $0, animated: true) })
        tagsCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .left)
    }

    func setFilter(_ filter: TypeOfPost) {
        guard let currentListController = pageController.viewControllers?.first as? HomeListViewController else {
            return
        }

        currentListController.filters = [filter]
    }

    func clearFilters() {
        guard let currentListController = pageController.viewControllers?.first as? HomeListViewController else {
            return
        }

        currentListController.filters = []
    }

    func updateFilter() {
        filterArray = [
            R.string.localizable.allFilter(),
            TypeOfPost.general.filterTitle,
            TypeOfPost.news.filterTitle,
            TypeOfPost.crime.filterTitle,
            TypeOfPost.event.filterTitle,
            TypeOfPost.offer.filterTitle,
            TypeOfPost.media.filterTitle
        ]

        if ArchiveService.shared.currentProfile?.type == .business ||
            ArchiveService.shared.currentProfile?.type == .basic &&
            ArchiveService.shared.seeBusinessContent {
            filterArray.append(TypeOfPost.onlyBusiness.filterTitle)
        }

        clearFilters()

        tagsCollectionView.reloadData()
        tagsCollectionView.layoutIfNeeded()

        if let currentListController = pageController.viewControllers?.first as? HomeListViewController, currentListController.filters.isEmpty {
            tagsCollectionView.indexPathsForSelectedItems?.filter({ $0.row != 0 }).forEach({ tagsCollectionView.deselectItem(at: $0, animated: true) })
            tagsCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .left)
        }
    }
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate
extension HomeViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case myNeighboursViewController:
            return recommendedPostsController
        case recommendedPostsController:
            return allPostsController
        default:
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case allPostsController:
            return recommendedPostsController
        case recommendedPostsController:
            return myNeighboursViewController
        case myNeighboursViewController:
            return nil
        default:
            return nil
        }
    }


    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        updateButtonState()
        updateFiltersState()

        if completed && pageViewController.viewControllers?.first is MyNeighborsViewController {
            tagsCollectionView.isHidden = true
            floatyButton.isHidden = true
            searchContainerView.isHidden = true
        } else {
            tagsCollectionView.isHidden = false
            floatyButton.isHidden = false
            searchContainerView.isHidden = false
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.filterItemCollectionCell, for: indexPath) else {
            NSLog("🔥 Error occurred while creating FilterItemCollectionCell")
            return UICollectionViewCell()
        }

        cell.setFilterTitle(filterArray[indexPath.row])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            clearFilters()
            collectionView.indexPathsForSelectedItems?.filter({ $0.row != 0 }).forEach({ collectionView.deselectItem(at: $0, animated: true) })
        } else {
            if collectionView.indexPathsForSelectedItems?.contains(IndexPath(item: 0, section: 0)) ?? false {
                collectionView.deselectItem(at: IndexPath(item: 0, section: 0), animated: true)
            }

            let cell = collectionView.cellForItem(at: indexPath)
            let filterName = (cell as? FilterItemCollectionCell)?.getFilterTitle()
            setFilter(filterName!)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let selectedIndecies = collectionView.indexPathsForSelectedItems,
            selectedIndecies.count == 1,
            selectedIndecies.first?.row == 0 {
            return false // prevent deselect All if it's only one select cell
        }

        return true
    }
}

// MARK: - UITextFieldDelegategdgb
extension HomeViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        guard let currentListController = pageController.viewControllers?.first as? HomeListViewController else {
            return false
        }

        currentListController.searchPostsByString = ""
        searchTextField.tintColor = .clear
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        searchTextField.tintColor = R.color.blueButton()
    }
}

// MARK: - SearchFieldUpdatable
extension HomeViewController: SearchFieldUpdatable {
    func clearTextField() {
        searchTextField.text = ""
    }
}
