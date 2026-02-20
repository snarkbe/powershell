# Send To shortcut location: %APPDATA%\Microsoft\Windows\SendTo\Sort to Subfolders.lnk
#   Target: C:\Program Files\PowerShell\7\pwsh.exe
#   Arguments: -NoProfile -WindowStyle Normal -ExecutionPolicy Bypass -File "<path>\SortImagesByDirectoryName.ps1" -move
#   Note: Do NOT add "%1" — Windows appends the selected folder automatically.

param(
    # Support for Send To context menu and command-line positional path
    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$InputPaths,
    
    # Require -move flag to actually move files (both command-line and Send To)
    [Parameter(Mandatory = $false)]
    [switch]$move = $false,

    [Parameter(Mandatory = $false)]
    [switch]$loop
)

# Determine source directory
$actualSourceDir = ""
$loopEnabled = $loop.IsPresent

if ($InputPaths -and $InputPaths.Count -gt 0) {
    # Path provided as positional argument (e.g. Send To context menu)
    # Filter out literal %1 which .lnk shortcuts may pass unexpanded
    $InputPaths = @($InputPaths | Where-Object { $_ -ne '%1' })

    if ($InputPaths.Count -eq 0) {
        # Only %1 was passed, no actual path
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("No folder path provided.", "Error")
        exit 1
    }

    # When a path with spaces is passed without proper quoting,
    # ValueFromRemainingArguments splits it into multiple elements.
    # Join them back into a single path.
    $actualSourceDir = ($InputPaths -join ' ').Trim()

    if (-not (Test-Path $actualSourceDir -PathType Container)) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("Selected item is not a folder: $actualSourceDir", "Error")
        exit 1
    }

    # Disable loop when called with a path argument (unless explicitly requested via -loop)
    if (-not $loop.IsPresent) { $loopEnabled = $false }
} else {
    # Use current directory
    $actualSourceDir = (Get-Location).Path
    
    if (-not (Test-Path $actualSourceDir -PathType Container)) {
        Write-Host "Directory does not exist: $actualSourceDir" -ForegroundColor Red
        exit 1
    }
}

# Define the regular expressions for the different filename formats
$regexPatterns = @(
    '_([^_\(]+?)\s*\(',  # pattern: prefix_prefix_name (number).ext
    '_([^_]+?) \(',      # pattern: prefix_name_series (number).ext
    '^.+-(.+?)_',        # pattern: prefix-series_number.ext
    '^.+-([A-Za-z0-9.-]+?)_', # pattern: prefix-name.with.dots_number.ext
    '^.+ - (.+?)\s+\d+$',                 # pattern: prefix - series name with spaces number.ext
    '^.+ - ([A-Za-z0-9.-]+?)\s*\(\d+\)', # pattern: prefix - title (number).ext
    '^.+ - (.+?)_',      # pattern: prefix - series_number.ext
    '^(.+?) \(',         # pattern: name (number).ext
    '-([^_]+?)_',        # pattern: prefix-series_number.ext
    '-([^_]+?)-',        # pattern: prefix-number-number.ext
    '_([^_]+?)_keyword_suffix_'  # pattern: prefix_category_description_keyword_suffix_number.ext
)

$loopIteration = 0
$idleCount = 0
$maxIdleCount = 5   # Exit loop after ~30 seconds of no new files

do {

    # Initialize a hashtable to keep track of the number of files moved to each directory
    $dirFileCount = @{}

    # Get all image files in the directory
    # Note: -Include requires a wildcard in -Path to work without -Recurse
    $files = Get-ChildItem -Path (Join-Path $actualSourceDir '*') -File -Include *.jpg,*.jpeg,*.png,*.gif

    # If there are no files to process
    if ($files.Count -eq 0) {
        if ($loopEnabled) {
            if ($loopIteration -eq 0) {
                Write-Output "No files to process. Exiting."
                break
            }
            $idleCount++
            if ($idleCount -ge $maxIdleCount) {
                Write-Output "No new files detected for a while. Exiting."
                break
            }
            # Adaptive sleep: longer wait when idle
            $sleepTime = [Math]::Min(3 + $idleCount, 10)
            Start-Sleep -Seconds $sleepTime
            $loopIteration++
            continue
        } else {
            break
        }
    }
    
    # Reset idle counter when files are found
    $idleCount = 0
    $loopIteration++

    foreach ($file in $files) {
        # Try each regex pattern and choose the cleanest directory name
        $dirName = $null
        foreach ($pattern in $regexPatterns) {
            if ($file.BaseName -match $pattern) {
                $potentialDirName = $Matches[1].Trim() -replace '[&!]', '_'

                # Check if the potential directory name is clean (letters, numbers, spaces, dots, hyphens, underscores)
                if ($potentialDirName -match '^[a-zA-Z0-9\s\._-]+$') {
                    if ($null -eq $dirName -or $potentialDirName.Length -lt $dirName.Length) {
                        $dirName = $potentialDirName
                    }
                }
            }
        }

        # If no directory name could be extracted, continue to the next file
        if ($null -eq $dirName) {
            continue
        }

        # Validate directory name doesn't contain path separators or invalid characters
        if ($dirName -match '[\\\/\:\*\?\"\<\>\|]|\.\.') {
            Write-Warning "Skipped '$($file.Name)' - invalid directory name: '$dirName'"
            continue
        }

        # Create the directory path
        $dirPath = Join-Path -Path $actualSourceDir -ChildPath $dirName

        # Create the directory if it doesn't exist and $move is true
        if ($move -and !(Test-Path -Path $dirPath)) {
            try {
                New-Item -ItemType Directory -Path $dirPath -ErrorAction Stop | Out-Null
                Write-Output "Created directory: $dirName"
            }
            catch {
                Write-Warning "Failed to create directory '$dirName': $_"
                continue
            }
        }

        # Move the file to the new directory if $move is true
        if ($move) {
            try {
                # Handle duplicate filenames by adding a counter
                $destPath = Join-Path $dirPath $file.Name
                $counter = 1
                while (Test-Path $destPath) {
                    $newName = "$($file.BaseName)_$counter$($file.Extension)"
                    $destPath = Join-Path $dirPath $newName
                    $counter++
                }
                
                Move-Item -Path $file.FullName -Destination $destPath -ErrorAction Stop
                
                # Notify if file was renamed due to duplicate
                if ($counter -gt 1) {
                    Write-Output "Renamed '$($file.Name)' to '$(Split-Path $destPath -Leaf)' (duplicate)"
                }
            }
            catch {
                Write-Warning "Failed to move '$($file.Name)': $_"
                continue
            }
        }
        # else {
        #     Write-Output ("Would move file '{0}' to directory '{1}'." -f $file.Name, $dirName)
        # }

        # Increment the count of files moved to the directory
        $dirFileCount[$dirName] = ($dirFileCount[$dirName] ?? 0) + 1
    }

    # Output the number of files processed to each directory
    if ($dirFileCount.Count -gt 0) {
        $action = if ($move) { "Moved" } else { "Would move" }
        $dirFileCount.GetEnumerator() | ForEach-Object {
            Write-Output ("{0} {1} file(s) to directory '{2}'" -f $action, $_.Value, $_.Key)
        }
        
        if ($loopEnabled) {
            Write-Output "Waiting for new files... (Press Ctrl+C to exit)"
            Start-Sleep -Seconds 3
        }
    }

} while ($loopEnabled)
