# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

A **monorepo of independent PowerShell utilities** — each top-level directory is a self-contained script with its own README. Scripts share no modules or imports between them; each can be copied and run standalone.

| Directory | Purpose |
|---|---|
| `SortImagesByDirectoryName/` | Sorts images into subdirs by parsing filename patterns with regex |
| `Add-TorrentToQbittorrent/` | Uploads `.torrent` files to qBittorrent via Web API using `curl.exe` |
| `GetNordVPNkey/` | Fetches NordVPN WireGuard credentials via API using `Invoke-RestMethod` |
| `VideoRenamer/` | Batch renames TV/movie files to standardized `Title S01E01.ext` / `Title (Year).ext` format |
| `removeGit/` | Removes Git and MobaXterm context-menu registry entries (requires elevation) |

## Running Scripts

All scripts target **PowerShell 5.1+** (Windows PowerShell). Scripts that use newer syntax (`??` null-coalescing, `pwsh` shebang) require **PowerShell 7+**.

```powershell
# Dry-run (preview without moving files)
.\SortImagesByDirectoryName\SortImagesByDirectoryName.ps1 -InputPaths "C:\Images"

# Actually move files
.\SortImagesByDirectoryName\SortImagesByDirectoryName.ps1 -InputPaths "C:\Images" -move

# Watch mode (adaptive sleep, exits after ~30s idle)
.\SortImagesByDirectoryName\SortImagesByDirectoryName.ps1 -move -loop

# Add torrent
.\Add-TorrentToQbittorrent\Add-TorrentToQbittorrent.ps1 -torrent "C:\file.torrent"

# Rename videos (dry-run is not available — renames happen immediately)
.\VideoRenamer\VideoRenamer\VideoRenamer.ps1 -DirectoryPath "C:\Videos" -Log

# Get NordVPN credentials (requires pwsh-dotenv module and .env file)
.\GetNordVPNkey\GetNordVPNkey.ps1

# Remove Git/MobaXterm context menu entries (self-elevates to Administrator)
.\removeGit\removeGit.ps1
```

## Conventions

### Credentials & Config
- Secrets go in `.env` files (loaded via `pwsh-dotenv` module) or JSON config files — never hardcoded.
- Always commit a `.sample` version; add the real file to `.gitignore`.
- JSON configs are loaded with `Get-Content -Raw | ConvertFrom-Json` and required fields are validated before use.

### Parameters
- Use `param()` blocks with `[Parameter(ValueFromRemainingArguments = $true)]` to support Windows "Send To" menu invocation (where Windows appends the path without a named flag).
- Paths with spaces passed via Send To are split across array elements; rejoin with `($InputPaths -join ' ').Trim()`.
- Use `[switch]` for boolean flags; never rely on implicit truthy strings.

### Error Handling
- File operations use `try/catch` with `-ErrorAction Stop`.
- `Write-Warning` for recoverable per-item failures (continue to next item); `Write-Error` + `exit 1` for fatal failures.
- For GUI contexts (Send To menu), show errors via `[System.Windows.MessageBox]::Show()` after `Add-Type -AssemblyName PresentationFramework`.
- Scripts launched by file association show a countdown exit prompt (`Wait-ForExit`) so errors are visible before the window closes.

### File Operations
- Use `Join-Path` for all path construction — never string concatenation.
- Handle duplicate destinations by appending `_1`, `_2`, etc. to the basename.
- Use `-LiteralPath` (not `-Path`) when filenames may contain regex-special characters like `[`, `]`.

### Regex for Filename Parsing
- Apply multiple patterns; select the shortest valid match to get the cleanest name.
- Validate extracted names against Windows forbidden characters: `[\\\/\:\*\?\"\<\>\|]` and `..` path traversal.
- Allowed characters in directory names: `^[a-zA-Z0-9\s\._'\-]+$`.

### Loop/Watch Mode
- Adaptive sleep: starts at 3s, increases toward 10s when idle.
- Exit after `$maxIdleCount` consecutive idle iterations (~30s by default).
- Reset idle counter when new files are found.

### Logging (optional `-Log` switch)
- Log file: `ScriptName_YYYYMMDD_HHMMSS.log` in the target directory.
- Format: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message` — levels are `INFO`, `WARN`, `SUCCESS`.

### Windows Integration
- **Send To**: shortcut target is `pwsh.exe` (PS7) or `powershell.exe` (PS5), with `-NoProfile -WindowStyle Normal -ExecutionPolicy Bypass -File "<path>"`. Do **not** append `%1` — Windows does it automatically.
- **File association**: `powershell.exe -ExecutionPolicy Bypass -File "path\script.ps1" "%1"` via `HKEY_CLASSES_ROOT\.ext\shell\open\command`.

## Adding a New Script

1. Create a top-level directory named after the script.
2. Add a `README.md` covering features, parameters, usage examples, and any security notes.
3. Provide `.sample` config files for any external configuration.
4. Update the root `README.md` with a summary entry.
