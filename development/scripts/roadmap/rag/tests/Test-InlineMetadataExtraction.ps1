# Test-InlineMetadataExtraction.ps1
# Script de test pour l'extraction des métadonnées inline
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestFilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
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
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour créer un fichier de test
function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $testContent = @"
# Test de l'extraction des métadonnées inline

## Tâches avec tags

- [x] **1** Tâche terminée #done
  - [x] **1.1** Tâche avec plusieurs tags #important #urgent #done
  - [ ] **1.2** Tâche avec tag de priorité #priority:high
  - [ ] **1.3** Tâche avec tag de catégorie #category:development

## Tâches avec attributs

- [ ] **2** Tâche avec attribut simple (important)
  - [ ] **2.1** Tâche avec attribut clé-valeur (priorité:haute)
  - [ ] **2.2** Tâche avec plusieurs attributs (assigné:Jean) (échéance:2025-06-01)
  - [ ] **2.3** Tâche avec attributs imbriqués (métadonnées:(type:feature)(complexité:moyenne))

## Tâches avec dates

- [ ] **3** Tâche avec date due:2025-06-01
  - [ ] **3.1** Tâche avec date de début start:2025-05-20
  - [ ] **3.2** Tâche avec date de fin end:2025-06-15
  - [ ] **3.3** Tâche avec plusieurs dates start:2025-05-20 end:2025-06-15

## Tâches avec combinaisons de métadonnées

- [ ] **4** Tâche complexe #important (priorité:haute) due:2025-06-01
  - [ ] **4.1** Tâche avec toutes les métadonnées #urgent #feature (assigné:Marie) (complexité:élevée) start:2025-05-15 end:2025-06-30
  - [ ] **4.2** Tâche avec métadonnées et description détaillée #documentation
    Cette tâche comprend une description sur plusieurs lignes
    avec des détails supplémentaires.
"@
    
    try {
        $testContent | Set-Content -Path $FilePath -Encoding UTF8
        Write-Log "Fichier de test créé : $FilePath" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de la création du fichier de test : $_" -Level "Error"
        return $false
    }
}

