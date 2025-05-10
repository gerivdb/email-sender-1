# Test-IndentationAnalysis.ps1
# Script de test pour l'analyse d'indentation
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
# Test de l'analyse d'indentation

## Section 1

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

## Section 2

- [ ] **3** Tâche de niveau 1 avec indentation incohérente
   - [ ] **3.1** Tâche de niveau 2 avec indentation de 3 espaces
     - [ ] **3.1.1** Tâche de niveau 3 avec indentation de 5 espaces
  - [ ] **3.2** Tâche de niveau 2 avec indentation normale

## Section 3

- [ ] **4** Tâche avec des métadonnées
  - [ ] **4.1** Tâche avec tag #important
  - [ ] **4.2** Tâche avec attribut (priorité:haute)
  - [ ] **4.3** Tâche avec date due:2025-06-01
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

# Fonction pour exécuter le test d'analyse d'indentation
function Test-IndentationAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Log "Test de l'analyse d'indentation..." -Level "Info"
    
    # Vérifier si le script d'analyse d'indentation existe
    $indentationScriptPath = Join-Path -Path $parentPath -ChildPath "hierarchy\Analyze-IndentationLevels.ps1"
    
    if (-not (Test-Path -Path $indentationScriptPath)) {
        Write-Log "Script d'analyse d'indentation introuvable : $indentationScriptPath" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie
    $outputDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "output"
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Exécuter l'analyse d'indentation
    $outputPath = Join-Path -Path $outputDir -ChildPath "indentation-analysis.json"
    
    $params = @{
        FilePath = $FilePath
        OutputPath = $outputPath
        FixInconsistencies = $true
        PreferredSpacesPerLevel = 2
        ConvertTabsToSpaces = $true
    }
    
    try {
        $result = & $indentationScriptPath @params
        
        if ($null -eq $result) {
            Write-Log "L'analyse d'indentation n'a pas retourné de résultat." -Level "Error"
            return $false
        }
        
        # Vérifier les résultats
        $analysis = $result.Analysis
        
        Write-Log "Résultats de l'analyse d'indentation :" -Level "Info"
        Write-Log "  - Espaces par niveau : $($analysis.SpacesPerLevel)" -Level "Info"
        Write-Log "  - Indentation incohérente : $($analysis.InconsistentIndentation)" -Level "Info"
        Write-Log "  - Lignes indentées : $($analysis.IndentationStats.IndentedLines) / $($analysis.IndentationStats.TotalLines)" -Level "Info"
        
        if ($analysis.InconsistentLines.Count -gt 0) {
            Write-Log "  - Lignes avec indentation incohérente : $($analysis.InconsistentLines -join ", ")" -Level "Warning"
        }
        
        # Vérifier le contenu normalisé
        if ($result.NormalizedContent) {
            $normalizedPath = Join-Path -Path $outputDir -ChildPath "normalized-indentation.md"
            $result.NormalizedContent | Set-Content -Path $normalizedPath -Encoding UTF8
            Write-Log "Contenu normalisé enregistré dans : $normalizedPath" -Level "Success"
        }
        
        # Générer un rapport si demandé
        if ($GenerateReport) {
            $reportPath = Join-Path -Path $outputDir -ChildPath "indentation-report.md"
            
            $report = "# Rapport d'analyse d'indentation`n`n"
            $report += "Date d'analyse : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            
            $report += "## Résultats`n`n"
            $report += "- Espaces par niveau : $($analysis.SpacesPerLevel)`n"
            $report += "- Tabulations utilisées : $($analysis.TabsUsed)`n"
            $report += "- Espaces utilisés : $($analysis.SpacesUsed)`n"
            $report += "- Indentation mixte : $($analysis.MixedIndentation)`n"
            $report += "- Indentation incohérente : $($analysis.InconsistentIndentation)`n"
            $report += "- Niveau d'indentation maximal : $($analysis.MaxIndentLevel)`n"
            $report += "- Lignes indentées : $($analysis.IndentationStats.IndentedLines) / $($analysis.IndentationStats.TotalLines)`n"
            
            if ($analysis.InconsistentLines.Count -gt 0) {
                $report += "- Lignes avec indentation incohérente : $($analysis.InconsistentLines -join ", ")`n"
            }
            
            $report | Set-Content -Path $reportPath -Encoding UTF8
            Write-Log "Rapport d'analyse enregistré dans : $reportPath" -Level "Success"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'analyse d'indentation : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-IndentationTest {
    [CmdletBinding()]
    param (
        [string]$TestFilePath,
        [switch]$GenerateReport
    )
    
    Write-Log "Démarrage du test d'analyse d'indentation..." -Level "Info"
    
    # Créer un fichier de test si nécessaire
    if ([string]::IsNullOrEmpty($TestFilePath)) {
        $TestFilePath = Join-Path -Path $scriptPath -ChildPath "data\indentation-test.md"
        
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
    $testResult = Test-IndentationAnalysis -FilePath $TestFilePath -GenerateReport:$GenerateReport
    
    if ($testResult) {
        Write-Log "Test d'analyse d'indentation terminé avec succès." -Level "Success"
    } else {
        Write-Log "Test d'analyse d'indentation terminé avec des erreurs." -Level "Error"
    }
    
    return $testResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-IndentationTest -TestFilePath $TestFilePath -GenerateReport:$GenerateReport
}
