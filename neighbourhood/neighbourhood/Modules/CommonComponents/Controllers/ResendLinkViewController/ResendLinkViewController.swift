//
//  ResendLinkViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class ResendLinkViewController: UIViewController {

    @IBOutlet weak var titleLabel: HeadingLabel!
    @IBOutlet weak var messageLabel: ParagraphLabel!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!

    lazy var registrationManager: RestRegistrationManager = RestService.shared.createOperationsManager(from: self, type: RestRegistrationManager.self)

    let email: String
    var onClose: (() -> Void)?
    var timer: Timer?

    static var disabledTill: Date?

    init(email: String, onClose: @escaping () -> Void) {
        self.email = email
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = Alert.Title.confirmEmail
        messageLabel.text = Alert.Message.confirmEmail
        resendButton.setTitle(Alert.Action.resendLink, for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let disabledTill = ResendLinkViewController.disabledTill,
            disabledTill > Date() {
            self.runTimer()
            self.timerTick()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    @IBAction func didTapClose(_ sender: Any) {
        dismiss(animated: true) {
            self.onClose?()
        }
    }

    @IBAction func didTapResend(_ sender: Any) {
        resendEmail()
    }

    private func resendEmail() {
        registrationManager.sendVerificationLink(email: email)
            .onStateChanged({ [weak self] (state) in
                if state == .started {
                    ResendLinkViewController.disabledTill = Calendar.current.date(byAdding: .minute, value: 2, to: Date())
                    self?.runTimer()
                }
            })
            .onComplete {(_) in
                Toast.show(message: Alert.Message.pleaseWaitResend)
        } .onError { [weak self] (error) in
            (self as? ErrorHandling)?.handleError(error)
            self?.timerStopped()
        } .run()
    }

    private func runTimer() {
        countdownLabel.isHidden = false
        resendButton.isHidden = true
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (_) in
            self?.timerTick()
        })
        timerTick()
    }

    private func timerTick() {
        print(Date(), ResendLinkViewController.disabledTill)
        guard let disabledTill = ResendLinkViewController.disabledTill,
            let seconds = Calendar.current.dateComponents([.second], from: Date(), to: disabledTill).second,
            seconds > 0 else {
            timerStopped()
            return
        }
        updateCountdown(seconds: seconds)
    }

    private func updateCountdown(seconds: Int) {
        let minutes = seconds / 60
        let seconds = seconds % 60
        countdownLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    private func timerStopped() {
        self.timer?.invalidate()
        resendButton.isHidden = false
        countdownLabel.isHidden = true
    }
}
