#!/usr/bin/env pwsh
# filepath: d:\Git\powershell\VideoRenamer.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$DirectoryPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$Log # Enable logging when this switch is set
)

if (-not (Test-Path -LiteralPath $DirectoryPath)) {
    Write-Error "Directory '$DirectoryPath' does not exist."
    exit 1
}

# Initialize logging
$logFile = if ($Log) { Join-Path $DirectoryPath "VideoRenamer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" } else { $null }
$script:logEntries = @()

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    if ($script:logFile) {
        $script:logEntries += $logEntry
    }
}


# Get all video files from the directory (non-recursive)
$videoFiles = Get-ChildItem -LiteralPath $DirectoryPath -File -Include *.mkv,*.mp4,*.avi

if ($videoFiles.Count -eq 0) {
    Log-Message "No video files found in '$DirectoryPath'." "INFO"
    exit 0
}

Log-Message "Found $($videoFiles.Count) video file(s) to process." "INFO"

# Define regex patterns for series and movies (case-insensitive)
# Supports: S01E01, S1E1, Season 01 Episode 01, etc.
$seriesPattern = '(?i)^(?<title>.+?)[\s\.]+(?:S(?<season>\d{1,2})E(?<episode>\d{1,2})|Season\s+\d{1,2}\s+Episode\s+\d{1,2}|Ep(?:isode)?\s+\d{1,2})\b.*\.(?<ext>mkv|mp4|avi)$'
$moviePattern  = '(?i)^(?<title>.+?)[\s\.](?<year>\d{4})\b.*\.(?<ext>mkv|mp4|avi)$'

foreach ($file in $videoFiles) {

    $resolvedPath = $file.FullName
    $fileName = $file.Name
    $directory = $file.DirectoryName

    if ($fileName -match $seriesPattern) {
        # For a series: extract title and season/episode
        $cleanTitle = $Matches['title'] -replace '\.', ' '
        $season     = $Matches['season']
        $episode    = $Matches['episode']
        $ext        = $Matches['ext']
        
        # Normalize season and episode to 2 digits
        $seasonNum = [int]$season
        $episodeNum = [int]$episode
        $newFileName = "{0} S{1:D2}E{2:D2}.{3}" -f $cleanTitle, $seasonNum, $episodeNum, $ext
        $newFilePath = Join-Path $directory $newFileName

        if (Test-Path -LiteralPath $newFilePath) {
            Log-Message "File '$newFileName' already exists in directory." "WARN"
            continue
        }

        Rename-Item -LiteralPath $resolvedPath -NewName $newFileName
        Log-Message "Renamed: '$fileName' -> '$newFileName'" "SUCCESS"
    }
    elseif ($fileName -match $moviePattern) {
        # For a movie: extract title and year
        $cleanTitle = $Matches['title'] -replace '\.', ' '
        $year       = $Matches['year']
        $ext        = $Matches['ext']
        
        $newFileName = "{0} ({1}).{2}" -f $cleanTitle, $year, $ext
        $newFilePath = Join-Path $directory $newFileName

        if (Test-Path -LiteralPath $newFilePath) {
            Log-Message "File '$newFileName' already exists in directory." "WARN"
            continue
        }

        Rename-Item -LiteralPath $resolvedPath -NewName $newFileName
        Log-Message "Renamed: '$fileName' -> '$newFileName'" "SUCCESS"
    }
    else {
        Log-Message "File '$fileName' does not match expected patterns (series or movie)." "WARN"
    }
}

# Save log file before final message
Log-Message "Processing complete." "INFO"

try {
    if ($logFile) {
        $logEntries | Out-File -FilePath $logFile -Encoding UTF8
        Write-Host "`nLog saved to: $logFile" -ForegroundColor Cyan
    }
}
catch {
    Write-Warning "Could not save log file: $_"
}