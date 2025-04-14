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
````

## Options

- `-sourceDir`: Specifies the directory containing the files to organize. If not provided, the script uses the current directory.
- `-move`: If included, the script will move the files. If not included, the script will show what would be moved but won’t actually move anything.
- `-loop`: If included, the script will keep looping until there are no more files to process.

## Notes

- Always backup your files before running the script, **just in case**.
- Ensure that you have **sufficient permissions** to read from the source directory and write to the destination directories.
- The script will not fail if the directories already exist; it will simply move the files into the existing directories.
- The script will continue to the next file if it cannot extract a directory name from the file name.
