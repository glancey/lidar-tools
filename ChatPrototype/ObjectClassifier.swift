//
//  ObjectClassifier.swift
//  ChatPrototype
//
//  Created by Glenn Silverman on 6/16/26.
//

import Foundation
import ARKit
import Vision
import CoreML
import UIKit

/// AI-driven object classification using Vision framework
class ObjectClassifier {
    
    // MARK: - Object Categories
    
    enum ObjectCategory: String {
        case furniture
        case structure
        case appliance
        case decoration
        case storage
        case seating
        case surface
        case unknown
        
        var displayName: String {
            switch self {
            case .furniture: return "Furniture"
            case .structure: return "Structure"
            case .appliance: return "Appliance"
            case .decoration: return "Decoration"
            case .storage: return "Storage"
            case .seating: return "Seating"
            case .surface: return "Surface"
            case .unknown: return "Unknown"
            }
        }
    }
    
    struct ClassificationResult {
        let label: String
        let category: ObjectCategory
        let confidence: Float
        let isMovable: Bool  // Distinguishes furniture from structure
    }
    
    // MARK: - Vision-based Classification
    
    /// Classify object using Vision framework with ML model
    func classifyWithVision(object: DetectedObject, frame: ARFrame?) async -> ClassificationResult {
        // First, try geometry-based classification (fast)
        let geometryResult = classifyByGeometry(object: object)
        
        // If we have a camera frame, enhance with vision analysis
        if let frame = frame {
            let visionResult = await classifyByVision(object: object, frame: frame)
            return visionResult ?? geometryResult
        }
        
        return geometryResult
    }
    
    // MARK: - Enhanced Geometry Classification
    
    private func classifyByGeometry(object: DetectedObject) -> ClassificationResult {
        let size = object.boundingBox.size
        let height = size.y
        let width = max(size.x, size.z)
        let depth = min(size.x, size.z)
        let volume = object.volume
        let aspectRatio = width / height
        let depthRatio = depth / height
        
        // Multi-dimensional classification with confidence scoring
        
        // STRUCTURE DETECTION (immovable)
        if isWall(height: height, width: width, depth: depth, volume: volume) {
            return ClassificationResult(
                label: "Wall",
                category: .structure,
                confidence: 0.9,
                isMovable: false
            )
        }
        
        if isFloor(height: height, width: width, depth: depth, volume: volume) {
            return ClassificationResult(
                label: "Floor",
                category: .structure,
                confidence: 0.85,
                isMovable: false
            )
        }
        
        if isDoor(height: height, width: width, depth: depth) {
            return ClassificationResult(
                label: "Door",
                category: .structure,
                confidence: 0.8,
                isMovable: false
            )
        }
        
        if isWindow(height: height, width: width, depth: depth) {
            return ClassificationResult(
                label: "Window",
                category: .structure,
                confidence: 0.75,
                isMovable: false
            )
        }
        
        // FURNITURE - SEATING
        if isChair(height: height, width: width, depth: depth, volume: volume) {
            return ClassificationResult(
                label: "Chair",
                category: .seating,
                confidence: 0.8,
                isMovable: true
            )
        }
        
        if isSofa(height: height, width: width, depth: depth, volume: volume) {
            return ClassificationResult(
                label: "Sofa",
                category: .seating,
                confidence: 0.75,
                isMovable: true
            )
        }
        
        // FURNITURE - SURFACES
        if isTable(height: height, width: width, depth: depth, aspectRatio: aspectRatio) {
            return ClassificationResult(
                label: "Table",
                category: .surface,
                confidence: 0.8,
                isMovable: true
            )
        }
        
        if isDesk(height: height, width: width, depth: depth, aspectRatio: aspectRatio) {
            return ClassificationResult(
                label: "Desk",
                category: .surface,
                confidence: 0.75,
                isMovable: true
            )
        }
        
        if isCountertop(height: height, width: width, depth: depth) {
            return ClassificationResult(
                label: "Countertop",
                category: .surface,
                confidence: 0.7,
                isMovable: false
            )
        }
        
        // FURNITURE - STORAGE
        if isCabinet(height: height, width: width, depth: depth) {
            return ClassificationResult(
                label: "Cabinet",
                category: .storage,
                confidence: 0.75,
                isMovable: true
            )
        }
        
        if isBookshelf(height: height, width: width, depth: depth, aspectRatio: aspectRatio) {
            return ClassificationResult(
                label: "Bookshelf",
                category: .storage,
                confidence: 0.7,
                isMovable: true
            )
        }
        
        if isDresser(height: height, width: width, depth: depth) {
            return ClassificationResult(
                label: "Dresser",
                category: .storage,
                confidence: 0.7,
                isMovable: true
            )
        }
        
        // FURNITURE - BEDS
        if isBed(height: height, width: width, depth: depth, volume: volume) {
            return ClassificationResult(
                label: "Bed",
                category: .furniture,
                confidence: 0.8,
                isMovable: true
            )
        }
        
        // APPLIANCES
        if isRefrigerator(height: height, width: width, depth: depth) {
            return ClassificationResult(
                label: "Refrigerator",
                category: .appliance,
                confidence: 0.7,
                isMovable: true
            )
        }
        
        if isOven(height: height, width: width, depth: depth) {
            return ClassificationResult(
                label: "Oven/Stove",
                category: .appliance,
                confidence: 0.7,
                isMovable: false
            )
        }
        
        // DEFAULT CLASSIFICATION
        if volume < 0.1 {
            return ClassificationResult(
                label: "Small Object",
                category: .decoration,
                confidence: 0.5,
                isMovable: true
            )
        } else if volume > 5.0 {
            return ClassificationResult(
                label: "Large Structure",
                category: .structure,
                confidence: 0.6,
                isMovable: false
            )
        } else {
            return ClassificationResult(
                label: "Object",
                category: .furniture,
                confidence: 0.4,
                isMovable: true
            )
        }
    }
    
