//
//  ChatTextFieldView.swift
//  iCare
//
//  Created by Dioksa on 06.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum ChatType {
    case `private`, `public`
}

protocol ChatMessageSenderProtocol: AnyObject {
    func didTapSend(text: String?, attachment: ChatTextFieldView.Attachment?)
    func didTapUpdate(messageID: Int, text: String?, attachment: ChatTextFieldView.Attachment?)
    func didTapAddAttachment()
    func didTapRemoveAttachment()
    func didStartTyping()
    func didEndTyping()
}

enum AudioRecordAction {
    case start, change, end
}

protocol LongPressDelegate: AnyObject {
    func recordActionDid(_ actionType: AudioRecordAction)
}

final class ChatTextFieldView: UIView {
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var commentBackgroundView: UIView!
    @IBOutlet private weak var attachmentLabel: UILabel!
    @IBOutlet private var attachImageView: UIImageView!
    @IBOutlet private weak var recordView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var attachmentStackView: UIStackView!
    @IBOutlet weak var editingView: UIView!
    @IBOutlet weak var inputStackView: UIStackView!
    @IBOutlet private weak var mentionsView: MentionsView!
    @IBOutlet weak var mentionsHolderView: UIStackView!

    /// Public
    @IBOutlet weak var recordButton: DarkButton!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var messageTextFieldView: UITextView!
    @IBOutlet weak var removeAttachmentButton: UIButton!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recordHintView: UIButton!

    private var timer: Timer?
    private var seconds = 0
    private var originCoordinates: CGPoint?
    private var recordCancelled = false

    private var hintAnimating = false

    private var text: String?
    private var attachment: Attachment? {
        didSet { updateAttachmentView() }
    }
    private var editMessageID: Int? {
        didSet { editingView.isHidden = editMessageID == nil }
    }

    private var selectedMentions: [NSRange: (fullName: String, id: Int)] = [:]
    
    /// Public
    var chatType: ChatType = .public {
        didSet { updateLayout() }
    }
    weak var delegate: ChatMessageSenderProtocol?
    weak var audioDelegate: LongPressDelegate?


    public var textWithMentions: String {
        var text = messageTextFieldView.attributedText.string as NSString
        for range in selectedMentions.keys.sorted(by: {$0.location > $1.location}) {
            guard let profile = selectedMentions[range] else {
                continue
            }
            text = text.replacingCharacters(in: range, with: "[\(profile.fullName)|\(profile.id)]") as NSString
        }
        return text as String
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        loadFromXib(R.nib.chatTextFieldView.name, contextOf: ChatTextFieldView.self)
        setupTextView()
        setupGestureRecognizers()
        mentionsView.delegate = self
    }

    @IBAction func didTapSend(_ sender: Any) {
        if text == nil, attachment == nil {
            if chatType == .private {
                showRecordHint()
            }
            return
        }
        
        if let messageID = editMessageID {
            delegate?.didTapUpdate(messageID: messageID, text: textWithMentions, attachment: attachment)
        } else {
            delegate?.didTapSend(text: textWithMentions, attachment: attachment)
        }
    }

    @IBAction func didTapAttachment(_ sender: Any) {
        delegate?.didTapAddAttachment()
    }

    @IBAction func didTapRemoveAttachment(_ sender: Any) {
        removeAttachment()
    }
    @IBAction func didTapEndEdit(_ sender: Any) {
        clear()
    }
}

// MARK: - Public methods

extension ChatTextFieldView {

    struct Attachment {
        var id: Int? = nil
        let fileName: String?
        let attachment: AttachmentData

        static func from(_ attachmentModel: ChatAttachmentModel) -> Attachment {
            let attachment: AttachmentData
            switch attachmentModel.type {
            case .image:
                attachment = .storedImage(attachmentModel.origin)
            case .video:
                attachment = .video(attachmentModel.origin)
            case .voice:
                attachment = .voice(attachmentModel.origin)
            case .other:
                attachment = .file(attachmentModel.origin)
            }
            return .init(id: attachmentModel.id, fileName: attachmentModel.originName, attachment: attachment)
        }
    }

    public func addAttachment(_ attachment: Attachment) {
        self.attachment = attachment
    }

    public func edit(messageID: Int, text: String, attachment: Attachment?) {
        self.editMessageID = messageID
        var newText = text
        while let mentionRange = newText.linksRanges(types: [.rawMentions]).sorted(by: {$0.range.lowerBound < $1.range.lowerBound}).first {
            var link = mentionRange.link
            link.remove(at: link.index(link.endIndex, offsetBy: -1))
            link.remove(at: link.startIndex)
            let values = link.split(separator: "|")
            if let id = Int(values.last!) {
                let name = link.replacingOccurrences(of: "|\(id)", with: "")
                let mention = "@\(name)"
                newText = (newText as NSString).replacingCharacters(in: mentionRange.range, with: mention)
                let range = (newText as NSString).range(of: mention)
                selectedMentions[range] = (name, id)
            }
        }
        self.text = newText
        self.updateTextView()
        self.attachment = attachment
    }

