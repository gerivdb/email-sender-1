# Script pour mettre à jour les références dans les fichiers de roadmap
# Ce script met à jour les chemins dans les fichiers de roadmap pour qu'ils pointent vers les nouveaux emplacements

# Configuration
$roadmapFiles = @(
    "Roadmap\roadmap_perso.md",
    "Roadmap\roadmap_perso_fixed.md"
)
$oldPath = "docs\roadmap_management"
$newPath = "Roadmap\scripts"

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
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# Fonction pour mettre à jour les références dans un fichier
function Update-References {
    param (
        [string]$FilePath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Log "Le fichier n'existe pas: $FilePath" "ERROR"
        return $false
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Remplacer les références
    $updatedContent = $content -replace [regex]::Escape($oldPath), $newPath
    
    # Vérifier si des modifications ont été apportées
    if ($updatedContent -ne $content) {
        # Sauvegarder le fichier original
        $backupPath = "$FilePath.bak"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        
        # Écrire le contenu mis à jour
        Set-Content -Path $FilePath -Value $updatedContent -Encoding UTF8
        
        Write-Log "Références mises à jour dans: $FilePath" "SUCCESS"
        Write-Log "Sauvegarde créée: $backupPath" "INFO"
        
        return $true
    }
    else {
        Write-Log "Aucune référence à mettre à jour dans: $FilePath" "INFO"
        return $false
    }
}

# Fonction pour mettre à jour les références dans les scripts
function Update-ScriptReferences {
    param (
        [string]$FolderPath
    )
    
    # Obtenir tous les fichiers PowerShell dans le dossier
    $scripts = Get-ChildItem -Path $FolderPath -Filter "*.ps1" -Recurse
    
    $updatedCount = 0
    
    foreach ($script in $scripts) {
        $updated = Update-References -FilePath $script.FullName
        
        if ($updated) {
            $updatedCount++
        }
    }
    
    Write-Log "Scripts mis à jour: $updatedCount" "INFO"
}

# Mettre à jour les références dans les fichiers de roadmap
foreach ($file in $roadmapFiles) {
    Update-References -FilePath $file
}

# Mettre à jour les références dans les scripts
Update-ScriptReferences -FolderPath $newPath

Write-Log "Mise à jour des références terminée" "SUCCESS"
