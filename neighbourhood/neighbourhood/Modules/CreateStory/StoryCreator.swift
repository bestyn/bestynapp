//
//  StoryCreator.swift
//  neighbourhood
//
//  Created by Artem Korzh on 30.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

enum ImageProcessingError: Error {
    case outputSettingsApplyFailed
    case emptyPixelBuffer
    case contextCreationFailed
    case processingFailed
}

enum VideoCreationError: Error {
    case failedToCreateVideo
}

class StoryCreator {

    struct VideoEntity {
        let asset: AVAsset
        var videoCompositionTrack: AVMutableCompositionTrack!
        var audioCompositionTrack: AVMutableCompositionTrack!
        var videoComposition: AVMutableVideoComposition!
        var range: ClosedRange<Double>!

        var duration: Double {
            if let range = range {
                return range.upperBound - range.lowerBound
            } else {
                return asset.duration.seconds
            }
        }
    }

    struct TextEntity: Hashable {
        let id = UUID().uuidString
        var editorEntity: TextEditorEntity
        var position: CGPoint = .zero
        var transform: CGAffineTransform = .identity
        var range: ClosedRange<Double>!

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    struct AudioTrack {
        let track: AudioTrackModel
        var asset: AVAsset
        var startsAt: Double

        var duration: Double {
            asset.duration.seconds - startsAt
        }
    }

    struct ClipContent {
        var videoEntities: [VideoEntity] = []
        var composition: AVMutableComposition!
        var videoComposition: AVMutableVideoComposition!
        var layerComposition: AVMutableVideoComposition?
        var audioMix: AVAudioMix?
        var finalRange: ClosedRange<Double>!

        var lastPosition: CMTime { videoEntities.reduce(.zero, {$0 + $1.asset.duration}) }
        var assetParams: VideoAssetParams { .init(asset: composition, videoComposition: videoComposition, layerComposition: nil, audioMix: audioMix) }
        var backgroundSong: AudioTrack?
    }

    enum Mode {
        case recorded
        case gallery
        case text
        case duet
    }

    enum VolumeTrack {
        case original
        case added
    }

    static let shared = StoryCreator()

    private init() {
        setEmptyClip()
    }

    private(set) var mode: Mode = .recorded
    private var shouldMute: Bool = false
    private(set) var resultClipParams: VideoAssetParams!
    private(set) var editingClipContent: ClipContent!
    private(set) var sourceClipContent: ClipContent!
    private(set) var texts: [TextEntity] = []
    private(set) var textVideoLength: Double = 60
    private(set) var currentTextGradient: StoryGradient = StoryGradient.available[0]
    private(set) var textBackgroundLayer = CAGradientLayer()
    private(set) var originalVolume: Float = 1
    private(set) var addedVolume: Float = 0.5
    public var backgroundSong: AudioTrack? { editingClipContent?.backgroundSong ?? sourceClipContent.backgroundSong  }
    private(set) var duetOrigin: PostModel?
    private(set) var duetOriginAsset: AVAsset?

    private let videoSize: CGSize = {
        let width = UIScreen.main.bounds.size.multiplied(scale: UIScreen.main.scale).width
        var height = (width * 16 / 9).rounded(.toNearestOrEven)
        if height.truncatingRemainder(dividingBy: 2) != 0 {
            height -= 1
        }
        return CGSize(width: width, height: height)
    }()

