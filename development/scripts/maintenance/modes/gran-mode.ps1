<#
.SYNOPSIS
    Script pour décomposer une tâche de roadmap en sous-tâches plus granulaires (Mode GRAN).
    Version adaptée pour utiliser la configuration unifiée et gérer différents niveaux de complexité.

.DESCRIPTION
    Ce script permet de décomposer une tâche de roadmap en sous-tâches plus granulaires
    directement dans le document. Il implémente le mode GRAN (Granularité) décrit dans
    la documentation des modes de fonctionnement.
    Cette version est adaptée pour utiliser la configuration unifiée et peut générer
    un nombre variable de sous-tâches selon la complexité de la tâche principale.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à décomposer (par exemple, "1.2.1.3.2.3").
    Si non spécifié, l'utilisateur sera invité à le saisir.

.PARAMETER SubTasksFile
    Chemin vers un fichier contenant les sous-tâches à créer, une par ligne.
    Si non spécifié, le script utilisera un modèle basé sur la complexité.

.PARAMETER ComplexityLevel
    Niveau de complexité de la tâche à décomposer.
    Options : "Simple", "Medium", "Complex", "Auto".
    Par défaut : "Auto" (détection automatique basée sur le contenu de la tâche).

.PARAMETER IndentationStyle
    Style d'indentation à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case à cocher à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "GitHub", "Custom", "Auto".

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json".

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -ComplexityLevel "Complex"

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"

.NOTES
    Auteur: RoadmapParser Team
    Version: 3.0
    Date de création: 2023-08-15
    Date de mise à jour: 2025-06-01 - Adaptation pour gérer différents niveaux de complexité
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$SubTasksFile,

    [Parameter(Mandatory = $false)]
    [string]$SubTasksInput,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Simple", "Medium", "Complex", "Auto")]
    [string]$ComplexityLevel = "Auto",

    [Parameter(Mandatory = $false)]
    [string]$Domain = "None",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
    [string]$IndentationStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [ValidateSet("GitHub", "Custom", "Auto")]
    [string]$CheckboxStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json",

    [Parameter(Mandatory = $false)]
    [switch]$UseAI,

    [Parameter(Mandatory = $false)]
    [switch]$AddTimeEstimation,

    [Parameter(Mandatory = $false)]
    [switch]$SimulateAI,

    [Parameter(Mandatory = $false)]
    [string]$ApiKey,

    [Parameter(Mandatory = $false)]
    [string]$Model)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Stocker la clé API dans une variable de script si elle est fournie
if ($ApiKey) {
    $Script:OpenRouterApiKey = $ApiKey

    # Définir également la variable d'environnement pour les appels qui n'utilisent pas le gestionnaire de credentials
    [Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $ApiKey, "Process")
    Write-Host "Clé API définie pour cette session." -ForegroundColor Green
}

# Stocker le modèle dans une variable de script si il est fourni
if ($Model) {
    $Script:AIModel = $Model
    Write-Host "Modèle défini pour cette session : $Model" -ForegroundColor Green
}

# Charger la configuration unifiée
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    Write-Warning "Tentative de recherche d'un fichier de configuration alternatif..."

    # Essayer de trouver un fichier de configuration alternatif
    $alternativePaths = @(
        "development\config\unified-config.json",
        "development\roadmap\parser\config\modes-config.json",
        "development\roadmap\parser\config\config.json"
    )

    foreach ($path in $alternativePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de configuration trouvé à l'emplacement : $fullPath" -ForegroundColor Green
            $configPath = $fullPath
            try {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                break
            } catch {
                Write-Warning "Erreur lors du chargement de la configuration : $_"
            }
        }
    }

    if (-not $config) {
        Write-Error "Aucun fichier de configuration valide trouvé."
        exit 1
    }
}

# Utiliser les valeurs de la configuration si les paramètres ne sont pas spécifiés
if (-not $FilePath) {
    if ($config.Modes.Gran.DefaultRoadmapFile) {
        $FilePath = Join-Path -Path $projectRoot -ChildPath $config.Modes.Gran.DefaultRoadmapFile
    } elseif ($config.General.ActiveDocumentPath) {
        $FilePath = Join-Path -Path $projectRoot -ChildPath $config.General.ActiveDocumentPath
    } else {
        Write-Error "Aucun fichier de roadmap spécifié et aucun fichier par défaut trouvé dans la configuration."
        exit 1
    }
}

if (-not $SubTasksFile -and $config.Modes.Gran.SubTasksFile) {
    $SubTasksFile = Join-Path -Path $projectRoot -ChildPath $config.Modes.Gran.SubTasksFile
}

if ($IndentationStyle -eq "Auto" -and $config.Modes.Gran.IndentationStyle) {
    $IndentationStyle = $config.Modes.Gran.IndentationStyle
}

if ($CheckboxStyle -eq "Auto" -and $config.Modes.Gran.CheckboxStyle) {
    $CheckboxStyle = $config.Modes.Gran.CheckboxStyle
}

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
    $FilePath = Join-Path -Path $projectRoot -ChildPath $FilePath
}

if ($SubTasksFile -and -not [System.IO.Path]::IsPathRooted($SubTasksFile)) {
    $SubTasksFile = Join-Path -Path $projectRoot -ChildPath $SubTasksFile
}

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier de roadmap spécifié n'existe pas : $FilePath"
    exit 1
}

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\RoadmapParser.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le module RoadmapParser est introuvable : $modulePath"
    exit 1
}

# Afficher les paramètres
Write-Host "Mode GRAN - Décomposition de tâches en sous-tâches" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Gray
if ($TaskIdentifier) {
    Write-Host "Identifiant de tâche : $TaskIdentifier" -ForegroundColor Gray
}
if ($SubTasksInput) {
    Write-Host "Sous-tâches fournies via paramètre SubTasksInput" -ForegroundColor Gray
} elseif ($SubTasksFile) {
    Write-Host "Fichier de sous-tâches : $SubTasksFile" -ForegroundColor Gray
} else {
    Write-Host "Niveau de complexité : $ComplexityLevel" -ForegroundColor Gray
    if ($Domain -ne "None") {
        Write-Host "Domaine : $Domain" -ForegroundColor Gray
    } else {
        Write-Host "Domaine : Auto-détection" -ForegroundColor Gray
    }
}
Write-Host "Style d'indentation : $IndentationStyle" -ForegroundColor Gray
Write-Host "Style de case à cocher : $CheckboxStyle" -ForegroundColor Gray
Write-Host ""

