//
//  Card.swift
//  swiftui-boomerang-card-effect
//
//  Created by Jco Bea on 10/11/22.
//

import SwiftUI

struct Card: Identifiable {
    var id: String = UUID().uuidString
    // var imageName: String
    var isRotated: Bool = false
    var extraOffset: CGFloat = 0
    var scale: CGFloat = 1
    var zIndex: Double = 0
}
