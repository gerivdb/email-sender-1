# Move-RoadmapFiles.ps1
# Script pour déplacer les fichiers de roadmap de la racine vers le dossier consolidated
# Version: 1.0
# Date: 2025-05-17

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans",
    
    [Parameter(Mandatory = $false)]
    [string]$DestinationPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\consolidated",
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\reports\roadmap-files-moved.md",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction de journalisation
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

# Fonction pour déplacer les fichiers
function Move-Files {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    # Vérifier que les chemins existent
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Log "Le chemin source n'existe pas: $SourcePath" -Level "Error"
        return $null
    }
    
    if (-not (Test-Path -Path $DestinationPath)) {
        Write-Log "Création du dossier de destination: $DestinationPath" -Level "Info"
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }
    
    # Obtenir la liste des fichiers markdown à la racine
    $files = Get-ChildItem -Path $SourcePath -Filter "*.md" | Where-Object { $_.DirectoryName -eq $SourcePath }
    
    if ($files.Count -eq 0) {
        Write-Log "Aucun fichier markdown trouvé à la racine du dossier: $SourcePath" -Level "Warning"
        return $null
    }
    
    Write-Log "Nombre de fichiers à déplacer: $($files.Count)" -Level "Info"
    
    $movedFiles = @()
    
    # Déplacer chaque fichier
    foreach ($file in $files) {
        $destinationFile = Join-Path -Path $DestinationPath -ChildPath $file.Name
        
        try {
            Move-Item -Path $file.FullName -Destination $destinationFile -Force:$Force
            Write-Log "Fichier déplacé: $($file.Name)" -Level "Success"
            
            $movedFiles += [PSCustomObject]@{
                Name = $file.Name
                OriginalPath = $file.FullName
                NewPath = $destinationFile
                Size = $file.Length
                LastModified = $file.LastWriteTime
            }
        } catch {
            Write-Log "Erreur lors du déplacement du fichier $($file.Name): $_" -Level "Error"
        }
    }
    
    return $movedFiles
}

# Fonction pour mettre à jour les références dans les fichiers
function Update-References {
    param (
        [array]$MovedFiles,
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    $updatedFiles = @()
    
    foreach ($file in $MovedFiles) {
        $content = Get-Content -Path $file.NewPath -Raw
        $modified = $false
        
        # Rechercher les références relatives aux fichiers markdown
        $matches = [regex]::Matches($content, '\[.*?\]\((.*?\.md)\)')
        
        foreach ($match in $matches) {
            $reference = $match.Groups[1].Value
            
            # Si la référence est relative et pointe vers un fichier à la racine
            if ($reference -match '^\.?\/?' -and -not ($reference -match '^\.\.\/')) {
                $referencedFileName = Split-Path -Path $reference -Leaf
                $newReference = "../consolidated/$referencedFileName"
                
                # Remplacer la référence dans le contenu
                $content = $content -replace [regex]::Escape($reference), $newReference
                $modified = $true
                
                Write-Log "Référence mise à jour dans $($file.Name): $reference -> $newReference" -Level "Info"
            }
        }
        
        # Enregistrer le fichier si des modifications ont été apportées
        if ($modified) {
            Set-Content -Path $file.NewPath -Value $content
            Write-Log "Fichier mis à jour avec les nouvelles références: $($file.Name)" -Level "Success"
            $updatedFiles += $file.Name
        }
    }
    
    return $updatedFiles
}

# Fonction pour générer un rapport
function New-Report {
    param (
        [array]$MovedFiles,
        [array]$UpdatedFiles,
        [string]$ReportPath
    )
    
    $reportContent = @"
# Rapport de déplacement des fichiers de roadmap
*Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## Résumé

- **Nombre de fichiers déplacés**: $($MovedFiles.Count)
- **Nombre de fichiers avec références mises à jour**: $($UpdatedFiles.Count)
- **Source**: `$SourcePath`
- **Destination**: `$DestinationPath`

## Liste des fichiers déplacés

| Nom du fichier | Taille (octets) | Dernière modification |
|----------------|-----------------|------------------------|
"@
    
    foreach ($file in $MovedFiles) {
        $reportContent += "`n| $($file.Name) | $($file.Size) | $($file.LastModified) |"
    }
    
    $reportContent += @"

## Fichiers avec références mises à jour

"@
    
    if ($UpdatedFiles.Count -gt 0) {
        foreach ($file in $UpdatedFiles) {
            $reportContent += "- $file`n"
        }
    } else {
        $reportContent += "Aucun fichier n'a nécessité de mise à jour des références.`n"
    }
    
    # Créer le dossier du rapport si nécessaire
    $reportFolder = Split-Path -Path $ReportPath -Parent
    if (-not (Test-Path -Path $reportFolder)) {
        New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    Set-Content -Path $ReportPath -Value $reportContent
    
    Write-Log "Rapport généré: $ReportPath" -Level "Success"
}

# Fonction principale
function Main {
    Write-Log "Démarrage du déplacement des fichiers de roadmap..." -Level "Info"
    
    # Déplacer les fichiers
    $movedFiles = Move-Files -SourcePath $SourcePath -DestinationPath $DestinationPath
    
    if ($null -eq $movedFiles -or $movedFiles.Count -eq 0) {
        Write-Log "Aucun fichier n'a été déplacé. Fin du script." -Level "Warning"
        return
    }
    
    # Mettre à jour les références
    $updatedFiles = Update-References -MovedFiles $movedFiles -SourcePath $SourcePath -DestinationPath $DestinationPath
    
    # Générer un rapport
    New-Report -MovedFiles $movedFiles -UpdatedFiles $updatedFiles -ReportPath $ReportPath
    
    Write-Log "Déplacement des fichiers de roadmap terminé." -Level "Success"
}

# Exécuter la fonction principale
Main
