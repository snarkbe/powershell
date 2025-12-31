# VideoRenamer

A PowerShell script that automatically renames video files based on their naming patterns, supporting both TV series and movie formats.

## Features

- **Automatic Renaming**: Detects and renames video files according to standardized formats
- **Series Support**: Recognizes multiple series naming patterns:
  - `S01E01`, `S1E1` (various digit counts)
  - `Season 01 Episode 01`
  - `Ep01`, `Episode 01`
- **Movie Support**: Recognizes movie files with year format (e.g., `Title 2024`)
- **Case-Insensitive**: Matches patterns regardless of letter case
- **Safe Operations**: Prevents overwriting existing files
- **Logging**: Optional logging with timestamps and operation status
- **Special Character Handling**: Correctly handles filenames with square brackets and other special characters

## Supported Video Formats

- `.mkv` (Matroska)
- `.mp4` (MPEG-4)
- `.avi` (Audio Video Interleave)

## Usage

### Basic Usage

```powershell
.\VideoRenamer.ps1 -DirectoryPath "C:\Videos"
```

### With Logging

```powershell
.\VideoRenamer.ps1 -DirectoryPath "C:\Videos" -Log
```

When the `-Log` switch is used, a log file with timestamp is created in the target directory: `VideoRenamer_YYYYMMDD_HHMMSS.log`

## Parameters

- **DirectoryPath** (Required): The path to the directory containing video files to rename
- **Log** (Optional): Enable logging. When set, creates a timestamped log file in the target directory

## Renaming Format

### Series Files

Input format examples:

- `Game.of.Thrones.S01E01.mkv`
- `Breaking.Bad s02e05.mp4`
- `The Office Season 03 Episode 15.avi`
- `[GroupName]Show.Title.Ep01.mkv`

Output format:

- `Game of Thrones S01E01.mkv`
- `Breaking Bad S02E05.mp4`
- `The Office S03E15.avi`
- `[GroupName]Show Title S01E01.mkv`

### Movie Files

Input format examples:

- `Inception.2010.mkv`
- `The.Matrix.1999.mp4`
- `[Studio]Film.Name.2020.avi`

Output format:

- `Inception (2010).mkv`
- `The Matrix (1999).mp4`
- `[Studio]Film Name (2020).avi`

## Features in Detail

### Normalization

- Dots in filenames are converted to spaces for readability
- Season and episode numbers are normalized to 2 digits (e.g., `S1E5` becomes `S01E05`)
- Movie years are preserved as-is

### Error Handling

- Files that don't match series or movie patterns are reported as warnings
- Duplicate filenames are detected and skipped to prevent data loss
- All operations are logged with timestamps and status levels (INFO, WARN, SUCCESS)

### Logging Output

Each log entry includes:

- `[YYYY-MM-DD HH:MM:SS]` - Timestamp
- `[LEVEL]` - Log level (INFO, WARN, SUCCESS)
- Message describing the operation

Example log output:

```powershell
[2025-12-31 14:30:45] [INFO] Found 5 video file(s) to process.
[2025-12-31 14:30:46] [SUCCESS] Renamed: 'Game.of.Thrones.S01E01.mkv' -> 'Game of Thrones S01E01.mkv'
[2025-12-31 14:30:47] [WARNING] File 'Breaking Bad S02E05.mp4' already exists in directory.
[2025-12-31 14:30:48] [INFO] Processing complete.
```

## Examples

### Rename videos in a directory with logging

```powershell
.\VideoRenamer.ps1 -DirectoryPath "D:\Movies" -Log
```

### Rename videos without logging

```powershell
.\VideoRenamer.ps1 -DirectoryPath "D:\TV Shows"
```

## Notes

- The script processes files **non-recursively** (only in the specified directory, not subdirectories)
- Files with square brackets in their names are fully supported
- The script will not delete or move files, only rename them in place
- If a file fails to match either pattern, it will be reported but left unchanged
