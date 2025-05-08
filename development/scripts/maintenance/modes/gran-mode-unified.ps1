# Script de granularisation des tâches de roadmap
# Ce script décompose une tâche de roadmap en sous-tâches plus granulaires
# Version unifiée et corrigée avec support pour la granularité adaptative
# Auteur: Augment AI
# Date: 2025-06-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Simple", "Medium", "Complex", "VeryComplex")]
    [string]$ComplexityLevel = "Auto",

    [Parameter(Mandatory = $false)]
    [string]$Domain = "None",

    [Parameter(Mandatory = $false)]
    [string]$SubTasksFile = "",

    [Parameter(Mandatory = $false)]
    [switch]$AddTimeEstimation,

    [Parameter(Mandatory = $false)]
    [switch]$UseAI,

    [Parameter(Mandatory = $false)]
    [switch]$SimulateAI,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
    [string]$IndentationStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [ValidateSet("GitHub", "Custom", "Auto")]
    [string]$CheckboxStyle = "Auto",
    
    [Parameter(Mandatory = $false)]
    [switch]$AdaptiveGranularity
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while ($projectRoot -and -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = Split-Path -Parent $projectRoot
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Warning "Impossible de déterminer le chemin du projet. Utilisation du chemin courant."
        $projectRoot = Get-Location
    }
}

# Charger la configuration de granularité adaptative si demandé
$adaptiveGranularityConfig = $null
if ($AdaptiveGranularity) {
    $adaptiveGranularityConfigPath = Join-Path -Path $projectRoot -ChildPath "development\config\granularite-adaptative.json"
    if (Test-Path -Path $adaptiveGranularityConfigPath) {
        try {
            $adaptiveGranularityConfig = Get-Content -Path $adaptiveGranularityConfigPath -Raw | ConvertFrom-Json
            Write-Host "Configuration de granularité adaptative chargée avec succès." -ForegroundColor Green
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration de granularité adaptative: $_"
            Write-Warning "La granularité adaptative sera désactivée."
            $AdaptiveGranularity = $false
        }
    } else {
        Write-Warning "Fichier de configuration de granularité adaptative introuvable: $adaptiveGranularityConfigPath"
        Write-Warning "La granularité adaptative sera désactivée."
        $AdaptiveGranularity = $false
    }
}

# Importer la fonction Invoke-RoadmapGranularization
$granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularization-Fixed.ps1"
if (Test-Path -Path $granularizationPath) {
    . $granularizationPath
    Write-Host "Chargement de la fonction Invoke-RoadmapGranularization depuis $granularizationPath" -ForegroundColor Green
} else {
    $granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1"
    if (Test-Path -Path $granularizationPath) {
        . $granularizationPath
        Write-Host "Chargement de la fonction Invoke-RoadmapGranularization depuis $granularizationPath" -ForegroundColor Green
    } else {
        Write-Error "La fonction Invoke-RoadmapGranularization est introuvable. Assurez-vous que le fichier Invoke-RoadmapGranularization.ps1 ou Invoke-RoadmapGranularization-Fixed.ps1 est présent dans le répertoire development\roadmap\parser\module\Functions\Public\"
        exit 1
    }
}