    public func clear() {
        editMessageID = nil
        text = nil
        selectedMentions = [:]
        self.updateTextView()
        attachment = nil
        messageTextFieldView.resignFirstResponder()
    }
}

// MARK: - Setup

extension ChatTextFieldView {
    private func setupTextView() {
        messageTextFieldView.delegate = self
        messageTextFieldView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 0)
    }

    private func setupGestureRecognizers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: nil)
        tapRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        addGestureRecognizer(longPressRecognizer)
    }

    private func togglePlaceholder(shown: Bool) {
        if shown {
            if text != nil  {
                return
            }
            let placeholder = chatType == .public
                ? R.string.localizable.addCommentPlaceholder()
                : R.string.localizable.yourMessagePlaceholder()
            messageTextFieldView.attributedText = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: R.color.greyMedium(),
                .font: R.font.poppinsRegular(size: 14)
            ])
        } else {
            messageTextFieldView.text = text
            textViewDidChange(messageTextFieldView)
        }
    }
}

extension ChatTextFieldView {
    private func updateLayout() {
        recordButton.isHidden = chatType == .public

        if chatType == .private {
            recordButton.setBackgroundImage(R.image.record_icon(), for: .normal)
        }
    }

    private func updateAttachmentView() {
        guard let attachment = attachment else {
            attachmentStackView.isHidden = true
            return
        }
        attachmentStackView.isHidden = false
        attachmentLabel.text = attachment.fileName ?? attachment.attachment.fileName
        switch attachment.attachment {
        case .capturedImage, .storedImage:
            attachImageView.image = R.image.image_icon()
        case .video:
            attachImageView.image = R.image.camera_icon()
        case .file:
            attachImageView.image = R.image.file_icon()
        default:
            break
        }
        updateSendButtonState()
        setNeedsLayout()
    }

    private func updateSendButtonState() {
        if (text == nil || text == "") && attachment == nil {
            updateLayout()
            return
        }
        recordButton.isHidden = false
        if editMessageID == nil {
            recordButton.setBackgroundImage(R.image.send_message_button(), for: .normal)
        } else {
            recordButton.setBackgroundImage(R.image.edit_message_to_send_icon(), for: .normal)
        }
    }

    private func updateTextView() {
        if let text = text {
            messageTextFieldView.text = text
            textViewDidChange(messageTextFieldView)
        } else {
            if messageTextFieldView.isFocused {
                messageTextFieldView.text = nil
            } else {
                togglePlaceholder(shown: true)
            }
        }
        updateSendButtonState()
    }

    private func removeAttachment() {
        self.attachment = nil
        delegate?.didTapRemoveAttachment()
    }

    private func formIsValid() -> Bool {
        var valid = true

        if let validationError = ValidationManager()
            .validateMessageText(value: messageTextFieldView.text)
            .errorMessage(field: R.string.localizable.commentTitle()) {
            Toast.show(message: validationError.capitalizingFirstLetter())
            valid = false
        }

        return valid
    }

    private func showRecordHint() {
        if hintAnimating {
            return
        }
        hintAnimating = true
        recordHintView.isHidden = false
        UIView.animate(withDuration: 0.8) {
            self.recordHintView.transform = CGAffineTransform(translationX: 0, y: -50)
            self.recordHintView.alpha = 1
        }
        UIView.animateKeyframes(withDuration: 0.8, delay: 1.5, options: []) {
            self.recordHintView.transform = CGAffineTransform(translationX: 0, y: 200)
            self.recordHintView.alpha = 0
        } completion: { (_) in
            self.hintAnimating = false
            self.recordHintView.isHidden = true
            self.recordHintView.transform = .identity
        }
    }
}

extension ChatTextFieldView {

    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
    
    private func clearAfterRecord() {
        recordView.isHidden = true
        commentBackgroundView.isHidden = false
        inputStackView.setNeedsLayout()
        recordButton.layer.removeAllAnimations()
        seconds = 0
        timeLabel.text = "00:00"
        timer?.invalidate()
    }
    
    // MARK: - Private actions
    @objc private func longPressed(_ sender: UILongPressGestureRecognizer) {
        guard recordButton.currentBackgroundImage == R.image.record_icon() else { return }
        
        if sender.state == .began {
            recordCancelled = false
            recordButton.pulsate()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector:#selector(currentTimeChanged) , userInfo: nil, repeats: true)
            originCoordinates = sender.location(in: self)
            audioDelegate?.recordActionDid(.start)
            recordView.isHidden = false
            commentBackgroundView.isHidden = true
            inputStackView.setNeedsLayout()
        } else if sender.state == .changed {
            guard let originCoordinates = originCoordinates else { return }
            
            let coordinate = sender.location(in: self)
            if DirectionManager().defineSwipeDirection(originCoordinates, coordinate) == .left {
                recordCancelled = true
                clearAfterRecord()
                audioDelegate?.recordActionDid(.change)
            }
        } else if sender.state == .ended {
            clearAfterRecord()
            if !recordCancelled {
                audioDelegate?.recordActionDid(.end)
            }
        }
    }
    
