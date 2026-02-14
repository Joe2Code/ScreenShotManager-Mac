# ScreenShot Manager for Mac

A lightweight macOS menu bar app that automatically captures, organizes, and OCRs your screenshots.

## Features

- **Menu Bar App** -- lives in your menu bar, no dock icon clutter
- **Auto-Detection** -- watches `~/Desktop` for new screenshots via FSEvents
- **On-Device OCR** -- extracts text from every screenshot using Apple Vision framework
- **Smart Folders** -- auto-categorizes screenshots (Recipes, Prices, Addresses, URLs, Phone Numbers)
- **Tags** -- create custom color-coded tags to organize screenshots
- **Search** -- find any screenshot by its OCR text content
- **Copy Image** -- right-click to copy a screenshot, then paste into Messages, Telegram, etc.
- **Copy OCR Text** -- one-click copy of extracted text
- **Drag & Drop** -- drag screenshots out to other apps, or drop images in to import
- **Clipboard Monitor** -- optionally auto-import images from the clipboard
- **Expanded Window** -- full-size two-panel view for browsing large collections
- **Global Hotkey** -- `Cmd+Shift+S` to toggle the popover
- **Keyboard Navigation** -- arrow keys, Enter, Escape, `Cmd+C`
- **Pagination** -- loads 10 screenshots at a time for snappy performance
- **Configurable Grid** -- 1-4 columns per row (Settings)
- **Launch at Login** -- via `SMAppService`
- **Notifications** -- alerts for new screenshots and OCR completion
- **Gold Design Palette** -- clean, minimal UI with gold accents

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+

## Building

```bash
git clone https://github.com/Joe2Code/ScreenShotManager-Mac.git
cd ScreenShotManager-Mac
xcodebuild -scheme ScreenShotManager-Mac -destination 'platform=macOS' build
```

Or open `ScreenShotManager-Mac.xcodeproj` in Xcode and hit Run.

## Architecture

The app depends on [ScreenShotManagerCore](https://github.com/Joe2Code/ScreenShotManagerCore), a public Swift Package that provides:

- **CoreData stack** (`CorePersistenceController`) -- shared data model for screenshots, tags, and smart folders
- **OCR Engine** (`OCREngine`) -- cross-platform Vision framework wrapper using `CGImage`
- **Smart Folder Engine** (`SmartFolderEngine`) -- keyword and regex-based auto-categorization
- **Image Storage** (`CoreImageStorage`) -- file-based image and thumbnail management
- **Utilities** -- platform constants, color hex conversion, notification names

### App Structure

```
ScreenShotManager-Mac/
  App/
    ScreenShotManagerMacApp.swift    MenuBarExtra entry point + right-click menu
    AppState.swift                   Central @MainActor state manager
  Services/
    FolderWatcher.swift              FSEvents directory monitoring
    MacOCRService.swift              OCR orchestration
    MacImageStorage.swift            NSImage storage helper
    GlobalHotkey.swift               Cmd+Shift+S handler
    ClipboardMonitor.swift           NSPasteboard polling
    NotificationService.swift        UserNotifications
  Views/
    PopoverView.swift                Main popover with sidebar toggle
    ThumbnailGridView.swift          Paginated grid with hover actions
    SearchBarView.swift              Search input
    MenuBarIcon.swift                SF Symbols icon states
    SmartFoldersPanel.swift          Sidebar with folder list
    TagManagementView.swift          Tag CRUD
    QuickActionsOverlay.swift        Hover action buttons
    ScreenshotDetailView.swift       Full-size view with OCR text
    ExpandedWindowView.swift         Two-panel full window
    SettingsView.swift               Preferences
    StatsView.swift                  Statistics panel
    DesignTokens.swift               Gold color palette
  Models/
    ScreenshotInfo.swift             Lightweight display model
```

## License

MIT -- see [LICENSE](LICENSE)