# Fonction pour déterminer la complexité d'une tâche
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,
        
        [Parameter(Mandatory = $false)]
        [string]$Domain = "None"
    )
    
    # Mots-clés associés à différents niveaux de complexité
    $complexityKeywords = @{
        Simple = @("simple", "basique", "facile", "documentation", "readme", "guide", "configurer", "installer")
        Medium = @("moyen", "standard", "implémenter", "développer", "créer", "ajouter", "modifier", "frontend", "interface")
        Complex = @("complexe", "avancé", "optimiser", "refactoriser", "architecture", "backend", "algorithme", "système")
        VeryComplex = @("très complexe", "critique", "distribué", "scalable", "haute performance", "intelligence artificielle", "machine learning", "sécurité")
    }
    
    # Mots-clés spécifiques aux domaines
    $domainComplexity = @{
        Frontend = "Medium"
        Backend = "Complex"
        Database = "Complex"
        Testing = "Medium"
        DevOps = "Complex"
        Security = "VeryComplex"
        "AI-ML" = "VeryComplex"
        Documentation = "Simple"
    }
    
    # Si un domaine est spécifié et qu'il existe dans notre mapping, utiliser sa complexité par défaut
    if ($Domain -ne "None" -and $domainComplexity.ContainsKey($Domain)) {
        $defaultComplexity = $domainComplexity[$Domain]
    } else {
        $defaultComplexity = "Medium"
    }
    
    # Normaliser le contenu de la tâche
    $normalizedContent = $TaskContent.ToLower()
    
    # Calculer un score pour chaque niveau de complexité
    $scores = @{}
    foreach ($level in $complexityKeywords.Keys) {
        $score = 0
        foreach ($keyword in $complexityKeywords[$level]) {
            if ($normalizedContent -match $keyword) {
                $score += 1
            }
        }
        $scores[$level] = $score
    }
    
    # Trouver le niveau de complexité avec le score le plus élevé
    $maxScore = 0
    $detectedComplexity = $defaultComplexity
    
    foreach ($level in $scores.Keys) {
        if ($scores[$level] -gt $maxScore) {
            $maxScore = $scores[$level]
            $detectedComplexity = $level
        }
    }
    
    return $detectedComplexity
}

# Fonction pour déterminer le nombre optimal de sous-tâches en fonction de la complexité
function Get-OptimalSubTaskCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,
        
        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",
        
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$AdaptiveConfig = $null
    )
    
    # Valeurs par défaut si la configuration adaptative n'est pas disponible
    $defaultCounts = @{
        Simple = 3
        Medium = 5
        Complex = 7
        VeryComplex = 9
    }
    
    # Si la configuration adaptative est disponible, l'utiliser
    if ($AdaptiveConfig) {
        try {
            # Déterminer la profondeur optimale en fonction de la complexité
            $complexityKey = $ComplexityLevel.ToLower()
            if ($complexityKey -eq "medium") { $complexityKey = "moyenne" }
            if ($complexityKey -eq "verycomplex") { $complexityKey = "tres_elevee" }
            
            $minDepth = $AdaptiveConfig.granularite_adaptative.profondeur_par_complexite.$complexityKey.min
            $maxDepth = $AdaptiveConfig.granularite_adaptative.profondeur_par_complexite.$complexityKey.max
            
            # Si un domaine est spécifié, ajuster en fonction du domaine
            if ($Domain -ne "None") {
                $domainKey = $Domain.ToLower()
                if ($AdaptiveConfig.granularite_adaptative.profondeur_par_domaine.$domainKey) {
                    $domainMinDepth = $AdaptiveConfig.granularite_adaptative.profondeur_par_domaine.$domainKey.min
                    $domainMaxDepth = $AdaptiveConfig.granularite_adaptative.profondeur_par_domaine.$domainKey.max
                    
                    # Prendre la valeur la plus restrictive entre complexité et domaine
                    $minDepth = [Math]::Max($minDepth, $domainMinDepth)
                    $maxDepth = [Math]::Min($maxDepth, $domainMaxDepth)
                }
            }
            
            # Calculer le nombre optimal de sous-tâches (moyenne entre min et max)
            $optimalCount = [Math]::Ceiling(($minDepth + $maxDepth) / 2)
            return $optimalCount
            
        } catch {
            Write-Warning "Erreur lors de la détermination du nombre optimal de sous-tâches: $_"
            Write-Warning "Utilisation des valeurs par défaut."
        }
    }
    
    # Utiliser les valeurs par défaut si la configuration adaptative n'est pas disponible ou en cas d'erreur
    if ($defaultCounts.ContainsKey($ComplexityLevel)) {
        return $defaultCounts[$ComplexityLevel]
    } else {
        return $defaultCounts["Medium"]
    }
}