    @objc private func currentTimeChanged() {
        seconds += 1
        timeLabel.text = timeString(TimeInterval(seconds))
    }
}

// MARK: - UITextViewDelegate
extension ChatTextFieldView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textViewHeightConstraint.constant = min(max(36, textView.contentSize.height), 66)
        textView.setNeedsLayout()
        (text?.count ?? 0) == 0 ? delegate?.didEndTyping() : delegate?.didStartTyping()

        // mentions
        let selectedRange = textView.selectedRange
        var shouldShowMentions = false
        let attributedText = NSMutableAttributedString(string: textView.text, attributes: [
            .foregroundColor: R.color.mainBlack(),
            .font: R.font.poppinsRegular(size: 14)
        ])

        for range in selectedMentions.keys {
            attributedText.setAttributes([
                .font: R.font.poppinsRegular(size: 14),
                .foregroundColor: R.color.blueButton()
            ], range: range)
        }

        let mentionsRanges = textView.text.linksRanges(types: [.mentions])
        if mentionsRanges.count > 0 {
            for range in mentionsRanges
            where NSLocationInRange(selectedRange.location, range.range) || selectedRange.location == range.range.upperBound {
                mentionsView.handleMention(name: range.link.replacingOccurrences(of: "@", with: ""))
                mentionsHolderView.isHidden = false
                shouldShowMentions = true
            }
        }

        if !shouldShowMentions {
            mentionsHolderView.isHidden = true
        }

        textView.attributedText = attributedText
        textView.selectedRange = selectedRange
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let currentText = textView.text,
            let currentTextRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: currentTextRange, with: text)

            guard updatedText.count <= 10000 else {
                return false
            }
            for selectedRange in selectedMentions.keys {
                if selectedRange.intersection(range) != nil {
                    selectedMentions.removeValue(forKey: selectedRange)
                    continue
                }
                if selectedRange.location > range.location {
                    let moveLength = updatedText.length - currentText.length
                    let newRange = NSRange(location: selectedRange.location + moveLength, length: selectedRange.length)
                    let profile = selectedMentions[selectedRange]
                    selectedMentions.removeValue(forKey: selectedRange)
                    selectedMentions[newRange] = profile
                }
            }

            self.text = updatedText
            self.updateSendButtonState()
        }
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        togglePlaceholder(shown: false)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        togglePlaceholder(shown: true)
        delegate?.didEndTyping()
    }
}


// MARK: -

extension ChatTextFieldView: MentionsViewDelegate {
    func mentionedProfileSelected(_ profile: PostProfileModel) {
        replaceMention(with: profile)
    }

    private func replaceMention(with profile: PostProfileModel) {
        let ranges = messageTextFieldView.text.linksRanges(types: [.mentions])
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(attributedString: messageTextFieldView.attributedText)
        let selectedRange = messageTextFieldView.selectedRange
        let profileString = NSMutableAttributedString(string: "@\(profile.fullName)", attributes: [.font: R.font.poppinsRegular(size: 14), .foregroundColor : R.color.blueButton()])
        let finalString = profileString.mutableCopy() as! NSMutableAttributedString
        finalString.append(NSAttributedString(string: " "))
        var move = finalString.string.count
        if let currentRange = ranges.first(where: { range -> Bool in
            return NSLocationInRange(selectedRange.location, range.range) || selectedRange.location == range.range.upperBound
        }) {
            move = finalString.string.count - currentRange.range.length
            attributedText.replaceCharacters(in: currentRange.range, with: finalString)
        } else {
            attributedText.append(finalString)
        }
        messageTextFieldView.attributedText = attributedText
        messageTextFieldView.becomeFirstResponder()
        messageTextFieldView.selectedRange = NSMakeRange(selectedRange.lowerBound + move, selectedRange.length)

        let mentionRange = (attributedText.string as NSString).range(of: profileString.string)

        for selectedRange in selectedMentions.keys {
            if selectedRange.location > mentionRange.location {
                let newRange = NSRange(location: selectedRange.location + move, length: selectedRange.length)
                let profile = selectedMentions[selectedRange]
                selectedMentions.removeValue(forKey: selectedRange)
                selectedMentions[newRange] = profile
            }
        }


        selectedMentions[mentionRange] = (profile.fullName, profile.id)
        mentionsHolderView.isHidden = true
    }
}
