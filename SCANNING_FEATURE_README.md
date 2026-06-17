# Room Scanning Feature - Technical Implementation

## Overview

Real-time LiDAR room scanning with automatic wireframe object detection, smart filtering, and multi-format export. Features yellow wireframe visualization, on-demand export generation, and screen dimming prevention.

## Files Overview

### 1. **DetectedObject.swift**
- `BoundingBox` struct: 3D bounding boxes (center, size, rotation as simd_quatf)
- `DetectedObject` class: Observable object with properties:
  - `id: UUID` - Unique identifier
  - `boundingBox: BoundingBox` - 3D bounds
  - `label: String` - Object classification
  - `color: UIColor` - Visual identifier
  - `isVisible: Bool` - Wireframe visibility toggle
  - `volume: Float` - Calculated volume in cubic meters
  - `dimensionsString: String` - Formatted dimensions (e.g., "0.5m × 0.3m × 0.8m")
- UIColor extension for random bright colors (excludes dark colors)

### 2. **RoomScanManager.swift** (575 lines)
Main coordinator for scanning, object detection, and export

**Published Properties:**
- `detectedObjects: [DetectedObject]` - Array of detected objects
- `scanProgress: Float` - 0.0 to 1.0 progress indicator
- `isScanning: Bool` - Scanning state
- `meshAnchorsCount: Int` - Number of mesh anchors collected
- `statusMessage: String` - User-facing status text

**Size Thresholds (Configurable):**
```swift
minObjectVolume: 0.08 m³  // 80 liters minimum
minObjectDimension: 0.20 m  // 20cm minimum in any dimension
minAverageDimension: 0.35 m // 35cm average across dimensions  
maxObjectVolume: 3.0 m³    // 3 cubic meters maximum
```

**Key Methods:**
- `startScanning()`: Clears old data, sets scanning state
- `stopScanning()`: Ends scan, updates status
- `clearScan()`: Removes all objects and mesh data
- `processMeshAnchor(_ anchor: ARMeshAnchor)`: 
  - Stores mesh anchors in dictionary
  - Updates progress (target: 50 anchors = 100%)
  - Triggers `generateWireframesRealtime()` every 5 anchors
- `generateWireframes()`: Full wireframe generation with AI classification
- `generateWireframesRealtime()`: Fast generation during scanning (no classification)
- `exportScanData() -> String`: JSON export
- `exportAsOBJ() -> String?`: OBJ mesh export

**Object Detection Pipeline:**
1. `groupMeshesIntoObjects()` - Filters and groups mesh anchors
2. `createObjectFromMeshGroup()` - Calculates bounding boxes
3. Size filtering applied (volume + dimension checks)
4. Classification (geometry-based via ObjectClassifier)

### 3. **ObjectClassifier.swift** (474 lines)
AI-driven object classification system

**Classification Categories:**
```swift
enum ObjectCategory {
    case furniture      // Tables, chairs, desks
    case storage        // Shelves, cabinets, dressers
    case seating        // Sofas, chairs, stools
    case structure      // Walls, doors, floors
    case appliance      // Large appliances
    case decoration     // Art, plants, decorations
    case unknown        // Unclassified
}
```

**Classification Result:**
```swift
struct ClassificationResult {
    let label: String          // "Chair", "Table", etc.
    let category: ObjectCategory
    let confidence: Float      // 0.0 to 1.0
    let isMovable: Bool       // Furniture vs structure
}
```

**Methods:**
- `classifyWithVision(object:frame:)` - Geometry + vision classification
- Heuristic rules based on:
  - Dimensions (height, width, depth)
  - Aspect ratios
  - Volume
  - Position in room

### 4. **ScanningView.swift** (800+ lines)
Complete UI implementation with AR integration

**Main Components:**

#### ScanningView (SwiftUI)
- **Status Panel**: Shows progress, mesh count, object count
- **Control Buttons**:
  - 🟢 Play/Stop: Start/stop scanning
  - 🔵 Cube: Manual wireframe generation (debug)
  - 🟠 Export: Open export sheet
  - ⚪ Trash: Clear all data
  - 🔴 X: Return home
