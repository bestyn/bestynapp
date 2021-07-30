//
//  PrivateOutcomeChatVoiceCell.swift
//  neighbourhood
//
//  Created by Dioksa on 26.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation
import SoundWave

enum SoundAction {
    case play, pause
}

final class PrivateOutcomeChatVoiceCell: BaseChatVoiceCell {
    override var isIncome: Bool { false }

    @IBOutlet private weak var sentStateImageView: UIImageView!

    override func fillSpecificData(from message: PrivateChatMessageModel) {
        super.fillSpecificData(from: message)
        sentStateImageView.image = message.isRead ? R.image.sent_read_icon() : R.image.sent_unread_icon()
    }

}