    // MARK: - Detailed Classification Rules
    
    private func isWall(height: Float, width: Float, depth: Float, volume: Float) -> Bool {
        return height > 2.0 && depth < 0.3 && width > 1.0 && volume > 1.0
    }
    
    private func isFloor(height: Float, width: Float, depth: Float, volume: Float) -> Bool {
        return height < 0.15 && width > 0.5 && depth > 0.5
    }
    
    private func isDoor(height: Float, width: Float, depth: Float) -> Bool {
        return height > 1.8 && height < 2.4 && width > 0.6 && width < 1.2 && depth < 0.15
    }
    
    private func isWindow(height: Float, width: Float, depth: Float) -> Bool {
        return height > 0.5 && height < 1.8 && width > 0.5 && width < 2.5 && depth < 0.2
    }
    
    private func isChair(height: Float, width: Float, depth: Float, volume: Float) -> Bool {
        return height > 0.7 && height < 1.3 && 
               width > 0.4 && width < 0.8 && 
               depth > 0.4 && depth < 0.8 &&
               volume > 0.1 && volume < 0.5
    }
    
    private func isSofa(height: Float, width: Float, depth: Float, volume: Float) -> Bool {
        return height > 0.6 && height < 1.0 && 
               width > 1.2 && width < 3.0 && 
               depth > 0.7 && depth < 1.2 &&
               volume > 0.8
    }
    
    private func isTable(height: Float, width: Float, depth: Float, aspectRatio: Float) -> Bool {
        return height > 0.5 && height < 0.9 && 
               width > 0.6 && width < 2.5 && 
               depth > 0.6 && depth < 2.0 &&
               aspectRatio > 0.8
    }
    
    private func isDesk(height: Float, width: Float, depth: Float, aspectRatio: Float) -> Bool {
        return height > 0.65 && height < 0.85 && 
               width > 1.0 && width < 2.0 && 
               depth > 0.5 && depth < 0.9
    }
    
    private func isCountertop(height: Float, width: Float, depth: Float) -> Bool {
        return height > 0.8 && height < 1.1 && 
               width > 0.5 && 
               depth > 0.4 && depth < 0.8
    }
    
    private func isCabinet(height: Float, width: Float, depth: Float) -> Bool {
        return height > 0.3 && height < 2.2 && 
               width > 0.3 && width < 1.5 && 
               depth > 0.25 && depth < 0.7
    }
    
    private func isBookshelf(height: Float, width: Float, depth: Float, aspectRatio: Float) -> Bool {
        return height > 1.0 && height < 2.5 && 
               width > 0.6 && width < 2.0 && 
               depth > 0.2 && depth < 0.5 &&
               aspectRatio < 2.0
    }
    
    private func isDresser(height: Float, width: Float, depth: Float) -> Bool {
        return height > 0.7 && height < 1.3 && 
               width > 0.6 && width < 1.5 && 
               depth > 0.4 && depth < 0.7
    }
    
    private func isBed(height: Float, width: Float, depth: Float, volume: Float) -> Bool {
        return height > 0.3 && height < 0.8 && 
               width > 0.9 && width < 2.2 && 
               depth > 1.8 && depth < 2.3 &&
               volume > 1.0 && volume < 5.0
    }
    
    private func isRefrigerator(height: Float, width: Float, depth: Float) -> Bool {
        return height > 1.4 && height < 2.0 && 
               width > 0.6 && width < 1.0 && 
               depth > 0.6 && depth < 0.9
    }
    
    private func isOven(height: Float, width: Float, depth: Float) -> Bool {
        return height > 0.7 && height < 1.0 && 
               width > 0.5 && width < 0.9 && 
               depth > 0.5 && depth < 0.8
    }
    