# Fonction pour charger la configuration des modèles de sous-tâches
function Get-SubTasksTemplateConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $configPath = Join-Path -Path $ProjectRoot -ChildPath "development\templates\subtasks\config.json"

    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration des modèles de sous-tâches : $_"
            return $null
        }
    } else {
        Write-Warning "Fichier de configuration des modèles de sous-tâches introuvable : $configPath"
        return $null
    }
}

# Fonction pour détecter automatiquement la complexité et le domaine d'une tâche
function Get-TaskComplexityAndDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    # Initialiser les scores pour chaque niveau de complexité
    $complexityScores = @{
        "simple"  = 0
        "medium"  = 0
        "complex" = 0
    }

    # Initialiser les scores pour chaque domaine
    $domainScores = @{}

    # Initialiser les scores pour tous les domaines disponibles dans la configuration
    foreach ($domain in $Config.domain_templates.PSObject.Properties.Name) {
        $domainScores[$domain] = 0
    }

    # Définir des poids pour différents types d'analyse
    $keywordWeight = 2.0        # Poids pour les correspondances de mots-clés exacts
    $semanticWeight = 1.5       # Poids pour l'analyse sémantique
    $lengthWeight = 1.0         # Poids pour l'analyse de longueur
    $positionWeight = 1.2       # Poids pour les mots-clés en début de phrase

    # Normaliser le contenu de la tâche pour l'analyse
    $normalizedContent = $TaskContent.ToLower()

    # Extraire le titre de la tâche (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($normalizedContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $normalizedContent }

    # Vérifier les mots-clés de complexité dans le contenu de la tâche avec pondération
    foreach ($level in $complexityScores.Keys) {
        foreach ($keyword in $Config.keywords.$level) {
            $keywordLower = $keyword.ToLower()

            # Correspondance exacte
            if ($normalizedContent -match $keywordLower) {
                $complexityScores[$level] += $keywordWeight

                # Bonus si le mot-clé est au début du titre
                if ($taskTitle -match "^.*?\b$keywordLower\b") {
                    $complexityScores[$level] += $positionWeight
                }
            }

            # Analyse sémantique simplifiée (vérifier si des mots similaires sont présents)
            $similarWords = Get-SimilarWords -Word $keywordLower
            foreach ($similarWord in $similarWords) {
                if ($normalizedContent -match $similarWord) {
                    $complexityScores[$level] += $semanticWeight * 0.5
                }
            }
        }
    }

    # Vérifier les mots-clés de domaine dans le contenu de la tâche avec pondération
    foreach ($domain in $domainScores.Keys) {
        if ($Config.keywords.PSObject.Properties.Name -contains $domain) {
            foreach ($keyword in $Config.keywords.$domain) {
                $keywordLower = $keyword.ToLower()

                # Correspondance exacte
                if ($normalizedContent -match $keywordLower) {
                    $domainScores[$domain] += $keywordWeight

                    # Bonus si le mot-clé est au début du titre
                    if ($taskTitle -match "^.*?\b$keywordLower\b") {
                        $domainScores[$domain] += $positionWeight
                    }
                }

                # Analyse sémantique simplifiée
                $similarWords = Get-SimilarWords -Word $keywordLower
                foreach ($similarWord in $similarWords) {
                    if ($normalizedContent -match $similarWord) {
                        $domainScores[$domain] += $semanticWeight * 0.5
                    }
                }
            }
        }
    }

    # Vérifier la longueur du contenu (indicateur de complexité)
    $wordCount = ($normalizedContent -split '\s+').Count
    if ($wordCount -lt 10) {
        $complexityScores["simple"] += $lengthWeight * 2
    } elseif ($wordCount -lt 30) {
        $complexityScores["medium"] += $lengthWeight * 2
    } else {
        $complexityScores["complex"] += $lengthWeight * 2
    }

    # Analyse de la structure des phrases (phrases complexes = tâche complexe)
    $sentenceCount = ($normalizedContent -split '[.!?]').Count
    $avgWordsPerSentence = if ($sentenceCount -gt 0) { $wordCount / $sentenceCount } else { $wordCount }

    if ($avgWordsPerSentence -gt 15) {
        $complexityScores["complex"] += $lengthWeight
    } elseif ($avgWordsPerSentence -gt 10) {
        $complexityScores["medium"] += $lengthWeight
    } else {
        $complexityScores["simple"] += $lengthWeight
    }

    # Déterminer le niveau de complexité en fonction des scores
    $maxComplexityScore = 0
    $maxComplexityLevel = "medium" # Par défaut

    foreach ($level in $complexityScores.Keys) {
        if ($complexityScores[$level] -gt $maxComplexityScore) {
            $maxComplexityScore = $complexityScores[$level]
            $maxComplexityLevel = $level
        }
    }

    # Déterminer les domaines en fonction des scores (peut retourner plusieurs domaines)
    $domains = @()
    $domainThreshold = 2 * $keywordWeight # Seuil minimal pour considérer un domaine comme pertinent

    # Trier les domaines par score décroissant
    $sortedDomains = $domainScores.GetEnumerator() | Sort-Object -Property Value -Descending

    # Sélectionner les domaines au-dessus du seuil
    foreach ($domain in $sortedDomains) {
        if ($domain.Value -ge $domainThreshold) {
            $domains += $domain.Key
        }
    }

    # Limiter à 3 domaines maximum pour éviter la surcharge
    if ($domains.Count -gt 3) {
        $domains = $domains[0..2]
    }

    # Pour la compatibilité, on retourne le domaine principal comme avant
    $primaryDomain = if ($domains.Count -gt 0) { $domains[0] } else { $null }

    return @{
        Complexity       = $maxComplexityLevel
        Domain           = $primaryDomain
        Domains          = $domains
        ComplexityScore  = $maxComplexityScore
        DomainScore      = if ($domains.Count -gt 0) { $domainScores[$domains[0]] } else { 0 }
        DomainScores     = $domainScores
        ComplexityScores = $complexityScores
    }
}

