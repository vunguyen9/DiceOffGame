//
//  Player.swift
//  DiceOff
//
//  Created by Vu Nguyen on 12/27/21.
//

import Foundation
import SwiftUI

enum Player {
    case none, green, red
    
    var color: Color {
        switch self {
        case .none:
            return Color(white: 0.6)
        case .green:
            return .green
        case .red:
            return .red
        }
    }
}
