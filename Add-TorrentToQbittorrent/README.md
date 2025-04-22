# Add-TorrentToQbittorrent

A PowerShell script to add .torrent files to a remote qBittorrent instance via its Web API.

## Description

This script takes a .torrent file path as an argument and uploads it to the specified qBittorrent Web API using curl. It handles user authentication by obtaining and validating a session cookie and supports configurable download options. Designed for use with Windows file association, you can add torrents simply by double-clicking on a .torrent file.

## Features

- Upload .torrent files to a remote qBittorrent server.
- Authentication via username and password with session cookie validation.
- Configuration through an external JSON file.
- Configurable download options:
  - Save path specification.
  - Category assignment.
  - Setting the torrent as paused.
  - Enabling sequential downloads.
  - Prioritizing the first and last piece.
- Robust error handling and automatic cleanup of temporary cookie files.
- Compatible with Windows file association for simplified usage.

## Prerequisites

- PowerShell 5.1 or higher.
- curl.exe (pre-installed on Windows 10+).
- A qBittorrent instance with Web API enabled.

## Installation

1. Clone or download this repository to a folder of your choice.
2. Copy the `qBittorrentConfig.sample.json` file to `qBittorrentConfig.json`.
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

Basic example:

```powershell
.\Add-TorrentToQbittorrent.ps1 -torrent "C:\Downloads\my_file.torrent"
```

Example with additional options:

```powershell
.\Add-TorrentToQbittorrent.ps1 -torrent "C:\Downloads\my_file.torrent" -savePath "D:\Torrents\Completed" -category "Movies" -paused -sequential -firstLastPiecePrio
```

### Via File Association

Simply double-click on any .torrent file in Windows Explorer.

## Customization

All configurable options are now passed as parameters when running the script. There is no need to modify the script to set default values. You can pass the following parameters:

- **-torrent**: Path to the .torrent file (required).
- **-savePath**: The save path on the qBittorrent machine.
- **-category**: The category to assign.
- **-paused**: Use this switch to add the torrent in a paused state.
- **-sequential**: Use this switch to enable sequential download.
- **-firstLastPiecePrio**: Use this switch to prioritize the first and last piece.

Example usage:

```powershell
.\Add-TorrentToQbittorrent.ps1 -torrent "C:\Downloads\my_file.torrent" -savePath "D:\Torrents\Completed" -category "Movies" -paused -sequential -firstLastPiecePrio
```

## Security Notes

- The password is stored in plain text in the configuration file. Ensure you protect this file with appropriate permissions.
- The script uses the `-k` option with curl to ignore SSL certificate errors; for optimal security, valid certificates should be used if HTTPS is enabled.

## Author

Gilles Reichert

## Date

April 14, 2025

## API Version

qBittorrent Web API v2