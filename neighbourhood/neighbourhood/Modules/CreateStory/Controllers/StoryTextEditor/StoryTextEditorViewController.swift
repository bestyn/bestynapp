//
//  StoryTextEditorViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

// MARK: Defaults

private enum Defaults {
    static let fonts: [UIFont] = [
        R.font.rubikOneRegular(size: 34)!,
        R.font.pacificoRegular(size: 34)!,
        R.font.poppinsSemiBold(size: 34)!,
        R.font.oswaldRegular(size: 34)!,
        R.font.prostoOneRegular(size: 34)!,
        R.font.ptSansCaption(size: 34)!,
        R.font.playfairDisplayRegular(size: 34)!
    ]

    static let colors: [UIColor] = [
        .white, .black,
        .init(red: 0.854, green: 0.202, blue: 0.16, alpha: 1),
        .init(red: 1, green: 0.514, blue: 0.163, alpha: 1),
        .init(red: 0.992, green: 0.84, blue: 0.302, alpha: 1),
        .init(red: 0.546, green: 0.771, blue: 0.321, alpha: 1),
        .init(red: 0.321, green: 0.771, blue: 0.501, alpha: 1),
        .init(red: 0.321, green: 0.609, blue: 0.771, alpha: 1),
        .init(red: 0.207, green: 0.293, blue: 0.742, alpha: 1),
        .init(red: 0.433, green: 0.266, blue: 0.788, alpha: 1),
        .init(red: 0.941, green: 0.76, blue: 0.971, alpha: 1),
        .init(red: 0.733, green: 0.624, blue: 0.504, alpha: 1),
        .init(red: 0.338, green: 0.475, blue: 0.344, alpha: 1),
        .init(red: 0.231, green: 0.371, blue: 0.5, alpha: 1),
        .init(red: 0.709, green: 0.728, blue: 0.746, alpha: 1),
        .init(red: 0.364, green: 0.381, blue: 0.396, alpha: 1)
    ]

    static var highlightColors: [UIColor] {
        return [.clear] + colors
    }
}

// MARK: Delegate

protocol StoryTextEditorViewControllerDelegate: class {
    func textEditingComplete(entity: TextEditorEntity)
    func textEditingCanceled()
}

// MARK: Controller

class StoryTextEditorViewController: BaseViewController {

    // MARK: IBOutlets

    @IBOutlet private weak var textViewContainer: UIView!
    @IBOutlet private weak var fontButton: UIButton!
    @IBOutlet private weak var textColorButton: UIButton!
    @IBOutlet private weak var highlightButton: UIButton!
    @IBOutlet private weak var justifyButton: UIButton!
    @IBOutlet private weak var optionsCollectionView: UICollectionView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var cornersEditView: UIStackView!
    @IBOutlet private weak var cornersSlider: UISlider!
    @IBOutlet weak var doneButton: UIButton!
    private var textView: HighlightTextView!

    @objc override var canHideKeyboard: Bool { false }

    enum Setting {
        case font
        case color
        case highlight
    }

    // MARK: Variables

    private var currentSetting: Setting = .font {
        didSet {
            optionsCollectionView.reloadData()
            setSelectedOption()
            updateButtonsState()
            cornersEditView.isHidden = currentSetting != .highlight
        }
    }
    private var entity: TextEditorEntity = .init(text: "", textColor: .white, alignment: .center, font: Defaults.fonts[3], highlightColor: .clear, highlightRadius: 0) {
        didSet {
            updateTextView()
            updateDoneButton()
        }
    }

    public weak var delegate: StoryTextEditorViewControllerDelegate?

    // MARK: LifeCycle

    init(textEntity: TextEditorEntity? = nil) {
        if let textEntity = textEntity {
            self.entity = textEntity
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupCollectionView()
        setupBottomView()
        setupCornersSlider()
        updateTextView()
        updateButtonsState()
        setSelectedOption()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeTextView()
    }

    // MARK: IBActions

    @IBAction func didTapCancel(_ sender: Any) {
        cancel()
    }

    @IBAction func didTapDone(_ sender: Any) {
        done()
    }

    @IBAction func didTapFont(_ sender: Any) {
        currentSetting = .font
    }

    @IBAction func didTapColor(_ sender: Any) {
        currentSetting = .color

    }
    @IBAction func didTapHightlight(_ sender: Any) {
        currentSetting = .highlight
    }

    @IBAction func didTapJustify(_ sender: Any) {
        setNextJustify()
    }

    @IBAction func didChangeRadius(_ sender: UISlider) {
        let roundedValue = round(sender.value)
        sender.value = roundedValue
        entity.highlightRadius = Int(roundedValue * 10)
    }
}

// MARK: - Configuration

extension StoryTextEditorViewController {
    private func setupBottomView() {
        bottomView.roundCorners(corners: [.topLeft, .topRight], radius: 16)
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bottomView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bottomView.insertSubview(blurEffectView, at: 0)
    }

