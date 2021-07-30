//
//  Observable.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

@propertyWrapper
class Observable<T> {
    private var value: T

    typealias Listener = (T) -> ()
    private var listeners: [Listener] = []

    var projectedValue: Observable<T> { self }

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {value}
        set {
            value = newValue
            for l in listeners { l(value) }
        }
    }

    func bind(l: @escaping Listener) {
        listeners.append(l)
        l(value)
    }
}

@propertyWrapper
class ObservableState<T: Equatable> {
    private var value: T

    typealias Listener = (T) -> ()
    private var listeners: [Listener] = []

    var projectedValue: ObservableState<T> { self }

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {value}
        set {
            if value != newValue {
                value = newValue
                for l in listeners { l(value) }
            }
        }
    }

    func bind(l: @escaping Listener) {
        listeners.append(l)
    }
    
    func bindAndFire(l: @escaping Listener) {
        listeners.append(l)
        l(value)
    }
}

@propertyWrapper
class SingleEventObservable<T> {
    private var value: T
    private var isProcessed = true

    typealias Listener = (T) -> ()
    private var listeners: [Listener] = []

    var projectedValue: SingleEventObservable<T> { self }

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {value}
        set {
            value = newValue
            if listeners.count > 0 {
                for l in listeners { l(value) }
                isProcessed = true
            }
        }
    }

    func bind(l: @escaping Listener) {
        listeners.append(l)
        if !isProcessed {
            l(wrappedValue)
        }
    }
}

