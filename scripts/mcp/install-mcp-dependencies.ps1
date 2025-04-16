# Script d'installation des dépendances MCP
# Ce script vérifie et installe les packages npm nécessaires pour les serveurs MCP

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Fonction pour vérifier si un package npm est installé
function Test-NpmPackageInstalled {
    param (
        [string]$PackageName
    )

    $result = npm list -g $PackageName 2>$null
    return $result -match $PackageName
}

# Fonction pour installer un package npm
function Install-NpmPackage {
    param (
        [string]$PackageName
    )

    Write-Log "Installation du package $PackageName..." -Level "INFO"
    try {
        $output = npm install -g $PackageName 2>&1

        # Vérifier si l'installation a échoué avec une erreur 404
        if ($output -match "404 Not Found" -or $output -match "E404") {
            Write-Log "Le package $PackageName n'existe pas dans le registre npm" -Level "ERROR"
            return $false
        }

        Write-Log "Installation de $PackageName réussie" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Échec de l'installation de $PackageName : $_" -Level "ERROR"
        return $false
    }
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      INSTALLATION DES DÉPENDANCES MCP EMAIL_SENDER_1     " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# Liste des packages MCP nécessaires
$mcpPackages = @(
    "@modelcontextprotocol/server-filesystem",
    "@modelcontextprotocol/server-github",
    "gcp-mcp",
    "supergateway"
    # Les packages suivants ne sont pas disponibles dans le registre npm standard
    # "augment-mcp",
    # "mcp-gdriv"
)

# Vérifier et installer les packages manquants
$installedCount = 0
$failedCount = 0

foreach ($package in $mcpPackages) {
    Write-Host "Vérification de $package..." -NoNewline

    if (Test-NpmPackageInstalled -PackageName $package) {
        Write-Host " INSTALLÉ" -ForegroundColor Green
        $installedCount++
    } else {
        Write-Host " NON INSTALLÉ" -ForegroundColor Yellow

        $success = Install-NpmPackage -PackageName $package
        if ($success) {
            $installedCount++
        } else {
            $failedCount++
        }
    }
}

# Résumé
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                  RÉSUMÉ DE L'INSTALLATION               " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Packages installés avec succès: $installedCount" -ForegroundColor Green
Write-Host "Packages avec échec d'installation: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failedCount -eq 0) {
    Write-Host "Toutes les dépendances MCP sont installées correctement." -ForegroundColor Green
    Write-Host "Vous pouvez maintenant démarrer les serveurs MCP avec le script 'start-all-mcp-servers.cmd'." -ForegroundColor Green
} else {
    Write-Host "Certaines dépendances n'ont pas pu être installées." -ForegroundColor Red
    Write-Host "Veuillez résoudre les problèmes ci-dessus avant de démarrer les serveurs MCP." -ForegroundColor Red
}

Write-Host ""
