//
//  AudioTrackCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol AudioTrackCellDelegate: AudioTrackViewDelegate {
    func trackSelected(_ track: AudioTrackModel)
}

private enum Defaults {
    static let selectedColor = UIColor(red: 0.953, green: 0.922, blue: 0.996, alpha: 1)
}

class AudioTrackCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var audioTrackView: AudioTrackView!
    @IBOutlet weak var applyView: UIView!

    override var isSelected: Bool {
        didSet { updateSelectedState() }
    }

    public var track: AudioTrackModel! {
        didSet {
            audioTrackView.audioTrack = track
        }
    }
    public weak var delegate: AudioTrackCellDelegate? {
        didSet {
            audioTrackView.delegate = self.delegate
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.cornerRadius = 14
    }

    @IBAction func didTapApply(_ sender: Any) {
        if let track = track {
            delegate?.trackSelected(track)
        }
    }

    private func updateSelectedState() {
        containerView.backgroundColor = isSelected ? Defaults.selectedColor : .clear
        applyView.isHidden = !isSelected
    }
}
