<#
.SYNOPSIS
    Inventaire des scripts du projet
.DESCRIPTION
    Ce script scanne rÃ©cursivement les rÃ©pertoires pour trouver tous les scripts
    et extraire leurs mÃ©tadonnÃ©es.
.PARAMETER Path
    Chemin du rÃ©pertoire Ã  scanner (par dÃ©faut : rÃ©pertoire courant)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par dÃ©faut : inventory.json)
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es
.EXAMPLE
    .\Inventory-Scripts.ps1
    Effectue un inventaire des scripts dans le rÃ©pertoire courant
.EXAMPLE
    .\Inventory-Scripts.ps1 -Path scripts\maintenance -OutputPath maintenance-inventory.json
    Effectue un inventaire des scripts dans le rÃ©pertoire scripts\maintenance

<#
.SYNOPSIS
    Inventaire des scripts du projet
.DESCRIPTION
    Ce script scanne rÃ©cursivement les rÃ©pertoires pour trouver tous les scripts
    et extraire leurs mÃ©tadonnÃ©es.
.PARAMETER Path
    Chemin du rÃ©pertoire Ã  scanner (par dÃ©faut : rÃ©pertoire courant)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par dÃ©faut : inventory.json)
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es
.EXAMPLE
    .\Inventory-Scripts.ps1
    Effectue un inventaire des scripts dans le rÃ©pertoire courant
.EXAMPLE
    .\Inventory-Scripts.ps1 -Path scripts\maintenance -OutputPath maintenance-inventory.json
    Effectue un inventaire des scripts dans le rÃ©pertoire scripts\maintenance
#>

param (
    [string]$Path = ".",
    [string]$OutputPath = "..\D"
)

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
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal


# CrÃ©er le dossier de sortie s'il n'existe pas
$OutputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Dossier crÃ©Ã©: $OutputDir" -ForegroundColor Green
}

# Fonction pour extraire les mÃ©tadonnÃ©es d'un script
function Get-ScriptMetadata {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    # Lire le contenu du fichier
    $Content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if ($null -eq $Content) {
        return @{
            Author = ""
            Description = ""
            Version = ""
            Tags = @()
            Dependencies = @()
        }
    }
    
    # Initialiser l'objet de mÃ©tadonnÃ©es
    $Metadata = @{
        Author = ""
        Description = ""
        Version = ""
        Tags = @()
        Dependencies = @()
    }
    
    # Extraire les mÃ©tadonnÃ©es en fonction du type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^#\s*Author\s*:\s*(.+?)$|^#\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (premiÃ¨re ligne de commentaire ou bloc de commentaires)
            if ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = $matches[1].Trim()
            }
            
            # Extraire les tags (commentaires avec Tags ou Mots-clÃ©s)
            if ($Content -match '(?m)^#\s*Tags\s*:\s*(.+?)$|^#\s*Mots-clÃ©s\s*:\s*(.+?)$') {
                $TagsString = if ($matches[1]) { $matches[1] } else { $matches[2] }
                $Metadata.Tags = $TagsString -split ',' | ForEach-Object { $_.Trim() }
            }
            
            # Extraire les dÃ©pendances (Import-Module, . source, etc.)
            $ImportMatches = [regex]::Matches($Content, '(?m)^Import-Module\s+(.+?)$|^\.\s+(.+?)$')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
                $Metadata.Dependencies += $Dependency.Trim()
            }
        }
        "Python" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^#\s*Author\s*:\s*(.+?)$|^#\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (docstring ou premiÃ¨re ligne de commentaire)
            if ($Content -match '"""(.+?)"""' -or $Content -match "'''(.+?)'''") {
                $Metadata.Description = $matches[1].Trim()
            }
            elseif ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$|^__version__\s*=\s*[''"](.+?)[''"]') {
                $Metadata.Version = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire les tags
            if ($Content -match '(?m)^#\s*Tags\s*:\s*(.+?)$') {
                $TagsString = $matches[1]
                $Metadata.Tags = $TagsString -split ',' | ForEach-Object { $_.Trim() }
            }
            
            # Extraire les dÃ©pendances (import, from ... import)
            $ImportMatches = [regex]::Matches($Content, '(?m)^import\s+(.+?)$|^from\s+(.+?)\s+import')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
                $Metadata.Dependencies += $Dependency.Trim()
            }
        }
        "Batch" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^rem\s*Author\s*:\s*(.+?)$|^rem\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (premiÃ¨re ligne de commentaire)
            if ($Content -match '(?m)^rem\s*(.+?)$|^::\s*(.+?)$') {
                $Metadata.Description = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la version
            if ($Content -match '(?m)^rem\s*Version\s*:\s*(.+?)$|^::\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
        }
        "Shell" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^#\s*Author\s*:\s*(.+?)$|^#\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (premiÃ¨re ligne de commentaire)
            if ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = $matches[1].Trim()
            }
            
            # Extraire les dÃ©pendances (source, ., etc.)
            $ImportMatches = [regex]::Matches($Content, '(?m)^source\s+(.+?)$|^\.\s+(.+?)$')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
                $Metadata.Dependencies += $Dependency.Trim()
            }
        }
    }
    
    return $Metadata
}

