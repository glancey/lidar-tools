# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- USDZ export format support
- Room dimension measurements (length × width × height)
- Floor plan generation from scans
- Object labeling and custom annotations
- Multiple scan sessions with comparison
- Cloud storage integration
- Scan history management

## [1.0.0] - 2026-06-16

### Added
- 📏 Point-to-point measurement feature
  - Visual markers at measurement points
  - Real-time distance calculation
  - Support for meters, feet, and inches
  - Automatic measurement cleanup after 3 seconds
- 🏠 Room scanning feature
  - LiDAR mesh reconstruction
  - Automatic object detection
  - Wireframe visualization
  - Real-time scan progress tracking
  - Object classification (Tables, Chairs, Walls, etc.)
- 👁️ Object visibility controls
  - Toggle individual objects on/off
  - Color-coded object markers
  - Object list view with dimensions
- 💾 Export functionality
  - OBJ format export (as .txt for iOS compatibility)
  - JSON format export with structured data
  - Copy to clipboard
  - File browser for choosing save location
  - Share sheet integration (AirDrop, Messages, Mail)
- 🎨 Compact UI design
  - Minimal bottom toolbars
  - Maximum camera visibility
  - Icon-based controls
  - Status indicators
- ✅ LiDAR availability checking
  - Device compatibility detection
  - User-friendly error messages
- 📱 iOS native integrations
  - Document picker for file management
  - Share sheet for file distribution
  - Alert dialogs for user feedback

### Technical
- Built with SwiftUI and Swift Concurrency
- ARKit integration for LiDAR scanning
- RealityKit for 3D rendering
- UIKit bridging for native pickers and sheets
- Observable object pattern for state management

### Documentation
- Comprehensive README with features and usage
- MIT License
- Contributing guidelines
- GitHub setup guide
- Code comments and documentation

## Version History

### Version Numbering

This project uses Semantic Versioning:
- **MAJOR** version: Incompatible API changes
- **MINOR** version: New functionality (backward-compatible)
- **PATCH** version: Bug fixes (backward-compatible)

### Release Process

1. Update CHANGELOG.md with changes
2. Update version in Xcode project
3. Commit changes
4. Create Git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
5. Push tag: `git push origin v1.0.0`
6. Create GitHub release with release notes

---

## Legend

- ✨ New feature
- 🐛 Bug fix
- 🔄 Change/Update
- 🗑️ Deprecation
- 🔥 Removal
- 🔒 Security
- 📝 Documentation
- ⚡ Performance
- 🎨 UI/UX

[Unreleased]: https://github.com/yourusername/lidar-tools/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/lidar-tools/releases/tag/v1.0.0
