# Contributing to LiDAR Tools

First off, thank you for considering contributing to LiDAR Tools! It's people like you that make this app better for everyone.

## Code of Conduct

This project and everyone participating in it is governed by common sense and mutual respect. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** to demonstrate the steps
- **Describe the behavior you observed** after following the steps
- **Explain which behavior you expected to see instead and why**
- **Include screenshots or videos** if possible
- **Specify your device model** and iOS version
- **Note if the problem is related to LiDAR scanning**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description** of the suggested enhancement
- **Provide specific examples** to demonstrate the steps
- **Describe the current behavior** and **explain the behavior you'd like to see**
- **Explain why this enhancement would be useful**
- **List any alternative solutions** you've considered

### Pull Requests

- Fill in the required template
- Follow the Swift style guide (see below)
- Include screenshots and animated GIFs in your pull request when appropriate
- Document new code based on the Documentation Styleguide
- End all files with a newline
- Avoid platform-dependent code

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/lidar-tools.git
   cd lidar-tools
   ```

2. **Open in Xcode**
   ```bash
   open ChatPrototype.xcodeproj
   ```

3. **Select your development team** in project settings

4. **Build and run** on a LiDAR-enabled device

## Style Guide

### Swift Code Style

- Use Swift naming conventions (camelCase for variables/functions, PascalCase for types)
- Use meaningful variable and function names
- Keep functions focused and small (preferably under 50 lines)
- Add comments for complex logic
- Use `// MARK: -` to organize code sections
- Prefer Swift's type inference where it improves readability
- Use guard statements for early returns
- Prefer immutable values (`let`) over mutable ones (`var`)

### SwiftUI Best Practices

- Keep views small and composable
- Extract reusable components into separate structs
- Use `@State` for view-local state
- Use `@StateObject` for creating observable objects
- Use `@ObservedObject` for passing observable objects
- Use `@Binding` for two-way data flow
- Prefer SwiftUI native views over UIKit representatives when possible

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line
- Consider starting the commit message with an applicable emoji:
  - 🎨 `:art:` when improving the format/structure of the code
  - 🐎 `:racehorse:` when improving performance
  - 🐛 `:bug:` when fixing a bug
  - 🔥 `:fire:` when removing code or files
  - 📝 `:memo:` when writing docs
  - ✨ `:sparkles:` when adding a new feature
  - ♻️ `:recycle:` when refactoring code
  - ✅ `:white_check_mark:` when adding tests

### Example:
```
✨ Add USDZ export format support

- Implement Model I/O framework integration
- Add USDZ export option in ExportView
- Update README with new export format info

Closes #42
```

## Project Structure

```
lidar-tools/
├── ContentView.swift           # Main navigation hub
├── AppMode.swift              # App state enum
├── ScanningView.swift         # Scanning UI
├── RoomScanManager.swift      # Scan logic
├── DetectedObject.swift       # Object model
├── ChatPrototypeApp.swift     # App entry point
├── README.md                  # Project documentation
├── LICENSE                    # MIT License
└── CONTRIBUTING.md           # This file
```

## Testing

Before submitting a pull request:

1. Test on a real LiDAR-enabled device (Simulator won't work)
2. Test both measurement and scanning features
3. Test export functionality for both OBJ and JSON formats
4. Test on different iOS versions if possible
5. Verify UI works on different screen sizes

## Areas for Contribution

Here are some areas where contributions are especially welcome:

### High Priority
- USDZ export implementation
- Room dimension calculations
- Floor plan generation
- Improved object classification algorithms

### Medium Priority
- Unit tests for RoomScanManager
- UI tests for main workflows
- Performance optimizations
- Accessibility improvements

### Nice to Have
- Dark mode refinements
- iPad-specific UI improvements
- Localization support
- Cloud storage integration

## Questions?

Feel free to open an issue with the "question" label if you need help or clarification on anything!

## Recognition

Contributors will be recognized in the README.md file and in release notes.

Thank you for contributing! 🙏
