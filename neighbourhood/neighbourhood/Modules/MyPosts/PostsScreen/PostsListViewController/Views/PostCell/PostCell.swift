//
//  PostCell.swift
//  neighbourhood
//
//  Created by Dioksa on 26.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVKit
import ExpandableLabel
import FaveButton
import GSPlayer

private let ratio: CGFloat = 1.5

final class PostCell: BasePostCell {
    @IBOutlet private weak var scrollView: MediaScrollView!
    @IBOutlet private weak var pageControll: UIPageControl!
    @IBOutlet private weak var eventInfoStackView: UIStackView!
    @IBOutlet private weak var eventDateAndTimeLabel: UILabel!
    @IBOutlet private weak var eventTitleLabel: UILabel!
    @IBOutlet private weak var locationStackView: UIStackView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var holeStackView: UIStackView!
    @IBOutlet private weak var mediaView: UIView!
    @IBOutlet private weak var descriptionLabel: ExpandableLabel!
    @IBOutlet private weak var audioStackView: UIStackView!
    @IBOutlet private weak var videoView: UIView!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var videoViewHeightConstraint: NSLayoutConstraint!

    private let helper = PageScrollingHelper()
    private var videoPlayer = VideoPlayerView()
    private lazy var videoLayer: AVPlayerLayer = {
        let layer = videoPlayer.playerLayer
        layer.videoGravity = .resizeAspect
        videoView.layer.insertSublayer(layer, at: 0)
        return layer
    }()

    private var postImages: [UIImageView] = []
    var expanded: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDescriptionLabel()
        setupMediaView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        eventInfoStackView.isHidden = true
        postImages = []
        mediaView.isHidden = true
        audioStackView.isHidden = true
        audioStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        videoView.isHidden = true
        videoPlayer.pause(reason: .hidden)
    }

    override func fillAdditionalInfo(from post: PostModel) {
        if let media = post.media {
            updatePostMedia(media: media)
        }
        setTexts(post: post)
        updateElementsVisibility(post: post)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        videoPlayer.isMuted = ArchiveService.shared.storiesMuted
        setImageForMuteButton()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        descriptionLabel.text = post?.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        updateVideoView()
    }

    public func playVideo() {
        videoPlayer.resume()
    }

    public func hasVideo() -> Bool {
        if case .none = videoPlayer.state,
           case .error = videoPlayer.state {
            return false
        }
        return true
    }

    public func pauseVideo() {
        videoPlayer.pause(reason: .userInteraction)
        videoPlayer.seek(to: .zero)
    }

    @IBAction func didTapToggleMute(_ sender: Any) {
        videoPlayer.isMuted.toggle()
        setImageForMuteButton()
        ArchiveService.shared.storiesMuted = videoPlayer.isMuted
    }
}

// MARK: - Setup

extension PostCell {
    private func setupDescriptionLabel() {
        descriptionLabel.textReplacementType = .word
        descriptionLabel.numberOfLines = 2
        descriptionLabel.ellipsis = NSAttributedString(string: "...", attributes: [.foregroundColor: R.color.greyMedium()!])
        descriptionLabel.collapsedAttributedLink = NSAttributedString(string: R.string.localizable.viewAllTitle(), attributes: [.foregroundColor: R.color.greyMedium()!])
        descriptionLabel.delegate = self
    }

    private func setupMediaView() {
        scrollView.delegate = self
        pageControll.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openFullScreenImage))
        scrollView.addGestureRecognizer(tapRecognizer)
        let videoTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openFullScreenVideo))
        videoView.addGestureRecognizer(videoTapRecognizer)
    }

    @objc private func openFullScreenImage() {
        guard let currentMedia = post?.media?[pageControll.currentPage] else {
            return
        }
        cellDelegate?.openMedia(currentMedia)
    }
    @objc private func openFullScreenVideo() {
        guard let currentMedia = post?.media?.first(where: {$0.type == .video}) else {
            return
        }
        cellDelegate?.openMedia(currentMedia)
    }
}

// MARK: - Fill Data

extension PostCell {

    private func updateElementsVisibility(post: PostModel) {
        eventInfoStackView.isHidden = ![.event].contains(post.type)
        locationStackView.isHidden = ![.crime, .event].contains(post.type)
        priceLabel.isHidden = ![.offer].contains(post.type)
    }

    private func updateEventDateTime(post: PostModel) {
        guard post.type == .event else {
            return
        }
        guard let startTime = post.startDatetime else {
            if let endTime = post.endDatetime {
                eventDateAndTimeLabel.isHidden = false
                eventDateAndTimeLabel.text = endTime.dateTimeString
            } else {
                eventDateAndTimeLabel.isHidden = true
            }
            return
        }
        eventDateAndTimeLabel.isHidden = false
        guard let endTime = post.endDatetime, !endTime.isDateTimeEqual(startTime) else {
            eventDateAndTimeLabel.text = startTime.dateTimeString
            return
        }
        if startTime.isDateEqual(endTime) {
            eventDateAndTimeLabel.text = "\(startTime.eventDateTimeString) - \(endTime.timeString)"
            return
        }
        eventDateAndTimeLabel.text = "\(startTime.eventDateTimeString) - \(endTime.eventDateTimeString)"
    }

