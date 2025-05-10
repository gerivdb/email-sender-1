# Test-NumericIdentifiersAnalysis.ps1
# Script de test pour l'analyse des identifiants numériques
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
# Test de l'analyse des identifiants numériques

## Section 1 - Format hiérarchique cohérent

- [x] **1** Tâche de niveau 1
  - [ ] **1.1** Tâche de niveau 2
    - [ ] **1.1.1** Tâche de niveau 3
    - [ ] **1.1.2** Tâche de niveau 3
  - [ ] **1.2** Tâche de niveau 2
- [ ] **2** Tâche de niveau 1
  - [ ] **2.1** Tâche de niveau 2
    - [ ] **2.1.1** Tâche de niveau 3
      - [ ] **2.1.1.1** Tâche de niveau 4
  - [ ] **2.2** Tâche de niveau 2

## Section 2 - Format numérique simple

- [ ] **3** Tâche avec identifiant simple
- [ ] **4** Tâche avec identifiant simple
- [ ] **5** Tâche avec identifiant simple

## Section 3 - Format mixte et incohérences

- [ ] **A.1** Tâche avec identifiant alphanumérique
- [ ] **B.2** Tâche avec identifiant alphanumérique
- [ ] Tâche sans identifiant
- [ ] **6.1.3** Tâche avec identifiant hiérarchique (séquence interrompue)
- [ ] **6.2** Tâche avec identifiant hiérarchique

## Section 4 - Identifiants en double

- [ ] **7** Première tâche avec identifiant 7
- [ ] **7** Deuxième tâche avec identifiant 7 (en double)
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