# Fonction pour estimer le temps nécessaire pour une sous-tâche
function Get-TaskTimeEstimate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,

        [Parameter(Mandatory = $false)]
        [string]$Domain = $null,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    # Charger la configuration des estimations de temps
    $timeConfigPath = Join-Path -Path $ProjectRoot -ChildPath "development\templates\subtasks\time-estimates.json"

    if (-not (Test-Path -Path $timeConfigPath)) {
        Write-Warning "Fichier de configuration des estimations de temps introuvable : $timeConfigPath"
        return $null
    }

    try {
        $timeConfig = Get-Content -Path $timeConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration des estimations de temps : $_"
        return $null
    }

    # Normaliser le contenu de la tâche
    $normalizedContent = $TaskContent.ToLower()

    # Déterminer le type de tâche (analyse, conception, implémentation, test, documentation)
    $taskType = "default"
    $maxScore = 0

    foreach ($type in $timeConfig.task_keywords.PSObject.Properties.Name) {
        $score = 0
        foreach ($keyword in $timeConfig.task_keywords.$type) {
            if ($normalizedContent -match $keyword) {
                $score += 1
            }
        }

        if ($score -gt $maxScore) {
            $maxScore = $score
            $taskType = $type
        }
    }

    # Obtenir le temps de base pour ce type de tâche
    $baseTime = $timeConfig.base_times.$taskType.value
    $timeUnit = $timeConfig.base_times.$taskType.unit

    # Appliquer le multiplicateur de complexité
    $complexityMultiplier = $timeConfig.complexity_multipliers.($ComplexityLevel.ToLower())
    $estimatedTime = $baseTime * $complexityMultiplier

    # Appliquer le multiplicateur de domaine si spécifié
    if ($Domain -and $timeConfig.domain_multipliers.PSObject.Properties.Name -contains $Domain.ToLower()) {
        $domainMultiplier = $timeConfig.domain_multipliers.($Domain.ToLower())
        $estimatedTime = $estimatedTime * $domainMultiplier
    }

    # Arrondir à 0.5 près
    $estimatedTime = [Math]::Round($estimatedTime * 2) / 2

    # Retourner l'estimation
    return @{
        Time      = $estimatedTime
        Unit      = $timeUnit
        Type      = $taskType
        Formatted = "$estimatedTime $timeUnit"
    }
}

# Fonction pour obtenir des mots similaires (analyse sémantique simplifiée)
function Get-SimilarWords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Word
    )

    # Dictionnaire simplifié de synonymes et de mots associés
    $synonyms = @{
        # Complexité
        "simple"          = @("facile", "basique", "élémentaire", "rapide", "direct")
        "facile"          = @("simple", "aisé", "accessible", "évident")
        "basique"         = @("simple", "fondamental", "élémentaire", "essentiel")
        "moyen"           = @("intermédiaire", "modéré", "standard", "normal")
        "standard"        = @("normal", "habituel", "courant", "conventionnel")
        "normal"          = @("standard", "régulier", "ordinaire", "habituel")
        "complexe"        = @("compliqué", "difficile", "sophistiqué", "élaboré", "avancé")
        "difficile"       = @("complexe", "ardu", "compliqué", "exigeant", "délicat")
        "critique"        = @("crucial", "essentiel", "vital", "important", "majeur")

        # Domaines
        "interface"       = @("UI", "frontend", "affichage", "écran", "visuel")
        "ui"              = @("interface", "frontend", "visuel", "écran")
        "ux"              = @("expérience utilisateur", "interface", "ergonomie", "utilisabilité")
        "frontend"        = @("interface", "client", "UI", "présentation", "affichage")
        "api"             = @("interface de programmation", "service", "endpoint", "backend")
        "service"         = @("API", "backend", "microservice", "fonctionnalité")
        "backend"         = @("serveur", "API", "service", "traitement", "logique métier")
        "base de données" = @("BDD", "SQL", "stockage", "données", "persistance")
        "sql"             = @("base de données", "requête", "stockage", "données")
        "test"            = @("vérification", "validation", "contrôle", "qualité")
        "sécurité"        = @("protection", "authentification", "autorisation", "chiffrement")
        "ia"              = @("intelligence artificielle", "ML", "apprentissage", "modèle")
        "ml"              = @("machine learning", "IA", "apprentissage", "modèle")
        "documentation"   = @("doc", "guide", "manuel", "référence", "tutoriel")
        "devops"          = @("CI/CD", "déploiement", "intégration", "livraison", "pipeline")
    }

    # Retourner les synonymes si le mot est dans le dictionnaire
    if ($synonyms.ContainsKey($Word)) {
        return $synonyms[$Word]
    }

    # Sinon, retourner un tableau vide
    return @()
}

# Fonction pour détecter automatiquement la complexité d'une tâche (pour compatibilité)
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityConfig
    )

    # Utiliser la nouvelle fonction pour obtenir la complexité et le domaine
    $result = Get-TaskComplexityAndDomain -TaskContent $TaskContent -Config $ComplexityConfig

    # Retourner uniquement la complexité pour maintenir la compatibilité
    return $result.Complexity
}

