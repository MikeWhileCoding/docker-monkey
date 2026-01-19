# Dockey Distribution Guide

## Building for Distribution

### 1. Archive the App

In Xcode:
1. Select **Product → Archive**
2. Wait for the archive to complete
3. In the Organizer window, select your archive

### 2. Export the App

Since this is for direct distribution (not App Store):

1. Click **Distribute App**
2. Select **Copy App** (or "Direct Distribution")
3. Choose a destination folder
4. You'll get `Dockey.app`

### 3. Create a DMG (Optional but Recommended)

```bash
# Create a DMG for easy distribution
hdiutil create -volname "Dockey" -srcfolder /path/to/Dockey.app -ov -format UDZO Dockey.dmg
```

Or use a tool like [create-dmg](https://github.com/create-dmg/create-dmg) for a prettier DMG:
```bash
brew install create-dmg
create-dmg --volname "Dockey" --app-drop-link 400 100 Dockey.dmg /path/to/Dockey.app
```

---

## Distribution Options

### Option A: Direct Share (Simplest)
1. Zip or DMG the app
2. Send via file sharing (Dropbox, Google Drive, AirDrop, etc.)
3. Recipient drags to `/Applications`

### Option B: GitHub Releases
1. Create a GitHub repo (if not already)
2. Tag releases: `git tag v1.0.0 && git push --tags`
3. Upload DMG to GitHub Releases
4. Share the releases URL

---

## Update Mechanism

### Simple: Manual Updates
1. Build new version in Xcode
2. Export and create new DMG
3. Send to users with instructions to replace old app

### Recommended: Sparkle Framework

[Sparkle](https://sparkle-project.org/) is the standard macOS update framework.

#### Setup Sparkle:

1. **Add Sparkle via SPM** in Xcode:
   - File → Add Package Dependencies
   - URL: `https://github.com/sparkle-project/Sparkle`

2. **Configure Info.plist**:
   ```xml
   <key>SUFeedURL</key>
   <string>https://your-server.com/appcast.xml</string>
   ```

3. **Add update check** in your app:
   ```swift
   import Sparkle

   // In DockeyApp.swift
   @StateObject private var updaterController = SPUStandardUpdaterController(
       startingUpdater: true,
       updaterDelegate: nil,
       userDriverDelegate: nil
   )
   ```

4. **Host an appcast.xml** on your server containing version info

#### Quick Alternative: GitHub + Sparkle

Use [Sparkle's GitHub integration](https://github.com/mxcl/AppUpdater) which uses GitHub Releases as the update source:

```swift
// Package.swift dependency
.package(url: "https://github.com/mxcl/AppUpdater", from: "1.0.0")
```

---

## Version Workflow

1. **Bump version** in Xcode (Target → General → Version)
2. **Build & Archive**: Product → Archive
3. **Export** the app
4. **Create DMG**: `hdiutil create ...`
5. **Upload** to GitHub Releases or your server
6. **Update appcast.xml** (if using Sparkle)
7. Users get notified automatically

---

## Quick Command Reference

```bash
# Build release from command line (alternative to Xcode)
xcodebuild -project DockeyApp/Dockey/Dockey.xcodeproj \
  -scheme Dockey \
  -configuration Release \
  -archivePath build/Dockey.xcarchive \
  archive

# Export from archive
xcodebuild -exportArchive \
  -archivePath build/Dockey.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist
```
