# Script pour simplifier la gestion de la roadmap
# Ce script conserve uniquement le fichier Roadmap\"Roadmap\roadmap_perso.md" et supprime les autres

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

try {
    # 1. Identifier le fichier principal et les fichiers à supprimer
    $projectRoot = Get-Location
    $mainRoadmapPath = "Roadmap\roadmap_perso.md"""
    $filesToRemove = @(
        (Join-Path -Path $projectRoot -ChildPath ""Roadmap\roadmap_perso.md""),
        ("Roadmap\roadmap_perso.md"""),
        ("Roadmap\roadmap_perso.md""")
    )
    
    # 2. Vérifier que le fichier principal existe
    if (-not (Test-Path -Path $mainRoadmapPath -PathType Leaf)) {
        Write-Host "ERREUR: Le fichier roadmap principal n'existe pas: $mainRoadmapPath" -ForegroundColor Red
        exit 1
    }
    
    # 3. Créer des sauvegardes des fichiers à supprimer
    foreach ($file in $filesToRemove) {
        if (Test-Path -Path $file -PathType Leaf) {
            $backupPath = "$file.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -Path $file -Destination $backupPath
            Write-Host "Sauvegarde créée: $file -> $backupPath" -ForegroundColor Yellow
        }
    }
    
    # 4. Supprimer les fichiers
    foreach ($file in $filesToRemove) {
        if (Test-Path -Path $file -PathType Leaf) {
            Remove-Item -Path $file -Force
            Write-Host "Fichier supprimé: $file" -ForegroundColor Green
        }
    }
    
    # 5. Créer un fichier README.md simple
    $readmePath = Join-Path -Path (Split-Path -Path $mainRoadmapPath -Parent) -ChildPath "README.md"
    $readmeContent = @"
# Gestion de la Roadmap

Le fichier roadmap principal est `"Roadmap\roadmap_perso.md"` dans ce répertoire.

Tous les scripts doivent faire référence à ce fichier avec le chemin complet:
`Roadmap\"Roadmap\roadmap_perso.md"`

Dernière mise à jour : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host "Fichier README.md créé: $readmePath" -ForegroundColor Green
    
    # 6. Mettre à jour le journal de développement
    $journalPath = Join-Path -Path $projectRoot -ChildPath "journal\development_log.md"
    if (Test-Path -Path $journalPath -PathType Leaf) {
        $journalEntry = @"

## $(Get-Date -Format "yyyy-MM-dd") - Simplification de la gestion de la roadmap

### Actions réalisées
- Conservation uniquement du fichier roadmap principal: Roadmap\"Roadmap\roadmap_perso.md"
- Suppression des autres fichiers roadmap (avec sauvegarde)
- Création d'un README.md simple pour documenter la structure

### Problèmes résolus
- Confusion due à la présence de plusieurs fichiers roadmap dans différents répertoires
"@
        
        Add-Content -Path $journalPath -Value $journalEntry -Encoding UTF8
        Write-Host "Journal de développement mis à jour: $journalPath" -ForegroundColor Green
    }
    
    # Afficher un résumé
    Write-Host "`nRésumé de la simplification de la roadmap :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichier roadmap conservé : $mainRoadmapPath" -ForegroundColor White
    Write-Host "Fichiers supprimés : $($filesToRemove.Count)" -ForegroundColor Green
    
    Write-Host "`nATTENTION: Les scripts qui font référence aux fichiers supprimés devront être mis à jour manuellement." -ForegroundColor Yellow
    Write-Host "Utilisez le chemin 'Roadmap\"Roadmap\roadmap_perso.md"' dans tous les scripts." -ForegroundColor Yellow
}
catch {
    Write-Host "ERREUR: Une erreur critique s'est produite: $_" -ForegroundColor Red
    exit 1
}
