
# Load .env file using powershell-dotenv
Import-Module powershell-dotenv -ErrorAction Stop
if (Test-Path "$PSScriptRoot/.env") {
    $envVars = Get-Dotenv -Path "$PSScriptRoot/.env"
    $env:NORDVPN_TOKEN = $envVars["NORDVPN_TOKEN"]
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

Invoke-RestMethod -Uri $url -Headers $headers -Method Get

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
            TechnologyID   = $wireguardTech.id
            TechnologyName = $wireguardTech.name
            Identifier     = $wireguardTech.identifier
            CreatedAt      = $wireguardTech.created_at
            UpdatedAt      = $wireguardTech.updated_at
            PublicKey      = $publicKey
        }
    }
}