    private func setTexts(post: PostModel) {
        updateEventDateTime(post: post)

        addressLabel.text = post.address
        descriptionLabel.isHidden = post.description == nil
        descriptionLabel.collapsed = !expanded
        descriptionLabel.text = post.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        descriptionLabel.setNeedsLayout()
        eventTitleLabel.text = post.name

        if let price = post.price {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: GlobalConstants.Languages.speechLanguage)
            formatter.currencyCode = GlobalConstants.Common.currentCurrency
            priceLabel.text = formatter.string(from: NSNumber(value: price))
        }
    }

    private func updatePostMedia(media: [MediaDataModel]) {
        mediaView.isHidden = media.images.count + media.videos.count == 0
        audioStackView.isHidden = media.audios.count == 0

        var hasVideo = false
        media.forEach { media in
            switch media.type {
            case .image:
                addImageThumbnail(media: media)
            case .video:
                addVideo(media: media)
                hasVideo = true
            case .voice:
                let audioView = DownloadableAudioView()
                audioView.url = media.origin
                audioView.listenCount = media.viewsCount
                audioView.delegate = self
                audioStackView.addArrangedSubview(audioView)
                break
            }
        }

        pageControll.isHidden = postImages.count <= 1
        pageControll.numberOfPages = postImages.count
        scrollView.views = postImages
        mediaView.isHidden = postImages.count == 0
        videoView.isHidden = !hasVideo
    }
}

// MARK: - Private utility

extension PostCell {

    private func addVideo(media: MediaDataModel) {
        guard let videoURL = media.formatted?.origin else {
            let imageView = thumbnailImage()
            imageView.image = R.image.video_placeholder()
            if let thumbnail = media.formatted?.thumbnail {
                imageView.load(from: thumbnail, completion: {})
            } else {
                let originURL = media.origin
                let asset = AVURLAsset(url: originURL, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.appliesPreferredTrackTransform = true
                let time = CMTimeMake(value: 0, timescale: 1)

                imgGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (_, cgImage, _, result, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard let cgImage = cgImage else {
                        print("Failed to fetch video preview for \(originURL.absoluteString)")
                        return
                    }
                    DispatchQueue.main.async {
                        let uiImage = UIImage(cgImage: cgImage)
                        imageView.image = uiImage
                        imageView.setNeedsDisplay()
                    }
                }
            }
            return
        }
        videoPlayer.play(for: videoURL)
        videoPlayer.pause(reason: .userInteraction)
        if let videoRatio = media.videoRatio {
            let width = self.videoView.bounds.width
            let height = width * CGFloat(videoRatio)
            self.videoViewHeightConstraint.constant = height
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    private func addImageThumbnail(media: MediaDataModel) {
        if let imagesURL = media.formatted?.medium {
            let imageView = thumbnailImage()
            imageView.kf.setImage(with: imagesURL, placeholder: R.image.image_placeholder())
            postImages.append(imageView)
        }
    }

    private func thumbnailImage() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }

    private func updateVideoView() {
        videoLayer.frame = CGRect(origin: .zero, size: CGSize(width: videoView.bounds.width, height: videoViewHeightConstraint.constant))
    }

    private func setImageForMuteButton() {
        let image = videoPlayer.isMuted ? R.image.mute_stories_icon() : R.image.unmute_stories_icon()
        muteButton.setImage(image, for: .normal)
    }
}

// MARK: - UIScrollViewDelegate
extension PostCell: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = scrollView.contentOffset.x / (scrollView.frame.size.width)
        pageControll.currentPage = Int(pageNumber)
        pageControll.currentPageIndicatorTintColor = R.color.accentGreen()
    }
}

// MARK: - ExpandableTextViewDelegate

extension PostCell: ExpandableTextViewDelegate {
    func expandableTextView(_ textView: ExpandableTextView, didChangeState isExpanded: Bool) {
        if let post = post {
            cellDelegate?.reloadDescriptionLabel(post: post)
        }
    }
}

// MARK: - ExpandableLabelDelegate

extension PostCell: CustomExpandableLabelDelegate {
    func willExpandLabel(_ label: ExpandableLabel) {
        if let post = post {
            cellDelegate?.reloadDescriptionLabel(post: post)
        }
    }

    func didExpandLabel(_ label: ExpandableLabel) {
        if let post = post {
            cellDelegate?.reloadDescriptionLabel(post: post)
        }
    }

    func willCollapseLabel(_ label: ExpandableLabel) {

    }

    func didCollapseLabel(_ label: ExpandableLabel) {

    }

    func linkPressed(type: CustomExpandableLabel.DetectedLinkType) {
        switch type {
        case .link(let urlString):
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        case .hashtag(let hashtag):
            cellDelegate?.hashtagSelected(hashtag)
        case .profile(let profileId):
            cellDelegate?.mentionSelected(profileId: profileId)
        }
    }
}

extension PostCell: DownloadableAudioViewDelegate {
    func audioPlayed(url: URL) {
        guard let audioMedia = post?.media?.first(where: {$0.type == .voice && $0.origin == url}) else {
            return
        }
        cellDelegate?.mediaViewed(media: audioMedia)
    }
}

