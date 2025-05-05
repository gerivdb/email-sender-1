


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
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal
# Script pour verifier l'integrite de la structure du projet

Write-Host "=== Verification de l'integrite de la structure du projet ===" -ForegroundColor Cyan

# Structure de dossiers attendue
$expectedFolders = @(
    "src",
    "src/workflows",
    "src/mcp",
    "src/mcp/batch",
    "src/mcp/config",
    "scripts",
    "development/scripts/setup",
    "development/scripts/maintenance",
    "config",
    "logs",
    "docs",
    "docs/guides",
    "docs/api",
    "tests",
    "tools",
    "assets"
)

# Verifier si les dossiers existent
$missingFolders = @()
foreach ($folder in $expectedFolders) {
    if (-not (Test-Path ".\$folder")) {
        $missingFolders += $folder
    }
}

if ($missingFolders.Count -eq 0) {
    Write-Host "Tous les dossiers attendus existent" -ForegroundColor Green
} else {
    Write-Host "Les dossiers suivants sont manquants:" -ForegroundColor Red
    foreach ($folder in $missingFolders) {
        Write-Host "- $folder" -ForegroundColor Red
    }
    
    Write-Host "`nVoulez-vous creer les dossiers manquants ? (O/N)" -ForegroundColor Yellow
    $createFolders = Read-Host
    
    if ($createFolders -eq "O" -or $createFolders -eq "o") {
        foreach ($folder in $missingFolders) {
            New-Item -ItemType Directory -Path ".\$folder" -Force | Out-Null
            Write-Host "Dossier $folder cree" -ForegroundColor Green
        }
    }
}

# Fichiers essentiels a verifier
$essentialFiles = @(
    @{Path = ".\README.md"; Description = "Fichier README principal"},
    @{Path = "..\..\D"; Description = "Fichier batch MCP Standard"},
    @{Path = "..\..\D"; Description = "Fichier batch MCP Notion"},
    @{Path = "..\mcp\gateway.exe.cmd"; Description = "Fichier batch MCP Gateway"},
    @{Path = "..\..\D"; Description = "Fichier batch MCP Git Ingest"},
    @{Path = "..\..\D"; Description = "Script de demarrage n8n"},
    @{Path = "..\..\D"; Description = "Script d'organisation automatique"},
    @{Path = "..\..\D"; Description = "Script de creation de fichiers"}
)

# Verifier si les fichiers essentiels existent
$missingFiles = @()
foreach ($file in $essentialFiles) {
    if (-not (Test-Path $file.Path)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host "`nTous les fichiers essentiels existent" -ForegroundColor Green
} else {
    Write-Host "`nLes fichiers essentiels suivants sont manquants:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "- $($file.Path) ($($file.Description))" -ForegroundColor Red
    }
}

# Verifier les workflows
$workflowFiles = Get-ChildItem -Path ".\src\workflows" -Filter "*.json" -File -ErrorAction SilentlyContinue

if ($workflowFiles -eq $null -or $workflowFiles.Count -eq 0) {
    Write-Host "`nAucun workflow n'a ete trouve dans le dossier src/workflows" -ForegroundColor Red
} else {
    Write-Host "`n$($workflowFiles.Count) workflows trouves dans le dossier src/workflows" -ForegroundColor Green
}

# Verifier les fichiers de documentation
$docFiles = Get-ChildItem -Path ".\docs\guides" -Filter "*.md" -File -ErrorAction SilentlyContinue

if ($docFiles -eq $null -or $docFiles.Count -eq 0) {
    Write-Host "`nAucun fichier de documentation n'a ete trouve dans le dossier docs/guides" -ForegroundColor Red
} else {
    Write-Host "`n$($docFiles.Count) fichiers de documentation trouves dans le dossier docs/guides" -ForegroundColor Green
}

# Verifier les fichiers a la racine
$rootFiles = Get-ChildItem -Path "." -File | Where-Object { $_.Name -ne "README.md" -and $_.Name -ne ".gitignore" }

if ($rootFiles -ne $null -and $rootFiles.Count -gt 0) {
    Write-Host "`nAttention: $($rootFiles.Count) fichiers sont encore presents a la racine du projet:" -ForegroundColor Yellow
    foreach ($file in $rootFiles) {
        Write-Host "- $($file.Name)" -ForegroundColor Yellow
    }
    
    Write-Host "`nVoulez-vous executer le script d'organisation automatique pour deplacer ces fichiers ? (O/N)" -ForegroundColor Yellow
    $organizeFiles = Read-Host
    
    if ($organizeFiles -eq "O" -or $organizeFiles -eq "o") {
        & "..\..\D"
    }
}

Write-Host "`n=== Verification terminee ===" -ForegroundColor Cyan


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