# Fonction pour obtenir le modèle de sous-tâches approprié
function Get-SubTasksTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,

        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",

        [Parameter(Mandatory = $false)]
        [string[]]$Domains,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TemplateConfig,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $false)]
        [switch]$CombineModels
    )

    # Si des domaines multiples sont spécifiés, utiliser ceux-là
    if (-not $Domains -and $Domain -ne "None") {
        $Domains = @($Domain)
    }

    # Si l'option de combinaison de modèles est activée et qu'il y a plusieurs domaines
    if ($CombineModels -and $Domains -and $Domains.Count -gt 1) {
        return Get-CombinedDomainTemplate -Domains $Domains -TemplateConfig $TemplateConfig -ProjectRoot $ProjectRoot
    }

    # Vérifier si un domaine spécifique est demandé et s'il existe
    $useDomainTemplate = $false
    $normalizedDomain = if ($Domain -ne "None") { $Domain.ToLower() } else { "none" }

    if ($normalizedDomain -ne "none" -and $TemplateConfig.domain_templates -and $TemplateConfig.domain_templates.PSObject.Properties.Name -contains $normalizedDomain) {
        $useDomainTemplate = $true
    }

    if ($useDomainTemplate) {
        # Utiliser le modèle spécifique au domaine
        $templateFilePath = $TemplateConfig.domain_templates.$normalizedDomain.template_file

        # Convertir le chemin relatif en chemin absolu si nécessaire
        if (-not [System.IO.Path]::IsPathRooted($templateFilePath)) {
            $templateFilePath = Join-Path -Path $ProjectRoot -ChildPath $templateFilePath
        }

        # Vérifier si le fichier de modèle existe
        if (Test-Path -Path $templateFilePath) {
            try {
                $templateContent = Get-Content -Path $templateFilePath -Encoding UTF8 -Raw
                return @{
                    Content     = $templateContent
                    Level       = "domain"
                    Domain      = $normalizedDomain
                    Domains     = @($normalizedDomain)
                    Description = $TemplateConfig.domain_templates.$normalizedDomain.description
                    MaxSubTasks = $TemplateConfig.domain_templates.$normalizedDomain.max_subtasks
                    Combined    = $false
                }
            } catch {
                Write-Warning "Erreur lors du chargement du modèle de sous-tâches spécifique au domaine : $_"
                # Continuer avec le modèle basé sur la complexité
            }
        } else {
            Write-Warning "Fichier de modèle de sous-tâches spécifique au domaine introuvable : $templateFilePath"
            # Continuer avec le modèle basé sur la complexité
        }
    }

    # Utiliser le modèle basé sur la complexité

    # Normaliser le niveau de complexité
    $normalizedLevel = $ComplexityLevel.ToLower()
    if ($normalizedLevel -eq "auto") {
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # Vérifier si le niveau de complexité est valide
    if (-not $TemplateConfig.complexity_levels.$normalizedLevel) {
        Write-Warning "Niveau de complexité non reconnu : $ComplexityLevel. Utilisation du niveau par défaut : $($TemplateConfig.default_complexity)"
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # Obtenir le chemin du fichier de modèle
    $templateFilePath = $TemplateConfig.complexity_levels.$normalizedLevel.template_file

    # Convertir le chemin relatif en chemin absolu si nécessaire
    if (-not [System.IO.Path]::IsPathRooted($templateFilePath)) {
        $templateFilePath = Join-Path -Path $ProjectRoot -ChildPath $templateFilePath
    }

    # Vérifier si le fichier de modèle existe
    if (Test-Path -Path $templateFilePath) {
        try {
            $templateContent = Get-Content -Path $templateFilePath -Encoding UTF8 -Raw
            return @{
                Content     = $templateContent
                Level       = $normalizedLevel
                Domain      = $null
                Domains     = @()
                Description = $TemplateConfig.complexity_levels.$normalizedLevel.description
                MaxSubTasks = $TemplateConfig.complexity_levels.$normalizedLevel.max_subtasks
                Combined    = $false
            }
        } catch {
            Write-Warning "Erreur lors du chargement du modèle de sous-tâches : $_"
            return $null
        }
    } else {
        Write-Warning "Fichier de modèle de sous-tâches introuvable : $templateFilePath"
        return $null
    }
}

# Fonction pour générer des sous-tâches avec l'IA
function Get-AIGeneratedSubTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,

        [Parameter(Mandatory = $false)]
        [string[]]$Domains,

        [Parameter(Mandatory = $true)]
        [int]$MaxSubTasks,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $false)]
        [switch]$Simulate
    )

    # Si la simulation est activée, utiliser des données simulées
    if ($Simulate) {
        Write-Host "Mode simulation activé pour la génération de sous-tâches par IA." -ForegroundColor Yellow

        # Simuler un délai de traitement
        Start-Sleep -Seconds 2

        # Générer des sous-tâches en fonction du domaine et de la complexité
        $generatedTasks = @()

        # Sous-tâches communes à tous les domaines
        $generatedTasks += "Analyser les besoins du système"

        # Sous-tâches spécifiques au domaine Backend
        if ($Domains -contains "Backend") {
            $generatedTasks += "Concevoir l'architecture du backend"
            $generatedTasks += "Implémenter les modèles de données"
            $generatedTasks += "Développer les API RESTful"
        }

        # Sous-tâches spécifiques au domaine Security
        if ($Domains -contains "Security") {
            $generatedTasks += "Implémenter le système d'authentification"
            $generatedTasks += "Configurer les autorisations et rôles"
            $generatedTasks += "Mettre en place le chiffrement des données sensibles"
        }

        # Sous-tâches spécifiques au domaine Frontend
        if ($Domains -contains "Frontend") {
            $generatedTasks += "Concevoir l'interface utilisateur"
            $generatedTasks += "Développer les composants React"
            $generatedTasks += "Implémenter les formulaires et validations"
        }

        # Sous-tâches communes de fin
        $generatedTasks += "Tester toutes les fonctionnalités"
        $generatedTasks += "Documenter l'API et l'utilisation"

        # Ajuster le nombre de sous-tâches en fonction de la complexité
        if ($ComplexityLevel -eq "Simple") {
            # Garder seulement 3-4 tâches pour les tâches simples
            $generatedTasks = $generatedTasks | Select-Object -First 4
        } elseif ($ComplexityLevel -eq "Complex") {
            # Ajouter des tâches supplémentaires pour les tâches complexes
            $generatedTasks += "Optimiser les performances"
            $generatedTasks += "Mettre en place la surveillance et les alertes"
            $generatedTasks += "Préparer le déploiement en production"
        }

        # Limiter le nombre de sous-tâches au maximum spécifié
        if ($generatedTasks.Count -gt $MaxSubTasks) {
            $generatedTasks = $generatedTasks | Select-Object -First $MaxSubTasks
        }

        Write-Host "Sous-tâches générées avec succès par l'IA (simulation)." -ForegroundColor Green

        # Retourner les sous-tâches générées
        return @{
            Content     = $generatedTasks -join "`r`n"
            Level       = "ai"
            Domain      = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
            Domains     = $Domains
            Description = "Sous-tâches générées par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
            MaxSubTasks = $MaxSubTasks
            Combined    = $false
            AI          = $true
        }
    }

    # Mode normal (non simulé)
    # Charger la configuration de l'IA
    $aiConfigPath = Join-Path -Path $ProjectRoot -ChildPath "development\templates\subtasks\ai-config.json"

    if (-not (Test-Path -Path $aiConfigPath)) {
        Write-Warning "Fichier de configuration de l'IA introuvable : $aiConfigPath"
        return $null
    }

    try {
        $aiConfig = Get-Content -Path $aiConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration de l'IA : $_"
        return $null
    }

    # Vérifier si l'IA est activée
    if (-not $aiConfig.enabled) {
        Write-Warning "La génération de sous-tâches par IA est désactivée dans la configuration."
        return $null
    }

    # Vérifier si la clé API est définie
    $credentialName = $aiConfig.credential_name

    # Essayer d'utiliser le gestionnaire de credentials si disponible
    $credentialManagerPath = Join-Path -Path $ProjectRoot -ChildPath "development\tools\security\credential-manager.ps1"
    if (Test-Path -Path $credentialManagerPath) {
        try {
            # Importer le module de gestion des credentials
            . $credentialManagerPath

            # Récupérer la clé API
            $apiKey = Get-SecureCredential -Name $credentialName

            # Si la clé n'est pas trouvée, essayer de l'enregistrer si elle est fournie en paramètre
            if (-not $apiKey -and $Script:OpenRouterApiKey) {
                Set-SecureCredential -Name $credentialName -Value $Script:OpenRouterApiKey -StorageType "Environment"
                $apiKey = $Script:OpenRouterApiKey
            }
        } catch {
            Write-Warning "Erreur lors de l'utilisation du gestionnaire de credentials : $_"
            # Fallback : essayer de récupérer la clé API depuis les variables d'environnement
            $apiKey = [Environment]::GetEnvironmentVariable($credentialName)
        }
    } else {
        # Fallback : essayer de récupérer la clé API depuis les variables d'environnement
        $apiKey = [Environment]::GetEnvironmentVariable($credentialName)
    }

    if (-not $apiKey) {
        Write-Warning "Clé API non définie pour $credentialName"
        return $null
    }

    # Extraire le titre de la tâche (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($TaskContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $TaskContent }

    # Préparer les domaines pour le prompt
    $domainsText = if ($Domains -and $Domains.Count -gt 0) {
        $Domains -join ", "
    } else {
        "Non spécifié"
    }

    # Préparer le prompt
    $prompt = $aiConfig.prompt_template -replace "{task}", $taskTitle -replace "{complexity}", $ComplexityLevel -replace "{domains}", $domainsText -replace "{max_subtasks}", $MaxSubTasks

    # Préparer la requête API
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $apiKey"
        "HTTP-Referer"  = "https://github.com/augmentcode-ai"  # Requis par OpenRouter
        "X-Title"       = "Roadmap Task Granularization"  # Titre de l'application
    }

    # Déterminer le modèle à utiliser
    $model = if ($Script:AIModel) {
        # Utiliser le modèle spécifié en paramètre
        $Script:AIModel
    } elseif ($aiConfig.models -and $aiConfig.models.default) {
        # Utiliser le modèle par défaut de la configuration
        $aiConfig.models.default
    } elseif ($aiConfig.model) {
        # Utiliser le modèle de la configuration (ancienne structure)
        $aiConfig.model
    } else {
        # Modèle par défaut si aucun n'est spécifié
        "qwen/qwen3-32b:free"
    }

    Write-Host "Utilisation du modèle : $model" -ForegroundColor Gray

    $body = @{
        model       = $model
        messages    = @(
            @{
                role    = "system"
                content = "Tu es un expert en gestion de projet et en décomposition de tâches. Tu vas générer une liste de sous-tâches pour une tâche donnée."
            },
            @{
                role    = "user"
                content = $prompt
            }
        )
        temperature = $aiConfig.temperature
        max_tokens  = $aiConfig.max_tokens
    } | ConvertTo-Json

    # Déterminer l'URL de l'API
    $apiUrl = if ($aiConfig.api_url) { $aiConfig.api_url } else { "https://api.openai.com/v1/chat/completions" }

    # Appeler l'API
    try {
        Write-Host "Génération de sous-tâches avec l'IA..." -ForegroundColor Yellow
        Write-Host "Utilisation de l'API : $apiUrl" -ForegroundColor Gray

        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body

        # Traiter la réponse
        $generatedContent = $response.choices[0].message.content

        # Nettoyer le contenu généré (supprimer les numéros, les tirets, etc.)
        $lines = $generatedContent -split "`n" | ForEach-Object {
            $line = $_.Trim()
            # Supprimer les numéros et les tirets au début de la ligne
            $line = $line -replace "^(\d+[\.\)]\s*|\-\s*)", ""
            # Ignorer les lignes vides
            if ($line) { $line }
        }

        # Limiter le nombre de sous-tâches
        if ($lines.Count -gt $MaxSubTasks) {
            $lines = $lines[0..($MaxSubTasks - 1)]
        }

        Write-Host "Sous-tâches générées avec succès par l'IA." -ForegroundColor Green

        # Retourner les sous-tâches générées
        return @{
            Content     = $lines -join "`r`n"
            Level       = "ai"
            Domain      = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
            Domains     = $Domains
            Description = "Sous-tâches générées par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
            MaxSubTasks = $MaxSubTasks
            Combined    = $false
            AI          = $true
        }
    } catch {
        Write-Warning "Erreur lors de l'appel à l'API IA : $_"
        return $null
    }
}