# Fonction pour exécuter le test d'extraction des métadonnées inline
function Test-InlineMetadataExtraction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Log "Test de l'extraction des métadonnées inline..." -Level "Info"
    
    # Vérifier si le script d'extraction des métadonnées inline existe
    $metadataScriptPath = Join-Path -Path $parentPath -ChildPath "metadata\Extract-InlineMetadata.ps1"
    
    if (-not (Test-Path -Path $metadataScriptPath)) {
        Write-Log "Script d'extraction des métadonnées inline introuvable : $metadataScriptPath" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie
    $outputDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "output"
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Exécuter l'extraction des métadonnées inline
    $outputPath = Join-Path -Path $outputDir -ChildPath "inline-metadata.md"
    
    $params = @{
        FilePath = $FilePath
        OutputPath = $outputPath
        OutputFormat = "Markdown"
        DetectTags = $true
        DetectAttributes = $true
        DetectDates = $true
    }
    
    try {
        $result = & $metadataScriptPath @params
        
        if ($null -eq $result) {
            Write-Log "L'extraction des métadonnées inline n'a pas retourné de résultat." -Level "Error"
            return $false
        }
        
        # Vérifier les résultats
        $analysis = $result.Analysis
        
        Write-Log "Résultats de l'extraction des métadonnées inline :" -Level "Info"
        Write-Log "  - Tâches totales : $($analysis.Stats.TotalTasks)" -Level "Info"
        Write-Log "  - Tâches avec tags : $($analysis.Stats.TasksWithTags)" -Level "Info"
        Write-Log "  - Tâches avec attributs : $($analysis.Stats.TasksWithAttributes)" -Level "Info"
        Write-Log "  - Tâches avec dates : $($analysis.Stats.TasksWithDates)" -Level "Info"
        Write-Log "  - Tags uniques : $($analysis.Stats.UniqueTags)" -Level "Info"
        Write-Log "  - Attributs uniques : $($analysis.Stats.UniqueAttributes)" -Level "Info"
        
        # Exporter les résultats au format CSV
        $csvOutputPath = Join-Path -Path $outputDir -ChildPath "inline-metadata.csv"
        
        $csvParams = @{
            FilePath = $FilePath
            OutputPath = $csvOutputPath
            OutputFormat = "CSV"
            DetectTags = $true
            DetectAttributes = $true
            DetectDates = $true
        }
        
        $csvResult = & $metadataScriptPath @csvParams
        
        if ($null -ne $csvResult -and $null -ne $csvResult.Output) {
            Write-Log "Métadonnées inline exportées au format CSV : $csvOutputPath" -Level "Success"
        }
        
        # Générer un rapport si demandé
        if ($GenerateReport) {
            $reportPath = Join-Path -Path $outputDir -ChildPath "inline-metadata-report.md"
            
            $report = "# Rapport d'extraction des métadonnées inline`n`n"
            $report += "Date d'analyse : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            
            $report += "## Résultats`n`n"
            $report += "- Tâches totales : $($analysis.Stats.TotalTasks)`n"
            $report += "- Tâches avec tags : $($analysis.Stats.TasksWithTags)`n"
            $report += "- Tâches avec attributs : $($analysis.Stats.TasksWithAttributes)`n"
            $report += "- Tâches avec dates : $($analysis.Stats.TasksWithDates)`n"
            $report += "- Tags uniques : $($analysis.Stats.UniqueTags)`n"
            $report += "- Attributs uniques : $($analysis.Stats.UniqueAttributes)`n`n"
            
            if ($analysis.Tags.Count -gt 0) {
                $report += "## Tags`n`n"
                $report += "| Tag | Occurrences | Tâches |`n"
                $report += "|-----|------------|--------|`n"
                
                foreach ($tag in $analysis.Tags.Keys | Sort-Object) {
                    $tagInfo = $analysis.Tags[$tag]
                    $tasks = $tagInfo.Tasks -join ", "
                    $report += "| #$tag | $($tagInfo.Count) | $tasks |`n"
                }
                
                $report += "`n"
            }
            
            if ($analysis.Attributes.Count -gt 0) {
                $report += "## Attributs`n`n"
                $report += "| Attribut | Valeur | Occurrences | Tâches |`n"
                $report += "|----------|--------|------------|--------|`n"
                
                foreach ($attrKey in $analysis.Attributes.Keys | Sort-Object) {
                    $attrInfo = $analysis.Attributes[$attrKey]
                    $value = if ($attrInfo.Value -eq $true) { "✓" } else { $attrInfo.Value }
                    $tasks = $attrInfo.Tasks -join ", "
                    $report += "| $($attrInfo.Key) | $value | $($attrInfo.Count) | $tasks |`n"
                }
                
                $report += "`n"
            }
            
            if ($analysis.Dates.Count -gt 0) {
                $report += "## Dates`n`n"
                $report += "| Type | Date | Occurrences | Tâches |`n"
                $report += "|------|------|------------|--------|`n"
                
                foreach ($dateKey in $analysis.Dates.Keys | Sort-Object) {
                    $dateInfo = $analysis.Dates[$dateKey]
                    $tasks = $dateInfo.Tasks -join ", "
                    $report += "| $($dateInfo.Type) | $($dateInfo.Date) | $($dateInfo.Count) | $tasks |`n"
                }
                
                $report += "`n"
            }
            
            $report | Set-Content -Path $reportPath -Encoding UTF8
            Write-Log "Rapport d'extraction enregistré dans : $reportPath" -Level "Success"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'extraction des métadonnées inline : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-InlineMetadataTest {
    [CmdletBinding()]
    param (
        [string]$TestFilePath,
        [switch]$GenerateReport
    )
    
    Write-Log "Démarrage du test d'extraction des métadonnées inline..." -Level "Info"
    
    # Créer un fichier de test si nécessaire
    if ([string]::IsNullOrEmpty($TestFilePath)) {
        $TestFilePath = Join-Path -Path $scriptPath -ChildPath "data\inline-metadata-test.md"
        
        # Créer le répertoire de données si nécessaire
        $dataDir = Join-Path -Path $scriptPath -ChildPath "data"
        
        if (-not (Test-Path -Path $dataDir)) {
            New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
        }
        
        if (-not (New-TestFile -FilePath $TestFilePath)) {
            return $false
        }
    } else {
        if (-not (Test-Path -Path $TestFilePath)) {
            Write-Log "Le fichier de test spécifié n'existe pas : $TestFilePath" -Level "Error"
            return $false
        }
    }
    
    # Exécuter le test
    $testResult = Test-InlineMetadataExtraction -FilePath $TestFilePath -GenerateReport:$GenerateReport
    
    if ($testResult) {
        Write-Log "Test d'extraction des métadonnées inline terminé avec succès." -Level "Success"
    } else {
        Write-Log "Test d'extraction des métadonnées inline terminé avec des erreurs." -Level "Error"
    }
    
    return $testResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-InlineMetadataTest -TestFilePath $TestFilePath -GenerateReport:$GenerateReport
}