# Fonction pour générer des sous-tâches en fonction de la complexité et du domaine
function Get-SubTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,
        
        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",
        
        [Parameter(Mandatory = $false)]
        [string]$SubTasksFile = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseAI,
        
        [Parameter(Mandatory = $false)]
        [switch]$SimulateAI,
        
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$AdaptiveConfig = $null
    )
    
    # Si un fichier de sous-tâches est spécifié, l'utiliser
    if (-not [string]::IsNullOrEmpty($SubTasksFile) -and (Test-Path -Path $SubTasksFile)) {
        $subTasks = Get-Content -Path $SubTasksFile -Encoding UTF8
        return $subTasks
    }
    
    # Sous-tâches par défaut en fonction de la complexité
    $defaultSubTasks = @{
        Simple = @(
            "Analyser les besoins",
            "Implémenter la solution",
            "Tester la fonctionnalité"
        )
        Medium = @(
            "Analyser les besoins",
            "Concevoir la solution",
            "Implémenter le code",
            "Tester la fonctionnalité",
            "Documenter l'implémentation"
        )
        Complex = @(
            "Analyser les besoins détaillés",
            "Concevoir l'architecture",
            "Développer les composants principaux",
            "Implémenter les fonctionnalités secondaires",
            "Optimiser les performances",
            "Tester l'ensemble du système",
            "Documenter l'implémentation"
        )
        VeryComplex = @(
            "Analyser les besoins détaillés",
            "Rechercher les solutions existantes",
            "Concevoir l'architecture du système",
            "Développer les composants critiques",
            "Implémenter les fonctionnalités principales",
            "Développer les fonctionnalités secondaires",
            "Optimiser les performances",
            "Tester l'ensemble du système",
            "Documenter l'implémentation"
        )
    }
    
    # Déterminer le nombre optimal de sous-tâches
    $optimalCount = Get-OptimalSubTaskCount -ComplexityLevel $ComplexityLevel -Domain $Domain -AdaptiveConfig $adaptiveGranularityConfig
    
    # Utiliser les sous-tâches par défaut correspondant à la complexité
    if ($defaultSubTasks.ContainsKey($ComplexityLevel)) {
        $subTasks = $defaultSubTasks[$ComplexityLevel]
    } else {
        $subTasks = $defaultSubTasks["Medium"]
    }
    
    # Ajuster le nombre de sous-tâches si nécessaire
    if ($subTasks.Count -gt $optimalCount) {
        $subTasks = $subTasks[0..($optimalCount - 1)]
    } elseif ($subTasks.Count -lt $optimalCount) {
        # Ajouter des sous-tâches génériques pour atteindre le nombre optimal
        $genericTasks = @(
            "Analyser les aspects supplémentaires",
            "Développer des fonctionnalités additionnelles",
            "Implémenter des optimisations",
            "Ajouter des tests supplémentaires",
            "Améliorer la documentation",
            "Réaliser des revues de code",
            "Effectuer des tests de performance",
            "Préparer le déploiement"
        )
        
        $i = 0
        while ($subTasks.Count -lt $optimalCount -and $i -lt $genericTasks.Count) {
            $subTasks += $genericTasks[$i]
            $i++
        }
    }
    
    return $subTasks
}

# Préparer les paramètres pour Invoke-RoadmapGranularization
$params = @{
    FilePath = $FilePath
    TaskIdentifier = $TaskIdentifier
    IndentationStyle = $IndentationStyle
    CheckboxStyle = $CheckboxStyle
}

# Déterminer la complexité si elle est en mode Auto
if ($ComplexityLevel -eq "Auto") {
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8
    
    # Trouver la ligne correspondant à la tâche
    $taskLine = $content | Where-Object { $_ -match "\*\*$TaskIdentifier\*\*" } | Select-Object -First 1
    
    if ($taskLine) {
        $ComplexityLevel = Get-TaskComplexity -TaskContent $taskLine -Domain $Domain
        Write-Host "Complexité détectée: $ComplexityLevel" -ForegroundColor Cyan
    } else {
        Write-Warning "Tâche non trouvée. Utilisation de la complexité par défaut: Medium"
        $ComplexityLevel = "Medium"
    }
}

# Générer les sous-tâches
$subTasks = Get-SubTasks -ComplexityLevel $ComplexityLevel -Domain $Domain -SubTasksFile $SubTasksFile -UseAI:$UseAI -SimulateAI:$SimulateAI -AdaptiveConfig $adaptiveGranularityConfig

# Ajouter les sous-tâches aux paramètres
$params.SubTasksInput = $subTasks -join "`r`n"

# Appliquer la granularisation
$result = Invoke-RoadmapGranularization @params

# Afficher un message de fin
Write-Host "`nExécution du mode GRAN terminée." -ForegroundColor Cyan
Write-Host "Le document a été modifié : $FilePath" -ForegroundColor Green

# Retourner le résultat
return $result
