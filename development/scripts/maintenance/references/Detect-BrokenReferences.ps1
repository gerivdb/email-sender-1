<#
.SYNOPSIS
    DÃ©tecte les rÃ©fÃ©rences brisÃ©es dans les scripts.

.DESCRIPTION
    Ce script analyse les fichiers du projet pour identifier les rÃ©fÃ©rences de chemins qui ne correspondent plus
    Ã  la nouvelle structure suite Ã  la rÃ©organisation des scripts. Il gÃ©nÃ¨re un rapport dÃ©taillÃ© des rÃ©fÃ©rences
    brisÃ©es sans effectuer de modifications.

.PARAMETER ScanPath
    Chemin du rÃ©pertoire Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport des rÃ©fÃ©rences brisÃ©es. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER CustomMappings
    Chemin vers un fichier JSON contenant des mappages personnalisÃ©s de chemins obsolÃ¨tes vers nouveaux chemins.

.EXAMPLE
    .\Detect-BrokenReferences.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1"
    Analyse le rÃ©pertoire spÃ©cifiÃ© et gÃ©nÃ¨re un rapport des rÃ©fÃ©rences brisÃ©es.

.EXAMPLE
    .\Detect-BrokenReferences.ps1 -CustomMappings "path_mappings.json"
    Utilise des mappages personnalisÃ©s pour dÃ©tecter les rÃ©fÃ©rences brisÃ©es.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      PowerShell 5.1 ou supÃ©rieur
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScanPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$CustomMappings = ""
)

# DÃ©finition des chemins obsolÃ¨tes et leurs remplacements par dÃ©faut
$defaultPathMappings = @{
    "md\\roadmap_perso.md" = "Roadmap\\roadmap_perso.md"
    "md/roadmap_perso.md" = "Roadmap\\roadmap_perso.md"
    "Roadmap\\roadmap_perso_new.md" = "Roadmap\\roadmap_perso.md"
    "Roadmap/roadmap_perso_new.md" = "Roadmap\\roadmap_perso.md"
}

# Fonction pour charger des mappages personnalisÃ©s
function Import-CustomMappings {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier de mappages personnalisÃ©s n'existe pas: $Path"
        return $null
    }

    try {
        $mappings = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $result = @{}
        
        foreach ($property in $mappings.PSObject.Properties) {
            $result[$property.Name] = $property.Value
        }
        
        return $result
    }
    catch {
        Write-Error "Erreur lors du chargement des mappages personnalisÃ©s: $_"
        return $null
    }
}

# Fonction pour normaliser les chemins (convertir / en \)
function Get-NormalizedPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return $Path.Replace('/', '\')
}

# Fonction pour scanner les fichiers Ã  la recherche de rÃ©fÃ©rences brisÃ©es
function Find-BrokenReferences {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$PathMappings
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
        
        foreach ($oldPath in $PathMappings.Keys) {
            $normalizedOldPath = Get-NormalizedPath -Path $oldPath
            $newPath = $PathMappings[$oldPath]
            
            if ($content -match [regex]::Escape($normalizedOldPath)) {
                $matchingLines = $content -split "`n" | Select-String -Pattern ([regex]::Escape($normalizedOldPath))
                
                foreach ($line in $matchingLines) {
                    $results += [PSCustomObject]@{
                        FilePath = $file.FullName
                        OldPath = $normalizedOldPath
                        NewPath = $newPath
                        LineNumber = $line.LineNumber
                        LineContent = $line.Line.Trim()
                    }
                }
            }
            
            # VÃ©rifier Ã©galement avec l'autre type de sÃ©parateur
            $alternateOldPath = $oldPath.Replace('\', '/').Replace('//', '/')
            if ($content -match [regex]::Escape($alternateOldPath)) {
                $matchingLines = $content -split "`n" | Select-String -Pattern ([regex]::Escape($alternateOldPath))
                
                foreach ($line in $matchingLines) {
                    $results += [PSCustomObject]@{
                        FilePath = $file.FullName
                        OldPath = $alternateOldPath
                        NewPath = $newPath
                        LineNumber = $line.LineNumber
                        LineContent = $line.Line.Trim()
                    }
                }
            }
        }
    }
    
    Write-Progress -Activity "Analyse des fichiers" -Completed
    return $results
}

