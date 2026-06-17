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

struct ScanningView: View {
    @ObservedObject var scanManager: RoomScanManager
    @Binding var appMode: AppMode
    @State private var showingObjectList = false
    @State private var showingExportSheet = false
    
    var body: some View {
        ZStack {
            // AR View
            ARScanningView(scanManager: scanManager)
                .ignoresSafeArea()
            
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
                            Button(action: { scanManager.startScanning() }) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.green.opacity(0.8))
                                    .cornerRadius(8)
                            }
                            
                            if scanManager.meshAnchorsCount > 0 {
                                Button(action: { scanManager.generateWireframes() }) {
                                    Image(systemName: "cube.transparent")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(.blue.opacity(0.8))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        if !scanManager.detectedObjects.isEmpty {
                            Button(action: { showingObjectList = true }) {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.purple.opacity(0.8))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { showingExportSheet = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.orange.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if scanManager.meshAnchorsCount > 0 || !scanManager.detectedObjects.isEmpty {
                            Button(action: { scanManager.clearScan() }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.gray.opacity(0.8))
                                    .cornerRadius(8)
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
    }
}

// MARK: - AR Scanning View
struct ARScanningView: UIViewRepresentable {
    @ObservedObject var scanManager: RoomScanManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Set delegate
        arView.session.delegate = context.coordinator
        
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
        
        context.coordinator.arView = arView
        context.coordinator.scanManager = scanManager
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update wireframes when objects change
        context.coordinator.updateWireframes()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scanManager: scanManager)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var scanManager: RoomScanManager
        private var wireframeAnchors: [UUID: AnchorEntity] = [:]
        
        init(scanManager: RoomScanManager) {
            self.scanManager = scanManager
        }
        
        // MARK: - ARSessionDelegate
        
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
            guard let arView = arView else { return }
            
            // Remove old wireframes
            for (_, anchor) in wireframeAnchors {
                arView.scene.removeAnchor(anchor)
            }
            wireframeAnchors.removeAll()
            
            // Add new wireframes for visible objects
            for object in scanManager.detectedObjects where object.isVisible {
                let wireframe = createWireframe(for: object)
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(wireframe)
                arView.scene.addAnchor(anchor)
                wireframeAnchors[object.id] = anchor
            }
        }
        
        func createWireframe(for object: DetectedObject) -> ModelEntity {
            let box = object.boundingBox
            let corners = box.corners
            
            let wireframeEntity = ModelEntity()
            
            // Define the 12 edges of a bounding box
            let edges: [(Int, Int)] = [
                // Bottom face
                (0, 1), (1, 3), (3, 2), (2, 0),
                // Top face
                (4, 5), (5, 7), (7, 6), (6, 4),
                // Vertical edges
                (0, 4), (1, 5), (2, 6), (3, 7)
            ]
            
            for (startIdx, endIdx) in edges {
                let start = corners[startIdx]
                let end = corners[endIdx]
                let edge = createEdge(from: start, to: end, color: object.color, thickness: 0.008)
                wireframeEntity.addChild(edge)
            }
            
            return wireframeEntity
        }
        
        func createEdge(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor, thickness: Float) -> ModelEntity {
            let vector = end - start
            let length = simd_length(vector)
            let direction = simd_normalize(vector)
            
            // Create cylinder mesh
            let cylinder = ModelEntity(
                mesh: .generateBox(width: thickness, height: length, depth: thickness),
                materials: [SimpleMaterial(color: color, isMetallic: false)]
            )
            
            // Position at midpoint
            let midpoint = (start + end) / 2
            cylinder.position = midpoint
            
            // Rotate to align with direction
            let up = SIMD3<Float>(0, 1, 0)
            let angle = acos(dot(up, direction))
            let axis = cross(up, direction)
            
            if simd_length(axis) > 0.001 {
                cylinder.orientation = simd_quatf(angle: angle, axis: normalize(axis))
            }
            
            return cylinder
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
                                Text("Generating export data...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                // Show file size info instead of full content for large files
                                if exportFormat == .obj {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "doc.text.fill")
                                                .font(.largeTitle)
                                                .foregroundColor(.blue)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("OBJ File Ready")
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
                                } else {
                                    // For JSON, show full content since it's smaller
                                    Text(exportData)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                        .textSelection(.enabled)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Copy button
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
                    
                    // Save button for all formats
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
                    
                    // Share button for both formats
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
                    .disabled(exportData.isEmpty)
                    
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
                updateExportData()
            }
            .onChange(of: exportFormat) { _ in
                updateExportData()
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
            }
        }
        .alert("Save Status", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private func updateExportData() {
        isLoading = true
        
        Task {
            let data: String
            
            switch exportFormat {
            case .json:
                data = scanManager.exportScanData()
            case .obj:
                data = await Task.detached(priority: .userInitiated) {
                    return scanManager.exportAsOBJ() ?? "No mesh data available"
                }.value
            }
            
            await MainActor.run {
                exportData = data
                isLoading = false
            }
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
        print("🔄 Preparing file for sharing...")
        
        // Ensure we have data
        guard !exportData.isEmpty else {
            print("❌ No export data available")
            saveAlertMessage = "No data to share. Please wait for export to complete."
            showingSaveAlert = true
            return
        }
        
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileExtension = exportFormat == .obj ? "txt" : "json"
        let fileName = "room_scan_\(Date().timeIntervalSince1970).\(fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try exportData.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Created temp \(fileExtension.uppercased()) file at: \(fileURL.path)")
            
            // Store URL and show share sheet
            shareFileURL = fileURL
            showingShareSheet = true
            
        } catch {
            print("❌ Error saving \(fileExtension.uppercased()) file: \(error)")
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
