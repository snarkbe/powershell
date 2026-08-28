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

    # Resolve to an absolute path so the folder name (e.g. '.' -> 'Subject A') is correct.
    $actualSourceDir = (Resolve-Path -LiteralPath $actualSourceDir).Path

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

# Extractors are tried in order.
# Decode = $true  : dashes decoded as spaces (multi-dash → ' - ') — first valid match wins.
# Decode = $false : ampersands and dots normalised only — shortest valid match wins.
$extractors = @(
    # Title_Author_Quality_Index  — quality tag suffix present
    @{ P = '^(.+?)_.+_(?:high|medium|low|hd|sd|raw|ultra|orig|original)_\d+$'; Decode = $true  },
    # Author_Title-Name Index     — underscore prefix, title with dashes, trailing space+number
    @{ P = '^[^_]+_(.+?)\s+\d+$';                                               Decode = $true  },
    # Author_Title-Name_Index     — underscore prefix, title with dashes, trailing _number
    @{ P = '^[^_]+_(.+?)_\d+$';                                                 Decode = $true  },
    # Title-Name Index            — hyphenated title only, no prefix, trailing number
    @{ P = '^([A-Za-z][A-Za-z0-9]+(?:-[A-Za-z0-9]+)+)\s+\d+$';                Decode = $true  },
    # prefix - title (number)
    @{ P = '^.+ - ([A-Za-z0-9.-]+?)\s*\(\d+\)';                               Decode = $false },
    # prefix - series name number
    @{ P = '^.+ - (.+?)\s+\d+$';                                                Decode = $false },
    # prefix - series_number
    @{ P = '^.+ - (.+?)_';                                                        Decode = $false },
    # _name (number)
    @{ P = '_([^_\(]+?)\s*\(';                                                  Decode = $false },
    @{ P = '_([^_]+?) \(';                                                        Decode = $false },
    # name (number)
    @{ P = '^(.+?) \(';                                                           Decode = $false },
    # prefix-series_number
    @{ P = '^.+-([A-Za-z0-9 .-]+?)_';                                            Decode = $false },
    @{ P = '-([^_]+?)_';                                                          Decode = $false },
    @{ P = '-([^_]+?)-';                                                          Decode = $false },
    # Publisher.YYYY.MM.DD.Author.Content_NNNN
    @{ P = '^\w+\.\d{4}\.\d{2}\.\d{2}\.\w+\.(.+?)_\d+$';               Decode = $false }
)

# The containing folder name is often the best hint for the subject name.
# When a file's name references it (treating spaces, '-' and '_' as interchangeable),
# prefer the folder name over the regex extractors below.
$sourceFolderName = Split-Path $actualSourceDir -Leaf
$folderGuess      = ($sourceFolderName -replace '[\\\/\:\*\?\"\<\>\|]', '' -replace '\s+', ' ').Trim()
$folderGuessValid = ($folderGuess -match "^[a-zA-Z0-9\s\._'\-]+$") -and $folderGuess.Length -gt 0
# Normalised, regex-escaped token used to test whether a file name references the folder.
$folderToken      = [regex]::Escape((($folderGuess -replace '[\s_\-]+', ' ').Trim())) -replace '\\\ ', '[\s_\-]+'
# Require the token to land on a word boundary so it can't match inside an unrelated
# word (e.g. subject/folder name 'Lea' must not match the 'lea' hidden inside 'Pleasure').
$folderTokenPattern = "(?<![a-zA-Z0-9])(?:$folderToken)(?![a-zA-Z0-9])"

Write-Output "Processing: $actualSourceDir"

$loopIteration = 0
$idleCount = 0
$hasSeenFiles = $false
$maxIdleCount = 5                    # Once files have been seen: exit after ~30s of no new files
$maxIdleCountBeforeFirstFile = 33    # Before any file has been seen: allow ~5 min grace, so a watcher
                                      # started for a queued/sequential download isn't closed before its
                                      # first file arrives.

