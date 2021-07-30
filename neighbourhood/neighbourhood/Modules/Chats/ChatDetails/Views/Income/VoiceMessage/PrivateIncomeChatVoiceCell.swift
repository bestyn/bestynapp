//
//  PrivateIncomeChatVoiceCell.swift
//  neighbourhood
//
//  Created by Dioksa on 06.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation
import SoundWave

final class PrivateIncomeChatVoiceCell: BaseChatVoiceCell {

    @IBOutlet weak var heardIconImageView: UIImageView!

    override func fillSpecificData(from message: PrivateChatMessageModel) {
        super.fillSpecificData(from: message)
        heardIconImageView.isHidden = message.attachment?.additional?.listened != true
    }
}