- **Lifecycle Hooks**:
  - `onAppear`: Disables screen dimming
  - `onDisappear`: Re-enables screen dimming
  - `onChange(isScanning)`: Manages dimming based on state
- **Sheet Presentations**:
  - ObjectListView
  - ExportView

#### ARScanningView (UIViewRepresentable)
Wraps ARKit ARView for SwiftUI integration

**Configuration:**
```swift
let config = ARWorldTrackingConfiguration()
config.sceneReconstruction = .mesh  // LiDAR mesh
config.planeDetection = [.horizontal, .vertical]
config.environmentTexturing = .automatic
```

**Coordinator (ARSessionDelegate):**
- Implements ARSessionDelegate methods:
  - `session(_:didAdd:)` - New mesh anchors
  - `session(_:didUpdate:)` - Updated mesh anchors
  - `session(_:didRemove:)` - Removed mesh anchors
  - `session(_:didUpdate:)` - Passes frames to scan manager
- **Wireframe Rendering**:
  - Observes `detectedObjects` publisher
  - Debounced updates (100ms) to prevent flooding
  - `isUpdatingWireframes` flag prevents concurrent updates
  - Creates `AnchorEntity` for each object
  - Calls `createWireframeBox(for:)` to build geometry

#### Wireframe Generation (`createWireframeBox`)
Creates actual 3D wireframes using RealityKit:

```swift
// 8 corners of bounding box
let corners: [SIMD3<Float>] = [ /* 8 corner positions */ ]

// 12 edges (4 bottom, 4 top, 4 vertical)
let edges: [(Int, Int)] = [ /* edge pairs */ ]

// For each edge:
// 1. Calculate midpoint and direction
// 2. Generate cylinder mesh
// 3. Apply UnlitMaterial (systemYellow)
// 4. Position and rotate to align with edge
// 5. Add to wireframe entity
```

**Key Features:**
- Thin cylinders (0.005 radius) for clean lines
- Consistent yellow color (UIColor.systemYellow)
- Proper rotation using quaternions
- All edges added to single Entity container

#### ObjectListView
Sheet view showing all detected objects:
- `ForEach` over `detectedObjects`
- Each row shows:
  - Color indicator (circle)
  - Label and dimensions
  - Visibility toggle
- Updates trigger wireframe refresh via publisher

#### ExportView
Sophisticated export UI with on-demand generation:

**States:**
- `isLoading`: Showing progress indicator
- `exportData.isEmpty`: Ready to generate
- `exportData`: Preview available

**UI Elements:**
- Format picker (JSON/OBJ)
- Info boxes explaining each format
- **Purple button**: "Generate Preview" (manual trigger)
- **Blue button**: Copy to clipboard
- **Green button**: Save file (auto-generates if needed)
- **Orange button**: Share (auto-generates if needed)

**Export Logic:**
```swift
private func updateExportData() {
    isLoading = true
    exportData = ""
    
    exportTask = Task { @MainActor in
        // Small delay for UI update
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let format = exportFormat
        
        // Background thread export
        let data = await Task.detached(priority: .userInitiated) {
            switch format {
            case .json: return scanManager.exportScanData()
            case .obj: return scanManager.exportAsOBJ() ?? "No data"
            }
        }.value
        
        guard !Task.isCancelled else {
            isLoading = false
            return
        }
        
        exportData = data
        isLoading = false
    }
}
```

**Smart Export Features:**
- `shareFile()`: Auto-generates if data empty, then shares
- `createTempOBJFile()`: Auto-generates synchronously for picker
- Task cancellation on view disappear
- Preview shows first 20 lines for OBJ (can be huge)
- Full preview for JSON (smaller)

## How It Works

### Real-Time Scanning Flow:
1. User taps "Room Scanner" → ScanningView loads
2. User taps "Play" → `startScanning()` called
3. ARKit begins collecting mesh anchors
4. **Every 5 mesh anchors**: `generateWireframesRealtime()` called automatically
5. Wireframes appear immediately (no classification during scan)
6. User continues scanning → wireframes update live
7. User taps "Stop" → scanning ends
8. Optional: Tap "Cube" → `generateWireframes()` with full AI classification

