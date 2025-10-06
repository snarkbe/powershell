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

# Assign configuration values with validation
$qbtHost = $config.qbtHost
$qbtPort = $config.qbtPort
$qbtUser = $config.qbtUser
$qbtPassword = $config.qbtPassword
$useHttps = $config.useHttps
$ignoreCert = $config.ignoreCert

# Validate required configuration values
if ([string]::IsNullOrWhiteSpace($qbtHost)) {
    Write-Error "Error: 'qbtHost' is not configured in the configuration file."
    exit 1
}
if ([string]::IsNullOrWhiteSpace($qbtUser)) {
    Write-Error "Error: 'qbtUser' is not configured in the configuration file."
    exit 1
}
if ([string]::IsNullOrWhiteSpace($qbtPassword)) {
    Write-Error "Error: 'qbtPassword' is not configured in the configuration file."
    exit 1
}
if ($qbtPort -le 0 -or $qbtPort -gt 65535) {
    Write-Error "Error: 'qbtPort' must be a valid port number (1-65535). Current value: $qbtPort"
    exit 1
}

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

# Path to curl (usually in PATH on Windows 10+)
$curlExe = "curl.exe"

# Check if curl.exe is available
try {
    $null = Get-Command $curlExe -ErrorAction Stop
}
catch {
    Write-Error "Error: curl.exe is not found in PATH. Please ensure curl is installed (included in Windows 10+)."
    if ($Host.Name -eq "ConsoleHost") { Read-Host "Press Enter to exit" }
    exit 1
}

# Building the base URL
$protocol = if ($useHttps) { "https" } else { "http" }
$baseUrl = "${protocol}://$qbtHost`:$qbtPort"
$addUrl = "$baseUrl/api/v2/torrents/add"



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

# For switch parameters, always attach with explicit true/false value (PS 5.1 compatible)
if ($paused) {
    $curlArgs += "-F", "paused=true"
} else {
    $curlArgs += "-F", "paused=false"
}
if ($sequential) {
    $curlArgs += "-F", "sequentialDownload=true"
} else {
    $curlArgs += "-F", "sequentialDownload=false"
}
if ($firstLastPiecePrio) {
    $curlArgs += "-F", "firstLastPiecePrio=true"
} else {
    $curlArgs += "-F", "firstLastPiecePrio=false"
}

# Handle authentication for curl - create a random named temporary cookie file
$tempFileName = "qbt_cookie_" + [System.Guid]::NewGuid().ToString() + ".txt"
$cookieFile = Join-Path -Path $env:TEMP -ChildPath $tempFileName

try {
    Write-Host "Attempting to add torrent: '$([System.IO.Path]::GetFileName($torrent))' to $addUrl"
    
    # User/Pass method with curl (obtaining the SID cookie)
    Write-Verbose "Using Username/Password authentication with curl."
    $loginUrl = "$baseUrl/api/v2/auth/login"
    
    # URL encode username and password to handle special characters
    Add-Type -AssemblyName System.Web
    $encodedUser = [System.Web.HttpUtility]::UrlEncode($qbtUser)
    $encodedPass = [System.Web.HttpUtility]::UrlEncode($qbtPassword)
    $loginData = "username=$encodedUser&password=$encodedPass"

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
    Write-Verbose "Executing curl for login to: $loginUrl"
    & $curlExe $loginCurlArgs
    if ($LASTEXITCODE -ne 0) {
    throw "Failed to authenticate with qBittorrent (Exit Code: $LASTEXITCODE). Please verify the host (${qbtHost}:${qbtPort}), username, and password in the configuration file."
    }
    # Check if the cookie file was created and contains something
    if (-not (Test-Path $cookieFile) -or (Get-Item $cookieFile).Length -lt 10) {
        throw "Failed to obtain authentication cookie from qBittorrent. The server may be unreachable or credentials may be invalid."
    }
    Write-Verbose "Session cookie obtained successfully."
    # -b $cookieFile : Read cookies from the file for the next request
    $curlArgs += "-b", $cookieFile

    # Add the final URL to curl arguments
    $curlArgs += $addUrl

    # Execute the curl command for upload
    Write-Verbose "Uploading torrent file to qBittorrent..."
    Write-Verbose "Upload URL: $addUrl"
    if ($savePath) { Write-Verbose "Save path: $savePath" }
    if ($category) { Write-Verbose "Category: $category" }
    Write-Verbose "Options: Paused=$paused, Sequential=$sequential, FirstLastPiecePrio=$firstLastPiecePrio"
    
    $uploadOutput = & $curlExe $curlArgs 2>&1 # Redirect stderr to stdout to capture curl errors
    $curlExitCode = $LASTEXITCODE

    # Check the result
    if ($curlExitCode -eq 0 -and $uploadOutput -match "Ok.") {
        Write-Host "Success: Torrent '$([System.IO.Path]::GetFileName($torrent))' successfully added to qBittorrent." -ForegroundColor Green
        
        # Delete the torrent file after successful addition
        try {
            Remove-Item -Path $torrent -Force -ErrorAction Stop
            Write-Verbose "Torrent file deleted: '$torrent'"
        }
        catch {
            Write-Warning "Torrent added successfully, but could not delete the torrent file: $($_.Exception.Message)"
        }
    }
    elseif ($curlExitCode -eq 0) {
        throw "Upload completed but qBittorrent returned unexpected response. Output: $uploadOutput`nThis may indicate the torrent was already added or there was a server-side error."
    }
    else {
        throw "Failed to upload torrent file (Exit Code: $curlExitCode). Server response: $uploadOutput`nPlease check network connectivity and qBittorrent server status."
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