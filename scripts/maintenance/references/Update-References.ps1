<#
.SYNOPSIS
    Détecte et met à jour les références brisées dans les scripts.

.DESCRIPTION
    Ce script analyse les fichiers du projet pour identifier les références de chemins qui ne correspondent plus
    à la nouvelle structure suite à la réorganisation des scripts. Il génère un rapport des références à mettre à jour
    et peut effectuer les remplacements de manière sécurisée.

.PARAMETER ScanPath
    Chemin du répertoire à analyser. Par défaut, utilise le répertoire courant.

.PARAMETER ReportOnly
    Si spécifié, génère uniquement un rapport sans effectuer de modifications.

.PARAMETER BackupFiles
    Si spécifié, crée une sauvegarde des fichiers avant de les modifier.

.PARAMETER OutputPath
    Chemin où enregistrer le rapport des références brisées. Par défaut, utilise le répertoire courant.

.EXAMPLE
    .\Update-References.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1" -ReportOnly
    Analyse le répertoire spécifié et génère un rapport des références brisées sans effectuer de modifications.

.EXAMPLE
    .\Update-References.ps1 -BackupFiles
    Analyse le répertoire courant, crée des sauvegardes des fichiers et met à jour les références brisées.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
    Prérequis:      PowerShell 5.1 ou supérieur
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScanPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$ReportOnly,

    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path
)

# Définition des chemins obsolètes et leurs remplacements
$pathMappings = @{
    "md\\roadmap_perso.md" = "Roadmap\\roadmap_perso.md"
    "md/roadmap_perso.md" = "Roadmap\\roadmap_perso.md"
    "Roadmap\\roadmap_perso_new.md" = "Roadmap\\roadmap_perso.md"
    "Roadmap/roadmap_perso_new.md" = "Roadmap\\roadmap_perso.md"
}

# Fonction pour normaliser les chemins (convertir / en \)
function Get-NormalizedPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return $Path.Replace('/', '\')
}

# Fonction pour créer une sauvegarde d'un fichier
function Backup-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if ($BackupFiles) {
        $backupPath = "$FilePath.bak"
        Write-Verbose "Création d'une sauvegarde: $backupPath"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
    }
}

# Fonction pour scanner les fichiers à la recherche de références brisées
function Find-BrokenReferences {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()
    $extensions = @(".ps1", ".md", ".json", ".py", ".bat", ".txt")
    
    Write-Host "Recherche des fichiers à analyser..."
    $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object { $extensions -contains $_.Extension }
    Write-Host "Nombre de fichiers à analyser: $($files.Count)"
    
    $progressCounter = 0
    foreach ($file in $files) {
        $progressCounter++
        $percentComplete = [math]::Round(($progressCounter / $files.Count) * 100)
        Write-Progress -Activity "Analyse des fichiers" -Status "Traitement de $($file.Name)" -PercentComplete $percentComplete
        
        $content = Get-Content -Path $file.FullName -Raw
        
        foreach ($oldPath in $pathMappings.Keys) {
            $normalizedOldPath = Get-NormalizedPath -Path $oldPath
            $newPath = $pathMappings[$oldPath]
            
            if ($content -match [regex]::Escape($normalizedOldPath)) {
                $results += [PSCustomObject]@{
                    FilePath = $file.FullName
                    OldPath = $normalizedOldPath
                    NewPath = $newPath
                    LineCount = ($content -split "`n" | Select-String -Pattern ([regex]::Escape($normalizedOldPath))).Count
                }
            }
            
            # Vérifier également avec l'autre type de séparateur
            $alternateOldPath = $oldPath.Replace('\', '/').Replace('//', '/')
            if ($content -match [regex]::Escape($alternateOldPath)) {
                $results += [PSCustomObject]@{
                    FilePath = $file.FullName
                    OldPath = $alternateOldPath
                    NewPath = $newPath
                    LineCount = ($content -split "`n" | Select-String -Pattern ([regex]::Escape($alternateOldPath))).Count
                }
            }
        }
    }
    
    Write-Progress -Activity "Analyse des fichiers" -Completed
    return $results
}

# Fonction pour mettre à jour les références brisées
function Update-BrokenReferences {
    param (
        [Parameter(Mandatory = $true)]
        [array]$References
    )

    $updatedFiles = 0
    $updatedReferences = 0
    
    foreach ($reference in $References) {
        if ($PSCmdlet.ShouldProcess($reference.FilePath, "Mise à jour des références")) {
            try {
                Backup-File -FilePath $reference.FilePath
                
                $content = Get-Content -Path $reference.FilePath -Raw
                $updatedContent = $content.Replace($reference.OldPath, $reference.NewPath)
                
                Set-Content -Path $reference.FilePath -Value $updatedContent -Force -Encoding UTF8
                
                $updatedFiles++
                $updatedReferences += $reference.LineCount
                
                Write-Verbose "Mise à jour de $($reference.FilePath): $($reference.OldPath) -> $($reference.NewPath)"
            }
            catch {
                Write-Error "Erreur lors de la mise à jour de $($reference.FilePath): $_"
            }
        }
    }
    
    return @{
        UpdatedFiles = $updatedFiles
        UpdatedReferences = $updatedReferences
    }
}

# Fonction pour générer un rapport des références brisées
function Export-ReferenceReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$References,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "broken_references_report.json"
    $References | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath -Force -Encoding UTF8
    
    $summaryPath = Join-Path -Path $OutputPath -ChildPath "broken_references_summary.md"
    $summary = @"
# Rapport des références brisées

## Résumé
- **Nombre total de fichiers affectés**: $($References | Select-Object -Property FilePath -Unique | Measure-Object).Count
- **Nombre total de références à mettre à jour**: $($References | Measure-Object -Property LineCount -Sum).Sum
- **Date de génération**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Détails des références à mettre à jour

| Fichier | Ancien chemin | Nouveau chemin | Nombre d'occurrences |
|---------|--------------|---------------|---------------------|
$($References | ForEach-Object { "| $($_.FilePath) | $($_.OldPath) | $($_.NewPath) | $($_.LineCount) |" } | Out-String)

"@
    
    $summary | Set-Content -Path $summaryPath -Force -Encoding UTF8
    
    Write-Host "Rapport généré: $reportPath"
    Write-Host "Résumé généré: $summaryPath"
}

# Fonction principale
function Main {
    Write-Host "Démarrage de l'analyse des références brisées..."
    Write-Host "Répertoire analysé: $ScanPath"
    
    $brokenReferences = Find-BrokenReferences -Path $ScanPath
    
    if ($brokenReferences.Count -eq 0) {
        Write-Host "Aucune référence brisée trouvée."
        return
    }
    
    Write-Host "Nombre de références brisées trouvées: $($brokenReferences | Measure-Object -Property LineCount -Sum).Sum dans $($brokenReferences | Select-Object -Property FilePath -Unique | Measure-Object).Count fichiers."
    
    Export-ReferenceReport -References $brokenReferences -OutputPath $OutputPath
    
    if (-not $ReportOnly) {
        $confirmation = Read-Host "Voulez-vous mettre à jour ces références? (O/N)"
        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            $result = Update-BrokenReferences -References $brokenReferences
            Write-Host "Mise à jour terminée: $($result.UpdatedReferences) références mises à jour dans $($result.UpdatedFiles) fichiers."
        }
        else {
            Write-Host "Opération annulée. Aucune modification n'a été effectuée."
        }
    }
    else {
        Write-Host "Mode rapport uniquement. Aucune modification n'a été effectuée."
    }
}

# Exécution du script
Main
