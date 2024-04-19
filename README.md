# PowerShell File Organizer Script

This script organizes files in a directory based on their filenames. It's especially useful for organizing large collections of files where manual organization would be time-consuming.

## Features

- **Organizes files** into directories based on their filenames.
- Supports a variety of filename formats through the use of **regular expressions**.
- Can operate in a "**dry run**" mode that shows what would be moved without actually moving anything.
- Can **continuously loop** until there are no more files to process.

## Usage

1. Open PowerShell.
2. Navigate to the directory containing the script.
3. Run the script with the desired options.

Here's an example command:

```powershell
.\SortImagesByDirectoryName.ps1 -sourceDir "F:\TestDir" -move -loop