### Wireframe Update Pipeline:
```
processMeshAnchor() 
  ↓ (every 5 anchors)
generateWireframesRealtime()
  ↓
detectedObjects array updated
  ↓ (Combine publisher)
100ms debounce
  ↓
updateWireframes() in Coordinator
  ↓
createWireframeBox() for each object
  ↓
RealityKit renders yellow wireframes in AR
```

### Object Detection Algorithm:
```swift
1. Filter mesh anchors:
   - Exclude large surfaces (> 2m)
   - Check minimum size (> 5cm)
   - Check average size (≥ 35cm)

2. Create bounding box:
   - Calculate min/max from vertices
   - Transform to world space
   - Compute center and size

3. Apply size filters:
   - Min dimension ≥ 20cm
   - Average dimension ≥ 35cm
   - Volume: 80L to 3000L

4. Classify (if not real-time):
   - Analyze geometry
   - Apply heuristic rules
   - Assign label and category
```

### Export Generation:
- **On-Demand**: Only when user clicks button
- **Background Thread**: Uses `Task.detached`
- **Cancellable**: Task cancelled if view disappears
- **Progress UI**: Shows loading indicator
- **Auto-Generate**: Save/Share buttons generate if needed

## Performance Optimizations

### Debouncing & Throttling:
- **Wireframe updates**: 100ms debounce prevents flooding
- **Real-time generation**: Every 5 anchors (not every 1)
- **Concurrent prevention**: `isUpdatingWireframes` flag
- **Background export**: Off main thread

### Memory Management:
- Weak ARView reference in Coordinator
- Cancellable set for Combine subscriptions
- Dictionary-based anchor storage (O(1) lookup)
- Clear old wireframes before creating new ones

### UI Responsiveness:
- Export on background thread
- Small sleep before export (UI update time)
- Task cancellation on view disappear
- Loading states with progress indicators

## Usage Instructions

### Scanning Workflow:
1. **Launch**: Tap "Room Scanner"
2. **Start**: Tap green Play button
3. **Scan**: Move slowly around room (0.5 m/s)
4. **Watch counters**: M: (meshes), Obj: (objects)
5. **Wireframes appear automatically** as you scan
6. **Stop**: Tap red Stop button when done
7. **Optional**: Tap blue Cube for full classification

### Managing Objects:
- Objects appear automatically during scan
- No manual "Generate" step required (unless you want classification)
- Toggle visibility in Object List view
- Wireframes are yellow for consistency

### Exporting:
**Quick Method** (No Preview):
1. Open export sheet
2. Tap "Save File" or "Share File"
3. Data generates automatically
4. Choose destination

**Preview Method**:
1. Open export sheet
2. Tap "Generate Preview" (purple)
3. Review data/size
4. Then Save, Share, or Copy

## Size Filtering Explained

### Why Filter?
- Focuses on furniture, not clutter
- Improves performance
- Cleaner visualization
- Faster export

### What Gets Excluded:
- ❌ Books, mugs, phones
- ❌ Keyboards, mice, remotes
- ❌ Small decorations
- ❌ Picture frames < 30cm
- ❌ Objects with any dimension < 20cm
- ❌ Objects averaging < 35cm

### What Gets Included:
- ✅ Chairs (typically 40-60cm)
- ✅ Tables (60cm+)
- ✅ Sofas, beds
- ✅ Cabinets, dressers
- ✅ Desks, shelving units
- ✅ Large appliances

### Adjusting Thresholds:
Edit `RoomScanManager.swift`:
```swift
private let minObjectVolume: Float = 0.08     // 80 liters
private let minObjectDimension: Float = 0.20  // 20cm
private let minAverageDimension: Float = 0.35 // 35cm
```

## Known Issues & Solutions

### Issue: Export Freezing
**Solution**: Export now runs on background thread with proper task cancellation. Preview generation is optional.

### Issue: Wireframes Not Appearing
**Solution**: Real-time generation every 5 anchors. Check console for "Created wireframes" messages. Use debug button (cube) to force regeneration.

