# GetNordVPNkey

Small helper script to fetch NordVPN WireGuard credentials and a recommended server.

## Quickstart

1. Copy `.env.sample` to `.env` and add your NordVPN token:

```text
NORDVPN_TOKEN=your-nordvpn-token-here
```

2. Run the script in PowerShell:

```powershell
.\GetNordVPNkey.ps1
```

3. The script will print a PowerShell object containing server metadata and the WireGuard public key.

## Requirements

- PowerShell 5.1+
- `powershell-dotenv` module (the script imports it)

## Notes

- This script only reads the token and does not persist sensitive data.
