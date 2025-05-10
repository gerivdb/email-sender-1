# Test-ContextualRelationsAnalysis.ps1
# Script de test pour l'analyse des relations contextuelles
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
# Test de l'analyse des relations contextuelles

## Configuration du système

- [x] **1** Installer les dépendances
  - [x] **1.1** Installer Python et pip
  - [x] **1.2** Installer les bibliothèques Python
    - [x] **1.2.1** Installer sentence-transformers
    - [x] **1.2.2** Installer qdrant-client
  - [x] **1.3** Configurer l'environnement

## Développement des fonctionnalités

- [ ] **2** Développer les fonctionnalités principales
  - [ ] **2.1** Implémenter l'analyse de la hiérarchie
    - [ ] **2.1.1** Développer l'analyse des niveaux d'indentation
    - [ ] **2.1.2** Implémenter l'analyse des identifiants numériques
    - [ ] **2.1.3** Développer l'analyse contextuelle avancée @depends:2.1.1,2.1.2
  - [ ] **2.2** Implémenter l'extraction des métadonnées
    - [ ] **2.2.1** Implémenter l'extraction des métadonnées inline
    - [ ] **2.2.2** Développer l'extraction des blocs de métadonnées
    - [ ] **2.2.3** Implémenter l'inférence de métadonnées @depends:2.2.1,2.2.2

## Tests et validation

- [ ] **3** Développer les tests
  - [ ] **3.1** Créer les tests unitaires
    - [ ] **3.1.1** Tests pour l'analyse de la hiérarchie @depends:2.1
    - [ ] **3.1.2** Tests pour l'extraction des métadonnées @depends:2.2
  - [ ] **3.2** Développer les tests d'intégration
    - [ ] **3.2.1** Tests pour l'intégration avec Qdrant
    - [ ] **3.2.2** Tests pour la synchronisation bidirectionnelle

## Documentation

- [ ] **4** Rédiger la documentation
  - [ ] **4.1** Documentation utilisateur
    - [ ] **4.1.1** Guide d'installation
    - [ ] **4.1.2** Guide d'utilisation
  - [ ] **4.2** Documentation technique
    - [ ] **4.2.1** Architecture du système
    - [ ] **4.2.2** API et interfaces

## Déploiement

- [ ] **5** Préparer le déploiement
  - [ ] **5.1** Créer les scripts de déploiement
  - [ ] **5.2** Configurer l'environnement de production
  - [ ] **5.3** Déployer la version initiale @depends:3,4
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

