//
//  BaseChatTextCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Kingfisher

protocol BaseChatTextCellDelegate: class {
    func openProfile(id: Int)
}

class BaseChatTextCell: BaseChatCell {

    @IBOutlet weak var voiceButton: UIButton!
    @IBOutlet weak var chatMessageTextView: UITextView!

    public weak var delegate: BaseChatTextCellDelegate?

    private var voiceOnImage: UIImage? {
        isIncome ? R.image.chat_voice_income_icon() : R.image.chat_voice_outcome_icon()
    }

    private var voiceOffImage: UIImage? {
        isIncome ? R.image.chat_voice_off_icon() : R.image.chat_voice_outcome_off_icon()
    }

    // MARK: - Private actions

    @IBAction private func voiceButtonDidTap(_ sender: UIButton) {
        guard  let message = message else {
            return
        }

        VoiceMessageManager.shared.toggleSpeakText(message: message)
    }

    // MARK: - Cell logic

    override func setupSpecificView() {
        chatMessageTextView.delegate = self
        chatMessageTextView.linkTextAttributes = [.foregroundColor: isIncome ? R.color.blueButton() : UIColor.white, .underlineStyle: 1]
        voiceButton.setImage(voiceOnImage, for: .normal)
        if let recognizers = chatMessageTextView.gestureRecognizers {
            for recognizer in recognizers where recognizer is UILongPressGestureRecognizer {
                recognizer.isEnabled = false
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleStartSpeaking(notification:)), name: .startSpeakingTextMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStopSpeaking(notification:)), name: .stopSpeakingTextMessage, object: nil)
    }

    override func resetView() {
        voiceButton.setImage(voiceOnImage, for: .normal)
    }

    override func fillSpecificData(from message: PrivateChatMessageModel) {
        var textToShow = message.text
        var detectedLinks = [(NSRange, Int)]()
        while let mention = textToShow.linksRanges(types: [.rawMentions]).sorted(by: {$0.range.lowerBound < $1.range.lowerBound}).first {
            var link = mention.link
            link.remove(at: link.index(link.endIndex, offsetBy: -1))
            link.remove(at: link.startIndex)
            let values = link.split(separator: "|")
            if let id = Int(values.last!) {
                let name = "@\(link.replacingOccurrences(of: "|\(id)", with: ""))"
                textToShow = (textToShow as NSString).replacingCharacters(in: mention.range, with: name)
                let range = (textToShow as NSString).range(of: name)
                detectedLinks.append((range, id))
            }
        }
        let attributedString = NSMutableAttributedString(string: textToShow, attributes: [
            .foregroundColor: chatMessageTextView.textColor,
            .font: chatMessageTextView.font
        ])
        for detectedLink in detectedLinks {
            attributedString.addAttribute(.link, value: "profile://\(detectedLink.1)", range: detectedLink.0)
        }
        chatMessageTextView.attributedText = attributedString
        DispatchQueue.main.async {
            UIView.setAnimationsEnabled(false)
                self.chatMessageTextView.sizeToFit()
                self.setNeedsLayout()
                self.layoutIfNeeded()
            UIView.setAnimationsEnabled(true)
        }
        if VoiceMessageManager.shared.currentSpeakingMessage?.id == message.id {
            voiceButton.setImage(voiceOffImage, for: .normal)
        }
    }

    @objc private func handleStopSpeaking(notification: Notification) {
        if (notification.object as? Int) == message?.id {
            voiceButton.setImage(voiceOnImage, for: .normal)
        }
    }

    @objc private func handleStartSpeaking(notification: Notification) {
        if (notification.object as? Int) == message?.id {
            voiceButton.setImage(voiceOffImage, for: .normal)
        }
    }
}

// MARK: - UITextViewDelegate

extension BaseChatTextCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString.starts(with: "profile://"),
           let id = Int(URL.absoluteString.replacingOccurrences(of: "profile://", with: "")) {
            delegate?.openProfile(id: id)
            return false
        }
        UIApplication.shared.open(URL)
        return false
    }
}
