# Module d'inventaire pour le Script Manager
# Ce module permet de scanner récursivement les répertoires pour trouver tous les scripts
# et extraire leurs métadonnées
# Author: Script Manager
# Version: 2.0
# Tags: inventory, scripts, manager

function Invoke-ScriptInventory {
    <#
    .SYNOPSIS
        Effectue un inventaire des scripts dans un répertoire.
    .DESCRIPTION
        Scanne récursivement un répertoire pour trouver tous les scripts
        et extraire leurs métadonnées.
    .PARAMETER Path
        Chemin du répertoire à scanner.
    .PARAMETER OutputPath
        Chemin du fichier de sortie pour le rapport d'inventaire.
    .PARAMETER Extensions
        Liste des extensions de fichiers à rechercher.
    .PARAMETER Verbose
        Affiche des informations détaillées pendant l'exécution.
    .EXAMPLE
        Invoke-ScriptInventory -Path "scripts" -OutputPath "inventory.json"
        Effectue un inventaire des scripts dans le dossier "scripts" et enregistre le rapport dans "inventory.json".
    #>
    param (
        [string]$Path = ".",
        [string]$OutputPath = "inventory.json",
        [string[]]$Extensions = @("*.ps1", "*.py", "*.cmd", "*.bat", "*.sh"),
        [switch]$Verbose
    )
    
    Write-Host "Démarrage de l'inventaire des scripts dans: $Path" -ForegroundColor Cyan
    
    # Récupérer tous les fichiers avec les extensions spécifiées
    $AllFiles = @()
    foreach ($Extension in $Extensions) {
        $AllFiles += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
    }
    
    Write-Host "Nombre de scripts trouvés: $($AllFiles.Count)" -ForegroundColor Cyan
    
    # Créer un tableau pour stocker les informations sur les scripts
    $ScriptsInfo = @()
    
    # Traiter chaque fichier
    foreach ($File in $AllFiles) {
        if ($Verbose) {
            Write-Host "Traitement du fichier: $($File.FullName)" -ForegroundColor Cyan
        }
        
        # Déterminer le type de script en fonction de l'extension
        $ScriptType = switch ($File.Extension) {
            ".ps1" { "PowerShell" }
            ".psm1" { "PowerShell" }
            ".psd1" { "PowerShell" }
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
    
    Write-Host "Inventaire terminé. Résultats enregistrés dans: $OutputPath" -ForegroundColor Green
    
    return $Inventory
}

function Get-ScriptMetadata {
    <#
    .SYNOPSIS
        Extrait les métadonnées d'un script.
    .DESCRIPTION
        Analyse le contenu d'un script pour extraire ses métadonnées
        (auteur, description, version, tags, dépendances).
    .PARAMETER FilePath
        Chemin du fichier à analyser.
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell).
    .EXAMPLE
        Get-ScriptMetadata -FilePath "script.ps1" -ScriptType "PowerShell"
        Extrait les métadonnées du script PowerShell "script.ps1".
    #>
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    # Lire le contenu du fichier
    $Content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if ([string]::IsNullOrEmpty($Content)) {
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
            if ($Content -match '<#[\s\S]*?\.DESCRIPTION\s*([\s\S]*?)(\r?\n\s*\.[A-Za-z]|\r?\n\s*#>)') {
                $Metadata.Description = $matches[1].Trim()
            }
            elseif ($Content -match '(?m)^#\s*(.+?)$') {
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
            $ImportMatches = [regex]::Matches($Content, '(?m)^Import-Module\s+(.+?)($|\s)|^\.\s+(.+?)($|\s)')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[3].Value }
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
            if ($Content -match '(?m)^rem\s*Author\s*:\s*(.+?)$|^rem\s*par\s*:\s*(.+?)$|^::\s*Author\s*:\s*(.+?)$|^::\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = ($matches[1] -or $matches[2] -or $matches[3] -or $matches[4]).Trim()
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

# Exporter les fonctions du module
Export-ModuleMember -Function Invoke-ScriptInventory, Get-ScriptMetadata
