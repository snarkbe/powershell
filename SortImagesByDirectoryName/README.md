# PowerShell Im## Usage

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
- `-gui`: Reserved for future GUI implementation.r Script

This script organizes image files in a directory based on their filenames. It's especially useful for organizing large collections of image files where manual organization would be time-consuming.

## Features

- **Organizes image files** (JPG, JPEG, PNG, GIF) into directories based on their filenames.
- **Windows Explorer integration** - Can be called from the "Send To" context menu for easy access.
- Supports a variety of filename formats through the use of **multiple regular expressions**.
- **Smart pattern matching** - Uses multiple regex patterns and selects the cleanest directory name.
- Can operate in a "**dry run**" mode that shows what would be moved without actually moving anything.
- Can **continuously loop** until there are no more files to process.
- **File counting and reporting** - Shows how many files were moved to each directory.
- **Error handling** - Validates directories and provides user-friendly error messages.

## Usage

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
- `-loop`: If included, the script will keep looping until there are no more files to process.

## Supported Filename Patterns

The script recognizes and processes various filename patterns using multiple regular expressions.
The script automatically selects the cleanest (shortest and most appropriate) directory name when multiple patterns match.

## File Types

The script processes only image files with the following extensions:
- `.jpg`
- `.jpeg`
- `.png`
- `.gif`

## Notes

- Always backup your files before running the script, **just in case**.
- Ensure that you have **sufficient permissions** to read from the source directory and write to the destination directories.
- The script will not fail if the directories already exist; it will simply move the files into the existing directories.
- The script will continue to the next file if it cannot extract a directory name from the file name.
- When using the Send To menu, the script automatically operates in move mode (files will be moved, not just previewed).
- The script provides detailed reporting showing how many files were moved to each directory.
- Only image files are processed; other file types are ignored.
