#Requires -RunAsAdministrator

# Create a PSDrive for accessing the registry
try {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction Stop | Out-Null
} catch {
    Write-Output "Error creating PSDrive: $_"
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
        "${keyPath}OpenWithMobaXterm",
        "${keyPath}MobaDiff",
        "${keyPath}OpenWithMobaFind"
    )

    foreach ($keyToRemove in $keysToRemove) {
        Write-Output "Checking $keyToRemove"
        if (Test-Path $keyToRemove) {
            Remove-Item -Path $keyToRemove -Recurse -Force
            Write-Output "Removed $keyToRemove"
        }
    }
}