do {

    # Exit if the source directory was deleted while the script is running
    if (-not (Test-Path $actualSourceDir -PathType Container)) {
        Write-Output "Source directory no longer exists: $actualSourceDir. Exiting."
        break
    }

    # Initialize a hashtable to keep track of the number of files moved to each directory
    $dirFileCount = @{}

    # Get all image files in the directory
    # Note: -Include requires a wildcard in -Path to work without -Recurse
    $files = Get-ChildItem -Path (Join-Path $actualSourceDir '*') -File -Include *.jpg,*.jpeg,*.png,*.gif

    # If there are no files to process
    if ($files.Count -eq 0) {
        if ($loopEnabled) {
            $idleCount++
            $currentMaxIdle = if ($hasSeenFiles) { $maxIdleCount } else { $maxIdleCountBeforeFirstFile }
            if ($idleCount -ge $currentMaxIdle) {
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
    $hasSeenFiles = $true
    $loopIteration++

    foreach ($file in $files) {
        $dirName  = $null
        $sentinel = [char]0x1

        # Best guess: the containing folder name is the subject name. When the file
        # name references it, strip that subject portion (and the trailing index) and
        # use the remaining title as the subfolder name.
        # e.g. folder 'Subject A', file 'Some-Title_Subject-A_0124' -> 'Some Title'
        if ($folderGuessValid -and $file.BaseName -match $folderTokenPattern) {
            $title = $file.BaseName -replace $folderTokenPattern, ' '   # drop the subject name
            $title = $title -replace '[_\s\-]*\d+$', ''          # drop the trailing index
            $title = $title -replace '_', ' '                    # field separators -> space
            # Decode dashes: runs of 2+ -> ' - ', single -> space
            $title = $title -replace '-{2,}', $sentinel `
                            -replace '-',     ' '       `
                            -replace $sentinel, ' - '
            $title = ($title -replace '\s+', ' ').Trim(" -")
            if ($title -match "^[a-zA-Z0-9\s\._'\-]+$" -and $title.Length -gt 0) {
                $dirName = $title
            }
        }

        foreach ($extractor in $extractors) {
            if ($null -ne $dirName) { break }

            if ($file.BaseName -notmatch $extractor.P) { continue }

            $candidate = $Matches[1].Trim()

            if ($extractor.Decode) {
                # Decode dashes: runs of 2+ → ' - ', single → space
                $candidate = $candidate -replace '-{2,}', $sentinel `
                                        -replace '-',     ' '       `
                                        -replace $sentinel, ' - '
                $candidate = ($candidate -replace '\s+', ' ').Trim()
                # Priority pattern: first valid match wins
                if ($candidate -match "^[a-zA-Z0-9\s\._'\-]+$" -and $candidate.Length -gt 0) {
                    $dirName = $candidate
                    break
                }
            } else {
                $candidate = ($candidate -replace '[&!]', '_' -replace '\.', ' ' -replace '\s+', ' ').Trim()
                # Generic pattern: shortest valid match wins
                if ($candidate -match "^[a-zA-Z0-9\s\._'\-]+$" -and $candidate.Length -gt 0) {
                    if ($null -eq $dirName -or $candidate.Length -lt $dirName.Length) {
                        $dirName = $candidate
                    }
                }
            }
        }

        # If no directory name could be extracted, continue to the next file
        if ($null -eq $dirName) {
            continue
        }

        # Cover files belong with the gallery photos, not in a separate '<name> cover ...'
        # folder. Strip the trailing 'cover' token and any qualifier (e.g. 'clean', 'wide',
        # a number) so the file lands in the gallery directory:
        #   'Sunset cover'      -> 'Sunset'
        #   'BeachDay cover wide' -> 'BeachDay'
        if ($dirName -match '\s+cover(\s.*|\d*)?$') {
            $stripped = ($dirName -replace '\s+cover(\s.*|\d*)?$', '').Trim()
            if ($stripped.Length -gt 0) {
                $dirName = $stripped
            }
        }

        # Capitalize the first letter of the folder name, even when the filename is
        # lowercase (e.g. 'sunset' -> 'Sunset'). Leading non-letters are left as-is.
        if ($dirName.Length -gt 0) {
            $dirName = $dirName.Substring(0, 1).ToUpper() + $dirName.Substring(1)
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