# Fonction pour exécuter le test d'analyse des relations contextuelles
function Test-ContextualRelationsAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Log "Test de l'analyse des relations contextuelles..." -Level "Info"
    
    # Vérifier si le script d'analyse des relations existe
    $relationsScriptPath = Join-Path -Path $parentPath -ChildPath "hierarchy\Analyze-ContextualRelations.ps1"
    
    if (-not (Test-Path -Path $relationsScriptPath)) {
        Write-Log "Script d'analyse des relations introuvable : $relationsScriptPath" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie
    $outputDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "output"
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Exécuter l'analyse des relations contextuelles
    $outputPath = Join-Path -Path $outputDir -ChildPath "relations-analysis.md"
    
    $params = @{
        FilePath = $FilePath
        OutputPath = $outputPath
        OutputFormat = "Markdown"
        DetectImplicitRelations = $true
        AnalyzeSectionTitles = $true
        DetectThematicGroups = $true
    }
    
    try {
        $result = & $relationsScriptPath @params
        
        if ($null -eq $result) {
            Write-Log "L'analyse des relations contextuelles n'a pas retourné de résultat." -Level "Error"
            return $false
        }
        
        # Vérifier les résultats
        $analysis = $result.Analysis
        
        Write-Log "Résultats de l'analyse des relations contextuelles :" -Level "Info"
        Write-Log "  - Tâches totales : $($analysis.Stats.TotalTasks)" -Level "Info"
        Write-Log "  - Tâches terminées : $($analysis.Stats.CompletedTasks)" -Level "Info"
        Write-Log "  - Relations explicites : $($analysis.Stats.ExplicitRelations)" -Level "Info"
        Write-Log "  - Relations implicites : $($analysis.Stats.ImplicitRelations)" -Level "Info"
        Write-Log "  - Sections : $($analysis.Stats.Sections)" -Level "Info"
        Write-Log "  - Groupes thématiques : $($analysis.Stats.ThematicGroups)" -Level "Info"
        
        # Générer un graphique des relations si GraphViz est disponible
        $graphvizOutputPath = Join-Path -Path $outputDir -ChildPath "relations-graph.dot"
        
        $graphvizParams = @{
            FilePath = $FilePath
            OutputPath = $graphvizOutputPath
            OutputFormat = "GraphViz"
            DetectImplicitRelations = $true
            AnalyzeSectionTitles = $true
            DetectThematicGroups = $true
        }
        
        $graphvizResult = & $relationsScriptPath @graphvizParams
        
        if ($null -ne $graphvizResult -and $null -ne $graphvizResult.Output) {
            Write-Log "Graphique des relations enregistré dans : $graphvizOutputPath" -Level "Success"
            
            # Essayer de générer une image PNG si GraphViz est installé
            try {
                $graphvizExe = Get-Command "dot" -ErrorAction SilentlyContinue
                
                if ($null -ne $graphvizExe) {
                    $pngOutputPath = Join-Path -Path $outputDir -ChildPath "relations-graph.png"
                    & dot -Tpng -o $pngOutputPath $graphvizOutputPath
                    
                    if (Test-Path -Path $pngOutputPath) {
                        Write-Log "Image PNG des relations générée : $pngOutputPath" -Level "Success"
                    }
                } else {
                    Write-Log "GraphViz (dot) n'est pas installé. L'image PNG n'a pas été générée." -Level "Warning"
                }
            } catch {
                Write-Log "Erreur lors de la génération de l'image PNG : $_" -Level "Warning"
            }
        }
        
        # Générer un rapport si demandé
        if ($GenerateReport) {
            $reportPath = Join-Path -Path $outputDir -ChildPath "relations-report.md"
            
            $report = "# Rapport d'analyse des relations contextuelles`n`n"
            $report += "Date d'analyse : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            
            $report += "## Résultats`n`n"
            $report += "- Tâches totales : $($analysis.Stats.TotalTasks)`n"
            $report += "- Tâches terminées : $($analysis.Stats.CompletedTasks)`n"
            $report += "- Relations explicites : $($analysis.Stats.ExplicitRelations)`n"
            $report += "- Relations implicites : $($analysis.Stats.ImplicitRelations)`n"
            $report += "- Sections : $($analysis.Stats.Sections)`n"
            $report += "- Groupes thématiques : $($analysis.Stats.ThematicGroups)`n`n"
            
            $report += "## Relations explicites`n`n"
            $report += "| Tâche | Dépend de |`n"
            $report += "|-------|-----------|`n"
            
            foreach ($taskId in $analysis.ExplicitRelations.Keys | Sort-Object) {
                $dependencies = $analysis.ExplicitRelations[$taskId] -join ", "
                $report += "| $taskId | $dependencies |`n"
            }
            
            $report += "`n"
            
            $report += "## Sections`n`n"
            $report += "| Section | Niveau | Tâches |`n"
            $report += "|---------|--------|--------|`n"
            
            foreach ($sectionId in $analysis.Sections.Keys | Sort-Object { $analysis.Sections[$_].LineNumber }) {
                $section = $analysis.Sections[$sectionId]
                $taskCount = $section.Tasks.Count
                $report += "| $($section.Title) | $($section.Level) | $taskCount |`n"
            }
            
            $report += "`n"
            
            if ($analysis.ThematicGroups.Count -gt 0) {
                $report += "## Groupes thématiques`n`n"
                $report += "| Mot-clé | Tâches |`n"
                $report += "|---------|--------|`n"
                
                foreach ($groupId in $analysis.ThematicGroups.Keys | Sort-Object { $analysis.ThematicGroups[$_].Count } -Descending) {
                    $group = $analysis.ThematicGroups[$groupId]
                    $taskCount = $group.Tasks.Count
                    $report += "| $($group.Keyword) | $taskCount |`n"
                }
                
                $report += "`n"
            }
            
            $report | Set-Content -Path $reportPath -Encoding UTF8
            Write-Log "Rapport d'analyse enregistré dans : $reportPath" -Level "Success"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'analyse des relations contextuelles : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-ContextualRelationsTest {
    [CmdletBinding()]
    param (
        [string]$TestFilePath,
        [switch]$GenerateReport
    )
    
    Write-Log "Démarrage du test d'analyse des relations contextuelles..." -Level "Info"
    
    # Créer un fichier de test si nécessaire
    if ([string]::IsNullOrEmpty($TestFilePath)) {
        $TestFilePath = Join-Path -Path $scriptPath -ChildPath "data\relations-test.md"
        
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
    $testResult = Test-ContextualRelationsAnalysis -FilePath $TestFilePath -GenerateReport:$GenerateReport
    
    if ($testResult) {
        Write-Log "Test d'analyse des relations contextuelles terminé avec succès." -Level "Success"
    } else {
        Write-Log "Test d'analyse des relations contextuelles terminé avec des erreurs." -Level "Error"
    }
    
    return $testResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-ContextualRelationsTest -TestFilePath $TestFilePath -GenerateReport:$GenerateReport
}
