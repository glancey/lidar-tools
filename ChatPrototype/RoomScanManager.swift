//
//  RoomScanManager.swift
//  ChatPrototype
//
//  Created by Glenn Silverman on 6/16/26.
//

import Foundation
import ARKit
import RealityKit
import Combine

// MARK: - SIMD Extensions
extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
}

/// Manages the room scanning process and object detection
class RoomScanManager: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var scanProgress: Float = 0.0
    @Published var isScanning: Bool = false
    @Published var meshAnchorsCount: Int = 0
    @Published var statusMessage: String = "Ready to scan"
    
    private var meshAnchors: [UUID: ARMeshAnchor] = [:]
    private var scanStartTime: Date?
    
    // Size thresholds for object detection
    // Balance between excluding small clutter and detecting meaningful furniture
    // TEMPORARILY RELAXED FOR DEBUGGING
    private let minObjectVolume: Float = 0.01 // Very low for debugging
    private let minObjectDimension: Float = 0.05 // 5cm minimum  
    private let minAverageDimension: Float = 0.10 // 10cm average - very low for debugging
    private let maxObjectVolume: Float = 5.0 // Increased for debugging
    
    private let classifier = ObjectClassifier() // AI-driven classifier
    private var currentFrame: ARFrame? // Store latest frame for vision analysis
    
    // MARK: - Scanning Control
    
    /// Start scanning the room
    func startScanning() {
        print("🔍 ========== STARTING ROOM SCAN ==========")
        print("   Previous meshAnchorsCount: \(meshAnchorsCount)")
        print("   Previous detectedObjects: \(detectedObjects.count)")
        
        isScanning = true
        scanStartTime = Date()
        statusMessage = "Scanning... Move slowly around the room"
        clearScan()
        
        print("   After clearScan:")
        print("   meshAnchorsCount: \(meshAnchorsCount)")
        print("   detectedObjects: \(detectedObjects.count)")
        print("========================================")
    }
    
    /// Stop scanning
    func stopScanning() {
        print("⏹️ Stopping room scan...")
        isScanning = false
        statusMessage = "Scan stopped. \(meshAnchorsCount) mesh anchors collected"
    }
    
    /// Clear all scan data
    func clearScan() {
        print("🗑️ Clearing scan data...")
        detectedObjects.removeAll()
        meshAnchors.removeAll()
        meshAnchorsCount = 0
        scanProgress = 0.0
        statusMessage = "Scan cleared"
    }
    
    // MARK: - Mesh Processing
    
    /// Process a new mesh anchor from ARKit
    func processMeshAnchor(_ anchor: ARMeshAnchor) {
        guard isScanning else {
            print("⚠️ processMeshAnchor called but not scanning - ignoring")
            return
        }
        
        // Store or update the mesh anchor
        meshAnchors[anchor.identifier] = anchor
        meshAnchorsCount = meshAnchors.count
        
        // Update progress (rough estimate based on anchor count)
        // Most rooms have 20-100 mesh anchors
        scanProgress = min(Float(meshAnchorsCount) / 50.0, 1.0)
        
        print("📊 Processed mesh anchor #\(meshAnchorsCount)")
        
        // Auto-generate wireframes during scanning (every 5 meshes for more responsive updates)
        if meshAnchorsCount % 5 == 0 {
            print("   🔄 Triggering wireframe generation at \(meshAnchorsCount) meshes")
            generateWireframesRealtime()
        }
    }
    
    /// Update current AR frame for vision-based classification
    func updateFrame(_ frame: ARFrame) {
        currentFrame = frame
    }
    
    /// Update an existing mesh anchor
    func updateMeshAnchor(_ anchor: ARMeshAnchor) {
        guard isScanning else { return }
        meshAnchors[anchor.identifier] = anchor
    }
    
    /// Remove a mesh anchor
    func removeMeshAnchor(_ anchor: ARMeshAnchor) {
        meshAnchors.removeValue(forKey: anchor.identifier)
        meshAnchorsCount = meshAnchors.count
    }
    
    // MARK: - Object Generation
    
    /// Generate wireframes in real-time during scanning (simpler, faster)
    private func generateWireframesRealtime() {
        print("🔄 Real-time wireframe generation - mesh count: \(meshAnchorsCount)")
        
        // Don't classify during scanning, just show bounding boxes
        let groupedObjects = groupMeshesIntoObjects()
        
        print("   Grouped into \(groupedObjects.count) potential objects")
        
        // Build new object set
        var newObjects: [DetectedObject] = []
        var filteredByVolume = 0
        var filteredByDimension = 0
        
        for group in groupedObjects {
            if let object = createObjectFromMeshGroup(group) {
                let volume = object.volume
                let size = object.boundingBox.size
                
                // Check volume
                if volume < minObjectVolume {
                    filteredByVolume += 1
                    print("   ❌ Filtered by volume: \(volume) < \(minObjectVolume) - size: \(size)")
                    continue
                }
                
                if volume > maxObjectVolume {
                    filteredByVolume += 1
                    print("   ❌ Filtered by volume: \(volume) > \(maxObjectVolume) - size: \(size)")
                    continue
                }
                
                object.label = "Scanning..."
                newObjects.append(object)
                print("   ✅ Added object - volume: \(volume), size: \(size)")
            } else {
                filteredByDimension += 1
            }
        }
        
        print("   Created \(newObjects.count) valid objects")
        print("   Filtered: \(filteredByVolume) by volume, \(filteredByDimension) by dimension")
        
        // Replace objects array - this triggers the publisher
        detectedObjects = newObjects
        
        print("   ✅ Updated detectedObjects array")
    }
    
    /// Generate objects and wireframes from collected mesh data
    func generateWireframes() {
        print("🎨 Generating wireframes from \(meshAnchorsCount) mesh anchors...")
        statusMessage = "Processing mesh data..."
        
        detectedObjects.removeAll()
        print("   Cleared existing objects")
        
        // Group nearby meshes into objects
        let groupedObjects = groupMeshesIntoObjects()
        print("   Grouped into \(groupedObjects.count) potential objects")
        
        // Filter and create detected objects
        for group in groupedObjects {
            if let object = createObjectFromMeshGroup(group) {
                // Filter by volume to remove tiny fragments and huge walls
                if object.volume >= minObjectVolume && object.volume <= maxObjectVolume {
                    detectedObjects.append(object)
                    print("   ✅ Added object with volume: \(object.volume)")
                }
            }
        }
        
        print("📦 Created \(detectedObjects.count) objects from \(meshAnchorsCount) mesh anchors")
        
        // Force array update to trigger publisher
        detectedObjects = detectedObjects
        print("   Triggered detectedObjects publisher")
        
        // Classify objects using AI-driven classifier
        Task { @MainActor in
            await classifyObjectsWithAI()
            // Trigger UI update after classification completes
            self.detectedObjects = self.detectedObjects
            print("   Triggered post-classification update")
        }
    }
    
    /// Group nearby mesh anchors into logical objects
    private func groupMeshesIntoObjects() -> [[ARMeshAnchor]] {
        // Filter meshes to exclude large planar surfaces (walls, floors, ceilings)
        var objectMeshes: [ARMeshAnchor] = []
        
        for anchor in meshAnchors.values {
            let geometry = anchor.geometry
            
            // Calculate rough bounds in local space
            let vertices = geometry.vertices
            var minBounds = SIMD3<Float>(repeating: .infinity)
            var maxBounds = SIMD3<Float>(repeating: -.infinity)
            
            let vertexCount = min(vertices.count, 100) // Sample first 100 vertices for speed
            let vertexBuffer = vertices.buffer
            let vertexStride = vertices.stride
            let vertexOffset = vertices.offset
            
            for i in 0..<vertexCount {
                let vertexPointer = vertexBuffer.contents().advanced(by: vertexOffset + (i * vertexStride))
                let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                minBounds = min(minBounds, vertex)
                maxBounds = max(maxBounds, vertex)
            }
            
            let size = maxBounds - minBounds
            
            // Filter out large, flat surfaces (likely walls/floors)
            // AND very small objects (knick-knacks, small items on tables)
            // Use smart filtering:
            // - Not too large in any dimension (< 2 meters)
            // - All dimensions above minimum (> 5cm to avoid noise)
            // - Average dimension above threshold (> 35cm to avoid small clutter)
            let maxDimension = max(size.x, max(size.y, size.z))
            let minDimension = min(size.x, min(size.y, size.z))
            let avgDimension = (size.x + size.y + size.z) / 3.0
            
            let meetsMinimumSize = minDimension > 0.05 // All dimensions > 5cm
            let meetsAverageSize = avgDimension >= minAverageDimension // Average >= 35cm
            
            if maxDimension < 2.0 && meetsMinimumSize && meetsAverageSize {
                objectMeshes.append(anchor)
                print("   ✓ Mesh passed filter - size: \(size), avg: \(avgDimension)m")
            } else {
                print("   ✗ Mesh filtered - size: \(size), avg: \(avgDimension)m, max: \(maxDimension)m")
            }
        }
        
        // For now, treat each filtered mesh as its own object
        // Future: implement actual clustering of nearby meshes
        return objectMeshes.map { [$0] }
    }
    
    /// Create a single object from a group of mesh anchors
    private func createObjectFromMeshGroup(_ meshGroup: [ARMeshAnchor]) -> DetectedObject? {
        guard !meshGroup.isEmpty else { return nil }
        
        // Calculate combined bounding box
        var minBounds = SIMD3<Float>(repeating: .infinity)
        var maxBounds = SIMD3<Float>(repeating: -.infinity)
        
        for meshAnchor in meshGroup {
            let geometry = meshAnchor.geometry
            let vertices = geometry.vertices
            let transform = meshAnchor.transform
            
            let vertexCount = vertices.count
            let vertexBuffer = vertices.buffer
            let vertexStride = vertices.stride
            let vertexOffset = vertices.offset
            
            for i in 0..<vertexCount {
                let vertexPointer = vertexBuffer.contents().advanced(by: vertexOffset + (i * vertexStride))
                let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                
                // Transform to world space
                let worldPos = transform * SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1)
                let worldVertex = SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z)
                
                minBounds = min(minBounds, worldVertex)
                maxBounds = max(maxBounds, worldVertex)
            }
        }
        
        // Calculate center and size
        let center = (minBounds + maxBounds) / 2
        let size = maxBounds - minBounds
        
        // Filter out small objects using smart threshold
        // Check average dimension to exclude small clutter
        let avgDimension = (size.x + size.y + size.z) / 3.0
        let minDimension = min(size.x, min(size.y, size.z))
        
        guard minDimension > minObjectDimension && avgDimension >= minAverageDimension else {
            print("   ✗ Object filtered - size: \(size), avg: \(avgDimension)m, min: \(minDimension)m")
            return nil
        }
        
        print("   ✓ Object created - size: \(size), avg: \(avgDimension)m")
        
        let boundingBox = BoundingBox(
            center: center,
            size: size,
            rotation: simd_quatf()
        )
        
        let object = DetectedObject(
            boundingBox: boundingBox,
            meshAnchor: meshGroup.first,
            label: "Object"
        )
        
        return object
    }
    
    // MARK: - AI-Driven Classification
    
    /// Classify objects using enhanced AI classifier
    @MainActor
    private func classifyObjectsWithAI() async {
        statusMessage = "Classifying objects..."
        
        // If no objects, nothing to classify
        guard !detectedObjects.isEmpty else {
            statusMessage = "No objects detected"
            return
        }
        
        print("🔍 Classifying \(detectedObjects.count) objects...")
        
        for (index, object) in detectedObjects.enumerated() {
            // Use AI classifier (geometry-based only for stability)
            // Vision classification is disabled temporarily to prevent crashes
            let result = await classifier.classifyWithVision(object: object, frame: nil)
            
            // Update object with classification results
            object.label = "\(result.label) (\(result.category.displayName))"
            object.confidence = result.confidence
            
            // Add metadata for furniture vs structure
            if !result.isMovable {
                object.label = "🏗️ " + object.label
            } else {
                object.label = "🪑 " + object.label
            }
            
            print("  [\(index+1)/\(detectedObjects.count)] \(object.label) - confidence: \(result.confidence)")
        }
        
        statusMessage = "Generated \(detectedObjects.count) objects"
        print("✅ Generated \(detectedObjects.count) wireframe objects with AI classification")
    }
    
    // MARK: - Object Classification
    
    /// Update the visibility of an object
    func updateObjectVisibility(_ object: DetectedObject) {
        // The object's isVisible property is already updated
        // Force a refresh by reassigning the array (triggers @Published)
        detectedObjects = detectedObjects
    }
    
    /// Toggle visibility of all wireframes at once
    func toggleAllWireframes(visible: Bool) {
        print("👁️ Toggling wireframes to: \(visible ? "visible" : "hidden")")
        print("   Total objects: \(detectedObjects.count)")
        
        for object in detectedObjects {
            object.isVisible = visible
            print("   Set \(object.label) visibility to \(visible)")
        }
        
        // Force a refresh by reassigning the array (triggers @Published)
        detectedObjects = detectedObjects
        
        print("   Sent array update notification")
    }
    
    /// TEST METHOD: Create a simple test wireframe directly in front of camera
    func createTestWireframe() {
        print("🧪 Creating test wireframe...")
        
        // Create a simple box 1 meter in front of the camera
        let testBox = BoundingBox(
            center: SIMD3<Float>(0, 0, -1), // 1 meter in front
            size: SIMD3<Float>(0.3, 0.3, 0.3), // 30cm cube
            rotation: simd_quatf()
        )
        
        let testObject = DetectedObject(
            boundingBox: testBox,
            meshAnchor: nil,
            label: "🧪 TEST BOX",
            color: .systemPink
        )
        
        detectedObjects.append(testObject)
        detectedObjects = detectedObjects // Force update
        
        print("   ✅ Test object created at \(testBox.center)")
        print("   Total objects now: \(detectedObjects.count)")
    }
    
    private func classifyObject(_ object: DetectedObject) -> String {
        let size = object.boundingBox.size
        let height = size.y
        let width = max(size.x, size.z)
        let depth = min(size.x, size.z)
        let aspectRatio = width / height
        
        // Simple heuristic classification
        if height < 0.15 {
            return "Floor/Surface"
        } else if height > 2.0 && depth < 0.3 {
            return "Wall"
        } else if height > 0.5 && height < 1.0 && aspectRatio > 1.2 {
            return "Table"
        } else if height > 0.8 && height < 1.3 && width < 0.7 {
            return "Chair"
        } else if height > 1.5 && width < 1.0 {
            return "Door/Cabinet"
        } else if height < 0.5 && width < 0.5 {
            return "Small Object"
        } else {
            return "Object"
        }
    }
    
    // MARK: - Export
    
    func exportScanData() -> String {
        var json = "{\n"
        json += "  \"format_version\": \"1.0\",\n"
        json += "  \"scan_date\": \"\(Date().ISO8601Format())\",\n"
        json += "  \"object_count\": \(detectedObjects.count),\n"
        json += "  \"units\": \"meters\",\n"
        json += "  \"coordinate_system\": \"ARKit_world_space\",\n"
        json += "  \"objects\": [\n"
        
        for (index, object) in detectedObjects.enumerated() {
            let bbox = object.boundingBox
            json += "    {\n"
            json += "      \"id\": \"\(object.id)\",\n"
            json += "      \"label\": \"\(object.label)\",\n"
            json += "      \"position\": {\n"
            json += "        \"x\": \(bbox.center.x),\n"
            json += "        \"y\": \(bbox.center.y),\n"
            json += "        \"z\": \(bbox.center.z)\n"
            json += "      },\n"
            json += "      \"rotation\": {\n"
            json += "        \"x\": \(bbox.rotation.imag.x),\n"
            json += "        \"y\": \(bbox.rotation.imag.y),\n"
            json += "        \"z\": \(bbox.rotation.imag.z),\n"
            json += "        \"w\": \(bbox.rotation.real)\n"
            json += "      },\n"
            json += "      \"dimensions\": {\n"
            json += "        \"width\": \(bbox.size.x),\n"
            json += "        \"height\": \(bbox.size.y),\n"
            json += "        \"depth\": \(bbox.size.z)\n"
            json += "      },\n"
            json += "      \"volume\": \(object.volume),\n"
            json += "      \"bounding_box\": {\n"
            json += "        \"min\": {\n"
            json += "          \"x\": \(bbox.center.x - bbox.size.x/2),\n"
            json += "          \"y\": \(bbox.center.y - bbox.size.y/2),\n"
            json += "          \"z\": \(bbox.center.z - bbox.size.z/2)\n"
            json += "        },\n"
            json += "        \"max\": {\n"
            json += "          \"x\": \(bbox.center.x + bbox.size.x/2),\n"
            json += "          \"y\": \(bbox.center.y + bbox.size.y/2),\n"
            json += "          \"z\": \(bbox.center.z + bbox.size.z/2)\n"
            json += "        }\n"
            json += "      }\n"
            json += "    }"
            if index < detectedObjects.count - 1 {
                json += ","
            }
            json += "\n"
        }
        
        json += "  ]\n"
        json += "}"
        
        return json
    }
    
    /// Export scan data as USD/USDZ format (Apple's preferred 3D format)
    /// This format is compatible with ARKit, Reality Composer, and many 3D tools
    func exportAsUSDZ() -> URL? {
        // TODO: Implement USDZ export using Model I/O framework
        // This would create a proper 3D file that can be opened in:
        // - Reality Composer
        // - SketchUp (with plugins)
        // - Blender (with USD plugin)
        // - Autodesk Maya
        // - Houdini
        print("⚠️ USDZ export not yet implemented")
        return nil
    }
    
    /// Export raw mesh data as OBJ format
    /// OBJ is widely supported by almost all 3D software
    func exportAsOBJ() -> String? {
        guard !meshAnchors.isEmpty else { return nil }
        
        var obj = "# Exported from LiDAR Room Scanner\n"
        obj += "# Date: \(Date())\n"
        obj += "# Object count: \(meshAnchors.count)\n\n"
        
        var vertexOffset = 1
        
        for (index, anchor) in meshAnchors.values.enumerated() {
            obj += "o Object_\(index)\n"
            
            let geometry = anchor.geometry
            let vertices = geometry.vertices
            let faces = geometry.faces
            let transform = anchor.transform
            
            // Export vertices
            let vertexCount = vertices.count
            let vertexBuffer = vertices.buffer
            let vertexStride = vertices.stride
            let vertexOffset_data = vertices.offset
            
            for i in 0..<vertexCount {
                let vertexPointer = vertexBuffer.contents().advanced(by: vertexOffset_data + (i * vertexStride))
                let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                
                // Transform to world space
                let worldPos = transform * SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1)
                obj += "v \(worldPos.x) \(worldPos.y) \(worldPos.z)\n"
            }
            
            // Export faces
            let faceCount = faces.count
            let indexBuffer = faces.buffer
            let bytesPerIndex = faces.bytesPerIndex
            let primitiveType = faces.primitiveType
            let indexCountPerPrimitive = faces.indexCountPerPrimitive
            
            // ARKit typically uses triangles (3 indices per face)
            for i in 0..<faceCount {
                let faceStart = i * indexCountPerPrimitive * bytesPerIndex
                let facePointer = indexBuffer.contents().advanced(by: faceStart)
                
                obj += "f"
                for j in 0..<indexCountPerPrimitive {
                    let indexPointer = facePointer.advanced(by: j * bytesPerIndex)
                    let index: Int
                    
                    // Handle different index sizes (typically UInt32 or UInt16)
                    if bytesPerIndex == 4 {
                        index = Int(indexPointer.assumingMemoryBound(to: UInt32.self).pointee)
                    } else if bytesPerIndex == 2 {
                        index = Int(indexPointer.assumingMemoryBound(to: UInt16.self).pointee)
                    } else {
                        index = Int(indexPointer.assumingMemoryBound(to: UInt8.self).pointee)
                    }
                    
                    // OBJ format uses 1-based indexing
                    obj += " \(index + vertexOffset)"
                }
                obj += "\n"
            }
            
            vertexOffset += vertexCount
            obj += "\n"
        }
        
        return obj
    }
}
