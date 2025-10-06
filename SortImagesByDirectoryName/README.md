# PowerShell Image File Organizer Script

This script organizes image files in a directory based on their filenames. It's especially useful for organizing large collections of image files where manual organization would be time-consuming.

## Features

- **Organizes image files** (JPG, JPEG, PNG, GIF) into directories based on their filenames.
- **Windows Explorer integration** - Can be called from the "Send To" context menu for easy access.
- Supports a variety of filename formats through the use of **multiple regular expressions**.
- **Smart pattern matching** - Uses multiple regex patterns and selects the cleanest directory name.
- Can operate in a "**dry run**" mode that shows what would be moved without actually moving anything.
- **Smart loop mode** - Continuously monitors for new files with adaptive sleep intervals.
- **Duplicate file handling** - Automatically renames files when duplicates are detected.
- **Error handling** - Robust try-catch blocks with clear error messages.
- **Directory name validation** - Prevents invalid characters and path traversal attacks.
- **File counting and reporting** - Shows how many files were moved to each directory.

## Usage

### Command Line Usage

1. Open PowerShell.
2. Navigate to the directory containing the script.
3. Run the script with the desired options.

Here's an example command:

```powershell
.\SortImagesByDirectoryName.ps1 -sourceDir "F:\TestDir" -move -loop
```

### Windows Explorer Integration (Send To Menu)

1. Copy the script to your Windows "Send To" folder (typically `%APPDATA%\Microsoft\Windows\SendTo\`).
2. In Windows Explorer, right-click on any folder containing images.
3. Select "Send to" → "SortImagesByDirectoryName.ps1"
4. The script will automatically move files in the selected folder.

## Parameters

- `-sourceDir`: Specifies the directory containing the files to organize. If not provided, the script uses the current directory.
- `-move`: If included, the script will move the files. If not included, the script will show what would be moved but won't actually move anything (dry run mode).
- `-loop`: If included, the script will keep looping until there are no more files to process.

This script organizes image files in a directory based on their filenames. It's especially useful for organizing large collections of image files where manual organization would be time-consuming.

## Basic Usage

1. Open PowerShell.
2. Navigate to the directory containing the script.
3. Run the script with the desired options.

Here's an example command:

```powershell
.\SortImagesByDirectoryName.ps1 -sourceDir "F:\TestDir" -move -loop
````

## Options

- `-sourceDir`: Specifies the directory containing the files to organize. If not provided, the script uses the current directory.
- `-move`: If included, the script will move the files. If not included, the script will show what would be moved but won’t actually move anything.
- `-loop`: If included, the script will continuously monitor the directory for new files with adaptive sleep intervals (3-10 seconds) to reduce CPU usage when idle. Press Ctrl+C to exit.

## Supported Filename Patterns

The script recognizes and processes various filename patterns using multiple regular expressions.
The script automatically selects the cleanest (shortest and most appropriate) directory name when multiple patterns match.

## File Types

The script processes only image files with the following extensions:

- `.jpg`
- `.jpeg`
- `.png`
- `.gif`

## Advanced Features

### Duplicate File Handling

When a file with the same name already exists in the destination directory, the script automatically renames it with a counter suffix (e.g., `image_1.jpg`, `image_2.jpg`) to prevent data loss.

### Smart Loop Mode

- **Adaptive Sleep**: Starts with 3-second intervals and gradually increases to 10 seconds when idle
- **Clear Feedback**: Shows "Waiting for new files..." messages
- **Instant Response**: Resets to fast checking when new files are detected
- **Graceful Exit**: Press Ctrl+C to stop monitoring

### Error Handling

- Robust try-catch blocks protect against file access errors
- Clear warning messages for failed operations
- Continues processing remaining files after errors
- Validates directory names to prevent invalid characters and path traversal

## Notes

- Always backup your files before running the script, **just in case**.
- Ensure that you have **sufficient permissions** to read from the source directory and write to the destination directories.
- The script will not fail if the directories already exist; it will simply move the files into the existing directories.
- The script will continue to the next file if it cannot extract a directory name from the file name.
- When using the Send To menu, the script automatically operates in move mode (files will be moved, not just previewed).
- The script provides detailed reporting showing how many files were moved to each directory.
- Only image files are processed; other file types are ignored.
- Duplicate files are automatically renamed rather than overwritten.
