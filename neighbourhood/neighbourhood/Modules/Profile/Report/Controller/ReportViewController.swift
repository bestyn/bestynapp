//
//  ReportViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 18.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol Reportable {
    var reportableID: Int { get }
    var reportableType: ReportEntityType { get }
    var reportReasons: [ReportReason] { get }
    var reportEntityName: String { get }
}

class ReportViewController: BaseViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var screenTitleLabel: UILabel!
    @IBOutlet private weak var reportButton: GreyButton!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var reportReasonTitleLabel: UILabel!

    private let entity: Reportable

    private var selectedReason: ReportReason? {
        didSet { updateButtonState() }
    }
    private var otherReason: String?
    
    private lazy var reportManager: RestReportsManager = RestService.shared.createOperationsManager(from: self)
    
    init(entity: Reportable) {
        self.entity = entity
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupTableView()
        setupTexts()
    }
    
    // MARK: - Private actions
    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func reportButtonAction(_ sender: UIButton) {
        sendReport()
    }
}

// MARK: - Setup

extension ReportViewController {

    private func setupLayout() {
        bottomView.dropShadow(color: R.color.greyStroke()!, opacity: 0.3, offSet: CGSize(width: 0, height: -5), radius: 3.0)
    }

    private func setupTableView() {
        tableView.register(R.nib.reportCell)
    }

    private func setupTexts() {
        screenTitleLabel.text = R.string.localizable.complaintReason()

        let buttonTitle: String = {
            switch entity.reportableType {
            case .post, .audio:
                return R.string.localizable.commonReport()
            default:
                return R.string.localizable.reportEntityOption(entity.reportEntityName.capitalized)
            }
        }()

        let reportQuestion: String = {
            switch entity.reportableType {
            case .post, .audio:
                return R.string.localizable.commonReportQuestion()
            default:
                return R.string.localizable.reportEntityQuestion(entity.reportEntityName.lowercased())
            }
        }()

        reportButton.setTitle(buttonTitle, for: .normal)
        reportReasonTitleLabel.text = reportQuestion
    }
}

// MARK: - Private methods

extension ReportViewController {

    private func updateButtonState() {
        reportButton.setBackgroundColor(color: R.color.blueButton()!, forState: .normal)
        reportButton.isUserInteractionEnabled = selectedReason != nil
    }

    private func sendReport() {
        guard let selectedReason = selectedReason else {
            return
        }
        // TODO: validate other reason
        let data = ReportData(
            entityID: entity.reportableID,
            entityType: entity.reportableType,
            reason: selectedReason,
            comment: otherReason)
        restSendReport(data: data)
    }
}

extension ReportViewController {
    private func restSendReport(data: ReportData) {
        reportManager.report(data: data)
            .onStateChanged { [weak self] (state) in
                self?.reportButton.isLoading = state == .started
        } .onComplete { [weak self] _ in
            Alert(title: R.string.localizable.reportSuccessTitle(), message: R.string.localizable.reviewedByAdminMessage())
            .show { (result) in
                AuthorizationRouter(in: self?.navigationController).popToRootController()
            }
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ReportViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entity.reportReasons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.reportCell, for: indexPath)  else {
            return UITableViewCell()
        }
        cell.title = entity.reportReasons[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedReason = entity.reportReasons[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
