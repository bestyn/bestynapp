//
//  AsyncSequence.swift
//  neighbourhood
//
//  Created by Artem Korzh on 25.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

typealias NextExecution<T> = (_ item: T, _ next: @escaping () -> Void) -> Void

class AsyncSequence<T> {
    private var originalSequence: [T]

    init(originalSequence: [T]) {
        self.originalSequence = originalSequence
    }

    func execForEach(execution: @escaping NextExecution<T>, completion: @escaping () -> Void) {
        if self.originalSequence.count == 0 {
            completion()
            return
        }
        let item = originalSequence.removeFirst()
        execution(item) { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.execForEach(execution: execution, completion: completion)
            }
        }
    }
}
