//
//  PlansViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

class PlansViewController: BaseViewController {

    @IBOutlet weak var plansStackView: UIStackView!
    @IBOutlet weak var restorePurchasesButton: UIButton!
    @IBOutlet weak var bottomButtonView: UIView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var firstSubscriptionPointLabel: UILabel!
    @IBOutlet weak var secondSubscriptionPointLabel: UILabel!
    @IBOutlet weak var thirdSubscriptionPointLabel: UILabel!
    @IBOutlet weak var screenTitleLabel: UILabel!
    @IBOutlet var displayViews: [UIView]!
    @IBOutlet weak var loaderView: UIView!
    @IBOutlet weak var descriptionView: UIView!


    private var selectedPlanID: String?
    private var purchasedPlan: PaymentPlanModel? {
        SubscriptionsManager.shared.currentSubscription
    }
    private var products: [IAPProductModel] = []
    private var isCurrentPlanFetched = false
    private var isAvailableSubscriptionsFetched = false

    override func viewDidLoad() {
        super.viewDidLoad()
        AnalyticsService.logOpenPlanSelector()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SubscriptionsManager.shared.delegate = self
        loaderView.isHidden = false
        SubscriptionsManager.shared.getCurrentSubscription()
        if ValidationManager().checkInternetConnection() {
            SubscriptionsManager.shared.getAvailableSubscriptions()
        }
    }

    @IBAction func didTapRestorePurchases(_ sender: Any) {
        restoreSubscriptions()
    }

    @IBAction func didTapBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func didTapPurchase(_ sender: Any) {
        if purchasedPlan != nil {
            manageSubscriptions()
            return
        }
        guard let selectedPlanID = selectedPlanID else {
            return
        }
        SubscriptionsManager.shared.subscribe(subscriptionID: selectedPlanID)
    }


    override func setupViewUI() {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: R.color.accentBlue() as Any,
            .font: R.font.poppinsMedium(size: 14) as Any,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: R.color.accentBlue() as Any
        ]
        bottomButtonView.dropShadow(color: .gray, opacity: 0.2, offSet: .zero, radius: 15)

