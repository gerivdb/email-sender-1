<#
.SYNOPSIS
    Détecte les références brisées dans les scripts.

.DESCRIPTION
    Ce script analyse les fichiers du projet pour identifier les références de chemins qui ne correspondent plus
    à la nouvelle structure suite à la réorganisation des scripts. Il génère un rapport détaillé des références
    brisées sans effectuer de modifications.

.PARAMETER ScanPath
    Chemin du répertoire à analyser. Par défaut, utilise le répertoire courant.

.PARAMETER OutputPath
    Chemin où enregistrer le rapport des références brisées. Par défaut, utilise le répertoire courant.

.PARAMETER CustomMappings
    Chemin vers un fichier JSON contenant des mappages personnalisés de chemins obsolètes vers nouveaux chemins.

.EXAMPLE
    .\Detect-BrokenReferences.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1"
    Analyse le répertoire spécifié et génère un rapport des références brisées.

.EXAMPLE
    .\Detect-BrokenReferences.ps1 -CustomMappings "path_mappings.json"
    Utilise des mappages personnalisés pour détecter les références brisées.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
    Prérequis:      PowerShell 5.1 ou supérieur
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

# Définition des chemins obsolètes et leurs remplacements par défaut
$defaultPathMappings = @{
    "md\\roadmap_perso.md" = "Roadmap\\roadmap_perso.md"
    "md/roadmap_perso.md" = "Roadmap\\roadmap_perso.md"
    "Roadmap\\roadmap_perso_new.md" = "Roadmap\\roadmap_perso.md"
    "Roadmap/roadmap_perso_new.md" = "Roadmap\\roadmap_perso.md"
}

# Fonction pour charger des mappages personnalisés
function Import-CustomMappings {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier de mappages personnalisés n'existe pas: $Path"
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
        Write-Error "Erreur lors du chargement des mappages personnalisés: $_"
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

# Fonction pour scanner les fichiers à la recherche de références brisées
function Find-BrokenReferences {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$PathMappings
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
            
            # Vérifier également avec l'autre type de séparateur
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

# Fonction pour générer un rapport détaillé des références brisées
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
# Rapport détaillé des références brisées

## Résumé
- **Nombre total de fichiers affectés**: $fileCount
- **Nombre total de références à mettre à jour**: $referenceCount
- **Date de génération**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Détails des références à mettre à jour

"@
    
    $summary | Set-Content -Path $summaryPath -Force -Encoding UTF8
    
    $groupedReferences = $References | Group-Object -Property FilePath
    
    foreach ($group in $groupedReferences) {
        $fileInfo = @"

### Fichier: $($group.Name)
- **Nombre de références**: $($group.Count)

| Ligne | Ancien chemin | Nouveau chemin | Contenu |
|-------|--------------|---------------|---------|
$($group.Group | Sort-Object -Property LineNumber | ForEach-Object { "| $($_.LineNumber) | $($_.OldPath) | $($_.NewPath) | ``$($_.LineContent)`` |" } | Out-String)

"@
        
        Add-Content -Path $summaryPath -Value $fileInfo -Encoding UTF8
    }
    
    Write-Host "Rapport détaillé généré: $reportPath"
    Write-Host "Résumé détaillé généré: $summaryPath"
    
    return @{
        ReportPath = $reportPath
        SummaryPath = $summaryPath
    }
}

# Fonction principale
function Main {
    Write-Host "Démarrage de la détection des références brisées..."
    Write-Host "Répertoire analysé: $ScanPath"
    
    $pathMappings = $defaultPathMappings
    
    if ($CustomMappings -ne "") {
        $customMappings = Import-CustomMappings -Path $CustomMappings
        if ($null -ne $customMappings) {
            Write-Host "Utilisation des mappages personnalisés depuis: $CustomMappings"
            $pathMappings = $customMappings
        }
    }
    
    $brokenReferences = Find-BrokenReferences -Path $ScanPath -PathMappings $pathMappings
    
    if ($brokenReferences.Count -eq 0) {
        Write-Host "Aucune référence brisée trouvée."
        return
    }
    
    Write-Host "Nombre de références brisées trouvées: $($brokenReferences.Count) dans $($brokenReferences | Select-Object -Property FilePath -Unique | Measure-Object).Count fichiers."
    
    $reportPaths = Export-DetailedReferenceReport -References $brokenReferences -OutputPath $OutputPath
    
    Write-Host "Pour mettre à jour ces références, utilisez le script Update-References.ps1."
    Write-Host "Exemple: .\Update-References.ps1 -ScanPath `"$ScanPath`""
}

# Exécution du script
Main