    public var recordedDurations: [Double] { sourceClipContent.videoEntities.map({$0.asset.duration.seconds}) }
    public var recordedLength: Double { recordedDurations.reduce(0, +) }

}

// MARK: - Public setters

extension StoryCreator {
    public func setMode(_ mode: Mode) {
        self.mode = mode
        self.reset()
        if mode == .text {
            sourceClipContent.videoEntities = [.init(asset: AVAsset(url: R.file.blank_1080pMp4()!), range: 0...textVideoLength)]
            sourceClipContent = recreateComposition(in: sourceClipContent)
            sourceClipContent.finalRange = 0...min(sourceClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
            updateGradientLayer()
            addedVolume = 1
        } else {
            addedVolume = 0.5
        }
        resultClipParams = resultAsset(from: sourceClipContent)
    }

    public func addRecordedVideo(fileURL: URL) {
        let asset = AVURLAsset(url: fileURL)
        sourceClipContent.videoEntities.append(.init(asset: asset))
        sourceClipContent = recreateComposition(in: sourceClipContent)
        sourceClipContent.finalRange = 0...min(sourceClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
        resultClipParams = resultAsset(from: sourceClipContent)
    }

    public func removeLastVideo() {
        sourceClipContent.videoEntities.removeLast()
        sourceClipContent = recreateComposition(in: sourceClipContent)
        sourceClipContent.finalRange = 0...min(sourceClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
        resultClipParams = resultAsset(from: sourceClipContent)
    }

    public func addStoredVideo(asset: AVAsset) {
        let maxSeconds = min(asset.duration.seconds, 60)
        let entity = VideoEntity(asset: asset, range: 0...maxSeconds)
        if self.editingClipContent != nil {
            self.editingClipContent.videoEntities.append(entity)
            self.editingClipContent = self.recreateComposition(in: self.editingClipContent)
            editingClipContent.finalRange = 0...min(editingClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
            self.resultClipParams = self.resultAsset(from: self.editingClipContent)
        } else {
            self.sourceClipContent.videoEntities.append(entity)
            self.sourceClipContent = self.recreateComposition(in: self.sourceClipContent)
            sourceClipContent.finalRange = 0...min(sourceClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
            self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
        }
    }

    public func addStoredImage(image: UIImage, completion: @escaping (Error?) -> Void ) {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(Date().timeIntervalSince1970 ).mp4")
        let videoWriter: AVAssetWriter
        do {
            videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            completion(error)
            return
        }

        let size: CGSize = .init(width: image.size.width, height: image.size.height)

        let outputSettings: [String: Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : size.width,
            AVVideoHeightKey : size.height]

        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: .video) else {
            completion(ImageProcessingError.outputSettingsApplyFailed)
            return
        }

        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: image.size.width,
                kCVPixelBufferHeightKey as String: image.size.height
            ])

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }

        if videoWriter.startWriting() {
            videoWriter.startSession(atSourceTime: CMTime.zero)
        } else {
            completion(videoWriter.error)
            return
        }

        var pixelBufferCreated = true
        var pixelBuffer: CVPixelBuffer? = nil
        guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            completion(ImageProcessingError.emptyPixelBuffer)
            return
        }
        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)

        if let pixelBuffer = pixelBuffer, status == 0 {
            let managedPixelBuffer = pixelBuffer
            CVPixelBufferLockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(data: data, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue),
                  let cgImage = image.cgImage else {
                return
            }

            context.clear(CGRect(origin: .zero, size: size))
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        } else {
            print("Failed to allocate pixel buffer")
            pixelBufferCreated = false
        }

        if pixelBufferCreated, let pixelBuffer = pixelBuffer {
            var appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: .zero)
            while !videoWriterInput.isReadyForMoreMediaData {}

            let frameTime: CMTime = CMTimeMake(value: 3, timescale: 1)
            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            if (!appendSucceeded) {
                return
            }
            videoWriterInput.markAsFinished()
            videoWriter.endSession(atSourceTime: frameTime)
            videoWriter.finishWriting { [weak self] in
                guard let self = self else {
                    return
                }
                if videoWriter.status == .completed {
                    let asset = AVAsset(url: outputURL)
                    let entity = VideoEntity(
                        asset: asset,
                        range: 0...3)
                    if self.editingClipContent != nil {
                        self.editingClipContent.videoEntities.append(entity)
                        self.editingClipContent = self.recreateComposition(in: self.editingClipContent)
                        self.editingClipContent.finalRange = 0...min(self.editingClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
                        self.resultClipParams = self.resultAsset(from: self.editingClipContent)
                    } else {
                        self.sourceClipContent.videoEntities.append(entity)
                        self.sourceClipContent = self.recreateComposition(in: self.sourceClipContent)
                        self.sourceClipContent.finalRange = 0...min(self.sourceClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
                        self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
                    }
                    completion(nil)
                }
            }
        } else {
            completion(ImageProcessingError.processingFailed)
        }

    }

    public func setShouldMute(_ shouldMute: Bool) {
        self.shouldMute = shouldMute
    }

    public func clearTexts() {
        texts = []
    }

    public func startEditing() {
        editingClipContent = sourceClipContent
    }

    public func cancelEditing() {
        editingClipContent = nil
    }

    public func saveEdit() {
        sourceClipContent = editingClipContent
        sourceClipContent = recreateComposition(in: sourceClipContent)
        resultClipParams = resultAsset(from: sourceClipContent)
        editingClipContent = nil
    }