# Fonction pour combiner plusieurs modèles de domaines
function Get-CombinedDomainTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Domains,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TemplateConfig,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    # Normaliser les domaines
    $normalizedDomains = $Domains | ForEach-Object { $_.ToLower() } | Where-Object {
        $_ -ne "none" -and $TemplateConfig.domain_templates.PSObject.Properties.Name -contains $_
    }

    # Si aucun domaine valide n'est trouvé, retourner null
    if ($normalizedDomains.Count -eq 0) {
        Write-Warning "Aucun domaine valide spécifié pour la combinaison de modèles."
        return $null
    }

    # Si un seul domaine est valide, utiliser ce domaine directement
    if ($normalizedDomains.Count -eq 1) {
        return Get-SubTasksTemplate -ComplexityLevel "Auto" -Domain $normalizedDomains[0] -TemplateConfig $TemplateConfig -ProjectRoot $ProjectRoot
    }

    # Charger les modèles pour chaque domaine
    $domainTemplates = @()
    $maxSubTasks = 0
    $descriptions = @()

    foreach ($domain in $normalizedDomains) {
        $templateFilePath = $TemplateConfig.domain_templates.$domain.template_file

        # Convertir le chemin relatif en chemin absolu si nécessaire
        if (-not [System.IO.Path]::IsPathRooted($templateFilePath)) {
            $templateFilePath = Join-Path -Path $ProjectRoot -ChildPath $templateFilePath
        }

        # Vérifier si le fichier de modèle existe
        if (Test-Path -Path $templateFilePath) {
            try {
                $templateContent = Get-Content -Path $templateFilePath -Encoding UTF8
                $domainTemplates += @{
                    Domain      = $domain
                    Content     = $templateContent
                    Description = $TemplateConfig.domain_templates.$domain.description
                    MaxSubTasks = $TemplateConfig.domain_templates.$domain.max_subtasks
                }

                $maxSubTasks = [Math]::Max($maxSubTasks, $TemplateConfig.domain_templates.$domain.max_subtasks)
                $descriptions += $TemplateConfig.domain_templates.$domain.description
            } catch {
                Write-Warning "Erreur lors du chargement du modèle pour le domaine $domain : $_"
            }
        } else {
            Write-Warning "Fichier de modèle introuvable pour le domaine $domain : $templateFilePath"
        }
    }

    # Si aucun modèle n'a pu être chargé, retourner null
    if ($domainTemplates.Count -eq 0) {
        Write-Warning "Aucun modèle n'a pu être chargé pour les domaines spécifiés."
        return $null
    }

    # Combiner les modèles en utilisant un algorithme intelligent
    $combinedTasks = @()
    $usedTasks = @{}

    # Ajouter les tâches d'analyse et de conception qui sont communes à tous les domaines
    $commonPrefixes = @(
        "Analyser les besoins",
        "Concevoir",
        "Définir",
        "Planifier"
    )

    foreach ($template in $domainTemplates) {
        foreach ($task in $template.Content) {
            $taskTrimmed = $task.Trim()
            if ($taskTrimmed -eq "") { continue }

            # Vérifier si la tâche commence par un préfixe commun
            $isCommonTask = $false
            foreach ($prefix in $commonPrefixes) {
                if ($taskTrimmed -like "$prefix*") {
                    $isCommonTask = $true
                    break
                }
            }

            # Si c'est une tâche commune et qu'elle n'a pas déjà été ajoutée
            if ($isCommonTask -and -not $usedTasks.ContainsKey($taskTrimmed)) {
                $combinedTasks += $taskTrimmed
                $usedTasks[$taskTrimmed] = $true
            }
        }
    }

    # Ajouter les tâches spécifiques à chaque domaine
    foreach ($template in $domainTemplates) {
        $domainSpecificTasks = 0

        foreach ($task in $template.Content) {
            $taskTrimmed = $task.Trim()
            if ($taskTrimmed -eq "") { continue }

            # Vérifier si la tâche est spécifique au domaine (ne commence pas par un préfixe commun)
            $isDomainSpecific = $true
            foreach ($prefix in $commonPrefixes) {
                if ($taskTrimmed -like "$prefix*") {
                    $isDomainSpecific = $false
                    break
                }
            }

            # Si c'est une tâche spécifique au domaine et qu'elle n'a pas déjà été ajoutée
            if ($isDomainSpecific -and -not $usedTasks.ContainsKey($taskTrimmed)) {
                # Préfixer la tâche avec le nom du domaine pour éviter les ambiguïtés
                $prefixedTask = "[$($template.Domain)] $taskTrimmed"
                $combinedTasks += $prefixedTask
                $usedTasks[$taskTrimmed] = $true
                $domainSpecificTasks++

                # Limiter le nombre de tâches spécifiques par domaine pour éviter un modèle trop grand
                if ($domainSpecificTasks -ge 3) {
                    break
                }
            }
        }
    }

    # Ajouter des tâches communes de fin (tests, documentation)
    $commonSuffixes = @(
        "Tester",
        "Documenter",
        "Optimiser"
    )

    foreach ($template in $domainTemplates) {
        foreach ($task in $template.Content) {
            $taskTrimmed = $task.Trim()
            if ($taskTrimmed -eq "") { continue }

            # Vérifier si la tâche commence par un suffixe commun
            $isCommonEndTask = $false
            foreach ($suffix in $commonSuffixes) {
                if ($taskTrimmed -like "$suffix*") {
                    $isCommonEndTask = $true
                    break
                }
            }

            # Si c'est une tâche commune de fin et qu'elle n'a pas déjà été ajoutée
            if ($isCommonEndTask -and -not $usedTasks.ContainsKey($taskTrimmed)) {
                $combinedTasks += $taskTrimmed
                $usedTasks[$taskTrimmed] = $true
            }
        }
    }

    # Limiter le nombre total de tâches
    $maxCombinedTasks = [Math]::Min($maxSubTasks, 15) # Maximum 15 tâches pour éviter la surcharge
    if ($combinedTasks.Count -gt $maxCombinedTasks) {
        $combinedTasks = $combinedTasks[0..($maxCombinedTasks - 1)]
    }

    # Créer la description combinée
    $combinedDescription = "Combinaison des domaines: " + ($normalizedDomains -join ", ")

    # Retourner le modèle combiné
    return @{
        Content     = $combinedTasks -join "`r`n"
        Level       = "domain"
        Domain      = $normalizedDomains[0] # Le premier domaine est considéré comme principal
        Domains     = $normalizedDomains
        Description = $combinedDescription
        MaxSubTasks = $maxCombinedTasks
        Combined    = $true
    }
}

