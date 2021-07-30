//
//  CacheManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 04.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class CacheManager {
    enum StorageType {
        case file
        case session
    }

    private static let fileCacheManager = CacheManager(type: .file)
    private static let sessionCacheManager = CacheManager(type: .session)

    private let type: StorageType
    private let fileManager = FileManager.default
    private let sessionCache = NSCache<NSString, NSData>()
    private var inProgress: Set<URL> = []

    private var cacheFolder: URL {
        let folderPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return folderPath
    }

    static func of(type: StorageType) -> CacheManager {
        switch type {
        case .file:
            return fileCacheManager
        case .session:
            return sessionCacheManager
        }
    }

    private init(type: StorageType) {
        self.type = type
    }

    deinit {
        if type == .session {
            sessionCache.removeAllObjects()
        }
    }

    public func get(url: URL, completion: @escaping (URL?) -> Void) {
        switch type {
        case .file:
            getFromFile(url: url, completion: completion)
        case .session:
            getFromCache(url: url, completion: completion)
        }
    }

    public func insert(url: URL, completion: ((Result<URL, Error>) -> Void)? ) {
        if inProgress.contains(url) {
            return
        }
        inProgress.insert(url)
        switch type {
        case .file:
            saveToFile(url: url, completion: completion)
        case .session:
            saveToCache(url: url, completion: completion)
        }
    }

    public func remove(url: URL) {
        switch type {
        case .file:
            removeFromFiles(url: url)
        case .session:
            removeFromCache(url: url)
        }
    }

}

// MARK: - File cache

extension CacheManager {
    private func getFromFile(url: URL, completion: @escaping (URL?) -> Void) {
        let fileURL = cacheFolder.appendingPathComponent(fileName(for: url))
        if fileManager.fileExists(atPath: fileURL.path) {
            print("found in file cache data for ", url.absoluteURL)
            completion(fileURL)
        }
        completion(nil)
    }

    private func saveToFile(url: URL, completion: ((Result<URL, Error>) -> Void)?)  {
        let fileURL = cacheFolder.appendingPathComponent(fileName(for: url))
        if fileManager.fileExists(atPath: fileURL.path) {
            completion?(.success(fileURL))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            self?.inProgress.remove(url)
            if let error = error {
                completion?(.failure(error))
                return
            }
            if let data = data {
                try? data.write(to: fileURL)
                DispatchQueue.main.async {
                    completion?(.success(fileURL))
                }
                print("stored to file cache data for ", url.absoluteURL)
            }
        }
        task.priority = URLSessionTask.lowPriority
        task.resume()
    }

    private func removeFromFiles(url: URL) {
        let fileURL = cacheFolder.appendingPathComponent(fileName(for: url))
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    private func fileName(for url: URL) -> String {
        let fileName = url.absoluteString.md5
        let fileExtension = url.pathExtension
        return [fileName, fileExtension].joined(separator: ".")
    }
}


// MARK: - Session cache

extension CacheManager {
    private func getFromCache(url: URL, completion: @escaping (URL?) -> Void) {
//        if let nsData = sessionCache.object(forKey: NSString(string: url.absoluteString)) {
//            print("found in session cache data for ", url.absoluteURL)
//            completion(nsData as Data)
//            return
//        }
//        completion(nil)
    }

    private func saveToCache(url: URL, completion: ((Result<URL, Error>) -> Void)?)  {
//        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
//            self?.inProgress.remove(url)
//            if let error = error {
//                completion?(.failure(error))
//                return
//            }
//            if let data = data {
//                self?.sessionCache.setObject(data as NSData, forKey: NSString(string: url.absoluteString))
//                DispatchQueue.main.async {
//                    completion?(.success(data))
//                }
//                print("stored to session cache data for ", url.absoluteURL)
//            }
//        }
//        task.priority = URLSessionTask.lowPriority
//        task.resume()
    }

    private func removeFromCache(url: URL) {
//        sessionCache.removeObject(forKey: NSString(string: url.absoluteString))
    }
}

