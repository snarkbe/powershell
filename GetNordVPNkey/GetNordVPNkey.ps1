
# Load .env file using dotenv
Import-Module pwsh-dotenv -ErrorAction Stop
if (Test-Path "$PSScriptRoot/.env") {
    Import-Dotenv -Path "$PSScriptRoot/.env" -ErrorAction Stop
} else {
    Write-Error ".env file not found. Please create it from .env.sample and add your NordVPN token."
    exit 1
}

$username = "token"
$password = $env:NORDVPN_TOKEN
$pair = "$($username):$($password)"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$encodedCredentials = [Convert]::ToBase64String($bytes)
$url = "https://api.nordvpn.com/v1/users/services/credentials"

$headers = @{
    Authorization = "Basic $encodedCredentials"
}

$credentials = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

[pscustomobject]@{
    ID                  = $credentials.id
    Username            = $credentials.username
    Password            = $credentials.password
    "NordLynx Private Key"  = $credentials.nordlynx_private_key
    "Created At"           = $credentials.created_at
    "Updated At"           = $credentials.updated_at
}

$server = Invoke-RestMethod -Uri "https://api.nordvpn.com/v1/servers/recommendations?&filters[servers_technologies][identifier]=wireguard_udp&limit=1"

$server | ForEach-Object {
    $wireguardTech = $_.technologies | Where-Object { $_.identifier -eq 'wireguard_udp' }
    if ($wireguardTech) {
        # Extract metadata values
        $publicKey = $wireguardTech.metadata | Where-Object { $_.name -eq 'public_key' } | Select-Object -ExpandProperty value
        
        # Output with additional metadata columns
        [pscustomobject]@{
            Name           = $_.name
            Load           = $_.load
            Station        = $_.Station
            "Technology ID"   = $wireguardTech.id
            "Technology Name" = $wireguardTech.name
            Identifier     = $wireguardTech.identifier
            "Created At"      = $wireguardTech.created_at
            "Updated At"      = $wireguardTech.updated_at
            "Public Key"      = $publicKey
        }
    }
}