    public func setEditingTotalRange(_ range: ClosedRange<Double>) {
        if editingClipContent == nil {
            fatalError("You should call startEditing first")
        }
        texts = []
        editingClipContent.finalRange = range
    }

    public func setEditingClipRange(for clip: VideoEntity, range: ClosedRange<Double>) {
        if editingClipContent == nil {
            fatalError("You should call startEditing first")
        }
        texts = []
        editingClipContent.videoEntities = editingClipContent.videoEntities.map { (entity) in
            if entity.asset == clip.asset {
                var entity = entity
                entity.range = range
                return entity
            }
            return entity
        }
        editingClipContent = recreateComposition(in: editingClipContent)
        editingClipContent.finalRange = 0...min(editingClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
    }

    public func removeClip(_ clip: VideoEntity) {
        editingClipContent.videoEntities.removeAll(where: {$0.asset == clip.asset})
        editingClipContent = recreateComposition(in: editingClipContent)
        editingClipContent.finalRange = 0...min(editingClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
    }

    public func moveClip(from oldPosition: Int, to newPosition: Int) {
        let entity = editingClipContent.videoEntities[oldPosition]
        editingClipContent.videoEntities.remove(at: oldPosition)
        editingClipContent.videoEntities.insert(entity, at: newPosition)
        editingClipContent = recreateComposition(in: editingClipContent)
    }

    public func addText(entity: TextEditorEntity) {
        texts.append(.init(editorEntity: entity))
        self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
    }

    public func updateTextEntity(for textEntity: TextEntity) {
        guard let index = texts.firstIndex(of: textEntity) else {
            return
        }
        texts.remove(at: index)
        texts.append(textEntity)
        self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
    }

    public func removeText(entity: TextEntity) {
        guard let index = texts.firstIndex(of: entity) else {
            return
        }
        texts.remove(at: index)
    }

    public func reset() {
        setEmptyClip()
        editingClipContent = nil
        shouldMute = false
        texts = []
        addedVolume = 0.5
        originalVolume = 1
        currentTextGradient = StoryGradient.available[0]
    }

    public func changeTextBackgroundGradient(_ gradient: StoryGradient) {
        currentTextGradient = gradient
        updateGradientLayer()
        self.sourceClipContent = self.recreateComposition(in: self.sourceClipContent)
        sourceClipContent.finalRange = 0...min(sourceClipContent.videoEntities.reduce(0, {$0 + $1.range.upperBound - $1.range.lowerBound}), 60)
        self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
    }

    public func changeTextStoryDuration(seconds: Double) {
        sourceClipContent.videoEntities[0].range = 0...seconds
        texts = texts.map({ (originalText) -> TextEntity in
            var newEntity = originalText
            newEntity.range = nil
            return newEntity
        })
        self.sourceClipContent = self.recreateComposition(in: self.sourceClipContent)
        self.sourceClipContent.finalRange = 0...seconds
        self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
    }

    public func setAudioTrack(track: AudioTrackModel) {
        if backgroundSong == nil {
            self.originalVolume = mode == .text ? 0 : 0.5
        }
        sourceClipContent.backgroundSong = AudioTrack(track: track, asset: AVAsset(url: track.url), startsAt: 0)
        self.sourceClipContent = self.recreateComposition(in: self.sourceClipContent)
        self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
    }

    public func setAudioStart(_ start: Double) {
        guard backgroundSong != nil else {
            return
        }
        if self.editingClipContent != nil {
            self.editingClipContent.backgroundSong?.startsAt = start
            self.editingClipContent = self.recreateComposition(in: self.editingClipContent)
        } else {
            self.sourceClipContent.backgroundSong?.startsAt = start
            self.sourceClipContent = self.recreateComposition(in: self.sourceClipContent)
        }
    }

    public func changeVolume(track: VolumeTrack, volume: Float) {
        switch track {
        case .original:
            originalVolume = volume
        case .added:
            addedVolume = volume
        }
        self.sourceClipContent = self.recreateComposition(in: self.sourceClipContent)
        self.resultClipParams = self.resultAsset(from: self.sourceClipContent)
    }

    public func setDuetOrigin(story: PostModel) {
        guard let url = story.media?.first?.origin else {
            return
        }
        setMode(.duet)
        duetOrigin = story
        duetOriginAsset = AVAsset(url: url)
        CacheManager.of(type: .file).get(url: url) { [weak self] (cachedURL) in
            if let cachedURL = cachedURL {
                self?.duetOriginAsset = AVAsset(url: cachedURL)
            }
        }
    }
}

// MARK: - Public getters

extension StoryCreator {
    public func getThumbnail(at second: Int, completion: @escaping (UIImage) -> Void) {
        let imageGenerator = AVAssetImageGenerator(asset: resultClipParams.asset)
        imageGenerator.videoComposition = resultClipParams.layerComposition
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: Int64(second), timescale: 1)

        var actualTime : CMTime = CMTimeMake(value: 0, timescale: 0)
        if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: &actualTime) {
            let image = UIImage(cgImage: cgImage)
            completion(image)
        }
    }

