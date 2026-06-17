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

/// Manages the room scanning process and object detection
class RoomScanManager: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var scanProgress: Float = 0.0
    @Published var isScanning: Bool = false
    @Published var meshAnchorsCount: Int = 0
    @Published var statusMessage: String = "Ready to scan"
    
    private var meshAnchors: [UUID: ARMeshAnchor] = [:]
    private var scanStartTime: Date?
    private let minObjectVolume: Float = 0.01 // 10cm³ minimum
    private let maxObjectVolume: Float = 100.0 // 100m³ maximum
    
    // MARK: - Scanning Control
    
    /// Start scanning the room
    func startScanning() {
        print("🔍 Starting room scan...")
        isScanning = true
        scanStartTime = Date()
        statusMessage = "Scanning... Move slowly around the room"
        clearScan()
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
        guard isScanning else { return }
        
        // Store or update the mesh anchor
        meshAnchors[anchor.identifier] = anchor
        meshAnchorsCount = meshAnchors.count
        
        // Update progress (rough estimate based on anchor count)
        // Most rooms have 20-100 mesh anchors
        scanProgress = min(Float(meshAnchorsCount) / 50.0, 1.0)
        
        print("📊 Processed mesh anchor. Total: \(meshAnchorsCount)")
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
    
    /// Generate objects and wireframes from collected mesh data
    func generateWireframes() {
        print("🎨 Generating wireframes from \(meshAnchorsCount) mesh anchors...")
        statusMessage = "Processing mesh data..."
        
        detectedObjects.removeAll()
        
        // Process each mesh anchor
        for (_, meshAnchor) in meshAnchors {
            if let object = createObjectFromMesh(meshAnchor) {
                // Filter by volume
                if object.volume >= minObjectVolume && object.volume <= maxObjectVolume {
                    detectedObjects.append(object)
                }
            }
        }
        
        // Classify objects
        classifyObjects()
        
        statusMessage = "Generated \(detectedObjects.count) objects"
        print("✅ Generated \(detectedObjects.count) wireframe objects")
    }
    
    // MARK: - Object Creation
    
    private func createObjectFromMesh(_ meshAnchor: ARMeshAnchor) -> DetectedObject? {
        let boundingBox = calculateBoundingBox(for: meshAnchor)
        
        // Filter out very small or very large objects
        guard boundingBox.size.x > 0.05 && boundingBox.size.y > 0.05 && boundingBox.size.z > 0.05 else {
            return nil
        }
        
        let object = DetectedObject(
            boundingBox: boundingBox,
            meshAnchor: meshAnchor,
            label: "Object"
        )
        
        return object
    }
    
    private func calculateBoundingBox(for meshAnchor: ARMeshAnchor) -> BoundingBox {
        let geometry = meshAnchor.geometry
        let vertices = geometry.vertices
        
        var minBounds = SIMD3<Float>(repeating: .infinity)
        var maxBounds = SIMD3<Float>(repeating: -.infinity)
        
        // Access vertex data through the buffer
        let vertexCount = vertices.count
        let vertexBuffer = vertices.buffer
        let vertexStride = vertices.stride
        let vertexOffset = vertices.offset
        
        // Find min and max bounds
        for i in 0..<vertexCount {
            let vertexPointer = vertexBuffer.contents().advanced(by: vertexOffset + (i * vertexStride))
            let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
            
            minBounds = min(minBounds, vertex)
            maxBounds = max(maxBounds, vertex)
        }
        
        // Calculate center and size in local space
        let localCenter = (minBounds + maxBounds) / 2
        let size = maxBounds - minBounds
        
        // Transform to world space
        let transform = meshAnchor.transform
        let worldCenter = transform * SIMD4<Float>(localCenter.x, localCenter.y, localCenter.z, 1)
        
        return BoundingBox(
            center: SIMD3<Float>(worldCenter.x, worldCenter.y, worldCenter.z),
            size: size,
            rotation: simd_quatf(transform)
        )
    }
    
    // MARK: - Object Classification
    
    private func classifyObjects() {
        for object in detectedObjects {
            object.label = classifyObject(object)
        }
    }
    
    /// Update the visibility of an object
    func updateObjectVisibility(_ object: DetectedObject) {
        // The object's isVisible property is already updated
        // This method can be used to trigger additional updates if needed
        print("👁️ Object \(object.label) visibility: \(object.isVisible)")
        objectWillChange.send()
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