        restorePurchasesButton.setAttributedTitle(NSAttributedString(string: R.string.localizable.restorePurchases(), attributes: attributes), for: .normal)
        titleLabel.text = R.string.localizable.selectPaymentPlan()
        descriptionLabel.text = R.string.localizable.paymentsPlansDescription()
        firstSubscriptionPointLabel.text = R.string.localizable.subscriptionFirstPoint()
        secondSubscriptionPointLabel.text = R.string.localizable.subscriptionSecondPoint()
        thirdSubscriptionPointLabel.text = R.string.localizable.subscriptionThirdPoint()
        bottomButton.setTitle(R.string.localizable.purchaseSubscription(), for: .normal)
    }


    private func updateProductsList() {
        plansStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        products.forEach { (product) in
            let view = PlanView()
            view.delegate = self
            view.planProduct = product
            if let purchasedPlan = purchasedPlan,
                purchasedPlan.productName == product.id,
                purchasedPlan.platform == .android {
                view.price = R.string.localizable.purchasedFromAndroid()
            }
            view.isSelected = product.id == selectedPlanID ?? purchasedPlan?.productName
            view.isChecked = product.id == selectedPlanID
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 100).isActive = true
            plansStackView.addArrangedSubview(view)
        }
    }

    private func toggleDisplayViews() {
        if isCurrentPlanFetched, isAvailableSubscriptionsFetched {
            displayViews.forEach({$0.isHidden = false})
            loaderView.isHidden = true
        }
        togglePlansViews()
    }

    private func togglePlansViews() {
        titleLabel.text = purchasedPlan == nil ? R.string.localizable.selectPaymentPlan() : R.string.localizable.yourCurrentSubscription()
        descriptionView.isHidden = purchasedPlan != nil
        bottomButton.setTitle(purchasedPlan == nil ? R.string.localizable.purchaseSubscription() : R.string.localizable.manageSubscription(), for: .normal)
        bottomButton.isEnabled = purchasedPlan != nil
        bottomButton.backgroundColor = purchasedPlan == nil ? R.color.greyMedium() : R.color.blueButton()
    }

    private func manageSubscriptions() {
        if purchasedPlan?.platform == .android {
            Alert(title: Alert.Title.warning, message: Alert.Message.manageSubscriptionOnAndroid)
                .configure(doneText: Alert.Action.ok)
                .show()
        } else {
            if let url = URL(string: "itms-apps://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions"),
            UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func restoreSubscriptions() {
        if let currentSubscription = SubscriptionsManager.shared.currentSubscription,
            currentSubscription.platform == .android {
            Alert(title: Alert.Title.subscriptionOnAndroid, message: Alert.Message.noSubscriptionFoundCheckAndroid)
            .configure(doneText: Alert.Action.ok)
            .show()
            return
        }
        SubscriptionsManager.shared.restoreSubscriptions()
    }

    private func showRestoreResult() {
        if SubscriptionsManager.shared.restoredSubscription != nil {
            Alert(title: Alert.Title.subscriptionRestored, message: Alert.Message.subscriptionRestored)
                .configure(doneText: Alert.Action.ok)
                .show()
            return
        }
        if SubscriptionsManager.shared.currentSubscription?.platform == .ios {
            Alert(title: Alert.Title.subscriptionOnAndroid, message: Alert.Message.noSubscriptionFoundCheckIOS)
                .configure(doneText: Alert.Action.ok)
                .show()
            return
        }
        Alert(title: Alert.Title.noSubscriptionFound, message: Alert.Message.noSubscriptionFound)
            .configure(doneText: Alert.Action.ok)
            .show()
    }
}

// MARK: - PlanViewDelegate

extension PlansViewController: PlanViewDelegate {

    func planViewSelected(_ planView: PlanView) {
        if purchasedPlan != nil {
            if purchasedPlan?.productName != planView.planProduct?.id {
                manageSubscriptions()
            }
            return
        }
        plansStackView.arrangedSubviews.compactMap({$0 as? PlanView}).forEach({
            $0.isChecked = false
            $0.isSelected = false
        })
        planView.isChecked = true
        planView.isSelected = true
        bottomButton.isEnabled = true
        bottomButton.backgroundColor = R.color.blueButton()
        selectedPlanID = planView.planProduct?.id
    }
}

//MARK: - SubscriptionsManagerDelegate

extension PlansViewController: SubscriptionsManagerDelegate {
    func availableSubscriptionsUpdated(_ subscriptions: [IAPProductModel]) {
        self.products = subscriptions
        updateProductsList()
    }

    func currentSubscriptionReceived(_ currentSubscription: PaymentPlanModel?) {
    }

    func subscriptionProcessBegan(_ process: SubscriptionProcess) {
        loaderView.isHidden = false
    }

    func subscriptionProcessEnd(_ process: SubscriptionProcess?) {
        switch process {
        case .getCurrentSubscription:
            isCurrentPlanFetched = true
            toggleDisplayViews()
        case .fetchAvailableSubscriptions:
            isAvailableSubscriptionsFetched = true
            toggleDisplayViews()
        case .subscribe:
            togglePlansViews()
        case .restorePurchases:
            showRestoreResult()
        default:
            break
        }
        loaderView.isHidden = true
    }

    func subscriptionProcessFailed(_ process: SubscriptionProcess?, with error: Error) {
        if let apiError = error as? APIError {
            if case .processingError(_, let fieldError) = apiError,
                fieldError?.result?.contains(where: {$0.code == BackendError.subscriptionAlreadyConnected }) ?? false {
                Toast.show(message: Alert.Message.subscriptionConnectedToOtherAccount)
                return
            }
            self.handleError(apiError)
            return
        }
        Toast.show(message: error.localizedDescription)
    }

    func subscriptionProcessEndWithCancel(_ process: SubscriptionProcess?) {
        loaderView.isHidden = true
    }
}