    // MARK: - Vision Framework Classification
    
    private func classifyByVision(object: DetectedObject, frame: ARFrame) async -> ClassificationResult? {
        // Project 3D bounding box to 2D screen space
        guard let projectedBox = project3DBoxTo2D(object: object, frame: frame) else {
            return nil
        }
        
        // Crop the image to the bounding box
        let image = frame.capturedImage
        guard let croppedImage = cropImage(image, to: projectedBox) else {
            return nil
        }
        
        // Use Vision to classify
        return await performVisionClassification(on: croppedImage)
    }
    
    private func project3DBoxTo2D(object: DetectedObject, frame: ARFrame) -> CGRect? {
        let camera = frame.camera
        let viewMatrix = camera.viewMatrix(for: .portrait)
        let projectionMatrix = camera.projectionMatrix(for: .portrait, viewportSize: CGSize(width: 1920, height: 1080), zNear: 0.001, zFar: 1000)
        
        // Project center point to 2D
        let center = object.boundingBox.center
        let centerPoint = SIMD4<Float>(center.x, center.y, center.z, 1.0)
        let projected = projectionMatrix * viewMatrix * centerPoint
        
        if projected.w == 0 { return nil }
        
        let ndcX = projected.x / projected.w
        let ndcY = projected.y / projected.w
        
        // Convert NDC to screen space
        let screenX = (ndcX + 1.0) * 0.5 * 1920
        let screenY = (1.0 - ((ndcY + 1.0) * 0.5)) * 1080
        
        // Estimate box size in screen space
        let size = object.boundingBox.size
        let estimatedSize = max(size.x, size.y, size.z) * 200 // Rough conversion
        
        return CGRect(
            x: CGFloat(screenX - estimatedSize / 2),
            y: CGFloat(screenY - estimatedSize / 2),
            width: CGFloat(estimatedSize),
            height: CGFloat(estimatedSize)
        )
    }
    
    private func cropImage(_ pixelBuffer: CVPixelBuffer, to rect: CGRect) -> CIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return ciImage.cropped(to: rect)
    }
    
    private func performVisionClassification(on image: CIImage) async -> ClassificationResult? {
        // Use VNClassifyImageRequest for scene classification
        // Available in iOS 15+ and works well for furniture/room objects
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<ClassificationResult?, Never>) in
            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNClassificationObservation],
                      let topObservation = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Map Vision labels to our categories
                let label = topObservation.identifier
                let confidence = topObservation.confidence
                let category = self.mapVisionLabelToCategory(label)
                let isMovable = self.isMovableObject(label)
                
                let result = ClassificationResult(
                    label: self.cleanupVisionLabel(label),
                    category: category,
                    confidence: confidence,
                    isMovable: isMovable
                )
                
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(ciImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("❌ Vision classification failed: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func cleanupVisionLabel(_ label: String) -> String {
        // Vision framework returns labels like "table_lamp" or "dining_room"
        // Clean these up for better display
        let cleaned = label
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        
        // Extract the main object if it's a compound label
        if cleaned.contains(" ") {
            let words = cleaned.components(separatedBy: " ")
            // Look for furniture keywords
            let furnitureKeywords = ["Chair", "Table", "Sofa", "Bed", "Desk", "Cabinet", "Shelf"]
            for keyword in furnitureKeywords {
                if words.contains(keyword) {
                    return keyword
                }
            }
        }
        
        return cleaned
    }
    
    private func mapVisionLabelToCategory(_ label: String) -> ObjectCategory {
        let lowerLabel = label.lowercased()
        
        if lowerLabel.contains("chair") || lowerLabel.contains("seat") || lowerLabel.contains("sofa") || lowerLabel.contains("couch") {
            return .seating
        } else if lowerLabel.contains("table") || lowerLabel.contains("desk") || lowerLabel.contains("counter") {
            return .surface
        } else if lowerLabel.contains("cabinet") || lowerLabel.contains("shelf") || lowerLabel.contains("dresser") {
            return .storage
        } else if lowerLabel.contains("refrigerator") || lowerLabel.contains("oven") || lowerLabel.contains("microwave") {
            return .appliance
        } else if lowerLabel.contains("wall") || lowerLabel.contains("door") || lowerLabel.contains("window") || lowerLabel.contains("floor") {
            return .structure
        } else if lowerLabel.contains("bed") || lowerLabel.contains("couch") {
            return .furniture
        } else {
            return .unknown
        }
    }
    
    private func isMovableObject(_ label: String) -> Bool {
        let immovableKeywords = ["wall", "floor", "ceiling", "door", "window", "built-in", "countertop"]
        let lowerLabel = label.lowercased()
        return !immovableKeywords.contains(where: { lowerLabel.contains($0) })
    }
}
