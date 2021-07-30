//
//  AudioSearchCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class AudioSearchCell: UITableViewCell {

    @IBOutlet weak var audioTrackView: AudioTrackView!

    public var audioTrack: AudioTrackModel! {
        didSet { audioTrackView.audioTrack = audioTrack }
    }

    public var delegate: AudioTrackViewDelegate? {
        didSet { audioTrackView.delegate = delegate }
    }
}