# Afficher la banniÃ¨re
Write-Host "=== Inventaire des scripts ===" -ForegroundColor Cyan
Write-Host "RÃ©pertoire: $Path" -ForegroundColor Yellow
Write-Host "Fichier de sortie: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Liste des extensions de scripts Ã  rechercher
$ScriptExtensions = @(
    ".ps1",  # PowerShell
    ".py",   # Python
    ".cmd",  # Batch Windows
    ".bat",  # Batch Windows
    ".sh"    # Shell Unix
)

# RÃ©cupÃ©rer tous les fichiers avec les extensions spÃ©cifiÃ©es
$AllFiles = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
    $_.Extension -in $ScriptExtensions
}

Write-Host "Nombre de scripts trouvÃ©s: $($AllFiles.Count)" -ForegroundColor Cyan

# CrÃ©er un tableau pour stocker les informations sur les scripts
$ScriptsInfo = @()

# Traiter chaque fichier
$Counter = 0
$Total = $AllFiles.Count

foreach ($File in $AllFiles) {
    $Counter++
    $Progress = [math]::Round(($Counter / $Total) * 100)
    Write-Progress -Activity "Traitement des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
    
    # DÃ©terminer le type de script en fonction de l'extension
    $ScriptType = switch ($File.Extension) {
        ".ps1" { "PowerShell" }
        ".py"  { "Python" }
        ".cmd" { "Batch" }
        ".bat" { "Batch" }
        ".sh"  { "Shell" }
        default { "Unknown" }
    }
    
    # Extraire les mÃ©tadonnÃ©es du script
    $Metadata = Get-ScriptMetadata -FilePath $File.FullName -ScriptType $ScriptType
    
    # CrÃ©er un objet avec les informations du script
    $ScriptInfo = [PSCustomObject]@{
        Path = $File.FullName
        Name = $File.Name
        Directory = $File.DirectoryName
        Extension = $File.Extension
        Type = $ScriptType
        Size = $File.Length
        CreationTime = $File.CreationTime
        LastWriteTime = $File.LastWriteTime
        Metadata = $Metadata
    }
    
    # Ajouter l'objet au tableau
    $ScriptsInfo += $ScriptInfo
}

Write-Progress -Activity "Traitement des scripts" -Completed

# CrÃ©er un objet avec les informations de l'inventaire
$Inventory = [PSCustomObject]@{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalScripts = $ScriptsInfo.Count
    ScriptsByType = $ScriptsInfo | Group-Object -Property Type | ForEach-Object {
        [PSCustomObject]@{
            Type = $_.Name
            Count = $_.Count
        }
    }
    Scripts = $ScriptsInfo
}

# Convertir l'objet en JSON et l'enregistrer dans un fichier
$Inventory | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath

Write-Host ""
Write-Host "=== Inventaire terminÃ© ===" -ForegroundColor Green
Write-Host "Nombre total de scripts: $($Inventory.TotalScripts)" -ForegroundColor Cyan

# Afficher les statistiques par type de script
Write-Host ""
Write-Host "Statistiques par type de script:" -ForegroundColor Yellow
foreach ($TypeStat in $Inventory.ScriptsByType) {
    Write-Host "- $($TypeStat.Type): $($TypeStat.Count) script(s)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "RÃ©sultats enregistrÃ©s dans: $OutputPath" -ForegroundColor Green


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
