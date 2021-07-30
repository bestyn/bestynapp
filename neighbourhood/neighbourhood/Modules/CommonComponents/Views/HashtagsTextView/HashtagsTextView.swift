//
//  HashtagsTextView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol HashtagsTextViewDelegate: class {
    func hashtagsListToggle(isShown: Bool)
    func editingEnded()
}

class HashtagsTextView: UIView {

    private lazy var wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    private lazy var textViewStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.mainBlack()
        label.font = R.font.poppinsMedium(size: 14)
        return label
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 37)
        textViewHeightConstraint.isActive = true
        textView.heightAnchor.constraint(lessThanOrEqualToConstant: 37).isActive = true
        return textView
    }()
    private lazy var underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = R.color.greyStroke()
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }()
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = R.color.accentRed()
        label.font = R.font.poppinsMedium(size: 11)
        return label
    }()
    private lazy var hashtagsButton: UIButton = {
        let button = UIButton()
        button.borderWidth = 1
        button.borderColor = R.color.greyStroke()
        button.titleLabel?.font = R.font.poppinsMedium(size: 13)
        button.setTitleColor(R.color.greyMedium(), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        button.cornerRadius = 12
        button.setTitle("#hashtags", for: .normal)
        button.addTarget(self, action: #selector(toggleHashtags), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)
        return button
    }()
    private lazy var usersButton: UIButton = {
        let button = UIButton()
        button.borderWidth = 1
        button.borderColor = R.color.greyStroke()
        button.titleLabel?.font = R.font.poppinsMedium(size: 13)
        button.setTitleColor(R.color.greyMedium(), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        button.cornerRadius = 12
        button.setTitle("@users", for: .normal)
        button.addTarget(self, action: #selector(toggleMentions), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)
        return button
    }()
    private lazy var hashtagsTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "hashtagCell")
        return tableView
    }()
    private lazy var mentionsView: MentionsView = {
        let view = MentionsView(shouldChangeHeight: false)
        view.delegate = self
        view.isHidden = true
        return view
    }()
    private var textViewHeightConstraint: NSLayoutConstraint!

    private lazy var hashtagsManager: RestHashtagsManager = RestService.shared.createOperationsManager(from: self)
    private var popularHashtags: [HashtagModel] = []
    private var selectedMentions: [NSRange: (fullName: String, id: Int)] = [:]

    private(set) var textIsEmpty = true
    private var isTextViewMaxHeight = false
    private var isHashtagsShown: Bool = false {
        didSet {
            hashtagsTableView.isHidden = !isHashtagsShown
            delegate?.hashtagsListToggle(isShown: isHashtagsShown || isMentionsShown)
        }
    }

    private var isMentionsShown: Bool = false {
        didSet {
            mentionsView.isHidden = !isMentionsShown
            delegate?.hashtagsListToggle(isShown: isMentionsShown || isHashtagsShown)
        }
    }

    private var hashtags: [HashtagModel] = [] {
        didSet { hashtagsTableView.reloadData() }
    }

    public weak var delegate: HashtagsTextViewDelegate?
    public var text: String {
        get {
            textView.text
        }
        set {
            setTextViewText(newValue)
        }
    }

    public var textWithMentions: String {
        var text = textView.attributedText.string as NSString
        for range in selectedMentions.keys.sorted(by: {$0.location > $1.location}) {
            guard let profile = selectedMentions[range] else {
                continue
            }
            text = text.replacingCharacters(in: range, with: "[\(profile.fullName)|\(profile.id)]") as NSString
        }
        return text as String
    }
    
    public var title: String? {
        didSet { titleLabel.text = title }
    }

    public var error: String? {
        didSet {
            errorLabel.text = error
            errorLabel.isHidden = error == nil
            underlineView.backgroundColor = error == nil ? R.color.greyStroke() : R.color.accentRed()
        }
    }

    public var placeholder: String? {
        didSet {
            setPlaceholder()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
}

extension HashtagsTextView {
    private func setupView() {
        textViewStackView.addArrangedSubview(titleLabel)
        textViewStackView.addArrangedSubview(textView)
        textViewStackView.addArrangedSubview(underlineView)
        textViewStackView.addArrangedSubview(errorLabel)
        let hashtagsButtonWrapperView = UIView()
        let buttonsStackView = UIStackView()
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 10
        buttonsStackView.addArrangedSubview(hashtagsButton)
        buttonsStackView.addArrangedSubview(usersButton)
        hashtagsButtonWrapperView.addSubview(buttonsStackView)
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: hashtagsButtonWrapperView.topAnchor, constant: 17),
            buttonsStackView.leadingAnchor.constraint(equalTo: hashtagsButtonWrapperView.leadingAnchor),
            buttonsStackView.bottomAnchor.constraint(equalTo: hashtagsButtonWrapperView.bottomAnchor, constant: -17)
        ])
        textViewStackView.addArrangedSubview(hashtagsButtonWrapperView)
        wrapperStackView.addArrangedSubview(textViewStackView)
        wrapperStackView.addArrangedSubview(hashtagsTableView)
        wrapperStackView.addArrangedSubview(mentionsView)

        addSubview(wrapperStackView)
        wrapperStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            wrapperStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapperStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        setPlaceholder()
    }
}