    public func createVideo(completion: @escaping (URL?, Error?) -> Void) {
        var savePathUrl = FileManager.default.temporaryDirectory.appendingPathComponent("temp_video_data.mp4", isDirectory: false)
        savePathUrl = URL(fileURLWithPath: savePathUrl.path)
        do {
            try FileManager.default.removeItem(at: savePathUrl)
        } catch { print(error.localizedDescription) }

        let reader = try! AVAssetReader(asset: resultClipParams.asset)
        reader.timeRange = CMTimeRange(start: .zero, duration: resultClipParams.asset.duration)

        let videoTracks = resultClipParams.asset.tracks(withMediaType: .video)
        let videoOutput = AVAssetReaderVideoCompositionOutput(videoTracks: videoTracks, videoSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height
        ])
        videoOutput.videoComposition = resultClipParams.layerComposition
        videoOutput.alwaysCopiesSampleData = false
        reader.add(videoOutput)

        let audioTracks = resultClipParams.asset.tracks(withMediaType: .audio)

        let shouldRecordSound = !shouldMute && audioTracks.count > 0

        var audioOutput: AVAssetReaderAudioMixOutput?

        if shouldRecordSound {
            audioOutput = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: nil)
            audioOutput?.alwaysCopiesSampleData = false
            audioOutput?.audioMix = resultClipParams.audioMix
            reader.add(audioOutput!)
        }

        let writer = try! AVAssetWriter(outputURL: savePathUrl, fileType: .mp4)

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : videoSize.width,
            AVVideoHeightKey : videoSize.height
        ])
        videoInput.expectsMediaDataInRealTime = true

        var acl = AudioChannelLayout()
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_2_0
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0,
            AVEncoderBitRateKey: 64000,
            AVChannelLayoutKey: NSData(bytes: &acl, length: MemoryLayout<AudioChannelLayout>.size(ofValue: acl))
        ])

        audioInput.expectsMediaDataInRealTime = true

        writer.add(videoInput)
        writer.add(audioInput)



        print(writer.startWriting())
        print(reader.startReading())

        writer.startSession(atSourceTime: .zero)

        let group = DispatchGroup()
        let videoQueue = DispatchQueue(label: "video queue")
        let audioQueue = DispatchQueue(label: "audio queue")

        var videoBuffer: CMSampleBuffer!
        var audioBuffer: CMSampleBuffer!

        if reader.status == .failed {
            completion(nil, reader.error)
            return
        }


        if let audioOutput = audioOutput {
            group.enter()
            audioInput.requestMediaDataWhenReady(on: audioQueue) {
                while reader.status == .reading, audioInput.isReadyForMoreMediaData {
                    audioBuffer = audioOutput.copyNextSampleBuffer()
                    if let audioBuffer = audioBuffer {
                        audioInput.append(audioBuffer)
                    } else {
                        audioInput.markAsFinished()
                        group.leave()
                        break
                    }
                }
            }
        }

        group.enter()
        videoInput.requestMediaDataWhenReady(on: videoQueue) {
            while reader.status == .reading, videoInput.isReadyForMoreMediaData {
                videoBuffer = videoOutput.copyNextSampleBuffer()
                if let videoBuffer = videoBuffer {
                    videoInput.append(videoBuffer)
                } else {
                    videoInput.markAsFinished()
                    group.leave()
                    break
                }
            }
        }


        group.notify(queue: .main) {
            writer.finishWriting {
                if writer.status == .failed {
                    completion(nil, writer.error)
                } else {
                    completion(savePathUrl, nil)
                }
            }
        }
    }
}

// MARK: - Private methods

extension StoryCreator {
    private func setEmptyClip() {
        let compositions = createCompositions()
        sourceClipContent = .init(videoEntities: [], composition: compositions.composition, videoComposition: compositions.videoComposition, finalRange: 0...0)
    }

