//
//  DirectionManager.swift
//  neighbourhood
//
//  Created by Dioksa on 27.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit

enum SwipeDirection {
    case left, right, up, down
}

final class DirectionManager {
    func defineSwipeDirection(_ originCoordinates: CGPoint, _ coordinatesAfterChange: CGPoint) -> SwipeDirection {
        if coordinatesAfterChange.x < originCoordinates.x && coordinatesAfterChange.y < originCoordinates.y && (coordinatesAfterChange.x <= originCoordinates.x - 80) {
            return .left
        } else if coordinatesAfterChange.x > originCoordinates.x && coordinatesAfterChange.y > originCoordinates.y {
            return .right
        } else if coordinatesAfterChange.x > originCoordinates.x && coordinatesAfterChange.y < originCoordinates.y {
            return .up
        } else {
            return .down
        }
    }
}
