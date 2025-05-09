# Simple-RoadmapInventory.ps1
# Script simplifié pour inventorier les fichiers de roadmap
# Version: 1.0
# Date: 2025-05-15

# Paramètres
$directories = @("projet/roadmaps", "development/roadmap")
$fileExtensions = @(".md")
$outputPath = "projet/roadmaps/analysis/inventory.json"

# Fonction de journalisation simplifiée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $color
}

# Fonction pour extraire les métadonnées d'un fichier markdown
function Get-MarkdownMetadata {
    param (
        [string]$FilePath
    )
    
    $metadata = @{
        Title = ""
        CreationDate = $null
        ModificationDate = $null
        TaskCount = 0
        CompletedTaskCount = 0
        CompletionRate = 0
        Sections = @()
    }
    
    try {
        # Obtenir les dates de création et modification
        $fileInfo = Get-Item -Path $FilePath
        $metadata.CreationDate = $fileInfo.CreationTime
        $metadata.ModificationDate = $fileInfo.LastWriteTime
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Extraire le titre (première ligne commençant par #)
        if ($content -match "^#\s+(.+)$") {
            $metadata.Title = $Matches[1].Trim()
        }
        
        # Compter les tâches (lignes avec cases à cocher)
        $taskMatches = [regex]::Matches($content, "\s*[-*+]\s*\[([ xX])\]")
        $metadata.TaskCount = $taskMatches.Count
        
        # Compter les tâches terminées (cases cochées)
        $completedMatches = [regex]::Matches($content, "\s*[-*+]\s*\[[xX]\]")
        $metadata.CompletedTaskCount = $completedMatches.Count
        
        # Calculer le taux de complétion
        if ($metadata.TaskCount -gt 0) {
            $metadata.CompletionRate = [math]::Round(($metadata.CompletedTaskCount / $metadata.TaskCount) * 100, 2)
        }
        
        # Extraire les sections (lignes commençant par ##)
        $sectionMatches = [regex]::Matches($content, "^##\s+(.+)$")
        foreach ($match in $sectionMatches) {
            $metadata.Sections += $match.Groups[1].Value.Trim()
        }
    }
    catch {
        Write-Log "Erreur lors de l'extraction des métadonnées de $FilePath : $_" -Level "Error"
    }
    
    return $metadata
}

# Fonction principale pour parcourir les dossiers et inventorier les fichiers
function Get-RoadmapFiles {
    param (
        [string[]]$Directories,
        [string[]]$FileExtensions
    )
    
    $results = @()
    
    foreach ($directory in $Directories) {
        Write-Log "Parcours du dossier $directory..." -Level "Info"
        
        if (-not (Test-Path -Path $directory)) {
            Write-Log "Le dossier $directory n'existe pas." -Level "Warning"
            continue
        }
        
        # Récupérer tous les fichiers avec les extensions spécifiées
        $files = Get-ChildItem -Path $directory -Recurse -File | Where-Object {
            $FileExtensions -contains $_.Extension
        }
        
        Write-Log "Trouvé $($files.Count) fichiers dans $directory" -Level "Info"
        
        foreach ($file in $files) {
            $fileInfo = [PSCustomObject]@{
                Path = $file.FullName
                RelativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
                Name = $file.Name
                Extension = $file.Extension
                Directory = $file.DirectoryName
                Size = $file.Length
                CreationTime = $file.CreationTime
                LastWriteTime = $file.LastWriteTime
                Content = Get-Content -Path $file.FullName -Raw
                Metadata = Get-MarkdownMetadata -FilePath $file.FullName
            }
            
            $results += $fileInfo
        }
    }
    
    return $results
}

# Exécution principale
try {
    Write-Log "Démarrage de l'inventaire des fichiers de roadmap..." -Level "Info"
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $outputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    $roadmapFiles = Get-RoadmapFiles -Directories $directories -FileExtensions $fileExtensions
    
    Write-Log "Inventaire terminé. $($roadmapFiles.Count) fichiers trouvés au total." -Level "Success"
    
    # Exporter les résultats
    $roadmapFiles | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
    Write-Log "Résultats exportés dans $outputPath" -Level "Success"
}
catch {
    Write-Log "Erreur lors de l'inventaire des fichiers : $_" -Level "Error"
}
