//
//  StoryCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation
import GSPlayer

protocol StoryCellDelegate: class {
    func removeReaction(story: StoryListModel)
    func addReaction(story: StoryListModel, reaction: Reaction)
    func openMenu(story: StoryListModel)
    func openComments(story: StoryListModel)
    func toggleFollow(story: StoryListModel)
    func createStory()
    func hashtagSelected(_ hashtag: String)
    func openProfile(story: StoryListModel)
    func audioTapped(_ audio: AudioTrackModel)
    func canShowReactionPicker(completion: @escaping () -> Void)
    func mentionSelected(profileId: Int)
}

class StoryCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var subscribersLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: CustomExpandableLabel!
    @IBOutlet weak var muteUnmuteButton: UIButton!
    @IBOutlet weak var reactionPicker: ReactionPicker!
    @IBOutlet weak var pauseView: UIView!
    @IBOutlet weak var avatarContainerView: CircularProgressView!
    @IBOutlet weak var avatarView: MediumAvatarView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var commentsView: UIView!
    @IBOutlet weak var locationVIew: UIView!
    @IBOutlet weak var followView: UIView!
    @IBOutlet weak var audioView: UIStackView!
    @IBOutlet weak var audioLabel: UILabel!

    // MARK: - Private variables

    private var player = VideoPlayerView()
    private var playerLayer: AVPlayerLayer { player.playerLayer }
    private var isPlaying: Bool = false {
        didSet { updatePlayingState() }
    }
    private var hasMyReaction: Bool = false
    private var duration: Double = 0
    private var statusObserver: NSKeyValueObservation?
    private var progressObserver: Any?
    private var expanded: Bool = false

    // MARK: - Public variables
    public var storyListModel: StoryListModel! {
        didSet { fillData() }
    }
    private var story: PostModel {
        storyListModel.story
    }
    public weak var delegate: StoryCellDelegate?

    // MARK: - Lifecicle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarContainerView.setProgressWithAnimation(value: 0)
        player.pause()
        if let progressObserver = progressObserver {
            player.removeTimeObserver(progressObserver)
            self.progressObserver = nil
        }
    }

    // MARK: - IBActions

    @IBAction func didTapReaction(_ sender: Any) {
        toggleReaction()
    }

    @IBAction func didTapMenu(_ sender: Any) {
        delegate?.openMenu(story: storyListModel)
    }

    @IBAction func didTapToggleMute(_ sender: Any) {
        toggleMute()
    }

    @IBAction func didTapComments(_ sender: Any) {
        delegate?.openComments(story: storyListModel)
    }

    @IBAction func didTapFollow(_ sender: Any) {
        delegate?.toggleFollow(story: storyListModel)
    }

    @IBAction func didTapCreateStory(_ sender: Any) {
        delegate?.createStory()
    }

    @IBAction func didTapTogglePlay(_ sender: Any) {
        togglePlay()
    }
    
}

// MARK: - Configuration

extension StoryCell {

    private func setupViews() {
        setupPlayer()
        setupReactionButton()
        setupReactionPicker()
        setupProfileGestures()
        setupDescriptionLabel()
        setupAudioGestures()
    }

    private func setupPlayer() {
        playerLayer.frame = self.bounds
        playerLayer.videoGravity = .resizeAspectFill
        self.layer.insertSublayer(playerLayer, at: 0)
        player.stateDidChanged = { state in
            print(state)
        }
        player.replay = { [weak self] in
            guard let remoteURL = self?.story.media?.first?.origin, self?.player.playerURL == remoteURL else {
                return
            }
            CacheManager.of(type: .file).insert(url: remoteURL, completion: nil)
        }
    }

    private func setupDescriptionLabel() {
        descriptionLabel.font = R.font.poppinsRegular(size: 13)
        descriptionLabel.linkFont = R.font.poppinsSemiBold(size: 13)
        descriptionLabel.linkColor = .white
        descriptionLabel.textReplacementType = .word
        descriptionLabel.numberOfLines = 2
        descriptionLabel.shouldCollapse = true
        descriptionLabel.ellipsis = NSAttributedString(string: "...", attributes: [.foregroundColor: UIColor.white])
        descriptionLabel.collapsedAttributedLink = NSAttributedString(string: R.string.localizable.viewAllTitle(), attributes: [.foregroundColor: UIColor.white, .font: R.font.poppinsSemiBold(size: 13)])
        descriptionLabel.expandedAttributedLink = NSAttributedString(string: R.string.localizable.viewLessTitle(), attributes: [.foregroundColor: UIColor.white, .font: R.font.poppinsSemiBold(size: 13)])
        descriptionLabel.delegate = self
    }

    private func setupProfileGestures() {
        let avatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        let nameTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        avatarView.isUserInteractionEnabled = true
        nameLabel.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(avatarTapRecognizer)
        nameLabel.addGestureRecognizer(nameTapRecognizer)
    }

    private func setupAudioGestures() {
        let audioTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(audioTapped))
        audioView.isUserInteractionEnabled = true
        audioView.addGestureRecognizer(audioTapRecognizer)
    }

    private func setupReactionButton() {
        likeButton.imageView?.contentMode = .scaleAspectFit
    }

    private func setupReactionPicker() {
        reactionPicker.delegate = self
    }
}

