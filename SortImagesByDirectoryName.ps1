# Boolean parameter to control whether to move files or just show what would be moved
param (
    [Parameter(Mandatory = $false)]
    [switch]$move = $false,

    [Parameter(Mandatory = $false)]
    [string]$sourceDir = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$loop
)

# Define the regular expressions for the different filename formats
$regexPatterns = @(
    '_([^_]+?) \(', # matches filenames like S18_Malva_HugePleasure (99).jpg
    '^.+-(.+?)_', # matches filenames like Irina-TheHomestead_027.jpg
    '^.+ - (.+?)_', # matches filenames like femjoy_Ariel A - Sway_088.jpg
    '^(.+?) \(', # matches filenames like Z_Kamila_GenostaNext (102).JPG
    '-([^_]+?)_', # matches filenames like Katya Clover-Just18_001.jpg
    '-([^_]+?)-'       # matches filenames like sonja-003-008.jpg
)

do {

    # Initialize a hashtable to keep track of the number of files moved to each directory
    $dirFileCount = @{}

    # Get all the files in the directory
    $allFiles = Get-ChildItem -Path $sourceDir -File

    # Filter the files to include only images
    $files = $allFiles | Where-Object { $_.Extension -match ".jpg|.png|.gif|.JPG" }

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
        $dirPath = Join-Path -Path $sourceDir -ChildPath $dirName

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
        Write-Output ("Directory '{0}' has {1} file(s)." -f $_.Key, $_.Value)
    }
    Start-Sleep(3)

} while ($loop)
