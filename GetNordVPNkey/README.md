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

## Obtaining a NordVPN token

To use this script you need a NordVPN API token (sometimes called "service token" or "token"). Steps:

1. Log in to your Nord Account at https://my.nordaccount.com/
2. Go to the "Devices & apps" or "API/Developers" section (naming may change). Look for an option to create an API token or service token.
3. Create a new token and copy the value.
4. Open the `.env` file in the `GetNordVPNkey` folder and set:

```text
NORDVPN_TOKEN=your-real-nordvpn-token-here
```

5. Save the file. The script will read the token from `.env` on execution.

If you can't find the token settings, check NordVPN's documentation or contact NordVPN support — UI labels sometimes differ between accounts and regions.