# Fonction pour gÃ©nÃ©rer un rapport dÃ©taillÃ© des rÃ©fÃ©rences brisÃ©es
function Export-DetailedReferenceReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$References,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "broken_references_detailed.json"
    $References | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath -Force -Encoding UTF8
    
    $summaryPath = Join-Path -Path $OutputPath -ChildPath "broken_references_detailed.md"
    
    $fileCount = ($References | Select-Object -Property FilePath -Unique | Measure-Object).Count
    $referenceCount = $References.Count
    
    $summary = @"
# Rapport dÃ©taillÃ© des rÃ©fÃ©rences brisÃ©es

## RÃ©sumÃ©
- **Nombre total de fichiers affectÃ©s**: $fileCount
- **Nombre total de rÃ©fÃ©rences Ã  mettre Ã  jour**: $referenceCount
- **Date de gÃ©nÃ©ration**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## DÃ©tails des rÃ©fÃ©rences Ã  mettre Ã  jour

"@
    
    $summary | Set-Content -Path $summaryPath -Force -Encoding UTF8
    
    $groupedReferences = $References | Group-Object -Property FilePath
    
    foreach ($group in $groupedReferences) {
        $fileInfo = @"

### Fichier: $($group.Name)
- **Nombre de rÃ©fÃ©rences**: $($group.Count)

| Ligne | Ancien chemin | Nouveau chemin | Contenu |
|-------|--------------|---------------|---------|
$($group.Group | Sort-Object -Property LineNumber | ForEach-Object { "| $($_.LineNumber) | $($_.OldPath) | $($_.NewPath) | ``$($_.LineContent)`` |" } | Out-String)

"@
        
        Add-Content -Path $summaryPath -Value $fileInfo -Encoding UTF8
    }
    
    Write-Host "Rapport dÃ©taillÃ© gÃ©nÃ©rÃ©: $reportPath"
    Write-Host "RÃ©sumÃ© dÃ©taillÃ© gÃ©nÃ©rÃ©: $summaryPath"
    
    return @{
        ReportPath = $reportPath
        SummaryPath = $summaryPath
    }
}

# Fonction principale
function Main {
    Write-Host "DÃ©marrage de la dÃ©tection des rÃ©fÃ©rences brisÃ©es..."
    Write-Host "RÃ©pertoire analysÃ©: $ScanPath"
    
    $pathMappings = $defaultPathMappings
    
    if ($CustomMappings -ne "") {
        $customMappings = Import-CustomMappings -Path $CustomMappings
        if ($null -ne $customMappings) {
            Write-Host "Utilisation des mappages personnalisÃ©s depuis: $CustomMappings"
            $pathMappings = $customMappings
        }
    }
    
    $brokenReferences = Find-BrokenReferences -Path $ScanPath -PathMappings $pathMappings
    
    if ($brokenReferences.Count -eq 0) {
        Write-Host "Aucune rÃ©fÃ©rence brisÃ©e trouvÃ©e."
        return
    }
    
    Write-Host "Nombre de rÃ©fÃ©rences brisÃ©es trouvÃ©es: $($brokenReferences.Count) dans $($brokenReferences | Select-Object -Property FilePath -Unique | Measure-Object).Count fichiers."
    
    $reportPaths = Export-DetailedReferenceReport -References $brokenReferences -OutputPath $OutputPath
    
    Write-Host "Pour mettre Ã  jour ces rÃ©fÃ©rences, utilisez le script Update-References.ps1."
    Write-Host "Exemple: .\Update-References.ps1 -ScanPath `"$ScanPath`""
}

# ExÃ©cution du script
Main
