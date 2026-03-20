# Self-elevate if not running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    exit
}

# Create a PSDrive for accessing the registry
try {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Error creating PSDrive: $_" -ForegroundColor Red
    return
}

# Define the registry key paths to remove
$keyPaths = @(
    'HKLM:\SOFTWARE\Classes\Directory\background\shell\',
    'HKLM:\SOFTWARE\Classes\Directory\shell\',
    'HKLM:\SOFTWARE\Classes\LibraryFolder\background\shell\',
    'HKCR:\Directory\Background\shell\',
    'HKCR:\Directory\shell\',
    'HKCR:\LibraryFolder\background\shell\'
)

# Remove Git and Mobaxterm related registry keys
foreach ($keyPath in $keyPaths) {
    $keysToRemove = @(
        "${keyPath}git_gui",
        "${keyPath}git_shell",
        "${keyPath}MobaXterm",
        "${keyPath}OpenWithMobaXterm",
        "${keyPath}MobaDiff",
        "${keyPath}OpenWithMobaFind"
    )

    foreach ($keyToRemove in $keysToRemove) {
        Write-Host "Checking $keyToRemove" -ForegroundColor DarkGray
        if (Test-Path $keyToRemove) {
            Remove-Item -Path $keyToRemove -Recurse -Force
            Write-Host "Removed $keyToRemove" -ForegroundColor Green
        }
    }
}
