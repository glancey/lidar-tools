# GitHub Repository Setup Guide

This guide will help you set up a GitHub repository for the LiDAR Tools app.

## Prerequisites

- Git installed on your computer
- GitHub account created
- Xcode project ready

## Step 1: Create GitHub Repository

### Option A: Via GitHub Website

1. Go to [github.com](https://github.com) and sign in
2. Click the **"+"** icon in the top right corner
3. Select **"New repository"**
4. Fill in the details:
   - **Repository name**: `lidar-tools` (or your preferred name)
   - **Description**: "iOS app for LiDAR measurements and room scanning"
   - **Visibility**: Choose Public or Private
   - **Do NOT initialize** with README, .gitignore, or license (we already have these)
5. Click **"Create repository"**

### Option B: Via GitHub CLI

```bash
gh repo create lidar-tools --public --description "iOS app for LiDAR measurements and room scanning"
```

## Step 2: Initialize Git in Your Project

Open Terminal and navigate to your Xcode project directory:

```bash
cd /path/to/your/ChatPrototype
```

Initialize Git:

```bash
git init
```

## Step 3: Add Files to Git

Check which files will be added:

```bash
git status
```

Add all files:

```bash
git add .
```

## Step 4: Create Initial Commit

```bash
git commit -m "🎉 Initial commit - LiDAR Tools app

Features:
- Point-to-point measurement with LiDAR
- Room scanning with wireframe object detection
- OBJ and JSON export capabilities
- File browser and share sheet integration"
```

## Step 5: Connect to GitHub

Replace `YOUR_USERNAME` with your GitHub username:

```bash
git remote add origin https://github.com/YOUR_USERNAME/lidar-tools.git
```

Verify the remote was added:

```bash
git remote -v
```

## Step 6: Push to GitHub

For the first push, set the upstream branch:

```bash
git branch -M main
git push -u origin main
```

For subsequent pushes:

```bash
git push
```

## Step 7: Verify on GitHub

1. Go to your repository on GitHub
2. You should see all your files
3. README.md should display on the repository homepage

## Step 8: Add Topics/Tags (Optional)

On your GitHub repository page:

1. Click **"About"** (gear icon)
2. Add topics:
   - `swift`
   - `ios`
   - `lidar`
   - `arkit`
   - `realitykit`
   - `swiftui`
   - `3d-scanning`
   - `augmented-reality`
   - `room-scanning`

## Step 9: Set Up Branch Protection (Optional)

For collaborative projects:

1. Go to **Settings** → **Branches**
2. Click **"Add rule"**
3. Set branch name pattern: `main`
4. Enable:
   - ☑️ Require pull request reviews before merging
   - ☑️ Require status checks to pass before merging
5. Save changes

## Step 10: Create First Release (Optional)

When ready for your first release:

1. Go to **Releases** tab
2. Click **"Create a new release"**
3. Create a new tag: `v1.0.0`
4. Release title: `LiDAR Tools v1.0.0`
5. Add release notes
6. Click **"Publish release"**

## Common Git Commands

### Daily Workflow

```bash
# Check status
git status

# Add specific file
git add ContentView.swift

# Add all changes
git add .

# Commit changes
git commit -m "✨ Add new feature"

# Push to GitHub
git push

# Pull latest changes
git pull
```

### Branching

```bash
# Create new branch
git checkout -b feature/new-feature

# Switch to existing branch
git checkout main

# List all branches
git branch -a

# Delete local branch
git branch -d feature/old-feature
```

### Undoing Changes

```bash
# Discard changes in file
git checkout -- ContentView.swift

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

## Important Files Created

- ✅ **README.md** - Project documentation
- ✅ **.gitignore** - Files to exclude from Git
- ✅ **LICENSE** - MIT License
- ✅ **CONTRIBUTING.md** - Contribution guidelines

## Recommended GitHub Settings

### Repository Settings

1. **General**
   - ☑️ Allow squash merging
   - ☑️ Automatically delete head branches

2. **Options**
   - ☑️ Issues
   - ☑️ Projects
   - ☑️ Wiki (if you want documentation)

3. **Security**
   - Enable Dependabot alerts
   - Enable security advisories

## Next Steps

1. **Add Screenshots**: Create a `Screenshots` folder with app images
2. **Add Demo Video**: Record a demo and link it in README
3. **Create Issues**: Add issues for planned features
4. **Set up Projects**: Use GitHub Projects for task management
5. **Enable Discussions**: For community Q&A

## Troubleshooting

### Push Rejected

If push is rejected due to upstream changes:

```bash
git pull --rebase origin main
git push
```

### Authentication Issues

For HTTPS:
```bash
# Use personal access token instead of password
# Generate at: https://github.com/settings/tokens
```

For SSH:
```bash
# Set up SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add to GitHub: https://github.com/settings/keys

# Update remote to use SSH
git remote set-url origin git@github.com:YOUR_USERNAME/lidar-tools.git
```

### Large Files

If you accidentally added large files:

```bash
# Remove from Git but keep locally
git rm --cached large-file.zip

# Add to .gitignore
echo "*.zip" >> .gitignore

# Commit changes
git commit -m "Remove large file from tracking"
```

## Additional Resources

- [GitHub Guides](https://guides.github.com/)
- [Git Documentation](https://git-scm.com/doc)
- [GitHub CLI](https://cli.github.com/)
- [Pro Git Book](https://git-scm.com/book/en/v2)

## Support

If you run into issues:

1. Check [GitHub's documentation](https://docs.github.com/)
2. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/git)
3. Open an issue in your repository

---

**Your repository is now set up! 🎉**

Share the link with others: `https://github.com/YOUR_USERNAME/lidar-tools`