# Charger la configuration des modèles de sous-tâches
$templateConfig = Get-SubTasksTemplateConfig -ProjectRoot $projectRoot

# Lire les sous-tâches à partir du fichier ou du paramètre SubTasksInput
$subTasksInput = ""
if ($SubTasksInput) {
    # Utiliser directement les sous-tâches fournies en paramètre
    $subTasksInput = $SubTasksInput
    Write-Host "Sous-tâches fournies via le paramètre SubTasksInput" -ForegroundColor Green
} elseif ($SubTasksFile) {
    if (Test-Path -Path $SubTasksFile) {
        $subTasksInput = Get-Content -Path $SubTasksFile -Encoding UTF8 -Raw
        Write-Host "Sous-tâches lues depuis le fichier : $SubTasksFile" -ForegroundColor Green
    } else {
        Write-Error "Le fichier de sous-tâches spécifié n'existe pas : $SubTasksFile"
        exit 1
    }
} elseif ($templateConfig) {
    # Si aucun fichier de sous-tâches n'est spécifié, utiliser un modèle basé sur la complexité

    # Si l'identifiant de tâche est spécifié, lire le contenu de la tâche pour déterminer sa complexité et son domaine
    if ($TaskIdentifier -and ($ComplexityLevel -eq "Auto" -or $Domain -eq "None")) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Trouver la ligne contenant la tâche à décomposer
        $taskLineIndex = -1
        $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match $taskLinePattern) {
                $taskLineIndex = $i
                break
            }
        }

        if ($taskLineIndex -ne -1) {
            # Extraire le contenu de la tâche (la ligne elle-même)
            $taskContent = $content[$taskLineIndex]

            # Déterminer la complexité et les domaines de la tâche
            $taskAnalysis = Get-TaskComplexityAndDomain -TaskContent $taskContent -Config $templateConfig

            # Utiliser la complexité détectée si nécessaire
            $effectiveComplexity = $ComplexityLevel
            if ($ComplexityLevel -eq "Auto") {
                $effectiveComplexity = $taskAnalysis.Complexity
                Write-Host "Complexité détectée : $effectiveComplexity (score: $($taskAnalysis.ComplexityScore))" -ForegroundColor Cyan

                # Afficher les scores de complexité détaillés
                Write-Host "  Scores de complexité : " -ForegroundColor Gray -NoNewline
                foreach ($level in $taskAnalysis.ComplexityScores.Keys | Sort-Object) {
                    Write-Host "$level=$($taskAnalysis.ComplexityScores[$level]) " -ForegroundColor Gray -NoNewline
                }
                Write-Host ""
            }

            # Utiliser les domaines détectés si nécessaire
            $effectiveDomains = @()
            if ($Domain -ne "None") {
                $effectiveDomains = @($Domain)
            } elseif ($taskAnalysis.Domains -and $taskAnalysis.Domains.Count -gt 0) {
                $effectiveDomains = $taskAnalysis.Domains
                Write-Host "Domaines détectés : $($effectiveDomains -join ', ')" -ForegroundColor Cyan

                # Afficher les scores de domaine détaillés
                Write-Host "  Scores de domaine : " -ForegroundColor Gray -NoNewline
                foreach ($domain in $taskAnalysis.DomainScores.Keys | Sort-Object -Property { $taskAnalysis.DomainScores[$_] } -Descending) {
                    if ($taskAnalysis.DomainScores[$domain] -gt 0) {
                        Write-Host "$domain=$($taskAnalysis.DomainScores[$domain]) " -ForegroundColor Gray -NoNewline
                    }
                }
                Write-Host ""
            }

            # Déterminer si nous devons combiner les modèles
            $useCombinedModel = $false
            if ($effectiveDomains.Count -gt 1) {
                $useCombinedModel = $true
                Write-Host "Plusieurs domaines détectés, utilisation d'un modèle combiné." -ForegroundColor Yellow
            }

            # Obtenir le modèle de sous-tâches approprié
            $template = $null

            # Utiliser l'IA si demandé
            if ($UseAI) {
                Write-Host "Utilisation de l'IA pour générer des sous-tâches..." -ForegroundColor Yellow

                # Déterminer le nombre maximum de sous-tâches en fonction de la complexité
                $maxSubTasks = 5 # Par défaut
                if ($effectiveComplexity -eq "simple") {
                    $maxSubTasks = 3
                } elseif ($effectiveComplexity -eq "complex") {
                    $maxSubTasks = 10
                }

                # Générer les sous-tâches avec l'IA
                $template = Get-AIGeneratedSubTasks -TaskContent $taskContent -ComplexityLevel $effectiveComplexity -Domains $effectiveDomains -MaxSubTasks $maxSubTasks -ProjectRoot $projectRoot -Simulate:$SimulateAI

                # Si l'IA échoue, utiliser les modèles standards
                if (-not $template) {
                    Write-Warning "La génération de sous-tâches par IA a échoué. Utilisation des modèles standards."
                }
            }

            # Si pas de template (pas d'IA ou échec de l'IA), utiliser les modèles standards
            if (-not $template) {
                if ($useCombinedModel) {
                    $template = Get-SubTasksTemplate -ComplexityLevel $effectiveComplexity -Domains $effectiveDomains -TemplateConfig $templateConfig -ProjectRoot $projectRoot -CombineModels
                } else {
                    $effectiveDomain = if ($effectiveDomains.Count -gt 0) { $effectiveDomains[0] } else { "None" }
                    $template = Get-SubTasksTemplate -ComplexityLevel $effectiveComplexity -Domain $effectiveDomain -TemplateConfig $templateConfig -ProjectRoot $projectRoot
                }
            }

            if ($template) {
                $subTasksInput = $template.Content

                if ($template.Combined) {
                    Write-Host "Modèle de sous-tâches utilisé : Combinaison de domaines ($($template.Description))" -ForegroundColor Green
                } elseif ($template.Domain) {
                    Write-Host "Modèle de sous-tâches utilisé : Domaine $($template.Domain) ($($template.Description))" -ForegroundColor Green
                } else {
                    Write-Host "Modèle de sous-tâches utilisé : Complexité $($template.Level) ($($template.Description))" -ForegroundColor Green
                }

                Write-Host "Nombre maximum de sous-tâches : $($template.MaxSubTasks)" -ForegroundColor Green
            }
        }
    } else {
        # Vérifier si plusieurs domaines sont spécifiés
        $domainsList = $Domain -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "None" }
        $useCombinedModel = $domainsList.Count -gt 1

        # Obtenir le modèle de sous-tâches approprié
        $template = $null

        # Utiliser l'IA si demandé
        if ($UseAI) {
            Write-Host "Utilisation de l'IA pour générer des sous-tâches..." -ForegroundColor Yellow

            # Déterminer le nombre maximum de sous-tâches en fonction de la complexité
            $maxSubTasks = 5 # Par défaut
            if ($ComplexityLevel -eq "Simple") {
                $maxSubTasks = 3
            } elseif ($ComplexityLevel -eq "Complex") {
                $maxSubTasks = 10
            }

            # Créer un contenu de tâche fictif pour l'IA
            $taskContent = "Tâche à décomposer"
            if ($TaskIdentifier) {
                $taskContent = "**$TaskIdentifier** Tâche à décomposer"
            }

            # Générer les sous-tâches avec l'IA
            $template = Get-AIGeneratedSubTasks -TaskContent $taskContent -ComplexityLevel $ComplexityLevel -Domains $domainsList -MaxSubTasks $maxSubTasks -ProjectRoot $projectRoot -Simulate:$SimulateAI

            # Si l'IA échoue, utiliser les modèles standards
            if (-not $template) {
                Write-Warning "La génération de sous-tâches par IA a échoué. Utilisation des modèles standards."
            }
        }

        # Si pas de template (pas d'IA ou échec de l'IA), utiliser les modèles standards
        if (-not $template) {
            if ($useCombinedModel) {
                Write-Host "Plusieurs domaines spécifiés, utilisation d'un modèle combiné." -ForegroundColor Yellow
                $template = Get-SubTasksTemplate -ComplexityLevel $ComplexityLevel -Domains $domainsList -TemplateConfig $templateConfig -ProjectRoot $projectRoot -CombineModels
            } else {
                $template = Get-SubTasksTemplate -ComplexityLevel $ComplexityLevel -Domain $Domain -TemplateConfig $templateConfig -ProjectRoot $projectRoot
            }
        }

        if ($template) {
            $subTasksInput = $template.Content

            if ($template.Combined) {
                Write-Host "Modèle de sous-tâches utilisé : Combinaison de domaines ($($template.Description))" -ForegroundColor Green
            } elseif ($template.Domain) {
                Write-Host "Modèle de sous-tâches utilisé : Domaine $($template.Domain) ($($template.Description))" -ForegroundColor Green
            } else {
                Write-Host "Modèle de sous-tâches utilisé : Complexité $($template.Level) ($($template.Description))" -ForegroundColor Green
            }

            Write-Host "Nombre maximum de sous-tâches : $($template.MaxSubTasks)" -ForegroundColor Green
        }
    }
}

