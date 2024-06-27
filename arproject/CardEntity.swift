//
//  CardEntity.swift
//  arproject
//
//  Created by lhy on 2023/5/31.
//

import RealityKit
import Combine

struct CardComponent: Component, Codable {
    var revealed = false
    var model = ""
    var name = ""
    var paired = false
}

class CardEntity: Entity, HasModel, HasCollision {
    public var card: CardComponent {
        get { return components[CardComponent.self] ?? CardComponent() }
        set { components[CardComponent.self] = newValue }
    }
}

extension CardEntity {
    // Animate, change state
    func reveal() {
        // Update revealed property
        card.revealed = true
        // Flip card over to reveal contents
        var transform = self.transform
        transform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
        move(to: transform, relativeTo: parent, duration: 0.25, timingFunction: .easeInOut)
    }
    
    func hide() {
        card.revealed = false
        // Flip card over to reveal contents
        var transform = self.transform
        transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        move(to: transform, relativeTo: parent, duration: 0.25, timingFunction: .easeInOut)
    }
}