// MARK: - Fill data

extension StoryCell {
    private func fillData() {
        fillStoryInfo()
        fillDescription()
        fillVideo()
        fillReaction()
        fillMenuLabels()
    }

    private func fillDescription() {
        descriptionLabel.isHidden = story.description == nil
        descriptionLabel.collapsed = !expanded
        descriptionLabel.text = story.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        descriptionLabel.setNeedsLayout()
    }

    private func fillVideo() {
        guard let videoURL = story.media?.first?.origin else {
            return
        }
        CacheManager.of(type: .file).get(url: videoURL) { [weak self] (localURL) in
            self?.player.play(for: localURL ?? videoURL)
            let observerTime = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            self?.progressObserver = self?.player.addPeriodicTimeObserver(forInterval: observerTime, queue: .main, using: { [weak self] (time) in
                guard let duration = self?.player.totalDuration else {
                    return
                }
                self?.avatarContainerView.setProgressWithAnimation(value: Float(time.seconds / duration))
                if time.seconds >= duration {
                    self?.player.seek(to: .zero)
                }
            })
            self?.player.isMuted = ArchiveService.shared.storiesMuted
            self?.setImageForMuteButton()
            self?.setNeedsLayout()
        }
    }

    private func fillReaction() {
        let image = story.myReaction?.reaction.image ?? R.image.like_stories_icon()
        self.likeButton.setImage(image, for: .normal)
    }

    private func fillStoryInfo() {
        avatarView.isBusiness = story.profile?.type == .business
        avatarView.updateWith(imageURL: story.profile?.avatar?.formatted?.medium, fullName: story.profile?.fullName ?? "")
        nameLabel.text = story.profile?.fullName
        locationVIew.isHidden  = story.address == nil
        locationLabel.text = story.address
        followView.isHidden = story.isMy
        audioView.isHidden = story.audio == nil
        audioLabel.text = story.audio?.description
    }

    private func fillMenuLabels() {
        let labels: [UILabel] = [subscribersLabel, commentsLabel, likesLabel]
        let values = [story.followersCount, story.messagesCount, story.reactionsCount]

        zip(labels, values).forEach {
            $0.0.setStrokeText(
                $0.1.description,
                font: R.font.poppinsSemiBold(size: 13)!,
                color: .white,
                strokeWidth: 4,
                strokeColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
            )
        }
    }
}

// MARK: - Private methods

extension StoryCell {
    private func toggleReaction() {
        if story.myReaction == nil {
            if let delegate = delegate {
                delegate.canShowReactionPicker { [weak self] in
                    self?.reactionPicker.isHidden.toggle()
                }
            } else {
                reactionPicker.isHidden.toggle()
            }
        } else {
            delegate?.removeReaction(story: storyListModel)
        }
    }

    private func toggleMute() {
        player.isMuted.toggle()
        setImageForMuteButton()
        ArchiveService.shared.storiesMuted = player.isMuted
    }

    private func togglePlay() {
        self.reactionPicker.isHidden = true
        self.isPlaying.toggle()
    }

    private func setImageForMuteButton() {
        let image = self.player.isMuted ? R.image.mute_stories_icon() : R.image.unmute_stories_icon()
        self.muteUnmuteButton?.setImage(image, for: .normal)
    }

    @objc private func profileTapped() {
        delegate?.openProfile(story: storyListModel)
    }

    private func updatePlayingState() {
        self.isPlaying
            ? self.player.resume()
            : self.player.pause(reason: .userInteraction)

        self.pauseView.isHidden = isPlaying
        isPlaying ? self.avatarContainerView?.resumeAnimation() : self.avatarContainerView?.pauseAnimation()
    }

    @objc private func audioTapped() {
        guard let audio = story.audio else {
            return
        }
        delegate?.audioTapped(audio)
    }
}

// MARK: - Public methods

extension StoryCell {
    public func play() {
        player.seek(to: .zero)
        self.isPlaying = true
    }

    public func pause() {
        self.isPlaying = false
    }
}

// MARK: - CustomExpandableLabelDelegate

extension StoryCell: CustomExpandableLabelDelegate {
    func linkPressed(type: CustomExpandableLabel.DetectedLinkType) {
        switch type {
        case .link(let urlString):
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        case .hashtag(let hashtag):
            delegate?.hashtagSelected(hashtag)
        case .profile(let profileId):
            delegate?.mentionSelected(profileId: profileId)
        }
    }

    func willExpandLabel(_ label: ExpandableLabel) {}

    func didExpandLabel(_ label: ExpandableLabel) {}

    func willCollapseLabel(_ label: ExpandableLabel) {}

    func didCollapseLabel(_ label: ExpandableLabel) {}


}

// MARK: - ReactionPickerDelegate

extension StoryCell: ReactionPickerDelegate {
    func reactionSelected(_ reaction: Reaction) {
        reactionPicker.isHidden = true
        delegate?.addReaction(story: storyListModel, reaction: reaction)
    }
}
