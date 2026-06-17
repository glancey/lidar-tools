# LiDAR Tools

A powerful iOS app that leverages the iPhone's LiDAR scanner for point-to-point measurements and room scanning with wireframe object detection.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-14.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

### 📏 Point-to-Point Measurement
- Measure distances between any two points in real space
- Real-time visual feedback with red markers and yellow connecting lines
- Multiple unit support: meters, feet, and inches
- Automatic measurement cleanup after 3 seconds

### 🏠 Room Scanner
- Full room scanning using LiDAR mesh reconstruction
- Automatic object detection with wireframe visualization
- Smart object classification (Tables, Chairs, Walls, Doors, etc.)
- Real-time scan progress tracking
- Toggle object visibility individually

### 💾 Export Capabilities
- **OBJ Format**: Export 3D mesh data (saved as .txt for iOS compatibility)
  - Compatible with SketchUp, Blender, AutoCAD, 3ds Max, Maya, and more
  - Simply rename .txt to .obj on your computer
- **JSON Format**: Structured data with positions, dimensions, and classifications
- **Multiple Export Options**:
  - Copy to clipboard
  - Save to Files app (choose any location)
  - Share via AirDrop, Messages, Mail, etc.

## Requirements

- **Device**: iPhone 12 Pro or later, iPad Pro (2020 or later)
- **LiDAR Scanner**: Required for all features
- **iOS**: 15.0 or later
- **Xcode**: 14.0 or later (for development)

## Supported Devices

The following devices have LiDAR scanners and are fully supported:

### iPhone
- iPhone 12 Pro
- iPhone 12 Pro Max
- iPhone 13 Pro
- iPhone 13 Pro Max
- iPhone 14 Pro
- iPhone 14 Pro Max
- iPhone 15 Pro
- iPhone 15 Pro Max

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

1. Tap **"Room Scanner"** from the home screen
2. Tap the **Play button** to start scanning
3. Slowly move around the room, pointing your device at surfaces
4. Watch the mesh anchor count increase as surfaces are detected
5. Tap the **Stop button** when finished
6. Tap the **Cube button** to generate wireframe objects
7. Use the **List button** to view and toggle object visibility
8. Use the **Export button** to save your scan data

### Exporting Data

1. After generating objects, tap the **Export button** (up arrow)
2. Choose format: **OBJ** or **JSON**
3. Select an action:
   - **Copy to Clipboard**: Quick copy for small files
   - **Save File**: Browse and choose exact save location
   - **Share File**: AirDrop, Messages, Mail, or other apps

## Project Structure

```
lidar-tools/
├── ContentView.swift           # Main app view with navigation
├── AppMode.swift              # App state enumeration
├── ScanningView.swift         # Room scanning interface
├── RoomScanManager.swift      # Scan logic and object detection
├── DetectedObject.swift       # Object model and bounding box
└── ChatPrototypeApp.swift     # App entry point
```

## Architecture

### Core Components

- **ContentView**: Main navigation hub with mode switching
- **MeasurementModeView**: Point-to-point measurement UI
- **ARMeasurementView**: ARKit integration for measurements
- **ScanningView**: Room scanning interface with controls
- **ARScanningView**: ARKit mesh reconstruction
- **RoomScanManager**: Object detection and classification logic
- **DetectedObject**: 3D object representation with bounding boxes
- **ExportView**: Multi-format export with file browser
- **DocumentPicker**: Native file picker integration
- **ShareSheet**: iOS share sheet integration

### Technologies Used

- **SwiftUI**: Modern declarative UI framework
- **ARKit**: Augmented reality and LiDAR integration
- **RealityKit**: 3D rendering and entity management
- **Combine**: Reactive state management
- **UIKit Integration**: File pickers and share sheets

## Tips for Best Results

- 🚶 Move your device slowly during scanning
- 💡 Good lighting improves accuracy
- 📏 Works best from 0.5m to 5m distance
- 🔄 Scan from multiple angles for complete coverage
- 🎯 Point directly at surfaces for better mesh capture

## Known Limitations

- LiDAR range is limited to approximately 5 meters
- Very reflective or transparent surfaces may not scan well
- Small objects under 5cm may not be detected
- Object classification is heuristic-based and may not be 100% accurate

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
- [ ] Multiple scan sessions with comparison
- [ ] AR preview of detected objects
- [ ] Cloud storage integration
- [ ] Scan history and management

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
