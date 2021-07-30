//
//  RestAudioTracksManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestAudioTracksManager: RestOperationsManager {

    func list(data: AudioTracksData) -> PreparedOperation<[AudioTrackModel]> {
        let request = Request(
            url: RestURL.AudioTracks.list,
            method: .get,
            query: data.requestData,
            withAuthorization: true)
        return prepare(request: request)
    }

    func followTrack(track: AudioTrackModel) -> PreparedOperation<Empty> {
        let request = Request(url: RestURL.AudioTracks.follow(trackID: track.id), method: .post, withAuthorization: true)
        return prepare(request: request)
    }

    func unfollowTrack(track: AudioTrackModel) -> PreparedOperation<Empty> {
        let request = Request(url: RestURL.AudioTracks.follow(trackID: track.id), method: .delete, withAuthorization: true)
        return prepare(request: request)
    }

    func saveTrack(data: AudioTrackData) -> PreparedOperation<AudioTrackModel> {
        let request = Request(
            url: RestURL.AudioTracks.list,
            method: .post,
            withAuthorization: true,
            body: data,
            media: ["file": .custom(fileURL: data.file, contentType: data.file.mimeType)])
        return prepare(request: request)
    }

}
