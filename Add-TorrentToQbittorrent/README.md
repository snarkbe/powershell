# Add-TorrentToQbittorrent

A PowerShell script to add .torrent files to a remote qBittorrent instance via its Web API.

## Description

This script takes a .torrent file path as an argument and uploads it to the specified qBittorrent Web API. It is designed to be associated with .torrent files in Windows Explorer, allowing for quick addition by simply double-clicking on a torrent file.

## Features

- Upload .torrent files to a remote qBittorrent server
- Authentication via username and password
- Configuration through a separate JSON file
- Compatible with Windows file association for simplified usage
- Configurable download options (save path, category, etc.)

## Prerequisites

- PowerShell 5.1 or higher
- curl.exe (pre-installed on Windows 10+)
- A qBittorrent instance with Web API enabled

## Installation

1. Clone or download this repository to a folder of your choice
2. Copy the `qBittorrentConfig.sample.json` file to `qBittorrentConfig.json`
3. Modify the `qBittorrentConfig.json` file with your connection information:

```json
{
    "qbtHost": "your-qbittorrent-server",
    "qbtPort": 8080,
    "qbtUser": "your-username",
    "qbtPassword": "your-password",
    "useHttps": false
}
```

### File Association (optional)

To associate the script with .torrent files in Windows:

1. Open the Windows Registry (regedit)
2. Navigate to `HKEY_CLASSES_ROOT\.torrent`
3. Create or modify the `shell\open\command` key
4. Set the default value to:
   ```
   powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\Add-TorrentToQbittorrent.ps1" "%1"
   ```
   (Replace `C:\path\to\` with the actual path where your script is located)

## Usage

### Command Line

```powershell
.\Add-TorrentToQbittorrent.ps1 -torrent "C:\Downloads\my_file.torrent"
```

### Via File Association

Simply double-click on any .torrent file in Windows Explorer.

## Customization

To enable additional options such as save path or category, uncomment and modify the corresponding lines in the script:

```powershell
$savePath = "D:\Torrents\Completed"  # Save path on the qBittorrent machine
$category = "Movies"                 # Category to assign
$paused = "false"                    # Add paused? "true" or "false"
$sequential = "false"                # Sequential download? "true" or "false"
$firstLastPiecePrio = "false"        # Prioritize first/last piece? "true" or "false"
```

## Security Notes

- The password is stored in plain text in the configuration file. Make sure to protect this file with appropriate permissions.
- The `-k` option is used with curl to ignore SSL certificate errors. For optimal security, use valid certificates if you enable HTTPS.

## Author

Gilles Reichert

## Date

April 14, 2025

## API Version

qBittorrent Web API v2