    private func setupCollectionView() {
        optionsCollectionView.allowsMultipleSelection = false
        optionsCollectionView.register(R.nib.fontCell)
        optionsCollectionView.register(R.nib.colorCell)
    }

    private func setupCornersSlider() {
        cornersEditView.transform = .init(rotationAngle: -.pi/2)
        cornersSlider.value = Float(entity.highlightRadius / 10)
    }

    private func setupTextView() {
        textView = HighlightTextView(textEditorEntity: entity)
        textView.delegate = self
        textViewContainer.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor),
        ])
    }
}

// MARK: - Private methods

extension StoryTextEditorViewController {
    private func updateTextView() {
        guard textView != nil else {
            return
        }
        textView.font = entity.font
        textView.textColor = entity.textColor
        textView.color = entity.highlightColor
        textView.highlightCornerRadius = entity.highlightRadius
        textView.textAlignment = entity.alignment
    }

    private func resizeTextView() {
        if textView.contentSize.height < textView.bounds.height {
            textView.centerVertically()
        }
    }

    private func close() {
        dismiss(animated: true)
    }

    private func updateButtonsState() {
        fontButton.borderWidth = currentSetting == .font ? 1 : 0
        textColorButton.borderWidth = currentSetting == .color ? 1 : 0
        highlightButton.borderWidth = currentSetting == .highlight ? 1 : 0
    }

    private func changeSetting(_ setting: Setting) {
        if currentSetting == setting {
            return
        }
        currentSetting = setting
    }

    private func setNextJustify() {
        switch textView.textAlignment {
        case .center:
            entity.alignment = .left
            justifyButton.setImage(R.image.text_editor_adjustment_left_icon(), for: .normal)
        case .left:
            entity.alignment = .right
            justifyButton.setImage(R.image.text_editor_ajustment_right_icon(), for: .normal)
        case .right:
            entity.alignment = .center
            justifyButton.setImage(R.image.text_editor_ajustment_center_icon(), for: .normal)
        default:
            break
        }
    }

    private func setSelectedOption() {
        let index: Int? = {
            switch currentSetting {
            case .font:
                return Defaults.fonts.firstIndex(of: entity.font)
            case .color:
                return Defaults.colors.firstIndex(of: entity.textColor)
            case .highlight:
                return Defaults.highlightColors.firstIndex(of: entity.highlightColor)
            }
        }()
        if let index = index {
            optionsCollectionView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        }
    }

    private func cancel() {
        Alert(title: nil, message: Alert.Message.cancelChanges)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { [weak self] (result) in
                if result == .done {
                    self?.delegate?.textEditingCanceled()
                    self?.close()
                }
            }
    }

    private func done() {
        entity.text = textView.text
        delegate?.textEditingComplete(entity: entity)
        close()
    }

    private func updateDoneButton() {
        doneButton.alpha = textView.text.isEmpty ? 0 : 1
        doneButton.isEnabled = !textView.text.isEmpty
    }
}

// MARK: - UITextViewDelegate

extension StoryTextEditorViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        if numberOfChars > 150 {
            textView.text = (newText as NSString).substring(to: 150)
            textView.selectedRange = NSMakeRange(150, 0)
            textViewDidChange(textView)
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        resizeTextView()
        updateDoneButton()
    }

    
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension StoryTextEditorViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch currentSetting {
        case .font:
            return Defaults.fonts.count
        case .color:
            return Defaults.colors.count
        case .highlight:
            return Defaults.highlightColors.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch currentSetting {
        case .font:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.fontCell, for: indexPath)!
            cell.font = Defaults.fonts[indexPath.row]
            return cell
        default:
            let colors = currentSetting == .highlight ? Defaults.highlightColors : Defaults.colors
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.colorCell, for: indexPath)!
            cell.color = colors[indexPath.row]
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch currentSetting {
        case .font:
            entity.font = Defaults.fonts[indexPath.row]
            resizeTextView()
        case .color:
            entity.textColor = Defaults.colors[indexPath.row]
        case .highlight:
            entity.highlightColor = Defaults.highlightColors[indexPath.row]
        }
    }
}
