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
    [switch]$loop,

    [Parameter(Mandatory = $false)]
    [switch]$gui
)

# Determine if running from Send To or command line
$isSendTo = $false
$actualSourceDir = ""

if ($InputPaths -and $InputPaths.Count -gt 0) {
    # Called from Send To context menu
    $isSendTo = $true
    
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
    '_([^_]+?) \(',     # matches filenames like AB_Model_Serie (99).jpg
    '^.+-(.+?)_',       # matches filenames like Model-Serie_027.jpg
    '^.+ - (.+?)_',     # matches filenames like AB_Model A - Serie_088.jpg
    '^(.+?) \(',        # matches filenames like Z_Model_Serie (102).JPG
    '-([^_]+?)_',       # matches filenames like Model B-Serie_001.jpg
    '-([^_]+?)-'        # matches filenames like Model-005-008.jpg
    '_([^_]+?)_teenmodeling_tv_'  # matches filenames like clarissa_model_goldbikini_teenmodeling_tv_092.jpg
)

do {

    # Initialize a hashtable to keep track of the number of files moved to each directory
    $dirFileCount = @{}

    # Get all the files in the directory
    $allFiles = Get-ChildItem -Path $actualSourceDir -File

    # Filter the files to include only images
    $files = $allFiles | Where-Object { $_.Extension -match "(?i)\.jpg|\.jpeg|\.png|\.gif" }

    # If there are no files to process, break the loop
    if ($files.Count -eq 0) {
        break
    }

    foreach ($file in $files) {
        # Initialize directory name as null
        $dirName = $null

        # Initialize cleanest directory name as null
        $cleanestDirName = $null

        # Try each regex pattern and choose the cleanest directory name
        foreach ($pattern in $regexPatterns) {
            if ($file.BaseName -match $pattern) {
                $potentialDirName = $Matches[1].Trim()

                # Check if the potential directory name is clean (contains only letters, numbers and spaces)
                if ($potentialDirName -match '^[a-zA-Z0-9\s]+$') {
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

        # Create the directory path
        $dirPath = Join-Path -Path $actualSourceDir -ChildPath $dirName

        # Create the directory if it doesn't exist and $move is true
        if ($move -and !(Test-Path -Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath | Out-Null
            Write-Output "Created directory: $dirName"
        }

        # Move the file to the new directory if $move is true
        if ($move) {
            Move-Item -Path $file.FullName -Destination $dirPath
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
    $dirFileCount.GetEnumerator() | ForEach-Object {
        Write-Output ("Moved {1} file(s) in directory '{0}'" -f $_.Key, $_.Value)
    }
    if ($loop) { Start-Sleep(3) }

} while ($loop)
