# PowerShell Scripts Collection - Copilot Instructions

## Repository Architecture

This is a **monorepo of independent PowerShell utilities**, not a single integrated application. Each top-level directory (except `.git` and `.github`) is a self-contained script with its own README.

**Key principle**: Scripts are completely independent—no shared modules or dependencies between them. Each can be copied and run standalone.

### Current Scripts

- **SortImagesByDirectoryName**: Organizes images into folders by parsing filenames with regex patterns
- **VideoRenamer**: Batch renames TV/movie files to standardized formats
- **Add-TorrentToQbittorrent**: Uploads torrents to remote qBittorrent via Web API
- **GetNordVPNkey**: Retrieves WireGuard credentials from NordVPN API
- **removeGit**: (No README found—treat with caution)

## Conventions

### Security & Credentials

- **Never hardcode secrets in scripts**. All credentials must be externalized:
  - JSON config files (e.g., `qBittorrentConfig.json`)
  - `.env` files loaded with `powershell-dotenv` module
- Always provide `.sample` versions of config files committed to git
- Add actual config files to `.gitignore`

### Script Parameters

- Use PowerShell `param()` blocks with descriptive parameter names
- Support both **command-line** and **Windows Shell integration** patterns:
  - `[Parameter(ValueFromRemainingArguments = $true)]` for Send To menu support
  - Named parameters with `[switch]` for boolean flags
  - Optional `-WhatIf` style dry-run modes (e.g., omitting `-move` flag)

### Error Handling

- Wrap file operations in `try/catch` with `-ErrorAction Stop`
- Use `Write-Warning` for recoverable errors; continue processing remaining items
- Use `Write-Output` for user-facing messages
- For GUI contexts (Send To menu), use `[System.Windows.MessageBox]::Show()` after loading `Add-Type -AssemblyName PresentationFramework`

### Regex Patterns

When extracting directory/file names from filenames:
- Use **multiple regex patterns** to handle various naming conventions
- Select the "cleanest" match (usually shortest valid match)
- Validate extracted names against Windows path rules: `[\\\/\:\*\?\"\<\>\|]`
- Prevent path traversal: reject names containing `..`

### File Operations

- Use `Join-Path` for all path construction (never string concatenation)
- Handle duplicates by appending counters (e.g., `filename_1.ext`, `filename_2.ext`)
- Validate paths with `Test-Path -PathType Container` before processing
- Use `-File` or `-Directory` filters with `Get-ChildItem` for clarity

### JSON Configuration

Scripts using JSON config files (like `Add-TorrentToQbittorrent.ps1`):
- Load with `Get-Content -Raw | ConvertFrom-Json`
- Validate required fields exist before use
- Document config schema in README or provide well-commented samples

### Logging Patterns

Optional logging should:
- Accept a `-Log` switch parameter
- Create timestamped log files: `ScriptName_YYYYMMDD_HHMMSS.log`
- Use format: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`
- Levels: `INFO`, `WARN`, `SUCCESS`

### Loop & Watch Modes

For scripts with `-loop` functionality:
- Implement **adaptive sleep intervals** (start at 3s, increase to 10s when idle)
- Display "Waiting..." messages with exit instructions
- Reset sleep duration when new work is detected
- Allow graceful exit with Ctrl+C

## Windows Integration

### Send To Menu

Scripts can be added to `%APPDATA%\Microsoft\Windows\SendTo\` for right-click access:
- Detect context via `ValueFromRemainingArguments` parameter
- Validate single-selection for folder/file inputs
- Show GUI error messages for invalid inputs
- Default to "action mode" (e.g., `-move` enabled) when invoked from Send To

### File Type Associations

For scripts that process specific file types (e.g., `.torrent` files):
- Document registry key setup in README: `HKEY_CLASSES_ROOT\.extension\shell\open\command`
- Use command format: `powershell.exe -ExecutionPolicy Bypass -File "path\to\script.ps1" "%1"`

## Adding New Scripts

When contributing a new utility:

1. Create a new top-level directory with the script name
2. Include a comprehensive `README.md` with:
   - Feature list
   - Usage examples (command-line and Windows integration if applicable)
   - Parameter documentation
   - Security notes (if handling credentials)
3. Update the root `README.md` with a summary entry
4. Follow the established conventions above
5. Provide sample config files (`.sample` suffix) for any external configuration

## PowerShell Version

Scripts target **PowerShell 5.1+** (Windows PowerShell), not PowerShell Core unless explicitly noted.
