<#
.SYNOPSIS
    Adds a .torrent file to a remote qBittorrent instance via its Web API.
.DESCRIPTION
    This script takes the path of a .torrent file as an argument and uploads it
    to the specified qBittorrent API.
    It handles authentication via username/password.
    To be associated with .torrent files in Windows Explorer.
.PARAMETER torrent
    Full path to the .torrent file to be added. Required.
.EXAMPLE
    .\Add-TorrentToQbittorrent.ps1 -torrent "C:\Downloads\my_file.torrent"
.EXAMPLE
    # Via file association (Windows passes the path as an argument)
    powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Add-TorrentToQbittorrent.ps1" "%1"
.NOTES
    Author    : Gilles Reichert
    Date      : 2025-04-13
    API Version: qBittorrent Web API v2
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$torrent,

    [Parameter(Mandatory = $false)]
    [string]$savePath, # Save path on the qBittorrent machine

    [Parameter(Mandatory = $false)]
    [string]$category, # Category to assign

    [Parameter(Mandatory = $false)]
    [switch]$paused,              # Add paused? Switch; true if present, false otherwise

    [Parameter(Mandatory = $false)]
    [switch]$sequential,          # Sequential download? Switch; true if present, false otherwise

    [Parameter(Mandatory = $false)]
    [switch]$firstLastPiecePrio   # Prioritize first/last piece? Switch; true if present, false otherwise
)

# Load configuration from JSON file
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "qBittorrentConfig.json"

if (-not (Test-Path $configFilePath)) {
    Write-Error "Error: Configuration file not found at '$configFilePath'."
    exit 1
}

try {
    $config = Get-Content -Path $configFilePath | ConvertFrom-Json
}
catch {
    Write-Error "Error: Unable to read or parse the configuration file. $_"
    exit 1
}

# Assign configuration values
$qbtHost = $config.qbtHost
$qbtPort = $config.qbtPort
$qbtUser = $config.qbtUser
$qbtPassword = $config.qbtPassword
$useHttps = $config.useHttps
$ignoreCert = $config.ignoreCert

# --- Optional parameters (uncomment and adjust if needed) ---
# $savePath = "D:\Torrents\Completed"   # Save path on the qBittorrent machine
# $category = "Movies"                 # Category to assign
# $paused = "false"                    # Add paused? "true" or "false" (string)
# $sequential = "false"                # Sequential download? "true" or "false"
# $firstLastPiecePrio = "false"        # Prioritize first/last piece? "true" or "false"

# --- Script Logic ---

# Basic file validation
if (-not (Test-Path $torrent -PathType Leaf)) {
    Write-Error "Error: Torrent file not found at '$torrent'"
    # Pause to see the error if launched by double-click
    if ($Host.Name -eq "ConsoleHost") { Read-Host "Press Enter to exit" }
    exit 1
}
if ($torrent -notlike "*.torrent") {
    Write-Warning "Warning: The file '$torrent' does not appear to be a .torrent file."
    # Continue anyway just in case...
}

# Building the base URL
$protocol = if ($useHttps) { "https" } else { "http" }
$baseUrl = "${protocol}://$qbtHost`:$qbtPort"
$addUrl = "$baseUrl/api/v2/torrents/add"

# Path to curl (usually in PATH on Windows 10+)
$curlExe = "curl.exe"

# Prepare curl arguments
$curlArgs = @(
    "-s", "-S" # Silent mode but displays errors
    "--fail", # Fails silently on HTTP error
    # -F option for multipart/form-data: 'field_name=@file_path;type=mime_type'
    # Make sure the path is properly quoted if it contains spaces
    "-F", "torrents=@`"$torrent`";type=application/x-bittorrent"
)
if ($ignoreCert) { $curlArgs += "-k" } # Ignore SSL certificate errors (if HTTPS)

# Add optional parameters (if configured)
if ($savePath) { 
    $curlArgs += "-F"
    $curlArgs += "savepath=$savePath"
}
if ($category) { 
    $curlArgs += "-F"
    $curlArgs += "category=$category"
}

# For switch parameters, always attach with explicit true/false value.
$curlArgs += "-F", "paused=" + ($paused ? "true" : "false")
$curlArgs += "-F", "sequentialDownload=" + ($sequential ? "true" : "false")
$curlArgs += "-F", "firstLastPiecePrio=" + ($firstLastPiecePrio ? "true" : "false")

# Handle authentication for curl - create a random named temporary cookie file
$tempFileName = "qbt_cookie_" + [System.Guid]::NewGuid().ToString() + ".txt"
$cookieFile = Join-Path -Path $env:TEMP -ChildPath $tempFileName

try {
    Write-Host "Attempting to add via curl: $torrent to $addUrl"
    
    # User/Pass method with curl (obtaining the SID cookie)
    Write-Host "Using Username/Password authentication with curl."
    $loginUrl = "$baseUrl/api/v2/auth/login"
    $loginData = "username=$($qbtUser)&password=$($qbtPassword)"

    # Prepare curl arguments for login request
    $loginCurlArgs = @(
        "-s", "--fail" # Silent mode but fails on HTTP error
    )
    if ($ignoreCert) { $loginCurlArgs += "-k" } # Ignore SSL certificate errors (if HTTPS)
    $loginCurlArgs += @(
        "-c", "$cookieFile", # Save the cookie
        "--data-binary", "`"$loginData`"", # Send as data
        "-H", "`"Content-Type: application/x-www-form-urlencoded`"",
        "$loginUrl"
    )
    Write-Debug "Executing curl for login...: $loginCurlArgs"
    & $curlExe $loginCurlArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Failed curl login to qBittorrent (Code: $LASTEXITCODE). Check URL, user, pass."
    }
    # Check if the cookie file was created and contains something
    if (-not (Test-Path $cookieFile) -or (Get-Item $cookieFile).Length -lt 10) {
        throw "Failed to connect to qBittorrent (cookie not received/empty)."
    }
    Write-Host "Session cookie obtained."
    # -b $cookieFile : Read cookies from the file for the next request
    $curlArgs += "-b", $cookieFile

    # Add the final URL to curl arguments
    $curlArgs += $addUrl

    # Execute the curl command for upload
    Write-Host "Executing curl for upload..."
    # Write-Host "$curlExe $($curlArgs -join ' ')" # Uncomment to see the complete curl command
    $uploadOutput = & $curlExe $curlArgs 2>&1 # Redirect stderr to stdout to capture curl errors
    $curlExitCode = $LASTEXITCODE

    # Check the result
    if ($curlExitCode -eq 0 -and $uploadOutput -match "Ok.") {
        Write-Host "Success (via curl): Torrent '$([System.IO.Path]::GetFileName($torrent))' added to qBittorrent."
    }
    else {
        throw "Failed curl upload. Code: $curlExitCode. Output: $uploadOutput"
    }

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    # Pause to see the error if launched by double-click
    if ($Host.Name -eq "ConsoleHost") { Read-Host "Press Enter to exit" }
    exit 1
}
finally {
    # Clean up the cookie file if User/Pass was used
    if (Test-Path $cookieFile) {
        Remove-Item $cookieFile -ErrorAction SilentlyContinue
    }
}
exit 0