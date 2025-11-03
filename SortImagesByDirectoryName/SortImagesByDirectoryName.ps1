param(
    # Support for Send To context menu (single folder path)
    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$InputPaths,
    
    # Support for command-line usage
    [Parameter(Mandatory = $false)]
    [switch]$move = $false,

    [Parameter(Mandatory = $false)]
    [string]$sourceDir = "",

    [Parameter(Mandatory = $false)]
    [switch]$loop
)

# Determine if running from Send To or command line
$actualSourceDir = ""

if ($InputPaths -and $InputPaths.Count -gt 0) {
    # Called from Send To context menu
    
    # Add Windows Forms assembly for message boxes when using Send To
    Add-Type -AssemblyName PresentationFramework
    
    # Ensure only one item is selected
    if ($InputPaths.Count -ne 1) {
        [System.Windows.MessageBox]::Show("Please select only one folder.", "Error")
        exit 1
    }
    
    $actualSourceDir = $InputPaths[0]
    
    # Check if the path is a folder
    if (-not (Test-Path $actualSourceDir -PathType Container)) {
        [System.Windows.MessageBox]::Show("Selected item is not a folder.", "Error")
        exit 1
    }
    
    # For Send To, always move files
    $move = $true
    $loop = $false
} else {
    # Called from command line
    if ($sourceDir -eq "") {
        $actualSourceDir = (Get-Location).Path
    } else {
        $actualSourceDir = $sourceDir
    }
    
    # Check if the directory exists
    if (-not (Test-Path $actualSourceDir -PathType Container)) {
        Write-Host "Directory does not exist: $actualSourceDir" -ForegroundColor Red
        exit 1
    }
}

# Define the regular expressions for the different filename formats
$regexPatterns = @(
    '_([^_]+?) \(',     # matches filenames like Prefix_Name_Series (99).jpg
    '^.+-(.+?)_',       # matches filenames like Name-Series_027.jpg
    '^.+-([A-Za-z0-9.-]+?)_', # matches filenames like Prefix-Name.With.Dot_002.jpg -> Name.With.Dot
    '^.+ - (.+?)_',     # matches filenames like Prefix_Name A - Series_088.jpg
    '^(.+?) \(',        # matches filenames like Prefix_Name_Series (102).jpg
    '-([^_]+?)_',       # matches filenames like Name B-Series_001.jpg
    '-([^_]+?)-',       # matches filenames like Name-005-008.jpg
    '_([^_]+?)_keyword_suffix_'  # matches filenames like name_category_description_keyword_suffix_092.jpg
)

$loopIteration = 0
$idleCount = 0

do {

    # Initialize a hashtable to keep track of the number of files moved to each directory
    $dirFileCount = @{}

    # Get all the files in the directory
    $allFiles = Get-ChildItem -Path $actualSourceDir -File

    # Filter the files to include only images
    $files = $allFiles | Where-Object { $_.Extension -match "(?i)\.jpg|\.jpeg|\.png|\.gif" }

    # If there are no files to process
    if ($files.Count -eq 0) {
        if ($loop) {
            $idleCount++
            if ($loopIteration -eq 0) {
                Write-Output "No files to process. Waiting for new files... (Press Ctrl+C to exit)"
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
        # Initialize directory name as null
        $dirName = $null

        # Initialize cleanest directory name as null
        $cleanestDirName = $null

        # Try each regex pattern and choose the cleanest directory name
        foreach ($pattern in $regexPatterns) {
            if ($file.BaseName -match $pattern) {
                $potentialDirName = $Matches[1].Trim()

                # Check if the potential directory name is clean (letters, numbers, spaces, dots, hyphens)
                if ($potentialDirName -match '^[a-zA-Z0-9\s\.-]+$') {
                    # If this is the first match or if this match is cleaner than the previous match, update the cleanest directory name
                    if ($null -eq $cleanestDirName -or $potentialDirName.Length -lt $cleanestDirName.Length) {
                        $cleanestDirName = $potentialDirName
                    }
                }
            }
        }

        $dirName = $cleanestDirName

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
        else {
            Write-Output ("Would move file '{0}' to directory '{1}'." -f $file.Name, $dirName)
        }

        # Increment the count of files moved to the directory
        if ($dirFileCount.ContainsKey($dirName)) {
            $dirFileCount[$dirName]++
        }
        else {
            $dirFileCount[$dirName] = 1
        }
    }

    # Output the number of files moved to each directory
    if ($dirFileCount.Count -gt 0) {
        $dirFileCount.GetEnumerator() | ForEach-Object {
            Write-Output ("Moved {1} file(s) to directory '{0}'" -f $_.Key, $_.Value)
        }
        
        if ($loop) {
            Write-Output "Waiting for new files... (Press Ctrl+C to exit)"
            Start-Sleep -Seconds 3
        }
    }

} while ($loop)
