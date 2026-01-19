# 🐒 Docker Monkey (Dockey)

A macOS menu bar tool for managing local Docker-based projects. Designed for UI/UX designers and developers who want quick access to Docker commands without the terminal.

## 📦 Installation

### App Installation

1. Download the latest `Dockey.dmg` from releases
2. Open the DMG and drag `Dockey.app` to `/Applications`
3. Launch Dockey from Applications (or Spotlight)
4. The app will appear in your menu bar with a 🔨 icon

> **First Launch**: macOS may show a security warning. Go to **System Preferences → Privacy & Security** and click "Open Anyway".

### CLI Installation (Optional)

The CLI tool `dockey` is built separately from the Swift package. To install:

```bash
# Navigate to the project
cd /path/to/docker-monkey

# Build the CLI
swift build -c release

# Copy to /usr/local/bin
sudo cp .build/release/dockey /usr/local/bin/dockey
```

Or for development (symlink):
```bash
swift build
sudo ln -sf "$(pwd)/.build/debug/dockey" /usr/local/bin/dockey
```

Verify installation:
```bash
dockey --help
```

## 🚀 Usage

### Menu Bar App

- Click the menu bar icon to see all projects
- Run commands directly from the dropdown
- Access **Settings** to manage projects, containers, and commands
- Use the **Test** button in Settings to preview command output

### CLI Commands

```bash
# Projects
dockey project add "MyProject" --root /path/to/project
dockey project list
dockey project rm "MyProject"

# Containers
dockey project container add "MyProject" "mysql" --shell bash
dockey project container list "MyProject"

# Commands
dockey project command add "MyProject" "up" --script "docker compose up -d"
dockey project command add "MyProject" "down" --script "docker compose down"
dockey project command run "MyProject" "up"
```

## ✨ Features

- [x] Menu bar quick access to all projects
- [x] Run Docker commands with one click
- [x] Settings page for project/container/command management
- [x] Test commands with live console output
- [x] CLI tool for terminal users
- [ ] Project status indicators
- [ ] Quick navigation to project domains

## 🔄 Updates

When you receive a new version:
1. Download the new `Dockey.dmg`
2. Quit the running app (Menu Bar → Quit Dockey)
3. Replace the app in `/Applications`
4. Relaunch

## 📋 For Developers

See [DISTRIBUTION.md](DISTRIBUTION.md) for packaging and distribution instructions.

```bash
# Build CLI
swift build

# Run CLI during development
swift run dockey project list
```

