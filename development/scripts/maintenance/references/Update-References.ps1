<#
.SYNOPSIS
    DÃ©tecte et met Ã  jour les rÃ©fÃ©rences brisÃ©es dans les scripts.

.DESCRIPTION
    Ce script analyse les fichiers du projet pour identifier les rÃ©fÃ©rences de chemins qui ne correspondent plus
    Ã  la nouvelle structure suite Ã  la rÃ©organisation des scripts. Il gÃ©nÃ¨re un rapport des rÃ©fÃ©rences Ã  mettre Ã  jour
    et peut effectuer les remplacements de maniÃ¨re sÃ©curisÃ©e.

.PARAMETER ScanPath
    Chemin du rÃ©pertoire Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER ReportOnly
    Si spÃ©cifiÃ©, gÃ©nÃ¨re uniquement un rapport sans effectuer de modifications.

.PARAMETER BackupFiles
    Si spÃ©cifiÃ©, crÃ©e une sauvegarde des fichiers avant de les modifier.

.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport des rÃ©fÃ©rences brisÃ©es. Par dÃ©faut, utilise le rÃ©pertoire courant.

.EXAMPLE
    .\Update-References.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1" -ReportOnly
    Analyse le rÃ©pertoire spÃ©cifiÃ© et gÃ©nÃ¨re un rapport des rÃ©fÃ©rences brisÃ©es sans effectuer de modifications.

.EXAMPLE
    .\Update-References.ps1 -BackupFiles
    Analyse le rÃ©pertoire courant, crÃ©e des sauvegardes des fichiers et met Ã  jour les rÃ©fÃ©rences brisÃ©es.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      PowerShell 5.1 ou supÃ©rieur
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

# DÃ©finition des chemins obsolÃ¨tes et leurs remplacements
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

# Fonction pour crÃ©er une sauvegarde d'un fichier
function Backup-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if ($BackupFiles) {
        $backupPath = "$FilePath.bak"
        Write-Verbose "CrÃ©ation d'une sauvegarde: $backupPath"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
    }
}

# Fonction pour scanner les fichiers Ã  la recherche de rÃ©fÃ©rences brisÃ©es
function Find-BrokenReferences {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()
    $extensions = @(".ps1", ".md", ".json", ".py", ".bat", ".txt")
    
    Write-Host "Recherche des fichiers Ã  analyser..."
    $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object { $extensions -contains $_.Extension }
    Write-Host "Nombre de fichiers Ã  analyser: $($files.Count)"
    
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
            
            # VÃ©rifier Ã©galement avec l'autre type de sÃ©parateur
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

# Fonction pour mettre Ã  jour les rÃ©fÃ©rences brisÃ©es
function Update-BrokenReferences {
    param (
        [Parameter(Mandatory = $true)]
        [array]$References
    )

    $updatedFiles = 0
    $updatedReferences = 0
    
    foreach ($reference in $References) {
        if ($PSCmdlet.ShouldProcess($reference.FilePath, "Mise Ã  jour des rÃ©fÃ©rences")) {
            try {
                Backup-File -FilePath $reference.FilePath
                
                $content = Get-Content -Path $reference.FilePath -Raw
                $updatedContent = $content.Replace($reference.OldPath, $reference.NewPath)
                
                Set-Content -Path $reference.FilePath -Value $updatedContent -Force -Encoding UTF8
                
                $updatedFiles++
                $updatedReferences += $reference.LineCount
                
                Write-Verbose "Mise Ã  jour de $($reference.FilePath): $($reference.OldPath) -> $($reference.NewPath)"
            }
            catch {
                Write-Error "Erreur lors de la mise Ã  jour de $($reference.FilePath): $_"
            }
        }
    }
    
    return @{
        UpdatedFiles = $updatedFiles
        UpdatedReferences = $updatedReferences
    }
}

# Fonction pour gÃ©nÃ©rer un rapport des rÃ©fÃ©rences brisÃ©es
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
# Rapport des rÃ©fÃ©rences brisÃ©es

## RÃ©sumÃ©
- **Nombre total de fichiers affectÃ©s**: $($References | Select-Object -Property FilePath -Unique | Measure-Object).Count
- **Nombre total de rÃ©fÃ©rences Ã  mettre Ã  jour**: $($References | Measure-Object -Property LineCount -Sum).Sum
- **Date de gÃ©nÃ©ration**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## DÃ©tails des rÃ©fÃ©rences Ã  mettre Ã  jour

| Fichier | Ancien chemin | Nouveau chemin | Nombre d'occurrences |
|---------|--------------|---------------|---------------------|
$($References | ForEach-Object { "| $($_.FilePath) | $($_.OldPath) | $($_.NewPath) | $($_.LineCount) |" } | Out-String)

"@
    
    $summary | Set-Content -Path $summaryPath -Force -Encoding UTF8
    
    Write-Host "Rapport gÃ©nÃ©rÃ©: $reportPath"
    Write-Host "RÃ©sumÃ© gÃ©nÃ©rÃ©: $summaryPath"
}

# Fonction principale
function Main {
    Write-Host "DÃ©marrage de l'analyse des rÃ©fÃ©rences brisÃ©es..."
    Write-Host "RÃ©pertoire analysÃ©: $ScanPath"
    
    $brokenReferences = Find-BrokenReferences -Path $ScanPath
    
    if ($brokenReferences.Count -eq 0) {
        Write-Host "Aucune rÃ©fÃ©rence brisÃ©e trouvÃ©e."
        return
    }
    
    Write-Host "Nombre de rÃ©fÃ©rences brisÃ©es trouvÃ©es: $($brokenReferences | Measure-Object -Property LineCount -Sum).Sum dans $($brokenReferences | Select-Object -Property FilePath -Unique | Measure-Object).Count fichiers."
    
    Export-ReferenceReport -References $brokenReferences -OutputPath $OutputPath
    
    if (-not $ReportOnly) {
        $confirmation = Read-Host "Voulez-vous mettre Ã  jour ces rÃ©fÃ©rences? (O/N)"
        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            $result = Update-BrokenReferences -References $brokenReferences
            Write-Host "Mise Ã  jour terminÃ©e: $($result.UpdatedReferences) rÃ©fÃ©rences mises Ã  jour dans $($result.UpdatedFiles) fichiers."
        }
        else {
            Write-Host "OpÃ©ration annulÃ©e. Aucune modification n'a Ã©tÃ© effectuÃ©e."
        }
    }
    else {
        Write-Host "Mode rapport uniquement. Aucune modification n'a Ã©tÃ© effectuÃ©e."
    }
}

# ExÃ©cution du script
Main
