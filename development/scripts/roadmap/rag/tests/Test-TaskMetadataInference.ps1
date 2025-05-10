# Test-TaskMetadataInference.ps1
# Script de test pour l'inférence de métadonnées des tâches
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
# Test de l'inférence de métadonnées des tâches

## Tâches avec priorité implicite

- [x] **1** Tâche urgente à compléter immédiatement
  - [x] **1.1** Tâche critique pour le projet
  - [ ] **1.2** Tâche importante à faire dès que possible
  - [ ] **1.3** Tâche de priorité moyenne à compléter bientôt
  - [ ] **1.4** Tâche de faible priorité à faire quand possible
  - [ ] **1.5** Tâche optionnelle si le temps le permet

## Tâches avec complexité implicite

- [ ] **2** Tâche simple et rapide
  - [ ] **2.1** Tâche facile à implémenter
  - [ ] **2.2** Tâche de complexité moyenne nécessitant quelques heures
  - [ ] **2.3** Tâche complexe et difficile nécessitant une analyse approfondie
  - [ ] **2.4** Tâche très complexe avec de nombreux composants interdépendants

## Tâches avec catégorie implicite

- [ ] **3** Développer la fonctionnalité d'authentification
  - [ ] **3.1** Concevoir l'interface utilisateur de connexion
  - [ ] **3.2** Implémenter les tests unitaires pour l'authentification
  - [ ] **3.3** Documenter l'API d'authentification
  - [ ] **3.4** Optimiser les performances du système d'authentification
  - [ ] **3.5** Déployer la fonctionnalité sur le serveur de production

## Tâches avec dépendances implicites

- [ ] **4** Configurer l'environnement de développement
  - [ ] **4.1** Installer les dépendances requises
  - [ ] **4.2** Configurer la base de données après l'installation des dépendances
  - [ ] **4.3** Démarrer le serveur une fois la base de données configurée
  - [ ] **4.4** Vérifier que tout fonctionne correctement quand le serveur est démarré
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