### Issue: Too Many/Few Objects
**Solution**: Adjust size thresholds in `RoomScanManager.swift`. Current defaults exclude objects < 20cm or averaging < 35cm.

### Issue: Screen Dimming During Scan
**Solution**: Auto-disabled when ScanningView appears or when `isScanning == true`. Re-enabled when leaving view.

## Future Enhancements

### Planned (High Priority):
- [ ] Oriented Bounding Boxes (OBB) for tighter fit
- [ ] Mesh clustering (combine related mesh anchors)
- [ ] Tap to select individual objects in AR
- [ ] Floating AR labels above objects
- [ ] Scan session persistence

### Planned (Medium Priority):
- [ ] Room dimensions display (L × W × H)
- [ ] 2D floor plan view
- [ ] USDZ export (Apple's 3D format)
- [ ] Object annotations and notes
- [ ] Multi-room scanning

### Planned (Low Priority):
- [ ] ML-based object recognition (CoreML)
- [ ] Object tracking during scan
- [ ] Screenshot with annotations
- [ ] Cloud sync for scans
- [ ] Scan comparison mode

## Testing Checklist

### Basic Functionality:
- [ ] Start/stop scanning works
- [ ] Mesh anchors increment
- [ ] Objects appear automatically
- [ ] Wireframes are yellow
- [ ] Screen doesn't dim during scan
- [ ] Progress bar updates
- [ ] Stop button works

### Object Management:
- [ ] Object list shows all objects
- [ ] Visibility toggle works
- [ ] Wireframes update when toggled
- [ ] Clear button removes all data
- [ ] Colored circles match wireframes

### Export:
- [ ] Export sheet opens without freeze
- [ ] Format picker switches JSON/OBJ
- [ ] Generate Preview button works
- [ ] Loading indicator shows
- [ ] Preview displays correctly
- [ ] Copy to clipboard works
- [ ] Save File auto-generates data
- [ ] Share File auto-generates data
- [ ] File picker opens
- [ ] Share sheet opens

### Performance:
- [ ] 50+ mesh anchors handled smoothly
- [ ] Wireframe updates don't lag
- [ ] Export completes without freeze
- [ ] UI responsive during export
- [ ] Task cancels on view dismiss

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   ContentView                       │
│                  (AppMode enum)                     │
└───────────────────┬─────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼─────────┐    ┌───────▼──────────┐
│ MeasurementMode │    │  ScanningView    │
│      View       │    │   (Sheet host)   │
└─────────────────┘    └───────┬──────────┘
                               │
                    ┌──────────┼──────────┐
                    │          │          │
            ┌───────▼───┐  ┌──▼──────┐ ┌─▼────────┐
            │  ARScanning│  │ Object  │ │  Export  │
            │    View    │  │ListView │ │   View   │
            └────┬───────┘  └─────────┘ └────┬─────┘
                 │                            │
         ┌───────▼────────┐          ┌───────▼──────┐
         │   Coordinator  │          │ Background   │
         │ (ARSessionDel) │          │ Export Task  │
         └───┬────────────┘          └──────────────┘
             │
     ┌───────▼────────────┐
     │ RoomScanManager    │
     │ (ObservableObject) │
     └───┬────────────┬───┘
         │            │
    ┌────▼─────┐  ┌──▼───────────┐
    │ Detected │  │   Object     │
    │  Object  │  │  Classifier  │
    └──────────┘  └──────────────┘
```

## Build & Deploy

### Requirements:
- Xcode 15.0+
- iOS 17.0+ deployment target
- iPhone with LiDAR (12 Pro or later)
- Camera privacy permissions in Info.plist

### Build Steps:
1. Open project in Xcode
2. Select target device (with LiDAR)
3. Clean build folder (⌘+Shift+K)
4. Build (⌘+B)
5. Run (⌘+R)

### Console Logging:
Enable to see detailed output:
- `🔍` Scan start/stop
- `📊` Mesh anchor processing
- `🔄` Wireframe generation
- `✅` Successful operations
- `⚠️` Warnings
- `❌` Errors

---

**Created**: June 16, 2026  
**Last Updated**: June 17, 2026  
**Version**: 1.1  
**Status**: Production Ready
