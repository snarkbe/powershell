<#
.SYNOPSIS
    Ajoute un fichier .torrent à une instance distante de qBittorrent via son API Web.
.DESCRIPTION
    Ce script prend le chemin d'un fichier .torrent en argument et le téléverse
    vers l'API de qBittorrent spécifiée.
    Il gère l'authentification par nom d'utilisateur/mot de passe.
    À associer aux fichiers .torrent dans l'explorateur Windows.
.PARAMETER torrent
    Chemin complet vers le fichier .torrent à ajouter. Obligatoire.
.EXAMPLE
    .\Add-TorrentToQbittorrent.ps1 -torrent "C:\Downloads\mon_fichier.torrent"
.EXAMPLE
    # Via l'association de fichier (Windows passe le chemin en argument)
    powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Add-TorrentToQbittorrent.ps1" "%1"
.NOTES
    Auteur     : Gilles Reichert
    Date       : 2025-04-13
    Version API: qBittorrent Web API v2
#>
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$torrent
)

# Load configuration from JSON file
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "qBittorrentConfig.json"

if (-not (Test-Path $configFilePath)) {
    Write-Error "Erreur : Fichier de configuration introuvable à '$configFilePath'."
    exit 1
}

try {
    $config = Get-Content -Path $configFilePath | ConvertFrom-Json
} catch {
    Write-Error "Erreur : Impossible de lire ou de parser le fichier de configuration. $_"
    exit 1
}

# Assign configuration values
$qbtHost = $config.qbtHost
$qbtPort = $config.qbtPort
$qbtUser = $config.qbtUser
$qbtPassword = $config.qbtPassword
$useHttps = $config.useHttps

# --- Paramètres d'ajout optionnels (décommentez et ajustez si besoin) ---
# $savePath = "D:\Torrents\Terminés"   # Chemin de sauvegarde sur la machine qBittorrent
# $category = "Films"                 # Catégorie à assigner
# $paused = "false"                   # Ajouter en pause ? "true" ou "false" (chaîne de caractères)
# $sequential = "false"               # Téléchargement séquentiel ? "true" ou "false"
# $firstLastPiecePrio = "false"       # Prioriser première/dernière pièce ? "true" ou "false"

# --- Logique du Script ---

# Validation simple du fichier
if (-not (Test-Path $torrent -PathType Leaf)) {
    Write-Error "Erreur : Fichier torrent introuvable à '$torrent'"
    # Pause pour voir l'erreur si lancé par double-clic
    if ($Host.Name -eq "ConsoleHost") { Read-Host "Appuyez sur Entrée pour quitter" }
    exit 1
}
if ($torrent -notlike "*.torrent") {
    Write-Warning "Attention : Le fichier '$torrent' ne semble pas être un fichier .torrent."
    # On continue quand même au cas où...
}

# Construction de l'URL de base
$protocol = if ($useHttps) { "https" } else { "http" }
$baseUrl = "${protocol}://$qbtHost`:$qbtPort"
$addUrl = "$baseUrl/api/v2/torrents/add"

# Chemin vers curl (généralement dans le PATH sur Windows 10+)
$curlExe = "curl.exe"

# Préparer les arguments pour curl
$curlArgs = @(
    "-s", "-S" # Mode silencieux mais affiche les erreurs
    "--fail", # Échoue silencieusement sur erreur HTTP
    #"-v", # Mode verbeux (pour le débogage, à retirer en production)
    "-k", # Ignorer les erreurs de certificat SSL (si HTTPS)
    # Option -F pour multipart/form-data: 'nom_champ=@chemin_fichier;type=mime_type'
    # Assurez-vous que le chemin est bien quoté s'il contient des espaces
    "-F", "torrents=@`"$torrent`";type=application/x-bittorrent"
)

# Ajouter les paramètres optionnels (si configurés)
# if ($savePath) { $curlArgs += "-F", "savepath=$savePath" }
# if ($category) { $curlArgs += "-F", "category=$category" }
# if ($paused)   { $curlArgs += "-F", "paused=$paused" }

# Gérer l'authentification pour curl
$cookieFile = Join-Path -Path '.' -ChildPath "qbt_cookie.txt" # Fichier temporaire pour le cookie

try {
    Write-Host "Tentative d'ajout via curl : $torrent vers $addUrl"

    # Méthode User/Pass avec curl (obtention du cookie SID)
    Write-Host "Utilisation de l'authentification par Nom d'utilisateur/Mot de passe avec curl."
    $loginUrl = "$baseUrl/api/v2/auth/login"
    $loginData = "username=$($qbtUser)&password=$($qbtPassword)"

    # -c $cookieFile : Sauvegarde les cookies reçus dans le fichier
    # -d : Données POST
    # --fail : Échoue silencieusement sur erreur HTTP (pour vérifier après)
    $loginCurlArgs = @(
            "-s", "--fail",
            #"-v", # Mode verbeux (pour le débogage, à retirer en production)
            "-k", # Ignorer les erreurs de certificat SSL (si HTTPS)
            "-c", "$cookieFile", # Sauvegarder le cookie
            "--data-binary", "`"$loginData`"", # Envoyer comme data
            "-H", "`"Content-Type: application/x-www-form-urlencoded`"",
            "$loginUrl"
    )
    # Write-Host "Exécution de curl pour la connexion...: $loginCurlArgs"
    & $curlExe $loginCurlArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Échec de la connexion curl à qBittorrent (Code: $LASTEXITCODE). Vérifiez URL, user, pass."
    }
    # Vérifier si le fichier cookie a été créé et contient quelque chose
    if (-not (Test-Path $cookieFile) -or (Get-Item $cookieFile).Length -lt 10) {
            throw "Échec de la connexion à qBittorrent (cookie non reçu/vide)."
    }
    Write-Host "Cookie de session obtenu."
    # -b $cookieFile : Lit les cookies depuis le fichier pour la requête suivante
    $curlArgs += "-b", $cookieFile

    # Ajouter l'URL finale aux arguments curl
    $curlArgs += $addUrl

    # Exécuter la commande curl pour l'upload
    Write-Host "Exécution de curl pour l'upload..."
    # Write-Host "$curlExe $($curlArgs -join ' ')" # Décommentez pour voir la commande curl complète
    $uploadOutput = & $curlExe $curlArgs 2>&1 # Redirige stderr vers stdout pour capturer les erreurs curl
    $curlExitCode = $LASTEXITCODE

    # Vérifier le résultat
    if ($curlExitCode -eq 0 -and $uploadOutput -match "Ok.") {
         Write-Host "Succès (via curl) : Torrent '$([System.IO.Path]::GetFileName($torrent))' ajouté à qBittorrent."
    } else {
        throw "Échec de l'upload curl. Code: $curlExitCode. Sortie: $uploadOutput"
    }

} catch {
    Write-Error "Une erreur est survenue : $($_.Exception.Message)"
    # Pause pour voir l'erreur si lancé par double-clic
    if ($Host.Name -eq "ConsoleHost") { Read-Host "Appuyez sur Entrée pour quitter" }
    exit 1
} finally {
    # Nettoyer le fichier cookie si User/Pass a été utilisé
    if (Test-Path $cookieFile) {
        Remove-Item $cookieFile -ErrorAction SilentlyContinue
    }

exit 0