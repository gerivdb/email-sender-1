# Script pour simplifier la gestion de la roadmap
# Ce script conserve uniquement le fichier Roadmap\"Roadmap\roadmap_perso.md" et supprime les autres

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

try {
    # 1. Identifier le fichier principal et les fichiers Ã  supprimer
    $projectRoot = Get-Location
    $mainRoadmapPath = "Roadmap\roadmap_perso.md"""
    $filesToRemove = @(
        (Join-Path -Path $projectRoot -ChildPath ""Roadmap\roadmap_perso.md""),
        ("Roadmap\roadmap_perso.md"""),
        ("Roadmap\roadmap_perso.md""")
    )
    
    # 2. VÃ©rifier que le fichier principal existe
    if (-not (Test-Path -Path $mainRoadmapPath -PathType Leaf)) {
        Write-Host "ERREUR: Le fichier roadmap principal n'existe pas: $mainRoadmapPath" -ForegroundColor Red
        exit 1
    }
    
    # 3. CrÃ©er des sauvegardes des fichiers Ã  supprimer
    foreach ($file in $filesToRemove) {
        if (Test-Path -Path $file -PathType Leaf) {
            $backupPath = "$file.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -Path $file -Destination $backupPath
            Write-Host "Sauvegarde crÃ©Ã©e: $file -> $backupPath" -ForegroundColor Yellow
        }
    }
    
    # 4. Supprimer les fichiers
    foreach ($file in $filesToRemove) {
        if (Test-Path -Path $file -PathType Leaf) {
            Remove-Item -Path $file -Force
            Write-Host "Fichier supprimÃ©: $file" -ForegroundColor Green
        }
    }
    
    # 5. CrÃ©er un fichier README.md simple
    $readmePath = Join-Path -Path (Split-Path -Path $mainRoadmapPath -Parent) -ChildPath "README.md"
    $readmeContent = @"
# Gestion de la Roadmap

Le fichier roadmap principal est `"Roadmap\roadmap_perso.md"` dans ce rÃ©pertoire.

Tous les scripts doivent faire rÃ©fÃ©rence Ã  ce fichier avec le chemin complet:
`Roadmap\"Roadmap\roadmap_perso.md"`

DerniÃ¨re mise Ã  jour : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host "Fichier README.md crÃ©Ã©: $readmePath" -ForegroundColor Green
    
    # 6. Mettre Ã  jour le journal de dÃ©veloppement
    $journalPath = Join-Path -Path $projectRoot -ChildPath "journal\development_log.md"
    if (Test-Path -Path $journalPath -PathType Leaf) {
        $journalEntry = @"

## $(Get-Date -Format "yyyy-MM-dd") - Simplification de la gestion de la roadmap

### Actions rÃ©alisÃ©es
- Conservation uniquement du fichier roadmap principal: Roadmap\"Roadmap\roadmap_perso.md"
- Suppression des autres fichiers roadmap (avec sauvegarde)
- CrÃ©ation d'un README.md simple pour documenter la structure

### ProblÃ¨mes rÃ©solus
- Confusion due Ã  la prÃ©sence de plusieurs fichiers roadmap dans diffÃ©rents rÃ©pertoires
"@
        
        Add-Content -Path $journalPath -Value $journalEntry -Encoding UTF8
        Write-Host "Journal de dÃ©veloppement mis Ã  jour: $journalPath" -ForegroundColor Green
    }
    
    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la simplification de la roadmap :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichier roadmap conservÃ© : $mainRoadmapPath" -ForegroundColor White
    Write-Host "Fichiers supprimÃ©s : $($filesToRemove.Count)" -ForegroundColor Green
    
    Write-Host "`nATTENTION: Les scripts qui font rÃ©fÃ©rence aux fichiers supprimÃ©s devront Ãªtre mis Ã  jour manuellement." -ForegroundColor Yellow
    Write-Host "Utilisez le chemin 'Roadmap\"Roadmap\roadmap_perso.md"' dans tous les scripts." -ForegroundColor Yellow
}
catch {
    Write-Host "ERREUR: Une erreur critique s'est produite: $_" -ForegroundColor Red
    exit 1
}
