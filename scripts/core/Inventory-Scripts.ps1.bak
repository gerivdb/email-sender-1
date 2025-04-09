<#
.SYNOPSIS
    Inventaire des scripts du projet
.DESCRIPTION
    Ce script scanne récursivement les répertoires pour trouver tous les scripts
    et extraire leurs métadonnées.
.PARAMETER Path
    Chemin du répertoire à scanner (par défaut : répertoire courant)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par défaut : inventory.json)
.PARAMETER Verbose
    Affiche des informations détaillées
.EXAMPLE
    .\Inventory-Scripts.ps1
    Effectue un inventaire des scripts dans le répertoire courant
.EXAMPLE
    .\Inventory-Scripts.ps1 -Path scripts\maintenance -OutputPath maintenance-inventory.json
    Effectue un inventaire des scripts dans le répertoire scripts\maintenance
#>

param (
    [string]$Path = ".",
    [string]$OutputPath = "..\D"
)

# Créer le dossier de sortie s'il n'existe pas
$OutputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Dossier créé: $OutputDir" -ForegroundColor Green
}

# Fonction pour extraire les métadonnées d'un script
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
    
    # Initialiser l'objet de métadonnées
    $Metadata = @{
        Author = ""
        Description = ""
        Version = ""
        Tags = @()
        Dependencies = @()
    }
    
    # Extraire les métadonnées en fonction du type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^#\s*Author\s*:\s*(.+?)$|^#\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (première ligne de commentaire ou bloc de commentaires)
            if ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = $matches[1].Trim()
            }
            
            # Extraire les tags (commentaires avec Tags ou Mots-clés)
            if ($Content -match '(?m)^#\s*Tags\s*:\s*(.+?)$|^#\s*Mots-clés\s*:\s*(.+?)$') {
                $TagsString = if ($matches[1]) { $matches[1] } else { $matches[2] }
                $Metadata.Tags = $TagsString -split ',' | ForEach-Object { $_.Trim() }
            }
            
            # Extraire les dépendances (Import-Module, . source, etc.)
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
            
            # Extraire la description (docstring ou première ligne de commentaire)
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
            
            # Extraire les dépendances (import, from ... import)
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
            
            # Extraire la description (première ligne de commentaire)
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
            
            # Extraire la description (première ligne de commentaire)
            if ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = $matches[1].Trim()
            }
            
            # Extraire les dépendances (source, ., etc.)
            $ImportMatches = [regex]::Matches($Content, '(?m)^source\s+(.+?)$|^\.\s+(.+?)$')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
                $Metadata.Dependencies += $Dependency.Trim()
            }
        }
    }
    
    return $Metadata
}

# Afficher la bannière
Write-Host "=== Inventaire des scripts ===" -ForegroundColor Cyan
Write-Host "Répertoire: $Path" -ForegroundColor Yellow
Write-Host "Fichier de sortie: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Liste des extensions de scripts à rechercher
$ScriptExtensions = @(
    ".ps1",  # PowerShell
    ".py",   # Python
    ".cmd",  # Batch Windows
    ".bat",  # Batch Windows
    ".sh"    # Shell Unix
)

# Récupérer tous les fichiers avec les extensions spécifiées
$AllFiles = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
    $_.Extension -in $ScriptExtensions
}

Write-Host "Nombre de scripts trouvés: $($AllFiles.Count)" -ForegroundColor Cyan

# Créer un tableau pour stocker les informations sur les scripts
$ScriptsInfo = @()

# Traiter chaque fichier
$Counter = 0
$Total = $AllFiles.Count

foreach ($File in $AllFiles) {
    $Counter++
    $Progress = [math]::Round(($Counter / $Total) * 100)
    Write-Progress -Activity "Traitement des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
    
    # Déterminer le type de script en fonction de l'extension
    $ScriptType = switch ($File.Extension) {
        ".ps1" { "PowerShell" }
        ".py"  { "Python" }
        ".cmd" { "Batch" }
        ".bat" { "Batch" }
        ".sh"  { "Shell" }
        default { "Unknown" }
    }
    
    # Extraire les métadonnées du script
    $Metadata = Get-ScriptMetadata -FilePath $File.FullName -ScriptType $ScriptType
    
    # Créer un objet avec les informations du script
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

# Créer un objet avec les informations de l'inventaire
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
Write-Host "=== Inventaire terminé ===" -ForegroundColor Green
Write-Host "Nombre total de scripts: $($Inventory.TotalScripts)" -ForegroundColor Cyan

# Afficher les statistiques par type de script
Write-Host ""
Write-Host "Statistiques par type de script:" -ForegroundColor Yellow
foreach ($TypeStat in $Inventory.ScriptsByType) {
    Write-Host "- $($TypeStat.Type): $($TypeStat.Count) script(s)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Résultats enregistrés dans: $OutputPath" -ForegroundColor Green