    private func createCompositions() -> (composition: AVMutableComposition, videoComposition: AVMutableVideoComposition) {
        let composition = AVMutableComposition()
        composition.naturalSize = videoSize
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        return (composition, videoComposition)
    }

    private func duetOriginTransform(track: AVAssetTrack) -> CGAffineTransform {
        guard track.mediaType == .video else {
            return track.preferredTransform
        }

        let destinationSize = videoSize
        let sourceSize = track.orientedSize
        let scale: CGFloat = destinationSize.width / sourceSize.width

        let resultTransform: CGAffineTransform = {
            if track.naturalSize == destinationSize {
                return track.preferredTransform
            }

            return track.preferredTransform
                .concatenating(.init(scaleX: scale, y: scale))
        }()

        let yOffset = (destinationSize.height - sourceSize.height * scale) / 2 - destinationSize.height / 4
        let xOffset = (destinationSize.width - sourceSize.width * scale) / 2
        return resultTransform
            .concatenating(.init(translationX: xOffset, y: yOffset))
    }

    private func properVideoTransform(track: AVAssetTrack) -> CGAffineTransform {
        guard track.mediaType == .video else {
            return track.preferredTransform
        }

        let destinationSize = videoSize

        if track.naturalSize == destinationSize {
            return track.preferredTransform
        }
        let sourceSize = track.orientedSize

        let scale: CGFloat = destinationSize.width / sourceSize.width

        let resultTransform = track.preferredTransform
            .concatenating(.init(scaleX: scale, y: scale))
        let yOffset = mode == .duet
            ? (destinationSize.height - sourceSize.height * scale) / 2 + destinationSize.height / 4
            : (destinationSize.height - sourceSize.height * scale) / 2
        let xOffset = (destinationSize.width - sourceSize.width * scale) / 2
        return resultTransform.concatenating(.init(translationX: xOffset, y: yOffset))
    }

    // TODO: refactor this and resultAssets

