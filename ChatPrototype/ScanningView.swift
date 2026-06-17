//
//  ScanningView.swift
//  ChatPrototype
//
//  Created by Glenn Silverman on 6/16/26.
//

import SwiftUI
import ARKit
import RealityKit
import UIKit
import Combine

struct ScanningView: View {
    @ObservedObject var scanManager: RoomScanManager
    @Binding var appMode: AppMode
    @State private var showingObjectList = false
    @State private var showingExportSheet = false
    @State private var wireframeMessage: String = ""
    @State private var showWireframeMessage: Bool = false
    @State private var wireframesVisible: Bool = true  // Track wireframe visibility
    
    init(scanManager: RoomScanManager, appMode: Binding<AppMode>) {
        print("🚀 ScanningView.init() called")
        self.scanManager = scanManager
        self._appMode = appMode
        print("🚀 ScanningView.init() completed")
    }
    
    var body: some View {
        ZStack {
            // AR View
            ARScanningView(scanManager: scanManager)
                .ignoresSafeArea()
            
            // Wireframe generation message
            if showWireframeMessage {
                VStack {
                    Spacer()
                    Text(wireframeMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .padding(.bottom, 100)
                }
                .transition(.opacity)
            }
            
            VStack {
                Spacer()
                
                // Compact bottom control panel
                VStack(spacing: 6) {
                    // Status line
                    HStack(spacing: 6) {
                        if scanManager.isScanning {
                            ProgressView(value: scanManager.scanProgress)
                                .progressViewStyle(.linear)
                                .tint(.green)
                                .frame(width: 60)
                            Text("\(Int(scanManager.scanProgress * 100))%")
                                .font(.caption2)
                                .foregroundColor(.white)
                        } else {
                            Text(scanManager.statusMessage)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        
                        if scanManager.meshAnchorsCount > 0 {
                            Text("M:\(scanManager.meshAnchorsCount)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if !scanManager.detectedObjects.isEmpty {
                            Text("Obj:\(scanManager.detectedObjects.count)")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                    }
                    
                    // Main controls - single compact row
                    HStack(spacing: 8) {
                        if scanManager.isScanning {
                            Button(action: { scanManager.stopScanning() }) {
                                Image(systemName: "stop.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.red.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        } else {
                            Button(action: { 
                                print("▶️ START SCAN button pressed")
                                scanManager.startScanning()
                                print("   isScanning: \(scanManager.isScanning)")
                                print("   meshAnchorsCount: \(scanManager.meshAnchorsCount)")
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.green.opacity(0.8))
                                    .cornerRadius(8)
                            }
                            
                            // Only show these buttons when NOT scanning AND we have mesh data
                            if scanManager.meshAnchorsCount > 0 {
                                Button(action: { showingExportSheet = true }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(.orange.opacity(0.8))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: { scanManager.clearScan() }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(.gray.opacity(0.8))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { appMode = .home }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.red.opacity(0.8))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingObjectList) {
            ObjectListView(scanManager: scanManager)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(scanManager: scanManager)
        }
        .onAppear {
            // Prevent screen from dimming during scanning
            UIApplication.shared.isIdleTimerDisabled = true
            print("🔆 Screen dimming disabled")
        }
        .onDisappear {
            // Re-enable screen dimming when leaving scanning view
            UIApplication.shared.isIdleTimerDisabled = false
            print("🔅 Screen dimming re-enabled")
        }
        .onChange(of: scanManager.isScanning) { isScanning in
            // Also manage screen dimming based on scanning state
            UIApplication.shared.isIdleTimerDisabled = isScanning
            print(isScanning ? "🔆 Screen dimming disabled (scanning)" : "🔅 Screen dimming re-enabled (not scanning)")
        }
    }
}

// MARK: - AR Scanning View
struct ARScanningView: UIViewRepresentable {
    @ObservedObject var scanManager: RoomScanManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Set delegate
        arView.session.delegate = context.coordinator
        print("✅ Set AR session delegate")
        
        // Configure AR session with mesh reconstruction
        let config = ARWorldTrackingConfiguration()
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            print("✅ LiDAR mesh scanning enabled")
        } else {
            print("⚠️ LiDAR not available")
        }
        
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        print("✅ AR session started")
        
        context.coordinator.arView = arView
        context.coordinator.scanManager = scanManager
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates handled by Combine publishers
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scanManager: scanManager)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var scanManager: RoomScanManager
        private var wireframeAnchors: [UUID: AnchorEntity] = [:]
        private var cancellables = Set<AnyCancellable>()
        private var isUpdatingWireframes = false
        
        init(scanManager: RoomScanManager) {
            self.scanManager = scanManager
            super.init()
            
            // Observe changes to detected objects and update wireframes
            // Use debounce to prevent too many rapid updates, but make it faster
            scanManager.$detectedObjects
                .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateWireframes()
                }
                .store(in: &cancellables)
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Pass current frame to scan manager for vision-based classification
            scanManager.updateFrame(frame)
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    scanManager.processMeshAnchor(meshAnchor)
                }
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    scanManager.updateMeshAnchor(meshAnchor)
                }
            }
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    scanManager.removeMeshAnchor(meshAnchor)
                }
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ AR Session failed: \(error.localizedDescription)")
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            switch camera.trackingState {
            case .normal:
                print("✅ AR tracking normal")
            case .notAvailable:
                print("⚠️ AR tracking not available")
            case .limited(let reason):
                print("⚠️ AR tracking limited: \(reason)")
            }
        }
        
        // MARK: - Wireframe Rendering
        
        func updateWireframes() {
            guard let arView = arView else {
                print("⚠️ updateWireframes: arView is nil")
                return
            }
            
            // Prevent concurrent updates
            guard !isUpdatingWireframes else {
                print("⏭️ Skipping wireframe update - already in progress")
                return
            }
            
            isUpdatingWireframes = true
            defer { isUpdatingWireframes = false }
            
            let totalObjects = scanManager.detectedObjects.count
            print("🔄 updateWireframes called - detectedObjects count: \(totalObjects)")
            
            // Remove old wireframes
            let oldCount = wireframeAnchors.count
            for (_, anchor) in wireframeAnchors {
                arView.scene.removeAnchor(anchor)
            }
            wireframeAnchors.removeAll()
            
            print("   Cleared \(oldCount) old wireframes")
            
            // Add new wireframes for visible objects
            let visibleObjects = scanManager.detectedObjects.filter { $0.isVisible }
            
            print("   Found \(visibleObjects.count) visible objects (out of \(totalObjects) total)")
            
            for (index, object) in visibleObjects.enumerated() {
                // Create anchor at the object's world position with its rotation
                let anchor = AnchorEntity(world: object.boundingBox.center)
                anchor.orientation = object.boundingBox.rotation
                
                // Create and add wireframe box
                let wireframe = createWireframeBox(for: object)
                anchor.addChild(wireframe)
                
                arView.scene.addAnchor(anchor)
                wireframeAnchors[object.id] = anchor
                
                if (index + 1) % 10 == 0 || index == visibleObjects.count - 1 {
                    print("   Created wireframe \(index + 1)/\(visibleObjects.count)")
                }
            }
            
            print("✅ Created \(wireframeAnchors.count) wireframes total")
        }
        
        func createWireframeBox(for object: DetectedObject) -> Entity {
            let size = object.boundingBox.size
            let halfSize = SIMD3<Float>(size.x / 2, size.y / 2, size.z / 2)
            
            // Container entity to hold all the edge lines
            let wireframeEntity = Entity()
            
            // Define the 8 corners of the box
            let corners: [SIMD3<Float>] = [
                SIMD3(-halfSize.x, -halfSize.y, -halfSize.z), // 0: bottom-front-left
                SIMD3( halfSize.x, -halfSize.y, -halfSize.z), // 1: bottom-front-right
                SIMD3( halfSize.x, -halfSize.y,  halfSize.z), // 2: bottom-back-right
                SIMD3(-halfSize.x, -halfSize.y,  halfSize.z), // 3: bottom-back-left
                SIMD3(-halfSize.x,  halfSize.y, -halfSize.z), // 4: top-front-left
                SIMD3( halfSize.x,  halfSize.y, -halfSize.z), // 5: top-front-right
                SIMD3( halfSize.x,  halfSize.y,  halfSize.z), // 6: top-back-right
                SIMD3(-halfSize.x,  halfSize.y,  halfSize.z)  // 7: top-back-left
            ]
            
            // Define the 12 edges of the box (pairs of corner indices)
            let edges: [(Int, Int)] = [
                // Bottom face
                (0, 1), (1, 2), (2, 3), (3, 0),
                // Top face
                (4, 5), (5, 6), (6, 7), (7, 4),
                // Vertical edges
                (0, 4), (1, 5), (2, 6), (3, 7)
            ]
            
            // Create a cylinder for each edge
            let edgeRadius: Float = 0.005 // Thin lines for wireframe effect
            
            // Use a consistent bright color for all wireframes
            let wireframeColor = UIColor.systemYellow
            
            for (startIdx, endIdx) in edges {
                let start = corners[startIdx]
                let end = corners[endIdx]
                
                // Calculate edge properties
                let midpoint = (start + end) / 2
                let direction = end - start
                let length = simd_length(direction)
                
                // Create cylinder mesh for this edge
                let cylinder = MeshResource.generateCylinder(height: length, radius: edgeRadius)
                
                // Create material with consistent wireframe color
                var material = UnlitMaterial(color: wireframeColor)
                
                let edge = ModelEntity(mesh: cylinder, materials: [material])
                
                // Position at midpoint
                edge.position = midpoint
                
                // Rotate to align with edge direction
                if length > 0.0001 {
                    let up = SIMD3<Float>(0, 1, 0)
                    let normalizedDirection = simd_normalize(direction)
                    
                    // Calculate rotation to align cylinder (which points up by default) with edge direction
                    let rotationAxis = simd_cross(up, normalizedDirection)
                    let rotationAxisLength = simd_length(rotationAxis)
                    
                    if rotationAxisLength > 0.0001 {
                        let angle = acos(simd_dot(up, normalizedDirection))
                        let normalizedAxis = simd_normalize(rotationAxis)
                        edge.orientation = simd_quatf(angle: angle, axis: normalizedAxis)
                    } else if simd_dot(up, normalizedDirection) < 0 {
                        // Edge points down, rotate 180 degrees
                        edge.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
                    }
                }
                
                wireframeEntity.addChild(edge)
            }
            
            return wireframeEntity
        }
    }
}

// MARK: - Object List View
struct ObjectListView: View {
    @ObservedObject var scanManager: RoomScanManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scanManager.detectedObjects) { object in
                    ObjectRow(object: object, scanManager: scanManager)
                }
            }
            .navigationTitle("Detected Objects (\(scanManager.detectedObjects.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Object Row
struct ObjectRow: View {
    let object: DetectedObject
    @ObservedObject var scanManager: RoomScanManager
    @State private var isVisible: Bool
    
    init(object: DetectedObject, scanManager: RoomScanManager) {
        self.object = object
        self.scanManager = scanManager
        self._isVisible = State(initialValue: object.isVisible)
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(object.color))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(object.label)
                    .font(.headline)
                Text(object.dimensionsString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { object.isVisible },
                set: { newValue in
                    object.isVisible = newValue
                    scanManager.updateObjectVisibility(object)
                }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    @ObservedObject var scanManager: RoomScanManager
    @Environment(\.dismiss) var dismiss
    @State private var exportData: String = ""
    @State private var exportFormat: ExportFormat = .json
    @State private var isLoading: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var saveAlertMessage: String = ""
    @State private var showingShareSheet: Bool = false
    @State private var shareFileURL: URL?
    @State private var exportTask: Task<Void, Never>?
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case obj = "OBJ"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Scan Data Export")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Format picker
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Info box about compatibility
                    if exportFormat == .obj {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("OBJ File Format (.txt)")
                                    .font(.headline)
                            }
                            
                            Text("Saved as .txt for easy viewing on iOS. Rename to .obj to import into:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Label("SketchUp", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                Label("AutoCAD", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                Label("Blender", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                Label("3ds Max, Maya, Cinema 4D", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                Label("Most other 3D software", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("The file is saved as .txt so you can easily view and share it on iOS. Simply rename the extension from .txt to .obj on your computer to import into 3D software.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.green)
                                Text("JSON Format")
                                    .font(.headline)
                            }
                            
                            Text("Structured data with object positions, dimensions, classifications, and bounding boxes. Ideal for custom processing or web applications.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Export data preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Data")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .padding()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Generating export data...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if exportFormat == .obj {
                                        Text("This may take a moment for large scans")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                // Show file size info and preview for both formats
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(exportFormat == .obj ? .blue : .green)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(exportFormat.rawValue) File Ready")
                                                .font(.headline)
                                            Text("\(exportData.count) characters")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("≈ \(formatBytes(exportData.utf8.count))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Text("Preview (first 20 lines):")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(exportData.split(separator: "\n").prefix(20).joined(separator: "\n"))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    
                                    if exportData.split(separator: "\n").count > 20 {
                                        Text("... (\(exportData.split(separator: "\n").count - 20) more lines)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Copy button
                    if !exportData.isEmpty {
                        Button(action: {
                            UIPasteboard.general.string = exportData
                            saveAlertMessage = "Copied to clipboard!"
                            showingSaveAlert = true
                        }) {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Save button
                    if !exportData.isEmpty {
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            Label("Save \(exportFormat.rawValue) File", systemImage: "folder.badge.plus")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Share button
                    if !exportData.isEmpty {
                        Button(action: {
                            shareFile()
                        }) {
                            Label("Share \(exportFormat.rawValue) File", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                        .frame(height: 20)
                        .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                print("📋 ExportView appeared")
                // Auto-generate export data when sheet opens
                if exportData.isEmpty {
                    updateExportData()
                }
            }
            .onChange(of: exportFormat) { newFormat in
                print("📋 Export format changed to: \(newFormat)")
                // Regenerate when format changes
                exportData = "" // Clear old data
                updateExportData()
            }
            .onDisappear {
                print("📋 ExportView disappearing - cancelling tasks")
                // Cancel any ongoing export tasks
                exportTask?.cancel()
                exportTask = nil
                isLoading = false
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(
                fileURL: createTempOBJFile(),
                onSave: { success, path in
                    if success {
                        saveAlertMessage = "File saved successfully!\n\nLocation: \(path)"
                        showingSaveAlert = true
                    } else {
                        saveAlertMessage = "Failed to save file. Please try again."
                        showingSaveAlert = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = shareFileURL {
                ShareSheet(activityItems: [fileURL])
                    .onDisappear {
                        // Clean up the URL after sharing
                        print("📤 Share sheet dismissed")
                    }
            } else {
                // This shouldn't happen, but provide fallback
                Text("No file to share")
                    .onAppear {
                        print("⚠️ Share sheet presented without URL!")
                        showingShareSheet = false
                    }
            }
        }
        .alert("Save Status", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private func updateExportData() {
        print("📤 updateExportData called - format: \(exportFormat)")
        
        // Cancel any existing task
        exportTask?.cancel()
        exportTask = nil
        
        // Clear old data and show loading immediately
        exportData = ""
        isLoading = true
        
        // Start export task
        exportTask = Task { @MainActor in
            print("   Starting export task...")
            
            // Capture format value
            let format = exportFormat
            
            // Run export on background queue
            let data = await Task.detached(priority: .userInitiated) {
                print("   Running export on background thread...")
                
                let result: String
                switch format {
                case .json:
                    print("   Exporting JSON...")
                    result = self.scanManager.exportScanData()
                case .obj:
                    print("   Exporting OBJ...")
                    result = self.scanManager.exportAsOBJ() ?? "No mesh data available"
                }
                
                print("   Export complete - data length: \(result.count)")
                return result
            }.value
            
            // Check if cancelled
            guard !Task.isCancelled else {
                print("   ⚠️ Task was cancelled")
                isLoading = false
                return
            }
            
            // Update UI
            print("   Updating UI with exported data")
            exportData = data
            isLoading = false
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func createTempOBJFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileExtension = exportFormat == .obj ? "txt" : "json"
        let fileName = "room_scan_\(Date().timeIntervalSince1970).\(fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try exportData.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Created temp \(fileExtension.uppercased()) file at: \(fileURL.path)")
        } catch {
            print("❌ Failed to create temp file: \(error.localizedDescription)")
        }
        
        return fileURL
    }
    
    private func shareFile() {
        print("🔄 shareFile called")
        
        // Validate export data exists
        guard !exportData.isEmpty else {
            print("❌ No export data available")
            return
        }
        
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileExtension = exportFormat == .obj ? "txt" : "json"
        let fileName = "room_scan_\(Date().timeIntervalSince1970).\(fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        print("   Creating temp file: \(fileName)")
        
        do {
            // Write data to file
            try exportData.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Created temp \(fileExtension.uppercased()) file")
            print("   Path: \(fileURL.path)")
            print("   Size: \(exportData.utf8.count) bytes")
            
            // Verify file exists
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("❌ File verification failed")
                saveAlertMessage = "Failed to create temporary file."
                showingSaveAlert = true
                return
            }
            
            print("✅ File verified, preparing to show share sheet")
            
            // IMPORTANT: Set the URL first, then trigger the sheet
            // This ensures the URL is available when the sheet's closure executes
            shareFileURL = fileURL
            
            // Give SwiftUI a moment to process the state change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("   Showing share sheet now")
                showingShareSheet = true
            }
            
        } catch {
            print("❌ Error creating file: \(error)")
            saveAlertMessage = "Error creating file: \(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let fileURL: URL
    let onSave: (Bool, String) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSave: onSave)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSave: (Bool, String) -> Void
        
        init(onSave: @escaping (Bool, String) -> Void) {
            self.onSave = onSave
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                print("✅ File saved to: \(url.path)")
                onSave(true, url.path)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("ℹ️ File picker cancelled")
            onSave(false, "Cancelled")
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