# IMPORTANT: Ce script modifie DIRECTEMENT le document spécifié.
# La granularisation est appliquée en écrasant (overwriting) le contenu existant.
# Aucun résultat intermédiaire n'est affiché dans le terminal, seul le document est modifié.
Write-Host "ATTENTION: Ce script va modifier directement le document spécifié." -ForegroundColor Yellow
Write-Host "La granularisation sera appliquée en écrasant le contenu existant." -ForegroundColor Yellow
Write-Host "Aucun résultat intermédiaire ne sera affiché dans le terminal, seul le document sera modifié." -ForegroundColor Yellow
Write-Host ""

# Appeler la fonction Invoke-RoadmapGranularization
$params = @{
    FilePath         = $FilePath
    IndentationStyle = $IndentationStyle
    CheckboxStyle    = $CheckboxStyle
}

if ($TaskIdentifier) {
    $params.TaskIdentifier = $TaskIdentifier
}

if ($subTasksInput) {
    $params.SubTasksInput = $subTasksInput
}

# Déterminer quelle fonction utiliser en fonction des paramètres
$useTimeEstimation = $AddTimeEstimation

if ($useTimeEstimation) {
    # Importer la fonction Invoke-RoadmapGranularizationWithTimeEstimation si elle n'est pas déjà disponible
    # Essayer d'abord avec le chemin relatif
    $projectRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName

    # Essayer d'abord le fichier corrigé
    $granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularizationWithTimeEstimation-Fixed.ps1"
    if (Test-Path -Path $granularizationPath) {
        . $granularizationPath
        Write-Host "Chargement de la fonction Invoke-RoadmapGranularizationWithTimeEstimation depuis $granularizationPath" -ForegroundColor Green
    } else {
        # Essayer le fichier original
        $granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularizationWithTimeEstimation.ps1"
        if (Test-Path -Path $granularizationPath) {
            . $granularizationPath
            Write-Host "Chargement de la fonction Invoke-RoadmapGranularizationWithTimeEstimation depuis $granularizationPath" -ForegroundColor Green
        } else {
            Write-Warning "La fonction Invoke-RoadmapGranularizationWithTimeEstimation est introuvable. Utilisation de la fonction standard."
            $useTimeEstimation = $false
        }

        if ($useTimeEstimation) {
            # Ajouter les paramètres spécifiques à l'estimation de temps
            $params.AddTimeEstimation = $true

            # Convertir le niveau de complexité si nécessaire
            if ($ComplexityLevel -eq "Auto") {
                $params.ComplexityLevel = "Medium" # Valeur par défaut
            } else {
                $params.ComplexityLevel = $ComplexityLevel
            }

            $params.Domain = $Domain

            Write-Host "Utilisation de la fonction avec estimation de temps..." -ForegroundColor Yellow
            $result = Invoke-RoadmapGranularizationWithTimeEstimation @params
        }
    }

    if (-not $useTimeEstimation) {
        # Importer la fonction Invoke-RoadmapGranularization si elle n'est pas déjà disponible
        # Essayer d'abord avec le chemin relatif
        $projectRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName

        # Essayer d'abord le fichier corrigé
        $granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularization-Fixed.ps1"
        if (Test-Path -Path $granularizationPath) {
            . $granularizationPath
            Write-Host "Chargement de la fonction Invoke-RoadmapGranularization depuis $granularizationPath" -ForegroundColor Green
        } else {
            # Essayer le fichier original
            $granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1"
            if (Test-Path -Path $granularizationPath) {
                . $granularizationPath
                Write-Host "Chargement de la fonction Invoke-RoadmapGranularization depuis $granularizationPath" -ForegroundColor Green
            } else {
                # Essayer d'autres chemins possibles
                $granularizationPath = Join-Path -Path $projectRoot -ChildPath "scripts\roadmap-parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1"
                if (Test-Path -Path $granularizationPath) {
                    . $granularizationPath
                    Write-Host "Chargement de la fonction Invoke-RoadmapGranularization depuis $granularizationPath" -ForegroundColor Green
                } else {
                    Write-Error "La fonction Invoke-RoadmapGranularization est introuvable. Assurez-vous que le fichier Invoke-RoadmapGranularization.ps1 ou Invoke-RoadmapGranularization-Fixed.ps1 est présent dans le répertoire development\roadmap\parser\module\Functions\Public\"
                    exit 1
                }
            }
        }

        $result = Invoke-RoadmapGranularization @params
    }

    # Afficher un message de fin
    Write-Host "`nExécution du mode GRAN terminée." -ForegroundColor Cyan
    Write-Host "Le document a été modifié : $FilePath" -ForegroundColor Green

    # Retourner le résultat
    return $result
