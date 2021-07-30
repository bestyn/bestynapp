//
//  BasePostCommentFileCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 04.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import MBCircularProgressBar

class BasePostCommentFileCell: BasePostCommentTextCell {
    @IBOutlet private weak var fileNameLabel: UILabel!
    @IBOutlet private weak var progressView: MBCircularProgressBarView!

    override func fillSpecificData(message: ChatMessageModel) {
        super.fillSpecificData(message: message)
        fileNameLabel.text = message.attachment?.originName
    }

    @IBAction private func loadButtonDidTap(_ sender: UIButton) {
        downloadFile()
    }

    private func downloadFile() {
        guard let fileURL = message?.attachment?.origin else {
            return
        }
        DownloadManager.shared.activate().downloadTask(with: fileURL).resume()
        DownloadManager.shared.onProgress = { (progress) in
            OperationQueue.main.addOperation {
                UIView.animate(withDuration: 2.0, animations: {
                    self.progressView.value = CGFloat(progress)
                }, completion: { _ in
                    if progress == 1 {
                        Toast.show(message: R.string.localizable.downloadedFileAlert())
                    }
                })
            }
        }
    }
    
}
