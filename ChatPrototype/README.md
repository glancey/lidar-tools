# LiDAR Tools

A powerful iOS app that leverages the iPhone's LiDAR scanner for point-to-point measurements and room scanning with real-time wireframe object detection.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

### 📏 Point-to-Point Measurement
- Measure distances between any two points in real space
- Real-time visual feedback with red markers and yellow connecting lines
- Multiple unit support: meters, feet, and inches
- Automatic measurement cleanup after 3 seconds

### 🏠 Room Scanner
- **Real-time Scanning**: Automatic object detection as you scan (updates every 5 mesh anchors)
- **Yellow Wireframe Visualization**: Clean, consistent wireframes around all detected objects
- **Smart Size Filtering**: Excludes small clutter (< 20cm or < 80 liters) to focus on furniture
- **Live Progress Tracking**: See mesh anchor count and object count in real-time
- **Manual Controls**: Generate wireframes on-demand with debug button
- **Screen Dimming Prevention**: Screen stays on during active scanning

### 💾 Export Capabilities
- **OBJ Format**: Export 3D mesh data (saved as .txt for iOS compatibility)
  - Compatible with SketchUp, Blender, AutoCAD, 3ds Max, Maya, and more
  - Simply rename .txt to .obj on your computer
  - Preview first 20 lines before exporting
- **JSON Format**: Structured data with positions, dimensions, and classifications
  - Lightweight format for custom processing
- **Flexible Export Workflow**:
  - Generate preview on-demand (purple button)
  - Or skip preview and export directly
  - Copy to clipboard
  - Save to Files app (choose any location)
  - Share via AirDrop, Messages, Mail, etc.
- **Background Processing**: Export generation runs on background thread, UI stays responsive

## Requirements

- **Device**: iPhone 12 Pro or later, iPad Pro (2020 or later)
- **LiDAR Scanner**: Required for all features
- **iOS**: 17.0 or later
- **Xcode**: 15.0 or later (for development)

## Supported Devices

The following devices have LiDAR scanners and are fully supported:

### iPhone
- iPhone 12 Pro / 12 Pro Max
- iPhone 13 Pro / 13 Pro Max
- iPhone 14 Pro / 14 Pro Max
- iPhone 15 Pro / 15 Pro Max
- iPhone 16 Pro / 16 Pro Max (tested)

### iPad
- iPad Pro 11-inch (2nd generation or later)
- iPad Pro 12.9-inch (4th generation or later)

## Installation

### From Source

1. Clone this repository:
```bash
git clone https://github.com/yourusername/lidar-tools.git
cd lidar-tools
```

2. Open the project in Xcode:
```bash
open ChatPrototype.xcodeproj
```

3. Select your development team in the project settings

4. Build and run on a LiDAR-enabled device

## Usage

### Point-to-Point Measurement

1. Launch the app and tap **"Point-to-Point Measurement"**
2. Point your device at the first location and tap on the screen
3. Move to the second location and tap again
4. The distance will be displayed in meters, feet, and inches
5. Measurements automatically clear after 3 seconds

### Room Scanning

#### Basic Workflow:
1. Tap **"Room Scanner"** from the home screen
2. Tap the **Play button** (green) to start scanning
3. Slowly move around the room, pointing your device at surfaces
4. Watch the **mesh anchor count** (M:) and **object count** (Obj:) increase
5. **Wireframes appear automatically** every 5 mesh anchors
6. Tap the **Stop button** (red) when finished
7. Optionally tap the **Cube button** (blue) to manually regenerate wireframes
8. Tap the **Export button** (orange) to save your scan data

#### Controls:
- **🟢 Play**: Start scanning
- **🔴 Stop**: Stop scanning
- **🔵 Cube**: Force wireframe regeneration (debug)
- **🟠 Export**: Open export options
- **⚪ Trash**: Clear all scan data
- **🔴 X**: Return to home

### Exporting Data

1. After scanning, tap the **Export button** (up arrow)
2. Choose format: **OBJ** or **JSON**
3. Three workflow options:

   **Option A - Preview First:**
   - Tap **"Generate Preview"** (purple button)
   - Wait for generation (with progress indicator)
   - Review preview data
   - Then use Save, Share, or Copy

   **Option B - Direct Export:**
   - Tap **"Save File"** (green) - generates data automatically
   - OR tap **"Share File"** (orange) - generates data automatically
   - Choose destination

   **Option C - Quick Copy:**
   - Generate preview first
   - Tap **"Copy to Clipboard"** (blue)

## Project Structure

