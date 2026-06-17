//
//  DetectedObject.swift
//  ChatPrototype
//
//  Created by Glenn Silverman on 6/16/26.
//

import Foundation
import ARKit
import RealityKit
import UIKit
import Combine

/// Represents a bounding box in 3D space
struct BoundingBox {
    var center: SIMD3<Float>
    var size: SIMD3<Float> // width (x), height (y), depth (z)
    var rotation: simd_quatf
    
    /// Returns the 8 corner points of the bounding box
    var corners: [SIMD3<Float>] {
        let halfSize = size / 2
        let corners = [
            SIMD3<Float>(-halfSize.x, -halfSize.y, -halfSize.z),
            SIMD3<Float>( halfSize.x, -halfSize.y, -halfSize.z),
            SIMD3<Float>(-halfSize.x,  halfSize.y, -halfSize.z),
            SIMD3<Float>( halfSize.x,  halfSize.y, -halfSize.z),
            SIMD3<Float>(-halfSize.x, -halfSize.y,  halfSize.z),
            SIMD3<Float>( halfSize.x, -halfSize.y,  halfSize.z),
            SIMD3<Float>(-halfSize.x,  halfSize.y,  halfSize.z),
            SIMD3<Float>( halfSize.x,  halfSize.y,  halfSize.z)
        ]
        
        // Apply rotation and translation
        return corners.map { corner in
            let rotated = rotation.act(corner)
            return center + rotated
        }
    }
}

/// Represents a detected object in the scanned room
class DetectedObject: Identifiable, ObservableObject {
    let id = UUID()
    @Published var boundingBox: BoundingBox
    @Published var isVisible: Bool = true
    @Published var color: UIColor
    var meshAnchor: ARMeshAnchor?
    var wireframeEntity: ModelEntity?
    var label: String
    var confidence: Float
    
    init(boundingBox: BoundingBox, meshAnchor: ARMeshAnchor? = nil, label: String = "Object", color: UIColor? = nil) {
        self.boundingBox = boundingBox
        self.meshAnchor = meshAnchor
        self.label = label
        self.color = color ?? UIColor.randomBrightColor()
        self.confidence = 1.0
    }
    
    /// Volume of the bounding box in cubic meters
    var volume: Float {
        let size = boundingBox.size
        return size.x * size.y * size.z
    }
    
    /// Formatted dimensions string
    var dimensionsString: String {
        let size = boundingBox.size
        return String(format: "%.2fm × %.2fm × %.2fm", size.x, size.y, size.z)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    static func randomBrightColor() -> UIColor {
        let colors: [UIColor] = [
            .systemBlue, .systemGreen, .systemOrange, .systemPink,
            .systemPurple, .systemTeal, .systemYellow, .systemRed,
            .systemIndigo, .systemCyan, .systemMint
        ]
        return colors.randomElement() ?? .systemBlue
    }
}