# Fonction pour exécuter le test d'analyse des identifiants numériques
function Test-NumericIdentifiersAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Log "Test de l'analyse des identifiants numériques..." -Level "Info"
    
    # Vérifier si le script d'analyse des identifiants existe
    $identifiersScriptPath = Join-Path -Path $parentPath -ChildPath "hierarchy\Analyze-NumericIdentifiers.ps1"
    
    if (-not (Test-Path -Path $identifiersScriptPath)) {
        Write-Log "Script d'analyse des identifiants introuvable : $identifiersScriptPath" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie
    $outputDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "output"
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Exécuter l'analyse des identifiants
    $outputPath = Join-Path -Path $outputDir -ChildPath "identifiers-analysis.json"
    
    $params = @{
        FilePath = $FilePath
        OutputPath = $outputPath
        FixInconsistencies = $true
        PreferredFormat = "Hierarchical"
    }
    
    try {
        $result = & $identifiersScriptPath @params
        
        if ($null -eq $result) {
            Write-Log "L'analyse des identifiants n'a pas retourné de résultat." -Level "Error"
            return $false
        }
        
        # Vérifier les résultats
        $analysis = $result.Analysis
        
        Write-Log "Résultats de l'analyse des identifiants :" -Level "Info"
        Write-Log "  - Format numérique : $($analysis.IdentifierFormats.Numeric)" -Level "Info"
        Write-Log "  - Format hiérarchique : $($analysis.IdentifierFormats.Hierarchical)" -Level "Info"
        Write-Log "  - Format alphanumérique : $($analysis.IdentifierFormats.AlphaNumeric)" -Level "Info"
        Write-Log "  - Format mixte : $($analysis.IdentifierFormats.Mixed)" -Level "Info"
        Write-Log "  - Profondeur de la hiérarchie : $($analysis.HierarchyDepth)" -Level "Info"
        Write-Log "  - Lignes avec identifiants : $($analysis.Stats.LinesWithIdentifiers) / $($analysis.Stats.TotalLines)" -Level "Info"
        
        if ($analysis.InconsistentLines.Count -gt 0) {
            Write-Log "  - Lignes avec identifiants incohérents : $($analysis.InconsistentLines -join ", ")" -Level "Warning"
        }
        
        if ($analysis.MissingIdentifiers.Count -gt 0) {
            Write-Log "  - Lignes avec identifiants manquants : $($analysis.MissingIdentifiers -join ", ")" -Level "Warning"
        }
        
        if ($analysis.Stats.DuplicateIdentifiers -gt 0) {
            Write-Log "  - Identifiants en double : $($analysis.Stats.DuplicateIdentifiers)" -Level "Warning"
            
            foreach ($dupId in $analysis.DuplicateIdentifiers.Keys) {
                Write-Log "    - $dupId : $($analysis.DuplicateIdentifiers[$dupId]) occurrences" -Level "Warning"
            }
        }
        
        # Vérifier le contenu reconstruit
        if ($result.RebuiltContent) {
            $rebuiltPath = Join-Path -Path $outputDir -ChildPath "rebuilt-identifiers.md"
            $result.RebuiltContent | Set-Content -Path $rebuiltPath -Encoding UTF8
            Write-Log "Contenu reconstruit enregistré dans : $rebuiltPath" -Level "Success"
        }
        
        # Générer un rapport si demandé
        if ($GenerateReport) {
            $reportPath = Join-Path -Path $outputDir -ChildPath "identifiers-report.md"
            
            $report = "# Rapport d'analyse des identifiants numériques`n`n"
            $report += "Date d'analyse : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            
            $report += "## Résultats`n`n"
            $report += "- Format numérique : $($analysis.IdentifierFormats.Numeric)`n"
            $report += "- Format hiérarchique : $($analysis.IdentifierFormats.Hierarchical)`n"
            $report += "- Format alphanumérique : $($analysis.IdentifierFormats.AlphaNumeric)`n"
            $report += "- Format mixte : $($analysis.IdentifierFormats.Mixed)`n"
            $report += "- Profondeur de la hiérarchie : $($analysis.HierarchyDepth)`n"
            $report += "- Lignes avec identifiants : $($analysis.Stats.LinesWithIdentifiers) / $($analysis.Stats.TotalLines)`n"
            $report += "- Lignes incohérentes : $($analysis.Stats.InconsistentLines)`n"
            $report += "- Identifiants manquants : $($analysis.Stats.MissingIdentifiers)`n"
            $report += "- Identifiants en double : $($analysis.Stats.DuplicateIdentifiers)`n`n"
            
            if ($analysis.InconsistentLines.Count -gt 0) {
                $report += "### Lignes avec identifiants incohérents`n`n"
                $report += "- " + ($analysis.InconsistentLines -join "`n- ") + "`n`n"
            }
            
            if ($analysis.MissingIdentifiers.Count -gt 0) {
                $report += "### Lignes avec identifiants manquants`n`n"
                $report += "- " + ($analysis.MissingIdentifiers -join "`n- ") + "`n`n"
            }
            
            if ($analysis.Stats.DuplicateIdentifiers -gt 0) {
                $report += "### Identifiants en double`n`n"
                $report += "| Identifiant | Occurrences |`n"
                $report += "|-------------|-------------|`n"
                
                foreach ($dupId in $analysis.DuplicateIdentifiers.Keys | Sort-Object) {
                    $report += "| $dupId | $($analysis.DuplicateIdentifiers[$dupId]) |`n"
                }
                
                $report += "`n"
            }
            
            $report | Set-Content -Path $reportPath -Encoding UTF8
            Write-Log "Rapport d'analyse enregistré dans : $reportPath" -Level "Success"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'analyse des identifiants : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-NumericIdentifiersTest {
    [CmdletBinding()]
    param (
        [string]$TestFilePath,
        [switch]$GenerateReport
    )
    
    Write-Log "Démarrage du test d'analyse des identifiants numériques..." -Level "Info"
    
    # Créer un fichier de test si nécessaire
    if ([string]::IsNullOrEmpty($TestFilePath)) {
        $TestFilePath = Join-Path -Path $scriptPath -ChildPath "data\identifiers-test.md"
        
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
    $testResult = Test-NumericIdentifiersAnalysis -FilePath $TestFilePath -GenerateReport:$GenerateReport
    
    if ($testResult) {
        Write-Log "Test d'analyse des identifiants numériques terminé avec succès." -Level "Success"
    } else {
        Write-Log "Test d'analyse des identifiants numériques terminé avec des erreurs." -Level "Error"
    }
    
    return $testResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-NumericIdentifiersTest -TestFilePath $TestFilePath -GenerateReport:$GenerateReport
}
