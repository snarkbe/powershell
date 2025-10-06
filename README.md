# PowerShell Scripts Collection

A collection of PowerShell scripts for automation, file management, torrent handling, and VPN credential retrieval. Each script is self-contained and documented for easy use.

## Contents

- **SortImagesByDirectoryName**
  - Organizes image files into subdirectories based on filename patterns.
  - Supports command-line and Windows Explorer "Send To" integration.
  - Handles duplicate filenames, validates directory names, and features smart loop mode.
  - See [`SortImagesByDirectoryName/README.md`](./SortImagesByDirectoryName/README.md)

- **Add-TorrentToQbittorrent**
  - Adds `.torrent` files to a remote qBittorrent instance via its Web API.
  - Uses a JSON config for credentials and options.
  - Handles authentication, error reporting, and file cleanup.
  - See [`Add-TorrentToQbittorrent/README.md`](./Add-TorrentToQbittorrent/README.md)

- **GetNordVPNkey**
  - Retrieves NordVPN WireGuard credentials and server recommendations securely.
  - Loads your NordVPN token from a `.env` file (never hardcoded).
  - See [`GetNordVPNkey/README.md`](./GetNordVPNkey/README.md)

- **qBitEnv.ps1**
  - (Script purpose not documented; see script for details.)

- **VideoRenamer.ps1**
  - (Script purpose not documented; see script for details.)

## General Usage

- Each script is self-contained and can be run directly in PowerShell.
- See the individual script or folder README for detailed usage and configuration.
- Most scripts require PowerShell 5.1 or later.

## Security
- Sensitive tokens and credentials are never stored in the scripts or in git.
- `.env` and other secret files are excluded via `.gitignore`.

## License
MIT
