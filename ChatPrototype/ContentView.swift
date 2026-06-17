//
//  ContentView_NEW.swift
//  ChatPrototype
//
//  Created by Glenn Silverman on 6/16/26.
//
//  INSTRUCTIONS: Replace your ContentView.swift with this code
//

import SwiftUI
import ARKit
import RealityKit
import UIKit

struct ContentView: View {
    @State private var appMode: AppMode = .home
    @State private var lastMeasurement: String = "Tap two points to measure"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @StateObject private var scanManager = RoomScanManager()
    
    var body: some View {
        Group {
            switch appMode {
            case .home:
                HomeView(appMode: $appMode)
            case .measurement:
                MeasurementModeView(appMode: $appMode, lastMeasurement: $lastMeasurement)
            case .scanning:
                ScanningView(scanManager: scanManager, appMode: $appMode)
            }
        }
        .alert("LiDAR Unavailable", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @Binding var appMode: AppMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "cube.transparent")
                    .imageScale(.large)
                    .font(.system(size: 50))
                    .foregroundStyle(.tint)
                    .padding(.top, 20)
                
                Text("LiDAR Tools")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Use your iPhone's LiDAR scanner for measurements and room scanning")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Measurement Mode Button
                    Button(action: {
                        if checkLiDARAvailability() {
                            appMode = .measurement
                        } else {
                            alertMessage = "LiDAR is not available on this device. This feature requires an iPhone or iPad with a LiDAR scanner (iPhone 12 Pro or later, iPad Pro 2020 or later)."
                            showingAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "ruler")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Point-to-Point Measurement")
                                    .font(.headline)
                                Text("Measure distances between two points")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    // Room Scanning Button
                    Button(action: {
                        if checkLiDARAvailability() {
                            appMode = .scanning
                        } else {
                            alertMessage = "LiDAR is not available on this device. This feature requires an iPhone or iPad with a LiDAR scanner (iPhone 12 Pro or later, iPad Pro 2020 or later)."
                            showingAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "cube.transparent")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Room Scanner")
                                    .font(.headline)
                                Text("Scan room and detect objects with wireframes")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips:")
                        .font(.headline)
                    Text("• Move your device slowly for best results")
                        .font(.footnote)
                    Text("• Good lighting improves accuracy")
                        .font(.footnote)
                    Text("• Works best from 0.5m to 5m distance")
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .alert("LiDAR Unavailable", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    func checkLiDARAvailability() -> Bool {
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
}

// MARK: - Measurement Mode View
struct MeasurementModeView: View {
    @Binding var appMode: AppMode
    @Binding var lastMeasurement: String
    
    var body: some View {
        ZStack {
            ARMeasurementView(measurement: $lastMeasurement)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Bottom compact panel
                HStack(spacing: 12) {
                    Text(lastMeasurement)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Button(action: {
                        appMode = .home
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .imageScale(.medium)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - AR Measurement View
struct ARMeasurementView: UIViewRepresentable {
    @Binding var measurement: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Set delegate to monitor session
        arView.session.delegate = context.coordinator
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        
        // Enable scene reconstruction with LiDAR
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            print("✅ LiDAR scene reconstruction enabled")
        } else {
            print("⚠️ LiDAR not available on this device")
        }
        
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        print("🎬 Starting AR session...")
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // Add tap gesture for measurements
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Binding is already set in coordinator init, no need to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(measurement: $measurement)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var measurementPoints: [SIMD3<Float>] = []
        var sphereEntities: [AnchorEntity] = []
        var lineEntities: [AnchorEntity] = []
        var measurementBinding: Binding<String>
        
        init(measurement: Binding<String>) {
            self.measurementBinding = measurement
        }
        
        // ARSessionDelegate methods
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
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ AR session was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("✅ AR session interruption ended")
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else {
                print("❌ ARView is nil")
                return
            }
            
            let location = gesture.location(in: arView)
            print("👆 Tap detected at: \(location)")
            
            // Perform raycast to find real-world position
            let results = arView.raycast(from: location,
                                        allowing: .estimatedPlane,
                                        alignment: .any)
            
            print("🎯 Raycast results: \(results.count)")
            
            if let result = results.first {
                let position = result.worldTransform.columns.3
                let point = SIMD3<Float>(position.x, position.y, position.z)
                
                measurementPoints.append(point)
                
                // Add visual marker
                addSphere(at: point, in: arView)
                
                // Calculate distance if we have 2 points
                if measurementPoints.count == 2 {
                    let distance = calculateDistance()
                    let distanceInMeters = String(format: "%.2f", distance)
                    let distanceInFeet = String(format: "%.2f", distance * 3.28084)
                    let distanceInInches = String(format: "%.1f", distance * 39.3701)
                    
                    measurementBinding.wrappedValue = "\(distanceInMeters)m | \(distanceInFeet)ft | \(distanceInInches)in"
                    
                    // Draw line between points
                    drawLine(from: measurementPoints[0],
                            to: measurementPoints[1],
                            distance: distance,
                            in: arView)
                    
                    // Reset for next measurement
                    clearPreviousMeasurement()
                } else {
                    measurementBinding.wrappedValue = "Tap second point to complete measurement"
                }
            }
        }
        
        func addSphere(at position: SIMD3<Float>, in arView: ARView) {
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01),
                                    materials: [SimpleMaterial(color: .red, isMetallic: false)])
            
            let anchor = AnchorEntity(world: position)
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
            
            sphereEntities.append(anchor)
        }
        
        func calculateDistance() -> Float {
            guard measurementPoints.count == 2 else { return 0 }
            let vector = measurementPoints[1] - measurementPoints[0]
            return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        }
        
        func drawLine(from start: SIMD3<Float>, to end: SIMD3<Float>, distance: Float, in arView: ARView) {
            let midpoint = (start + end) / 2
            
            // Create cylinder as line
            let cylinder = ModelEntity(mesh: .generateBox(width: 0.005,
                                                         height: distance,
                                                         depth: 0.005),
                                      materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
            
            // Calculate rotation to align cylinder with measurement
            let direction = normalize(end - start)
            let up = SIMD3<Float>(0, 1, 0)
            
            var transform = Transform()
            transform.translation = midpoint
            
            // Rotate cylinder to point from start to end
            let angle = acos(dot(up, direction))
            let axis = normalize(cross(up, direction))
            if axis.x.isFinite && axis.y.isFinite && axis.z.isFinite {
                transform.rotation = simd_quatf(angle: angle, axis: axis)
            }
            
            cylinder.transform = transform
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(cylinder)
            arView.scene.addAnchor(anchor)
            
            lineEntities.append(anchor)
        }
        
        func clearPreviousMeasurement() {
            // Remove old spheres and lines after a delay to show the result
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self, let arView = self.arView else { return }
                
                for anchor in self.sphereEntities {
                    arView.scene.removeAnchor(anchor)
                }
                for anchor in self.lineEntities {
                    arView.scene.removeAnchor(anchor)
                }
                
                self.sphereEntities.removeAll()
                self.lineEntities.removeAll()
                self.measurementPoints.removeAll()
                self.measurementBinding.wrappedValue = "Tap two points to measure"
            }
        }
    }
}

#Preview {
    ContentView()
}