    private func recreateComposition(in clip: ClipContent) -> ClipContent {
        var clip = clip
        let compositions = createCompositions()
        clip.composition = compositions.composition
        clip.videoComposition = compositions.videoComposition
        var audioMixParams: [AVMutableAudioMixInputParameters] = []
        var insertTime: CMTime = .zero
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.backgroundColor = UIColor.clear.cgColor
        var instructions: [AVMutableVideoCompositionLayerInstruction] = []
        if mode == .duet, let duetOriginAsset = duetOriginAsset {
            if let videoTrack = duetOriginAsset.tracks(withMediaType: .video).first {
                let compositionVideoTrack = clip.composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
                let trackTimeRange = videoTrack.timeRange
                do {
                    try compositionVideoTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: .zero)
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                    let rect = CGRect(x: 0, y: videoTrack.naturalSize.height / 4, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height / 2)
                    layerInstruction.setCropRectangle(rect, at: insertTime)
                    layerInstruction.setTransform(duetOriginTransform(track: videoTrack), at: .zero)
                    layerInstruction.setOpacity(1, at: .zero)
                    layerInstruction.setOpacity(0, at: trackTimeRange.duration)
                    instructions.append(layerInstruction)
                } catch {print(error)}

                if let audioTrack = duetOriginAsset.tracks(withMediaType: .audio).first {
                    let compositionAudioTrack = clip.composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                    do {
                        try compositionAudioTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: .zero)
                        let audioParams = AVMutableAudioMixInputParameters()
                        audioParams.trackID = compositionAudioTrack.trackID
                        audioParams.setVolume(originalVolume, at: .zero)
                        audioMixParams.append(audioParams)
                    } catch {
                        print(error)
                        clip.composition.removeTrack(compositionAudioTrack)
                    }
                }
            }
        }

        clip.videoEntities = clip.videoEntities.map({ (entity) -> VideoEntity in
            guard let videoTrack = entity.asset.tracks(withMediaType: .video).first else {
                return entity
            }

            let compositionVideoTrack = clip.composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
            var compositionAudioTrack: AVMutableCompositionTrack?
            let trackTimeRange: CMTimeRange = {
                if let range = entity.range {
                    return CMTimeRangeMake(
                        start: .init(seconds: range.lowerBound, preferredTimescale: entity.asset.duration.timescale),
                        duration: .init(seconds: range.upperBound - range.lowerBound, preferredTimescale: entity.asset.duration.timescale))
                }
                return videoTrack.timeRange.duration.seconds > 60
                    ? .init(start: .zero, duration: CMTime(seconds: 60, preferredTimescale: 1))
                    : videoTrack.timeRange
            }()

            do {
                try compositionVideoTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: insertTime)
            } catch {print(error)}

            if let audioTrack = entity.asset.tracks(withMediaType: .audio).first {
                compositionAudioTrack = clip.composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                do {
                    try compositionAudioTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: insertTime)
                } catch {
                    print(error)
                    clip.composition.removeTrack(compositionAudioTrack!)
                }
                let audioParams = AVMutableAudioMixInputParameters()
                audioParams.trackID = compositionAudioTrack!.trackID
                audioParams.setVolume(originalVolume, at: .zero)
                audioMixParams.append(audioParams)
            }

            let entityVideoComposition = AVMutableVideoComposition()
            entityVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
            entityVideoComposition.renderSize = videoSize
            let entity = VideoEntity(
                asset: entity.asset,
                videoCompositionTrack: compositionVideoTrack,
                audioCompositionTrack: compositionAudioTrack,
                videoComposition: entityVideoComposition,
                range: entity.range ?? 0...entity.asset.duration.seconds)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            layerInstruction.setTransform(properVideoTransform(track: videoTrack), at: insertTime)
            if mode == .duet {
                let rect = CGRect(x: videoTrack.naturalSize.width / 4, y: 0, width: videoTrack.naturalSize.width / 2, height: videoTrack.naturalSize.height)
                layerInstruction.setCropRectangle(rect, at: insertTime)
            }
            layerInstruction.setOpacity(1, at: insertTime)
            layerInstruction.setOpacity(0, at: insertTime + trackTimeRange.duration)
            instructions.append(layerInstruction)
            insertTime = insertTime + trackTimeRange.duration

            let entityInstruction = AVMutableVideoCompositionInstruction()
            entityInstruction.timeRange = CMTimeRange(start: .zero, duration: entity.asset.duration)
            let entityLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            entityLayerInstruction.setTransform(properVideoTransform(track: videoTrack), at: .zero)
            entityLayerInstruction.setOpacity(1, at: .zero)
            entityInstruction.layerInstructions = [entityLayerInstruction]
            entityVideoComposition.instructions = [entityInstruction]
            return entity
        })

        instruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)
        instruction.layerInstructions = instructions

        if let addedSoundTrack = addSong(to: compositions.composition, from: clip) {
            let audioParams = AVMutableAudioMixInputParameters()
            audioParams.trackID = addedSoundTrack.trackID
            audioParams.setVolume(addedVolume, at: .zero)
            audioMixParams.append(audioParams)
        }

        if mode == .text {
            let videoLayer = CALayer()
            videoLayer.frame = CGRect(origin: .zero, size: videoSize)
            let parentLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: videoSize)
            parentLayer.addSublayer(videoLayer)
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = currentTextGradient.cgColors
            gradientLayer.locations = currentTextGradient.locations
            gradientLayer.startPoint = currentTextGradient.startPoint
            gradientLayer.endPoint = currentTextGradient.endPoint
            gradientLayer.transform = currentTextGradient.cgTransform
            gradientLayer.frame = parentLayer.bounds.insetBy(dx: -0.5 * parentLayer.bounds.width, dy: -0.5 * parentLayer.bounds.height)
            gradientLayer.isGeometryFlipped = true
            parentLayer.addSublayer(gradientLayer)
            let layerComposition = AVMutableVideoComposition()
            layerComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
            layerComposition.renderSize = videoSize
            layerComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
            layerComposition.instructions = [instruction]
            clip.layerComposition = layerComposition
        }

        clip.videoComposition.instructions = [instruction]
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioMixParams
        clip.audioMix = audioMix

        return clip
    }

    private func resultAsset(from clip: ClipContent) -> VideoAssetParams {
        let compositions = createCompositions()
        var trimLeft = clip.finalRange.lowerBound
        var clipLengthLeft = clip.finalRange.upperBound - clip.finalRange.lowerBound
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.backgroundColor = UIColor.clear.cgColor
        var instructions: [AVMutableVideoCompositionLayerInstruction] = []
        var insertTime: CMTime = .zero
        var audioMixParams: [AVMutableAudioMixInputParameters] = []

        if mode == .duet, let duetOriginAsset = duetOriginAsset {
            if let videoTrack = duetOriginAsset.tracks(withMediaType: .video).first {
                let compositionVideoTrack = compositions.composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
                let trackTimeRange: CMTimeRange = {
                    let duration = min(videoTrack.timeRange.duration.seconds, clipLengthLeft)
                    return CMTimeRangeMake(
                        start: .zero,
                        duration: .init(seconds: duration, preferredTimescale: videoTrack.timeRange.duration.timescale))
                }()
                do {
                    try compositionVideoTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: .zero)
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                    let rect = CGRect(x: 0, y: videoTrack.naturalSize.height / 4, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height / 2)
                    layerInstruction.setCropRectangle(rect, at: insertTime)
                    layerInstruction.setTransform(duetOriginTransform(track: videoTrack), at: .zero)
                    layerInstruction.setOpacity(1, at: .zero)
                    layerInstruction.setOpacity(0, at: trackTimeRange.duration)
                    instructions.append(layerInstruction)
                } catch {print(error)}

                if let audioTrack = duetOriginAsset.tracks(withMediaType: .audio).first {
                    let compositionAudioTrack = compositions.composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                    do {
                        try compositionAudioTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: .zero)
                        let audioParams = AVMutableAudioMixInputParameters()
                        audioParams.trackID = compositionAudioTrack.trackID
                        audioParams.setVolume(originalVolume, at: .zero)
                        audioMixParams.append(audioParams)
                    } catch {
                        print(error)
                        clip.composition.removeTrack(compositionAudioTrack)
                    }
                }
            }
        }

        for entity in clip.videoEntities {
            if entity.asset.duration.seconds < trimLeft {
                trimLeft -= entity.asset.duration.seconds
                continue
            }
            if round(clipLengthLeft * 100) / 100 <= 0 {
                break
            }

            guard let videoTrack = entity.asset.tracks(withMediaType: .video).first else {
                continue
            }

            let compositionVideoTrack = compositions.composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
            let trackTimeRange: CMTimeRange = {
                if let range = entity.range {
                    let duration = min(range.upperBound - range.lowerBound, clipLengthLeft)
                    return CMTimeRangeMake(
                        start: .init(seconds: range.lowerBound, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                        duration: .init(seconds: duration, preferredTimescale: entity.asset.duration.timescale))
                }
                let duration = min(entity.asset.duration.seconds, clipLengthLeft)
                return CMTimeRangeMake(
                    start: .zero,
                    duration: .init(seconds: duration, preferredTimescale: entity.asset.duration.timescale))
            }()

            if round(trackTimeRange.duration.seconds * 100) / 100 == 0 {
                continue
            }

            do {
                try compositionVideoTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: insertTime)
            } catch {print(error)}

            if let audioTrack = entity.asset.tracks(withMediaType: .audio).first {
                let compositionAudioTrack = compositions.composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                do {
                    try compositionAudioTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: insertTime)
                } catch {
                    print(error)
                    compositions.composition.removeTrack(compositionAudioTrack)
                }
                let audioParams = AVMutableAudioMixInputParameters()
                audioParams.trackID = compositionAudioTrack.trackID
                audioParams.setVolume(originalVolume, at: .zero)
                audioMixParams.append(audioParams)
            }

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            if mode == .duet {
                let rect = CGRect(x: videoTrack.naturalSize.width / 4, y: 0, width: videoTrack.naturalSize.width / 2, height: videoTrack.naturalSize.height)
                layerInstruction.setCropRectangle(rect, at: insertTime)
            }
            layerInstruction.setTransform(properVideoTransform(track: videoTrack), at: insertTime)
            layerInstruction.setOpacity(1, at: insertTime)
            layerInstruction.setOpacity(0, at: insertTime + trackTimeRange.duration)
            instructions.append(layerInstruction)
            insertTime = insertTime + trackTimeRange.duration
            clipLengthLeft -= trackTimeRange.duration.seconds
        }

        instruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)
        instruction.layerInstructions = instructions

        compositions.videoComposition.instructions = [instruction]

        let screenSize = UIScreen.main.bounds.size
        let scale = videoSize.width / screenSize.width

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)

        if mode == .text {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = currentTextGradient.cgColors
            gradientLayer.locations = currentTextGradient.locations
            gradientLayer.startPoint = currentTextGradient.startPoint
            gradientLayer.endPoint = currentTextGradient.endPoint
            gradientLayer.transform = currentTextGradient.cgTransform
            gradientLayer.isGeometryFlipped = true
            gradientLayer.frame = parentLayer.bounds.insetBy(dx: -0.5 * parentLayer.bounds.width, dy: -0.5 * parentLayer.bounds.height)
            parentLayer.addSublayer(gradientLayer)
        }

        if texts.count > 0 {
            let textContainerLayer = CALayer()
            textContainerLayer.frame = CGRect(origin: .zero, size: screenSize)
            for text in texts {
                let textView = HighlightTextView(textEditorEntity: text.editorEntity)

                let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                textView.setSizeInScreen()
                UIApplication.shared.currentWindow?.insertSubview(textView, at: 0)
                textView.contentOffset = .zero
                textView.center = center
                let textImage = textView.screenshot
                textView.removeFromSuperview()
                let textLayer = CALayer()
                textLayer.frame = textView.frame
                textLayer.frame.origin = CGPoint(x: center.x - textLayer.frame.width / 2, y: center.y - textLayer.frame.height / 2)
                textLayer.contents = textImage?.cgImage
                let scaleTransform = text.transform
                textLayer.transform = CATransform3DMakeAffineTransform(scaleTransform)


                if let range = text.range {
                    let showAnimation = CAKeyframeAnimation(keyPath: "hidden")
                    showAnimation.values = [true, false, false, true]
                    showAnimation.keyTimes = [0, 0.01, 0.99, 1]
                    showAnimation.duration = range.upperBound - range.lowerBound
                    showAnimation.beginTime =  AVCoreAnimationBeginTimeAtZero.advanced(by: range.lowerBound)
                    showAnimation.calculationMode = .linear
                    showAnimation.isRemovedOnCompletion = false
                    showAnimation.fillMode = .both
                    textLayer.add(showAnimation, forKey: "hidden")
                }
                textContainerLayer.addSublayer(textLayer)
            }
            parentLayer.addSublayer(textContainerLayer)
            textContainerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform.init(scaleX: scale, y: scale))
            textContainerLayer.frame.origin = .zero
            textContainerLayer.isGeometryFlipped = true
        }

        if let addedSoundTrack = addSong(to: compositions.composition, from: clip) {
            let audioParams = AVMutableAudioMixInputParameters()
            audioParams.trackID = addedSoundTrack.trackID
            audioParams.setVolume(addedVolume, at: .zero)
            audioMixParams.append(audioParams)
        }

        let layerComposition = AVMutableVideoComposition()
        layerComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layerComposition.renderSize = videoSize
        layerComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        layerComposition.instructions = compositions.videoComposition.instructions

        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioMixParams

        return .init(asset: compositions.composition, videoComposition: compositions.videoComposition, layerComposition: layerComposition, audioMix: audioMix)
    }

    private func updateGradientLayer() {
        textBackgroundLayer.colors = currentTextGradient.cgColors
        textBackgroundLayer.locations = currentTextGradient.locations
        textBackgroundLayer.startPoint = currentTextGradient.startPoint
        textBackgroundLayer.endPoint = currentTextGradient.endPoint
        textBackgroundLayer.transform = currentTextGradient.cgTransform
        let bounds = CGRect(origin: .zero, size: videoSize)
        textBackgroundLayer.frame = bounds.insetBy(dx: -0.5 * bounds.width, dy: -0.5 * bounds.height)
    }

    private func addSong(to composition: AVMutableComposition, from clip: ClipContent) -> AVMutableCompositionTrack? {
        guard let backgroundSong = clip.backgroundSong,
              let audioTrack = backgroundSong.asset.tracks(withMediaType: .audio).first else {
            return nil
        }
        let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var filledTime: Double = 0
        while filledTime < composition.duration.seconds {
            let leftTime = composition.duration.seconds - filledTime
            let trackDurationToInsert = min(leftTime, backgroundSong.duration)
            let audioTrackRange = CMTimeRangeMake(start: CMTime(seconds: backgroundSong.startsAt, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), duration: CMTime(seconds: trackDurationToInsert, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            try? compositionTrack?.insertTimeRange(audioTrackRange, of: audioTrack, at: CMTime(seconds: filledTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            filledTime += trackDurationToInsert
        }
        return compositionTrack
    }
}
//
//// MARK: - Story generation
//
//extension StoryCreator {
//
//    private func generateStoryComponents(from clip: ClipContent) {
//        let compositions = createCompositions()
//        var audioMixParams: [AVMutableAudioMixInputParameters] = []
//        var insertTime: CMTime = .zero
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.backgroundColor = UIColor.clear.cgColor
//        var instructions: [AVMutableVideoCompositionLayerInstruction] = []
//
//
//    }
//
//    private func ()
//
//}