extension HashtagsTextView {

    private func resizeTextView() {
        let maxHeight = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity)).height
        if maxHeight >= 100 {
            if !isTextViewMaxHeight {
                isTextViewMaxHeight = true
                textViewHeightConstraint.constant = 100
                textView.isScrollEnabled = true
            }
        } else {
            isTextViewMaxHeight = false
            textView.isScrollEnabled = false
            textViewHeightConstraint?.constant = maxHeight
        }
        invalidateIntrinsicContentSize()
    }

    private func replaceHashtag(with hashtag: HashtagModel) {
        let ranges = textView.text.linksRanges(types: [.hashtags])
        let attributedText: NSMutableAttributedString = textIsEmpty
            ? NSMutableAttributedString(string: "")
            : NSMutableAttributedString(attributedString: textView.attributedText)
        let selectedRange = textView.selectedRange
        let hashtagString = NSMutableAttributedString(string: hashtag.hashtag, attributes: [.font: R.font.poppinsRegular(size: 14), .foregroundColor : R.color.blueButton()])
        hashtagString.append(NSAttributedString(string: " "))
        var move = hashtagString.string.count
        if let currentRange = ranges.first(where: { range -> Bool in
            return NSLocationInRange(selectedRange.location, range.range) || selectedRange.location == range.range.upperBound
        }) {
            move = hashtagString.string.count - currentRange.range.length
            attributedText.replaceCharacters(in: currentRange.range, with: hashtagString)
        } else if selectedRange.location > 0,
                  textView.text[textView.text.utf16.indexAt(selectedRange.location - 1)] == "#" {
            move = hashtagString.string.count - 1
            attributedText.replaceCharacters(in: NSMakeRange(selectedRange.location - 1, 1), with: hashtagString)
        } else {
            attributedText.append(hashtagString)
        }
        textIsEmpty = false
        textView.attributedText = attributedText
        textView.becomeFirstResponder()
        textView.selectedRange = NSMakeRange(selectedRange.lowerBound + move, selectedRange.length)
        resizeTextView()
    }

    private func replaceMention(with profile: PostProfileModel) {
        let ranges = textView.text.linksRanges(types: [.mentions])
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        let selectedRange = textView.selectedRange
        let profileString = NSMutableAttributedString(string: "@\(profile.fullName)", attributes: [.font: R.font.poppinsRegular(size: 14), .foregroundColor : R.color.blueButton()])
        let finalString = profileString.mutableCopy() as! NSMutableAttributedString
        finalString.append(NSAttributedString(string: " "))
        var move = finalString.string.count
        if let currentRange = ranges.first(where: { range -> Bool in
            return NSLocationInRange(selectedRange.location, range.range) || selectedRange.location == range.range.upperBound
        }) {
            move = finalString.string.count - currentRange.range.length
            attributedText.replaceCharacters(in: currentRange.range, with: finalString)
        } else if selectedRange.location > 0,
                  textView.text[textView.text.utf16.indexAt(selectedRange.location - 1)] == "@" {
            move = finalString.string.count - 1
            attributedText.replaceCharacters(in: NSMakeRange(selectedRange.location - 1, 1), with: finalString)
        } else {
            attributedText.append(finalString)
        }
        textView.attributedText = attributedText
        textView.becomeFirstResponder()
        textView.selectedRange = NSMakeRange(selectedRange.lowerBound + move, selectedRange.length)

        let mentionRange = (attributedText.string as NSString).range(of: profileString.string)
        selectedMentions[mentionRange] = (profile.fullName, profile.id)
        isMentionsShown = true
        resizeTextView()
    }

    private func setTextViewText(_ text: String) {
        if text.isEmpty {
            setPlaceholder()
            return
        }
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
        let description = NSMutableAttributedString(
            string: newText,
            attributes: [.font: R.font.poppinsRegular(size: 14), .foregroundColor: R.color.mainBlack()])
        let hashtagsRanges = description.string.linksRanges(types: [.hashtags])
        for range in hashtagsRanges {
            description.addAttributes([
                .foregroundColor: R.color.blueButton()
            ], range: range.range)
        }
        for range in selectedMentions.keys {
            description.addAttributes([
                .foregroundColor: R.color.blueButton()
            ], range: range)
        }
        textView.attributedText = description
        textIsEmpty = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.resizeTextView()
        }
    }

    private func setPlaceholder() {
        guard let placeholder = placeholder else {
            return
        }
        if textIsEmpty {
            textView.attributedText = NSAttributedString(string: placeholder, attributes: [
                .font: R.font.poppinsRegular(size: 14),
                .foregroundColor: R.color.greyMedium()
            ])
        }
    }

    @objc private func toggleHashtags() {
        isHashtagsShown.toggle()
        if isHashtagsShown {
            restPopularHashtags()
            textView.becomeFirstResponder()
            let selection = textView.selectedRange
            guard selection.location > 0,
                  textView.text[textView.text.utf16.indexAt(selection.location - 1)] == "#"  else {
                setTextViewText(textView.text + "#") 
                return
            }
        }
    }

    @objc private func toggleMentions() {
        isMentionsShown.toggle()
        if isMentionsShown {
            textView.becomeFirstResponder()
            let selection = textView.selectedRange
            guard selection.location > 0,
                  textView.text[textView.text.utf16.indexAt(selection.location - 1)] == "@"  else {
                setTextViewText(textView.text + "@")
                return
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension HashtagsTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        errorLabel.isHidden = true
        underlineView.backgroundColor = R.color.greyStroke()

        if textIsEmpty {
            textView.text = nil
            textView.textColor = R.color.mainBlack()
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            setPlaceholder()
        }
        delegate?.editingEnded()
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
        }

        if text.count > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.textViewDidChange(textView)
            }
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        resizeTextView()
        textIsEmpty = textView.text.isEmpty
        let selectedRange = textView.selectedRange

        let attributedText = NSMutableAttributedString(string: textView.text, attributes: [
            .foregroundColor: R.color.mainBlack(),
            .font: R.font.poppinsRegular(size: 14)
        ])

        // hashtags
        var shouldShowHashtags = false
        let hashtagsRanges = textView.text.linksRanges(types: [.hashtags])
        if hashtagsRanges.count > 0 {
            for range in hashtagsRanges {
                attributedText.addAttributes([.foregroundColor: R.color.blueButton()], range: range.range)
                if NSLocationInRange(selectedRange.location, range.range) ||
                    selectedRange.location == range.range.upperBound {
                    restSearchHashtags(query: range.link.replacingOccurrences(of: "#", with: ""))
                    shouldShowHashtags = true
                }
            }
        }
        if !shouldShowHashtags, selectedRange.location > 0,
           textView.text[textView.text.utf16.indexAt(selectedRange.location - 1)] == "#" {
            restPopularHashtags()
            shouldShowHashtags = true
        }
        isHashtagsShown = shouldShowHashtags

        // mentions
        var shouldShowMentions = false
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
                shouldShowMentions = true
            }
        }

        isMentionsShown = shouldShowMentions
        
        textView.attributedText = attributedText
        textView.selectedRange = selectedRange
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension HashtagsTextView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hashtags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hashtagCell", for: indexPath)
        cell.textLabel?.textColor = .black
        cell.textLabel?.font = R.font.poppinsRegular(size: 14)
        cell.textLabel?.text = hashtags[indexPath.row].hashtag
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        replaceHashtag(with: hashtags[indexPath.row])
    }
}


extension HashtagsTextView {
    func restPopularHashtags() {
        if popularHashtags.count > 0 {
            hashtags = popularHashtags
            return
        }
        hashtagsManager.getPopularHastags()
            .onComplete { [weak self] (response) in
                if let hashtags = response.result {
                    self?.popularHashtags = hashtags
                    self?.hashtags = hashtags
                }
            }.run()
    }

    func restSearchHashtags(query: String) {
        hashtagsManager.searchHashtags(search: query, page: 1)
            .onComplete { [weak self] (response) in
                if let hashtags = response.result {
                    self?.hashtags = hashtags
                }
            }.run()
    }
}

extension HashtagsTextView: MentionsViewDelegate {
    func mentionedProfileSelected(_ profile: PostProfileModel) {
        replaceMention(with: profile)
        mentionsView.reset()
    }
}