```
lidar-tools/
├── ContentView.swift           # Main app view with navigation
├── AppMode.swift              # App state enumeration  
├── ScanningView.swift         # Room scanning UI (800+ lines)
├── RoomScanManager.swift      # Scan logic and object detection
├── ObjectClassifier.swift     # AI-driven object classification
├── DetectedObject.swift       # Object model and bounding box
└── ChatPrototypeApp.swift     # App entry point
```

## Architecture

### Core Components

- **ContentView**: Main navigation hub with mode switching
- **MeasurementModeView**: Point-to-point measurement UI
- **ARMeasurementView**: ARKit integration for measurements
- **ScanningView**: Room scanning interface with real-time controls
- **ARScanningView**: UIViewRepresentable for ARKit mesh reconstruction
- **Coordinator**: ARSessionDelegate handling mesh processing
- **RoomScanManager**: Object detection, classification, and export logic
- **ObjectClassifier**: Geometry-based object classification
- **DetectedObject**: 3D object representation with bounding boxes
- **ExportView**: Multi-format export with on-demand generation
- **DocumentPicker**: Native iOS file picker integration
- **ShareSheet**: iOS share sheet integration

### Technologies Used

- **SwiftUI**: Modern declarative UI framework
- **ARKit**: Augmented reality and LiDAR mesh reconstruction
- **RealityKit**: 3D rendering with ModelEntity and UnlitMaterial
- **Combine**: Reactive state management with publishers and debouncing
- **Swift Concurrency**: Async/await for background export tasks
- **UIKit Integration**: File pickers and share sheets
- **SIMD**: 3D vector math for bounding boxes

## Tips for Best Results

### Scanning:
- 🚶 **Move slowly**: 0.5 m/s or slower
- 💡 **Good lighting**: Better mesh quality
- 📏 **Optimal range**: 0.5m to 5m from surfaces
- 🔄 **Multiple angles**: Scan from different viewpoints
- 🎯 **Direct pointing**: Aim perpendicular to surfaces
- ⏱️ **Screen dimming**: Automatically disabled during scanning
- 📊 **Watch counters**: M: (meshes), Obj: (objects detected)

### Object Detection:
- Detects objects ≥ 20cm in any dimension
- Filters by average size ≥ 35cm
- Minimum volume: 80 liters
- Maximum volume: 3 cubic meters

### Export:
- **JSON**: Fast, small files (<100 KB typically)
- **OBJ**: Large files (can be several MB), takes longer
- Use "Generate Preview" for large scans to see size first
- Or skip preview and export directly for quick sharing

## Known Limitations

- LiDAR range limited to ~5 meters
- Reflective/transparent surfaces may not scan well
- Small objects under 20cm are filtered out intentionally
- Object classification is geometry-based (not ML)
- Very large scans (100+ mesh anchors) may take time to export
- Scan data not persisted between sessions

## Performance Optimizations

- **Debounced updates**: Wireframe updates throttled to 100ms
- **Background export**: OBJ/JSON generation on background thread
- **Concurrent update prevention**: Only one wireframe update at a time
- **Real-time filtering**: Objects filtered during scan, not after
- **On-demand export**: Data only generated when needed

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Future Enhancements

- [ ] USDZ export format (native iOS 3D format)
- [ ] Room dimension measurements (length × width × height)
- [ ] Floor plan generation
- [ ] Object labeling and annotations
- [ ] Scan session persistence
- [ ] AR labels floating above objects
- [ ] Cloud storage integration
- [ ] Scan history and management
- [ ] ML-based object recognition
- [ ] Oriented bounding boxes (OBB) for tighter fit

## Changelog

### Version 1.1 (June 17, 2026)
- Added real-time wireframe generation during scanning
- Implemented yellow wireframe visualization
- Added smart size filtering to exclude clutter
- Screen dimming prevention during active scanning
- On-demand export generation (no auto-load freeze)
- Background task processing for exports
- Improved UI with live counters
- Debug wireframe generation button

### Version 1.0 (June 16, 2026)
- Initial release
- Point-to-point measurements
- Room scanning with mesh reconstruction
- Basic object detection
- JSON export

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with ARKit and RealityKit from Apple
- Inspired by the amazing capabilities of LiDAR technology
- Thanks to the SwiftUI community for best practices

## Contact

For questions, issues, or suggestions, please open an issue on GitHub.

---

**Note**: This app requires a physical device with a LiDAR scanner. The iOS Simulator does not support LiDAR scanning functionality.

**Last Updated**: June 17, 2026
