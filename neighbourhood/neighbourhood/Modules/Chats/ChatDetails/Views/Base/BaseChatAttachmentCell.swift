//
//  BaseChatAttachmentCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import MBCircularProgressBar

class BaseChatAttachmentCell: BaseChatTextCell {

    @IBOutlet private weak var fileNameLabel: UILabel!
    @IBOutlet private weak var progressBar: MBCircularProgressBarView!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dividerView: UIView!

    override func fillSpecificData(from message: PrivateChatMessageModel) {
        super.fillSpecificData(from: message)
        let withText = !message.text.isEmpty
        fileNameLabel.text = message.attachment?.originName
        dividerView.isHidden = !withText
        chatMessageTextView.isHidden = !withText
        topConstraint.priority = UILayoutPriority(!withText ? 900 : 600)

        if withText {
            voiceButton.setImage(R.image.chat_voice_income_icon(), for: .normal)
        }
    }

    override func resetView() {
        super.resetView()
        voiceButton.setImage(nil, for: .normal)
    }


    // MARK: - Private actions
    @IBAction private func loadButtonDidTap(_ sender: UIButton) {
        guard let fileURL = message?.attachment?.origin  else {
            return
        }
        let task = DownloadManager.shared.activate().downloadTask(with: fileURL)
        task.resume()
        DownloadManager.shared.onProgress = { (progress) in
            OperationQueue.main.addOperation {
                UIView.animate(withDuration: 2.0, animations: {
                    self.progressBar.value = CGFloat(progress)
                }, completion: { _ in
                    Toast.show(message: R.string.localizable.downloadedFileAlert())
                })
            }
        }
    }
}
