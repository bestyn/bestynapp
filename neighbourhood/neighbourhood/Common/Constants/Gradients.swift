//
//  Gradients.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

struct StoryGradient {
    let colors: [UIColor]
    var locations: [NSNumber] = [0, 1]
    var startPoint: CGPoint = .init(x: 0.25, y: 0.5)
    var endPoint: CGPoint = .init(x: 0.75, y: 0.5)
    var transform: CGAffineTransform = CGAffineTransform(a: 0, b: -1, c: 1.03, d: 0.08, tx: -0.02, ty: 0.96)

    var cgColors: [CGColor] { colors.map({$0.cgColor}) }
    var cgTransform: CATransform3D { CATransform3DMakeAffineTransform(transform) }
}

extension StoryGradient {
    static let available: [StoryGradient] = [
        .init(
            colors: [
                UIColor(red: 0.365, green: 0.573, blue: 0.984, alpha: 1),
                UIColor(red: 0.533, green: 0.455, blue: 0.835, alpha: 1),
                UIColor(red: 0.588, green: 0.412, blue: 0.769, alpha: 1),
                UIColor(red: 0.745, green: 0.306, blue: 0.616, alpha: 1),
                UIColor(red: 0.992, green: 0.357, blue: 0.373, alpha: 1)
            ],
            locations: [0, 0.28, 0.48, 0.77, 1],
            transform: CGAffineTransform(a: 1.05, b: -1.04, c: 0.6, d: 0.13, tx: -0.3, ty: 0.94)),
        .init(
            colors: [
                UIColor(red: 0.793, green: 0.472, blue: 0.986, alpha: 1),
                UIColor(red: 0.333, green: 0.506, blue: 1, alpha: 1),
                UIColor(red: 0.2, green: 0.8, blue: 1, alpha: 1)
            ],
            locations: [0, 0.51, 1],
            transform: CGAffineTransform(a: 0, b: -1, c: 1.02, d: 0.03, tx: 0.02, ty: 0.98)),
        .init(
            colors: [
                UIColor(red: 0.856, green: 0.617, blue: 1, alpha: 1),
                UIColor(red: 1, green: 0.733, blue: 0.852, alpha: 1)
            ], locations: [0.4, 1],
            transform: CGAffineTransform(a: -0.11, b: -1, c: 1.04, d: 0.05, tx: -0.03, ty: 0.97)),
        .init(
            colors: [
                UIColor(red: 0.988, green: 0.643, blue: 0.267, alpha: 1),
                UIColor(red: 1, green: 0.2, blue: 0.555, alpha: 1)
            ], transform: CGAffineTransform(a: -0.11, b: -1, c: 1.04, d: 0.05, tx: -0.03, ty: 0.97)),
        .init(colors: [.black, .black]),
        .init(colors: [.white, .white]),
        .init(colors: [UIColor(red: 0.855, green: 0.2, blue: 0.161, alpha: 1),
                       UIColor(red: 0.958, green: 0.67, blue: 0.547, alpha: 1)]),
        .init(colors: [UIColor(red: 1, green: 0.514, blue: 0.161, alpha: 1),
                       UIColor(red: 1, green: 0.852, blue: 0.629, alpha: 1)]),
        .init(colors: [UIColor(red: 0.992, green: 0.839, blue: 0.302, alpha: 1),
                       UIColor(red: 0.938, green: 1, blue: 0.692, alpha: 1)]),
        .init(colors: [UIColor(red: 0.601, green: 0.773, blue: 0.322, alpha: 1),
                       UIColor(red: 0.597, green: 1, blue: 0.496, alpha: 1)]),
        .init(colors: [UIColor(red: 0.322, green: 0.608, blue: 0.773, alpha: 1),
                       UIColor(red: 0.48, green: 0.875, blue: 0.9, alpha: 1)]),
        .init(colors: [UIColor(red: 0.208, green: 0.294, blue: 0.741, alpha: 1),
                       UIColor(red: 0.514, green: 0.506, blue: 0.933, alpha: 1)]),
        .init(colors: [UIColor(red: 0.431, green: 0.267, blue: 0.788, alpha: 1),
                       UIColor(red: 0.654, green: 0.383, blue: 0.867, alpha: 1)]),
        .init(colors: [UIColor(red: 0.941, green: 0.761, blue: 0.973, alpha: 1),
                       UIColor(red: 0.887, green: 0.919, blue: 1, alpha: 1)]),
        .init(colors: [UIColor(red: 0.733, green: 0.624, blue: 0.506, alpha: 1),
                       UIColor(red: 1, green: 0.9, blue: 0.9, alpha: 1)]),
        .init(colors: [UIColor(red: 0.337, green: 0.475, blue: 0.345, alpha: 1),
                       UIColor(red: 0.579, green: 0.879, blue: 0.735, alpha: 1)]),
        .init(colors: [UIColor(red: 0.231, green: 0.373, blue: 0.502, alpha: 1),
                       UIColor(red: 0.603, green: 0.729, blue: 0.8, alpha: 1)]),
        .init(colors: [UIColor(red: 0.71, green: 0.729, blue: 0.745, alpha: 1),
                       UIColor(red: 0.887, green: 0.911, blue: 0.933, alpha: 1)]),
        .init(colors: [UIColor(red: 0.365, green: 0.38, blue: 0.396, alpha: 1),
                       UIColor(red: 0.569, green: 0.567, blue: 0.671, alpha: 1)])
    ]
}