# Fonction pour exécuter le test d'inférence de métadonnées
function Test-TaskMetadataInference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Log "Test de l'inférence de métadonnées des tâches..." -Level "Info"
    
    # Vérifier si le script d'inférence de métadonnées existe
    $inferenceScriptPath = Join-Path -Path $parentPath -ChildPath "metadata\Infer-TaskMetadata.ps1"
    
    if (-not (Test-Path -Path $inferenceScriptPath)) {
        Write-Log "Script d'inférence de métadonnées introuvable : $inferenceScriptPath" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie
    $outputDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "output"
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Exécuter l'inférence de métadonnées
    $outputPath = Join-Path -Path $outputDir -ChildPath "inferred-metadata.md"
    
    $params = @{
        FilePath = $FilePath
        OutputPath = $outputPath
        OutputFormat = "Markdown"
        InferPriority = $true
        InferComplexity = $true
        InferCategory = $true
        InferDependencies = $true
    }
    
    try {
        $result = & $inferenceScriptPath @params
        
        if ($null -eq $result) {
            Write-Log "L'inférence de métadonnées n'a pas retourné de résultat." -Level "Error"
            return $false
        }
        
        # Vérifier les résultats
        $tasks = $result.Tasks
        
        # Compter les tâches par priorité
        $priorityCounts = @{
            "High" = 0
            "Medium" = 0
            "Low" = 0
        }
        
        # Compter les tâches par complexité
        $complexityCounts = @{
            "High" = 0
            "Medium" = 0
            "Low" = 0
        }
        
        # Compter les tâches par catégorie
        $categoryCounts = @{}
        
        # Compter les tâches avec dépendances
        $tasksWithDependencies = 0
        
        foreach ($taskId in $tasks.Keys) {
            $task = $tasks[$taskId]
            
            if ($task.InferredMetadata.ContainsKey("Priority")) {
                $priority = $task.InferredMetadata.Priority
                $priorityCounts[$priority]++
            }
            
            if ($task.InferredMetadata.ContainsKey("Complexity")) {
                $complexity = $task.InferredMetadata.Complexity
                $complexityCounts[$complexity]++
            }
            
            if ($task.InferredMetadata.ContainsKey("Category")) {
                $category = $task.InferredMetadata.Category
                
                if (-not $categoryCounts.ContainsKey($category)) {
                    $categoryCounts[$category] = 0
                }
                
                $categoryCounts[$category]++
            }
            
            if ($task.InferredMetadata.ContainsKey("Dependencies") -and $task.InferredMetadata.Dependencies.Count -gt 0) {
                $tasksWithDependencies++
            }
        }
        
        Write-Log "Résultats de l'inférence de métadonnées :" -Level "Info"
        Write-Log "  - Tâches totales : $($tasks.Count)" -Level "Info"
        Write-Log "  - Priorité haute : $($priorityCounts.High)" -Level "Info"
        Write-Log "  - Priorité moyenne : $($priorityCounts.Medium)" -Level "Info"
        Write-Log "  - Priorité basse : $($priorityCounts.Low)" -Level "Info"
        Write-Log "  - Complexité haute : $($complexityCounts.High)" -Level "Info"
        Write-Log "  - Complexité moyenne : $($complexityCounts.Medium)" -Level "Info"
        Write-Log "  - Complexité basse : $($complexityCounts.Low)" -Level "Info"
        Write-Log "  - Tâches avec dépendances : $tasksWithDependencies" -Level "Info"
        
        # Exporter les résultats au format CSV
        $csvOutputPath = Join-Path -Path $outputDir -ChildPath "inferred-metadata.csv"
        
        $csvParams = @{
            FilePath = $FilePath
            OutputPath = $csvOutputPath
            OutputFormat = "CSV"
            InferPriority = $true
            InferComplexity = $true
            InferCategory = $true
            InferDependencies = $true
        }
        
        $csvResult = & $inferenceScriptPath @csvParams
        
        if ($null -ne $csvResult -and $null -ne $csvResult.Output) {
            Write-Log "Métadonnées inférées exportées au format CSV : $csvOutputPath" -Level "Success"
        }
        
        # Générer un rapport si demandé
        if ($GenerateReport) {
            $reportPath = Join-Path -Path $outputDir -ChildPath "inferred-metadata-report.md"
            
            $report = "# Rapport d'inférence de métadonnées des tâches`n`n"
            $report += "Date d'analyse : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            
            $report += "## Résultats`n`n"
            $report += "- Tâches totales : $($tasks.Count)`n"
            $report += "- Tâches avec priorité inférée : $($priorityCounts.High + $priorityCounts.Medium + $priorityCounts.Low)`n"
            $report += "- Tâches avec complexité inférée : $($complexityCounts.High + $complexityCounts.Medium + $complexityCounts.Low)`n"
            $report += "- Tâches avec catégorie inférée : $($categoryCounts.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum)`n"
            $report += "- Tâches avec dépendances inférées : $tasksWithDependencies`n`n"
            
            $report += "## Répartition par priorité`n`n"
            $report += "| Priorité | Nombre de tâches |`n"
            $report += "|----------|-----------------|`n"
            $report += "| Haute | $($priorityCounts.High) |`n"
            $report += "| Moyenne | $($priorityCounts.Medium) |`n"
            $report += "| Basse | $($priorityCounts.Low) |`n`n"
            
            $report += "## Répartition par complexité`n`n"
            $report += "| Complexité | Nombre de tâches |`n"
            $report += "|------------|-----------------|`n"
            $report += "| Haute | $($complexityCounts.High) |`n"
            $report += "| Moyenne | $($complexityCounts.Medium) |`n"
            $report += "| Basse | $($complexityCounts.Low) |`n`n"
            
            if ($categoryCounts.Count -gt 0) {
                $report += "## Répartition par catégorie`n`n"
                $report += "| Catégorie | Nombre de tâches |`n"
                $report += "|-----------|-----------------|`n"
                
                foreach ($category in $categoryCounts.Keys | Sort-Object) {
                    $report += "| $category | $($categoryCounts[$category]) |`n"
                }
                
                $report += "`n"
            }
            
            $report += "## Exemples de métadonnées inférées`n`n"
            
            # Sélectionner quelques tâches représentatives
            $sampleTasks = $tasks.Keys | Sort-Object | Select-Object -First 10
            
            foreach ($taskId in $sampleTasks) {
                $task = $tasks[$taskId]
                
                $report += "### $taskId : $($task.Title)`n`n"
                $report += "- Statut : $($task.Status)`n"
                
                if ($task.InferredMetadata.ContainsKey("Priority")) {
                    $report += "- Priorité inférée : $($task.InferredMetadata.Priority)`n"
                }
                
                if ($task.InferredMetadata.ContainsKey("Complexity")) {
                    $report += "- Complexité inférée : $($task.InferredMetadata.Complexity)`n"
                }
                
                if ($task.InferredMetadata.ContainsKey("Category")) {
                    $report += "- Catégorie inférée : $($task.InferredMetadata.Category)`n"
                }
                
                if ($task.InferredMetadata.ContainsKey("Dependencies") -and $task.InferredMetadata.Dependencies.Count -gt 0) {
                    $report += "- Dépendances inférées : $($task.InferredMetadata.Dependencies -join ", ")`n"
                }
                
                $report += "`n"
            }
            
            $report | Set-Content -Path $reportPath -Encoding UTF8
            Write-Log "Rapport d'inférence enregistré dans : $reportPath" -Level "Success"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'inférence de métadonnées : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-TaskMetadataInferenceTest {
    [CmdletBinding()]
    param (
        [string]$TestFilePath,
        [switch]$GenerateReport
    )
    
    Write-Log "Démarrage du test d'inférence de métadonnées des tâches..." -Level "Info"
    
    # Créer un fichier de test si nécessaire
    if ([string]::IsNullOrEmpty($TestFilePath)) {
        $TestFilePath = Join-Path -Path $scriptPath -ChildPath "data\inferred-metadata-test.md"
        
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
    $testResult = Test-TaskMetadataInference -FilePath $TestFilePath -GenerateReport:$GenerateReport
    
    if ($testResult) {
        Write-Log "Test d'inférence de métadonnées des tâches terminé avec succès." -Level "Success"
    } else {
        Write-Log "Test d'inférence de métadonnées des tâches terminé avec des erreurs." -Level "Error"
    }
    
    return $testResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-TaskMetadataInferenceTest -TestFilePath $TestFilePath -GenerateReport:$GenerateReport
}
