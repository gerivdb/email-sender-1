<#
.SYNOPSIS
    Script pour dÃ©composer une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires (Mode GRAN).
    Version adaptÃ©e pour utiliser la configuration unifiÃ©e et gÃ©rer diffÃ©rents niveaux de complexitÃ©.

.DESCRIPTION
    Ce script permet de dÃ©composer une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires
    directement dans le document. Il implÃ©mente le mode GRAN (GranularitÃ©) dÃ©crit dans
    la documentation des modes de fonctionnement.
    Cette version est adaptÃ©e pour utiliser la configuration unifiÃ©e et peut gÃ©nÃ©rer
    un nombre variable de sous-tÃ¢ches selon la complexitÃ© de la tÃ¢che principale.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  dÃ©composer (par exemple, "1.2.1.3.2.3").
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  le saisir.

.PARAMETER SubTasksFile
    Chemin vers un fichier contenant les sous-tÃ¢ches Ã  crÃ©er, une par ligne.
    Si non spÃ©cifiÃ©, le script utilisera un modÃ¨le basÃ© sur la complexitÃ©.

.PARAMETER ComplexityLevel
    Niveau de complexitÃ© de la tÃ¢che Ã  dÃ©composer.
    Options : "Simple", "Medium", "Complex", "Auto".
    Par dÃ©faut : "Auto" (dÃ©tection automatique basÃ©e sur le contenu de la tÃ¢che).

.PARAMETER IndentationStyle
    Style d'indentation Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case Ã  cocher Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "GitHub", "Custom", "Auto".

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json".

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -ComplexityLevel "Complex"

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"

.NOTES
    Auteur: RoadmapParser Team
    Version: 3.0
    Date de crÃ©ation: 2023-08-15
    Date de mise Ã  jour: 2025-06-01 - Adaptation pour gÃ©rer diffÃ©rents niveaux de complexitÃ©
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

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Stocker la clÃ© API dans une variable de script si elle est fournie
if ($ApiKey) {
    $Script:OpenRouterApiKey = $ApiKey

    # DÃ©finir Ã©galement la variable d'environnement pour les appels qui n'utilisent pas le gestionnaire de credentials
    [Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $ApiKey, "Process")
    Write-Host "ClÃ© API dÃ©finie pour cette session." -ForegroundColor Green
}

# Stocker le modÃ¨le dans une variable de script si il est fourni
if ($Model) {
    $Script:AIModel = $Model
    Write-Host "ModÃ¨le dÃ©fini pour cette session : $Model" -ForegroundColor Green
}

# Charger la configuration unifiÃ©e
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
            Write-Host "Fichier de configuration trouvÃ© Ã  l'emplacement : $fullPath" -ForegroundColor Green
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
        Write-Error "Aucun fichier de configuration valide trouvÃ©."
        exit 1
    }
}

# Utiliser les valeurs de la configuration si les paramÃ¨tres ne sont pas spÃ©cifiÃ©s
if (-not $FilePath) {
    if ($config.Modes.Gran.DefaultRoadmapFile) {
        $FilePath = Join-Path -Path $projectRoot -ChildPath $config.Modes.Gran.DefaultRoadmapFile
    } elseif ($config.General.ActiveDocumentPath) {
        $FilePath = Join-Path -Path $projectRoot -ChildPath $config.General.ActiveDocumentPath
    } else {
        Write-Error "Aucun fichier de roadmap spÃ©cifiÃ© et aucun fichier par dÃ©faut trouvÃ© dans la configuration."
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

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $FilePath"
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

# Afficher les paramÃ¨tres
Write-Host "Mode GRAN - DÃ©composition de tÃ¢ches en sous-tÃ¢ches" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Gray
if ($TaskIdentifier) {
    Write-Host "Identifiant de tÃ¢che : $TaskIdentifier" -ForegroundColor Gray
}
if ($SubTasksInput) {
    Write-Host "Sous-tÃ¢ches fournies via paramÃ¨tre SubTasksInput" -ForegroundColor Gray
} elseif ($SubTasksFile) {
    Write-Host "Fichier de sous-tÃ¢ches : $SubTasksFile" -ForegroundColor Gray
} else {
    Write-Host "Niveau de complexitÃ© : $ComplexityLevel" -ForegroundColor Gray
    if ($Domain -ne "None") {
        Write-Host "Domaine : $Domain" -ForegroundColor Gray
    } else {
        Write-Host "Domaine : Auto-dÃ©tection" -ForegroundColor Gray
    }
}
Write-Host "Style d'indentation : $IndentationStyle" -ForegroundColor Gray
Write-Host "Style de case Ã  cocher : $CheckboxStyle" -ForegroundColor Gray
Write-Host ""

# Fonction pour charger la configuration des modÃ¨les de sous-tÃ¢ches
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
            Write-Warning "Erreur lors du chargement de la configuration des modÃ¨les de sous-tÃ¢ches : $_"
            return $null
        }
    } else {
        Write-Warning "Fichier de configuration des modÃ¨les de sous-tÃ¢ches introuvable : $configPath"
        return $null
    }
}

# Fonction pour dÃ©tecter automatiquement la complexitÃ© et le domaine d'une tÃ¢che
function Get-TaskComplexityAndDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    # Initialiser les scores pour chaque niveau de complexitÃ©
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

    # DÃ©finir des poids pour diffÃ©rents types d'analyse
    $keywordWeight = 2.0        # Poids pour les correspondances de mots-clÃ©s exacts
    $semanticWeight = 1.5       # Poids pour l'analyse sÃ©mantique
    $lengthWeight = 1.0         # Poids pour l'analyse de longueur
    $positionWeight = 1.2       # Poids pour les mots-clÃ©s en dÃ©but de phrase

    # Normaliser le contenu de la tÃ¢che pour l'analyse
    $normalizedContent = $TaskContent.ToLower()

    # Extraire le titre de la tÃ¢che (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($normalizedContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $normalizedContent }

    # VÃ©rifier les mots-clÃ©s de complexitÃ© dans le contenu de la tÃ¢che avec pondÃ©ration
    foreach ($level in $complexityScores.Keys) {
        foreach ($keyword in $Config.keywords.$level) {
            $keywordLower = $keyword.ToLower()

            # Correspondance exacte
            if ($normalizedContent -match $keywordLower) {
                $complexityScores[$level] += $keywordWeight

                # Bonus si le mot-clÃ© est au dÃ©but du titre
                if ($taskTitle -match "^.*?\b$keywordLower\b") {
                    $complexityScores[$level] += $positionWeight
                }
            }

            # Analyse sÃ©mantique simplifiÃ©e (vÃ©rifier si des mots similaires sont prÃ©sents)
            $similarWords = Get-SimilarWords -Word $keywordLower
            foreach ($similarWord in $similarWords) {
                if ($normalizedContent -match $similarWord) {
                    $complexityScores[$level] += $semanticWeight * 0.5
                }
            }
        }
    }

    # VÃ©rifier les mots-clÃ©s de domaine dans le contenu de la tÃ¢che avec pondÃ©ration
    foreach ($domain in $domainScores.Keys) {
        if ($Config.keywords.PSObject.Properties.Name -contains $domain) {
            foreach ($keyword in $Config.keywords.$domain) {
                $keywordLower = $keyword.ToLower()

                # Correspondance exacte
                if ($normalizedContent -match $keywordLower) {
                    $domainScores[$domain] += $keywordWeight

                    # Bonus si le mot-clÃ© est au dÃ©but du titre
                    if ($taskTitle -match "^.*?\b$keywordLower\b") {
                        $domainScores[$domain] += $positionWeight
                    }
                }

                # Analyse sÃ©mantique simplifiÃ©e
                $similarWords = Get-SimilarWords -Word $keywordLower
                foreach ($similarWord in $similarWords) {
                    if ($normalizedContent -match $similarWord) {
                        $domainScores[$domain] += $semanticWeight * 0.5
                    }
                }
            }
        }
    }

    # VÃ©rifier la longueur du contenu (indicateur de complexitÃ©)
    $wordCount = ($normalizedContent -split '\s+').Count
    if ($wordCount -lt 10) {
        $complexityScores["simple"] += $lengthWeight * 2
    } elseif ($wordCount -lt 30) {
        $complexityScores["medium"] += $lengthWeight * 2
    } else {
        $complexityScores["complex"] += $lengthWeight * 2
    }

    # Analyse de la structure des phrases (phrases complexes = tÃ¢che complexe)
    $sentenceCount = ($normalizedContent -split '[.!?]').Count
    $avgWordsPerSentence = if ($sentenceCount -gt 0) { $wordCount / $sentenceCount } else { $wordCount }

    if ($avgWordsPerSentence -gt 15) {
        $complexityScores["complex"] += $lengthWeight
    } elseif ($avgWordsPerSentence -gt 10) {
        $complexityScores["medium"] += $lengthWeight
    } else {
        $complexityScores["simple"] += $lengthWeight
    }

    # DÃ©terminer le niveau de complexitÃ© en fonction des scores
    $maxComplexityScore = 0
    $maxComplexityLevel = "medium" # Par dÃ©faut

    foreach ($level in $complexityScores.Keys) {
        if ($complexityScores[$level] -gt $maxComplexityScore) {
            $maxComplexityScore = $complexityScores[$level]
            $maxComplexityLevel = $level
        }
    }

    # DÃ©terminer les domaines en fonction des scores (peut retourner plusieurs domaines)
    $domains = @()
    $domainThreshold = 2 * $keywordWeight # Seuil minimal pour considÃ©rer un domaine comme pertinent

    # Trier les domaines par score dÃ©croissant
    $sortedDomains = $domainScores.GetEnumerator() | Sort-Object -Property Value -Descending

    # SÃ©lectionner les domaines au-dessus du seuil
    foreach ($domain in $sortedDomains) {
        if ($domain.Value -ge $domainThreshold) {
            $domains += $domain.Key
        }
    }

    # Limiter Ã  3 domaines maximum pour Ã©viter la surcharge
    if ($domains.Count -gt 3) {
        $domains = $domains[0..2]
    }

    # Pour la compatibilitÃ©, on retourne le domaine principal comme avant
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

# Fonction pour estimer le temps nÃ©cessaire pour une sous-tÃ¢che
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

    # Normaliser le contenu de la tÃ¢che
    $normalizedContent = $TaskContent.ToLower()

    # DÃ©terminer le type de tÃ¢che (analyse, conception, implÃ©mentation, test, documentation)
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

    # Obtenir le temps de base pour ce type de tÃ¢che
    $baseTime = $timeConfig.base_times.$taskType.value
    $timeUnit = $timeConfig.base_times.$taskType.unit

    # Appliquer le multiplicateur de complexitÃ©
    $complexityMultiplier = $timeConfig.complexity_multipliers.($ComplexityLevel.ToLower())
    $estimatedTime = $baseTime * $complexityMultiplier

    # Appliquer le multiplicateur de domaine si spÃ©cifiÃ©
    if ($Domain -and $timeConfig.domain_multipliers.PSObject.Properties.Name -contains $Domain.ToLower()) {
        $domainMultiplier = $timeConfig.domain_multipliers.($Domain.ToLower())
        $estimatedTime = $estimatedTime * $domainMultiplier
    }

    # Arrondir Ã  0.5 prÃ¨s
    $estimatedTime = [Math]::Round($estimatedTime * 2) / 2

    # Retourner l'estimation
    return @{
        Time      = $estimatedTime
        Unit      = $timeUnit
        Type      = $taskType
        Formatted = "$estimatedTime $timeUnit"
    }
}

# Fonction pour obtenir des mots similaires (analyse sÃ©mantique simplifiÃ©e)
function Get-SimilarWords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Word
    )

    # Dictionnaire simplifiÃ© de synonymes et de mots associÃ©s
    $synonyms = @{
        # ComplexitÃ©
        "simple"          = @("facile", "basique", "Ã©lÃ©mentaire", "rapide", "direct")
        "facile"          = @("simple", "aisÃ©", "accessible", "Ã©vident")
        "basique"         = @("simple", "fondamental", "Ã©lÃ©mentaire", "essentiel")
        "moyen"           = @("intermÃ©diaire", "modÃ©rÃ©", "standard", "normal")
        "standard"        = @("normal", "habituel", "courant", "conventionnel")
        "normal"          = @("standard", "rÃ©gulier", "ordinaire", "habituel")
        "complexe"        = @("compliquÃ©", "difficile", "sophistiquÃ©", "Ã©laborÃ©", "avancÃ©")
        "difficile"       = @("complexe", "ardu", "compliquÃ©", "exigeant", "dÃ©licat")
        "critique"        = @("crucial", "essentiel", "vital", "important", "majeur")

        # Domaines
        "interface"       = @("UI", "frontend", "affichage", "Ã©cran", "visuel")
        "ui"              = @("interface", "frontend", "visuel", "Ã©cran")
        "ux"              = @("expÃ©rience utilisateur", "interface", "ergonomie", "utilisabilitÃ©")
        "frontend"        = @("interface", "client", "UI", "prÃ©sentation", "affichage")
        "api"             = @("interface de programmation", "service", "endpoint", "backend")
        "service"         = @("API", "backend", "microservice", "fonctionnalitÃ©")
        "backend"         = @("serveur", "API", "service", "traitement", "logique mÃ©tier")
        "base de donnÃ©es" = @("BDD", "SQL", "stockage", "donnÃ©es", "persistance")
        "sql"             = @("base de donnÃ©es", "requÃªte", "stockage", "donnÃ©es")
        "test"            = @("vÃ©rification", "validation", "contrÃ´le", "qualitÃ©")
        "sÃ©curitÃ©"        = @("protection", "authentification", "autorisation", "chiffrement")
        "ia"              = @("intelligence artificielle", "ML", "apprentissage", "modÃ¨le")
        "ml"              = @("machine learning", "IA", "apprentissage", "modÃ¨le")
        "documentation"   = @("doc", "guide", "manuel", "rÃ©fÃ©rence", "tutoriel")
        "devops"          = @("CI/CD", "dÃ©ploiement", "intÃ©gration", "livraison", "pipeline")
    }

    # Retourner les synonymes si le mot est dans le dictionnaire
    if ($synonyms.ContainsKey($Word)) {
        return $synonyms[$Word]
    }

    # Sinon, retourner un tableau vide
    return @()
}

# Fonction pour dÃ©tecter automatiquement la complexitÃ© d'une tÃ¢che (pour compatibilitÃ©)
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityConfig
    )

    # Utiliser la nouvelle fonction pour obtenir la complexitÃ© et le domaine
    $result = Get-TaskComplexityAndDomain -TaskContent $TaskContent -Config $ComplexityConfig

    # Retourner uniquement la complexitÃ© pour maintenir la compatibilitÃ©
    return $result.Complexity
}

# Fonction pour obtenir le modÃ¨le de sous-tÃ¢ches appropriÃ©
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

    # Si des domaines multiples sont spÃ©cifiÃ©s, utiliser ceux-lÃ 
    if (-not $Domains -and $Domain -ne "None") {
        $Domains = @($Domain)
    }

    # Si l'option de combinaison de modÃ¨les est activÃ©e et qu'il y a plusieurs domaines
    if ($CombineModels -and $Domains -and $Domains.Count -gt 1) {
        return Get-CombinedDomainTemplate -Domains $Domains -TemplateConfig $TemplateConfig -ProjectRoot $ProjectRoot
    }

    # VÃ©rifier si un domaine spÃ©cifique est demandÃ© et s'il existe
    $useDomainTemplate = $false
    $normalizedDomain = if ($Domain -ne "None") { $Domain.ToLower() } else { "none" }

    if ($normalizedDomain -ne "none" -and $TemplateConfig.domain_templates -and $TemplateConfig.domain_templates.PSObject.Properties.Name -contains $normalizedDomain) {
        $useDomainTemplate = $true
    }

    if ($useDomainTemplate) {
        # Utiliser le modÃ¨le spÃ©cifique au domaine
        $templateFilePath = $TemplateConfig.domain_templates.$normalizedDomain.template_file

        # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
        if (-not [System.IO.Path]::IsPathRooted($templateFilePath)) {
            $templateFilePath = Join-Path -Path $ProjectRoot -ChildPath $templateFilePath
        }

        # VÃ©rifier si le fichier de modÃ¨le existe
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
                Write-Warning "Erreur lors du chargement du modÃ¨le de sous-tÃ¢ches spÃ©cifique au domaine : $_"
                # Continuer avec le modÃ¨le basÃ© sur la complexitÃ©
            }
        } else {
            Write-Warning "Fichier de modÃ¨le de sous-tÃ¢ches spÃ©cifique au domaine introuvable : $templateFilePath"
            # Continuer avec le modÃ¨le basÃ© sur la complexitÃ©
        }
    }

    # Utiliser le modÃ¨le basÃ© sur la complexitÃ©

    # Normaliser le niveau de complexitÃ©
    $normalizedLevel = $ComplexityLevel.ToLower()
    if ($normalizedLevel -eq "auto") {
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # VÃ©rifier si le niveau de complexitÃ© est valide
    if (-not $TemplateConfig.complexity_levels.$normalizedLevel) {
        Write-Warning "Niveau de complexitÃ© non reconnu : $ComplexityLevel. Utilisation du niveau par dÃ©faut : $($TemplateConfig.default_complexity)"
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # Obtenir le chemin du fichier de modÃ¨le
    $templateFilePath = $TemplateConfig.complexity_levels.$normalizedLevel.template_file

    # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
    if (-not [System.IO.Path]::IsPathRooted($templateFilePath)) {
        $templateFilePath = Join-Path -Path $ProjectRoot -ChildPath $templateFilePath
    }

    # VÃ©rifier si le fichier de modÃ¨le existe
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
            Write-Warning "Erreur lors du chargement du modÃ¨le de sous-tÃ¢ches : $_"
            return $null
        }
    } else {
        Write-Warning "Fichier de modÃ¨le de sous-tÃ¢ches introuvable : $templateFilePath"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer des sous-tÃ¢ches avec l'IA
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

    # Si la simulation est activÃ©e, utiliser des donnÃ©es simulÃ©es
    if ($Simulate) {
        Write-Host "Mode simulation activÃ© pour la gÃ©nÃ©ration de sous-tÃ¢ches par IA." -ForegroundColor Yellow

        # Simuler un dÃ©lai de traitement
        Start-Sleep -Seconds 2

        # GÃ©nÃ©rer des sous-tÃ¢ches en fonction du domaine et de la complexitÃ©
        $generatedTasks = @()

        # Sous-tÃ¢ches communes Ã  tous les domaines
        $generatedTasks += "Analyser les besoins du systÃ¨me"

        # Sous-tÃ¢ches spÃ©cifiques au domaine Backend
        if ($Domains -contains "Backend") {
            $generatedTasks += "Concevoir l'architecture du backend"
            $generatedTasks += "ImplÃ©menter les modÃ¨les de donnÃ©es"
            $generatedTasks += "DÃ©velopper les API RESTful"
        }

        # Sous-tÃ¢ches spÃ©cifiques au domaine Security
        if ($Domains -contains "Security") {
            $generatedTasks += "ImplÃ©menter le systÃ¨me d'authentification"
            $generatedTasks += "Configurer les autorisations et rÃ´les"
            $generatedTasks += "Mettre en place le chiffrement des donnÃ©es sensibles"
        }

        # Sous-tÃ¢ches spÃ©cifiques au domaine Frontend
        if ($Domains -contains "Frontend") {
            $generatedTasks += "Concevoir l'interface utilisateur"
            $generatedTasks += "DÃ©velopper les composants React"
            $generatedTasks += "ImplÃ©menter les formulaires et validations"
        }

        # Sous-tÃ¢ches communes de fin
        $generatedTasks += "Tester toutes les fonctionnalitÃ©s"
        $generatedTasks += "Documenter l'API et l'utilisation"

        # Ajuster le nombre de sous-tÃ¢ches en fonction de la complexitÃ©
        if ($ComplexityLevel -eq "Simple") {
            # Garder seulement 3-4 tÃ¢ches pour les tÃ¢ches simples
            $generatedTasks = $generatedTasks | Select-Object -First 4
        } elseif ($ComplexityLevel -eq "Complex") {
            # Ajouter des tÃ¢ches supplÃ©mentaires pour les tÃ¢ches complexes
            $generatedTasks += "Optimiser les performances"
            $generatedTasks += "Mettre en place la surveillance et les alertes"
            $generatedTasks += "PrÃ©parer le dÃ©ploiement en production"
        }

        # Limiter le nombre de sous-tÃ¢ches au maximum spÃ©cifiÃ©
        if ($generatedTasks.Count -gt $MaxSubTasks) {
            $generatedTasks = $generatedTasks | Select-Object -First $MaxSubTasks
        }

        Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es avec succÃ¨s par l'IA (simulation)." -ForegroundColor Green

        # Retourner les sous-tÃ¢ches gÃ©nÃ©rÃ©es
        return @{
            Content     = $generatedTasks -join "`r`n"
            Level       = "ai"
            Domain      = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
            Domains     = $Domains
            Description = "Sous-tÃ¢ches gÃ©nÃ©rÃ©es par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
            MaxSubTasks = $MaxSubTasks
            Combined    = $false
            AI          = $true
        }
    }

    # Mode normal (non simulÃ©)
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

    # VÃ©rifier si l'IA est activÃ©e
    if (-not $aiConfig.enabled) {
        Write-Warning "La gÃ©nÃ©ration de sous-tÃ¢ches par IA est dÃ©sactivÃ©e dans la configuration."
        return $null
    }

    # VÃ©rifier si la clÃ© API est dÃ©finie
    $credentialName = $aiConfig.credential_name

    # Essayer d'utiliser le gestionnaire de credentials si disponible
    $credentialManagerPath = Join-Path -Path $ProjectRoot -ChildPath "development\tools\security\credential-manager.ps1"
    if (Test-Path -Path $credentialManagerPath) {
        try {
            # Importer le module de gestion des credentials
            . $credentialManagerPath

            # RÃ©cupÃ©rer la clÃ© API
            $apiKey = Get-SecureCredential -Name $credentialName

            # Si la clÃ© n'est pas trouvÃ©e, essayer de l'enregistrer si elle est fournie en paramÃ¨tre
            if (-not $apiKey -and $Script:OpenRouterApiKey) {
                Set-SecureCredential -Name $credentialName -Value $Script:OpenRouterApiKey -StorageType "Environment"
                $apiKey = $Script:OpenRouterApiKey
            }
        } catch {
            Write-Warning "Erreur lors de l'utilisation du gestionnaire de credentials : $_"
            # Fallback : essayer de rÃ©cupÃ©rer la clÃ© API depuis les variables d'environnement
            $apiKey = [Environment]::GetEnvironmentVariable($credentialName)
        }
    } else {
        # Fallback : essayer de rÃ©cupÃ©rer la clÃ© API depuis les variables d'environnement
        $apiKey = [Environment]::GetEnvironmentVariable($credentialName)
    }

    if (-not $apiKey) {
        Write-Warning "ClÃ© API non dÃ©finie pour $credentialName"
        return $null
    }

    # Extraire le titre de la tÃ¢che (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($TaskContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $TaskContent }

    # PrÃ©parer les domaines pour le prompt
    $domainsText = if ($Domains -and $Domains.Count -gt 0) {
        $Domains -join ", "
    } else {
        "Non spÃ©cifiÃ©"
    }

    # PrÃ©parer le prompt
    $prompt = $aiConfig.prompt_template -replace "{task}", $taskTitle -replace "{complexity}", $ComplexityLevel -replace "{domains}", $domainsText -replace "{max_subtasks}", $MaxSubTasks

    # PrÃ©parer la requÃªte API
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $apiKey"
        "HTTP-Referer"  = "https://github.com/augmentcode-ai"  # Requis par OpenRouter
        "X-Title"       = "Roadmap Task Granularization"  # Titre de l'application
    }

    # DÃ©terminer le modÃ¨le Ã  utiliser
    $model = if ($Script:AIModel) {
        # Utiliser le modÃ¨le spÃ©cifiÃ© en paramÃ¨tre
        $Script:AIModel
    } elseif ($aiConfig.models -and $aiConfig.models.default) {
        # Utiliser le modÃ¨le par dÃ©faut de la configuration
        $aiConfig.models.default
    } elseif ($aiConfig.model) {
        # Utiliser le modÃ¨le de la configuration (ancienne structure)
        $aiConfig.model
    } else {
        # ModÃ¨le par dÃ©faut si aucun n'est spÃ©cifiÃ©
        "qwen/qwen3-32b:free"
    }

    Write-Host "Utilisation du modÃ¨le : $model" -ForegroundColor Gray

    $body = @{
        model       = $model
        messages    = @(
            @{
                role    = "system"
                content = "Tu es un expert en gestion de projet et en dÃ©composition de tÃ¢ches. Tu vas gÃ©nÃ©rer une liste de sous-tÃ¢ches pour une tÃ¢che donnÃ©e."
            },
            @{
                role    = "user"
                content = $prompt
            }
        )
        temperature = $aiConfig.temperature
        max_tokens  = $aiConfig.max_tokens
    } | ConvertTo-Json

    # DÃ©terminer l'URL de l'API
    $apiUrl = if ($aiConfig.api_url) { $aiConfig.api_url } else { "https://api.openai.com/v1/chat/completions" }

    # Appeler l'API
    try {
        Write-Host "GÃ©nÃ©ration de sous-tÃ¢ches avec l'IA..." -ForegroundColor Yellow
        Write-Host "Utilisation de l'API : $apiUrl" -ForegroundColor Gray

        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body

        # Traiter la rÃ©ponse
        $generatedContent = $response.choices[0].message.content

        # Nettoyer le contenu gÃ©nÃ©rÃ© (supprimer les numÃ©ros, les tirets, etc.)
        $lines = $generatedContent -split "`n" | ForEach-Object {
            $line = $_.Trim()
            # Supprimer les numÃ©ros et les tirets au dÃ©but de la ligne
            $line = $line -replace "^(\d+[\.\)]\s*|\-\s*)", ""
            # Ignorer les lignes vides
            if ($line) { $line }
        }

        # Limiter le nombre de sous-tÃ¢ches
        if ($lines.Count -gt $MaxSubTasks) {
            $lines = $lines[0..($MaxSubTasks - 1)]
        }

        Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es avec succÃ¨s par l'IA." -ForegroundColor Green

        # Retourner les sous-tÃ¢ches gÃ©nÃ©rÃ©es
        return @{
            Content     = $lines -join "`r`n"
            Level       = "ai"
            Domain      = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
            Domains     = $Domains
            Description = "Sous-tÃ¢ches gÃ©nÃ©rÃ©es par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
            MaxSubTasks = $MaxSubTasks
            Combined    = $false
            AI          = $true
        }
    } catch {
        Write-Warning "Erreur lors de l'appel Ã  l'API IA : $_"
        return $null
    }
}

# Fonction pour combiner plusieurs modÃ¨les de domaines
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

    # Si aucun domaine valide n'est trouvÃ©, retourner null
    if ($normalizedDomains.Count -eq 0) {
        Write-Warning "Aucun domaine valide spÃ©cifiÃ© pour la combinaison de modÃ¨les."
        return $null
    }

    # Si un seul domaine est valide, utiliser ce domaine directement
    if ($normalizedDomains.Count -eq 1) {
        return Get-SubTasksTemplate -ComplexityLevel "Auto" -Domain $normalizedDomains[0] -TemplateConfig $TemplateConfig -ProjectRoot $ProjectRoot
    }

    # Charger les modÃ¨les pour chaque domaine
    $domainTemplates = @()
    $maxSubTasks = 0
    $descriptions = @()

    foreach ($domain in $normalizedDomains) {
        $templateFilePath = $TemplateConfig.domain_templates.$domain.template_file

        # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
        if (-not [System.IO.Path]::IsPathRooted($templateFilePath)) {
            $templateFilePath = Join-Path -Path $ProjectRoot -ChildPath $templateFilePath
        }

        # VÃ©rifier si le fichier de modÃ¨le existe
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
                Write-Warning "Erreur lors du chargement du modÃ¨le pour le domaine $domain : $_"
            }
        } else {
            Write-Warning "Fichier de modÃ¨le introuvable pour le domaine $domain : $templateFilePath"
        }
    }

    # Si aucun modÃ¨le n'a pu Ãªtre chargÃ©, retourner null
    if ($domainTemplates.Count -eq 0) {
        Write-Warning "Aucun modÃ¨le n'a pu Ãªtre chargÃ© pour les domaines spÃ©cifiÃ©s."
        return $null
    }

    # Combiner les modÃ¨les en utilisant un algorithme intelligent
    $combinedTasks = @()
    $usedTasks = @{}

    # Ajouter les tÃ¢ches d'analyse et de conception qui sont communes Ã  tous les domaines
    $commonPrefixes = @(
        "Analyser les besoins",
        "Concevoir",
        "DÃ©finir",
        "Planifier"
    )

    foreach ($template in $domainTemplates) {
        foreach ($task in $template.Content) {
            $taskTrimmed = $task.Trim()
            if ($taskTrimmed -eq "") { continue }

            # VÃ©rifier si la tÃ¢che commence par un prÃ©fixe commun
            $isCommonTask = $false
            foreach ($prefix in $commonPrefixes) {
                if ($taskTrimmed -like "$prefix*") {
                    $isCommonTask = $true
                    break
                }
            }

            # Si c'est une tÃ¢che commune et qu'elle n'a pas dÃ©jÃ  Ã©tÃ© ajoutÃ©e
            if ($isCommonTask -and -not $usedTasks.ContainsKey($taskTrimmed)) {
                $combinedTasks += $taskTrimmed
                $usedTasks[$taskTrimmed] = $true
            }
        }
    }

    # Ajouter les tÃ¢ches spÃ©cifiques Ã  chaque domaine
    foreach ($template in $domainTemplates) {
        $domainSpecificTasks = 0

        foreach ($task in $template.Content) {
            $taskTrimmed = $task.Trim()
            if ($taskTrimmed -eq "") { continue }

            # VÃ©rifier si la tÃ¢che est spÃ©cifique au domaine (ne commence pas par un prÃ©fixe commun)
            $isDomainSpecific = $true
            foreach ($prefix in $commonPrefixes) {
                if ($taskTrimmed -like "$prefix*") {
                    $isDomainSpecific = $false
                    break
                }
            }

            # Si c'est une tÃ¢che spÃ©cifique au domaine et qu'elle n'a pas dÃ©jÃ  Ã©tÃ© ajoutÃ©e
            if ($isDomainSpecific -and -not $usedTasks.ContainsKey($taskTrimmed)) {
                # PrÃ©fixer la tÃ¢che avec le nom du domaine pour Ã©viter les ambiguÃ¯tÃ©s
                $prefixedTask = "[$($template.Domain)] $taskTrimmed"
                $combinedTasks += $prefixedTask
                $usedTasks[$taskTrimmed] = $true
                $domainSpecificTasks++

                # Limiter le nombre de tÃ¢ches spÃ©cifiques par domaine pour Ã©viter un modÃ¨le trop grand
                if ($domainSpecificTasks -ge 3) {
                    break
                }
            }
        }
    }

    # Ajouter des tÃ¢ches communes de fin (tests, documentation)
    $commonSuffixes = @(
        "Tester",
        "Documenter",
        "Optimiser"
    )

    foreach ($template in $domainTemplates) {
        foreach ($task in $template.Content) {
            $taskTrimmed = $task.Trim()
            if ($taskTrimmed -eq "") { continue }

            # VÃ©rifier si la tÃ¢che commence par un suffixe commun
            $isCommonEndTask = $false
            foreach ($suffix in $commonSuffixes) {
                if ($taskTrimmed -like "$suffix*") {
                    $isCommonEndTask = $true
                    break
                }
            }

            # Si c'est une tÃ¢che commune de fin et qu'elle n'a pas dÃ©jÃ  Ã©tÃ© ajoutÃ©e
            if ($isCommonEndTask -and -not $usedTasks.ContainsKey($taskTrimmed)) {
                $combinedTasks += $taskTrimmed
                $usedTasks[$taskTrimmed] = $true
            }
        }
    }

    # Limiter le nombre total de tÃ¢ches
    $maxCombinedTasks = [Math]::Min($maxSubTasks, 15) # Maximum 15 tÃ¢ches pour Ã©viter la surcharge
    if ($combinedTasks.Count -gt $maxCombinedTasks) {
        $combinedTasks = $combinedTasks[0..($maxCombinedTasks - 1)]
    }

    # CrÃ©er la description combinÃ©e
    $combinedDescription = "Combinaison des domaines: " + ($normalizedDomains -join ", ")

    # Retourner le modÃ¨le combinÃ©
    return @{
        Content     = $combinedTasks -join "`r`n"
        Level       = "domain"
        Domain      = $normalizedDomains[0] # Le premier domaine est considÃ©rÃ© comme principal
        Domains     = $normalizedDomains
        Description = $combinedDescription
        MaxSubTasks = $maxCombinedTasks
        Combined    = $true
    }
}

# Charger la configuration des modÃ¨les de sous-tÃ¢ches
$templateConfig = Get-SubTasksTemplateConfig -ProjectRoot $projectRoot

# Lire les sous-tÃ¢ches Ã  partir du fichier ou du paramÃ¨tre SubTasksInput
$subTasksInput = ""
if ($SubTasksInput) {
    # Utiliser directement les sous-tÃ¢ches fournies en paramÃ¨tre
    $subTasksInput = $SubTasksInput
    Write-Host "Sous-tÃ¢ches fournies via le paramÃ¨tre SubTasksInput" -ForegroundColor Green
} elseif ($SubTasksFile) {
    if (Test-Path -Path $SubTasksFile) {
        $subTasksInput = Get-Content -Path $SubTasksFile -Encoding UTF8 -Raw
        Write-Host "Sous-tÃ¢ches lues depuis le fichier : $SubTasksFile" -ForegroundColor Green
    } else {
        Write-Error "Le fichier de sous-tÃ¢ches spÃ©cifiÃ© n'existe pas : $SubTasksFile"
        exit 1
    }
} elseif ($templateConfig) {
    # Si aucun fichier de sous-tÃ¢ches n'est spÃ©cifiÃ©, utiliser un modÃ¨le basÃ© sur la complexitÃ©

    # Si l'identifiant de tÃ¢che est spÃ©cifiÃ©, lire le contenu de la tÃ¢che pour dÃ©terminer sa complexitÃ© et son domaine
    if ($TaskIdentifier -and ($ComplexityLevel -eq "Auto" -or $Domain -eq "None")) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Trouver la ligne contenant la tÃ¢che Ã  dÃ©composer
        $taskLineIndex = -1
        $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match $taskLinePattern) {
                $taskLineIndex = $i
                break
            }
        }

        if ($taskLineIndex -ne -1) {
            # Extraire le contenu de la tÃ¢che (la ligne elle-mÃªme)
            $taskContent = $content[$taskLineIndex]

            # DÃ©terminer la complexitÃ© et les domaines de la tÃ¢che
            $taskAnalysis = Get-TaskComplexityAndDomain -TaskContent $taskContent -Config $templateConfig

            # Utiliser la complexitÃ© dÃ©tectÃ©e si nÃ©cessaire
            $effectiveComplexity = $ComplexityLevel
            if ($ComplexityLevel -eq "Auto") {
                $effectiveComplexity = $taskAnalysis.Complexity
                Write-Host "ComplexitÃ© dÃ©tectÃ©e : $effectiveComplexity (score: $($taskAnalysis.ComplexityScore))" -ForegroundColor Cyan

                # Afficher les scores de complexitÃ© dÃ©taillÃ©s
                Write-Host "  Scores de complexitÃ© : " -ForegroundColor Gray -NoNewline
                foreach ($level in $taskAnalysis.ComplexityScores.Keys | Sort-Object) {
                    Write-Host "$level=$($taskAnalysis.ComplexityScores[$level]) " -ForegroundColor Gray -NoNewline
                }
                Write-Host ""
            }

            # Utiliser les domaines dÃ©tectÃ©s si nÃ©cessaire
            $effectiveDomains = @()
            if ($Domain -ne "None") {
                $effectiveDomains = @($Domain)
            } elseif ($taskAnalysis.Domains -and $taskAnalysis.Domains.Count -gt 0) {
                $effectiveDomains = $taskAnalysis.Domains
                Write-Host "Domaines dÃ©tectÃ©s : $($effectiveDomains -join ', ')" -ForegroundColor Cyan

                # Afficher les scores de domaine dÃ©taillÃ©s
                Write-Host "  Scores de domaine : " -ForegroundColor Gray -NoNewline
                foreach ($domain in $taskAnalysis.DomainScores.Keys | Sort-Object -Property { $taskAnalysis.DomainScores[$_] } -Descending) {
                    if ($taskAnalysis.DomainScores[$domain] -gt 0) {
                        Write-Host "$domain=$($taskAnalysis.DomainScores[$domain]) " -ForegroundColor Gray -NoNewline
                    }
                }
                Write-Host ""
            }

            # DÃ©terminer si nous devons combiner les modÃ¨les
            $useCombinedModel = $false
            if ($effectiveDomains.Count -gt 1) {
                $useCombinedModel = $true
                Write-Host "Plusieurs domaines dÃ©tectÃ©s, utilisation d'un modÃ¨le combinÃ©." -ForegroundColor Yellow
            }

            # Obtenir le modÃ¨le de sous-tÃ¢ches appropriÃ©
            $template = $null

            # Utiliser l'IA si demandÃ©
            if ($UseAI) {
                Write-Host "Utilisation de l'IA pour gÃ©nÃ©rer des sous-tÃ¢ches..." -ForegroundColor Yellow

                # DÃ©terminer le nombre maximum de sous-tÃ¢ches en fonction de la complexitÃ©
                $maxSubTasks = 5 # Par dÃ©faut
                if ($effectiveComplexity -eq "simple") {
                    $maxSubTasks = 3
                } elseif ($effectiveComplexity -eq "complex") {
                    $maxSubTasks = 10
                }

                # GÃ©nÃ©rer les sous-tÃ¢ches avec l'IA
                $template = Get-AIGeneratedSubTasks -TaskContent $taskContent -ComplexityLevel $effectiveComplexity -Domains $effectiveDomains -MaxSubTasks $maxSubTasks -ProjectRoot $projectRoot -Simulate:$SimulateAI

                # Si l'IA Ã©choue, utiliser les modÃ¨les standards
                if (-not $template) {
                    Write-Warning "La gÃ©nÃ©ration de sous-tÃ¢ches par IA a Ã©chouÃ©. Utilisation des modÃ¨les standards."
                }
            }

            # Si pas de template (pas d'IA ou Ã©chec de l'IA), utiliser les modÃ¨les standards
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
                    Write-Host "ModÃ¨le de sous-tÃ¢ches utilisÃ© : Combinaison de domaines ($($template.Description))" -ForegroundColor Green
                } elseif ($template.Domain) {
                    Write-Host "ModÃ¨le de sous-tÃ¢ches utilisÃ© : Domaine $($template.Domain) ($($template.Description))" -ForegroundColor Green
                } else {
                    Write-Host "ModÃ¨le de sous-tÃ¢ches utilisÃ© : ComplexitÃ© $($template.Level) ($($template.Description))" -ForegroundColor Green
                }

                Write-Host "Nombre maximum de sous-tÃ¢ches : $($template.MaxSubTasks)" -ForegroundColor Green
            }
        }
    } else {
        # VÃ©rifier si plusieurs domaines sont spÃ©cifiÃ©s
        $domainsList = $Domain -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "None" }
        $useCombinedModel = $domainsList.Count -gt 1

        # Obtenir le modÃ¨le de sous-tÃ¢ches appropriÃ©
        $template = $null

        # Utiliser l'IA si demandÃ©
        if ($UseAI) {
            Write-Host "Utilisation de l'IA pour gÃ©nÃ©rer des sous-tÃ¢ches..." -ForegroundColor Yellow

            # DÃ©terminer le nombre maximum de sous-tÃ¢ches en fonction de la complexitÃ©
            $maxSubTasks = 5 # Par dÃ©faut
            if ($ComplexityLevel -eq "Simple") {
                $maxSubTasks = 3
            } elseif ($ComplexityLevel -eq "Complex") {
                $maxSubTasks = 10
            }

            # CrÃ©er un contenu de tÃ¢che fictif pour l'IA
            $taskContent = "TÃ¢che Ã  dÃ©composer"
            if ($TaskIdentifier) {
                $taskContent = "**$TaskIdentifier** TÃ¢che Ã  dÃ©composer"
            }

            # GÃ©nÃ©rer les sous-tÃ¢ches avec l'IA
            $template = Get-AIGeneratedSubTasks -TaskContent $taskContent -ComplexityLevel $ComplexityLevel -Domains $domainsList -MaxSubTasks $maxSubTasks -ProjectRoot $projectRoot -Simulate:$SimulateAI

            # Si l'IA Ã©choue, utiliser les modÃ¨les standards
            if (-not $template) {
                Write-Warning "La gÃ©nÃ©ration de sous-tÃ¢ches par IA a Ã©chouÃ©. Utilisation des modÃ¨les standards."
            }
        }

        # Si pas de template (pas d'IA ou Ã©chec de l'IA), utiliser les modÃ¨les standards
        if (-not $template) {
            if ($useCombinedModel) {
                Write-Host "Plusieurs domaines spÃ©cifiÃ©s, utilisation d'un modÃ¨le combinÃ©." -ForegroundColor Yellow
                $template = Get-SubTasksTemplate -ComplexityLevel $ComplexityLevel -Domains $domainsList -TemplateConfig $templateConfig -ProjectRoot $projectRoot -CombineModels
            } else {
                $template = Get-SubTasksTemplate -ComplexityLevel $ComplexityLevel -Domain $Domain -TemplateConfig $templateConfig -ProjectRoot $projectRoot
            }
        }

        if ($template) {
            $subTasksInput = $template.Content

            if ($template.Combined) {
                Write-Host "ModÃ¨le de sous-tÃ¢ches utilisÃ© : Combinaison de domaines ($($template.Description))" -ForegroundColor Green
            } elseif ($template.Domain) {
                Write-Host "ModÃ¨le de sous-tÃ¢ches utilisÃ© : Domaine $($template.Domain) ($($template.Description))" -ForegroundColor Green
            } else {
                Write-Host "ModÃ¨le de sous-tÃ¢ches utilisÃ© : ComplexitÃ© $($template.Level) ($($template.Description))" -ForegroundColor Green
            }

            Write-Host "Nombre maximum de sous-tÃ¢ches : $($template.MaxSubTasks)" -ForegroundColor Green
        }
    }
}

# IMPORTANT: Ce script modifie DIRECTEMENT le document spÃ©cifiÃ©.
# La granularisation est appliquÃ©e en Ã©crasant (overwriting) le contenu existant.
# Aucun rÃ©sultat intermÃ©diaire n'est affichÃ© dans le terminal, seul le document est modifiÃ©.
Write-Host "ATTENTION: Ce script va modifier directement le document spÃ©cifiÃ©." -ForegroundColor Yellow
Write-Host "La granularisation sera appliquÃ©e en Ã©crasant le contenu existant." -ForegroundColor Yellow
Write-Host "Aucun rÃ©sultat intermÃ©diaire ne sera affichÃ© dans le terminal, seul le document sera modifiÃ©." -ForegroundColor Yellow
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

# DÃ©terminer quelle fonction utiliser en fonction des paramÃ¨tres
$useTimeEstimation = $AddTimeEstimation

if ($useTimeEstimation) {
    # Importer la fonction Invoke-RoadmapGranularizationWithTimeEstimation si elle n'est pas dÃ©jÃ  disponible
    # Essayer d'abord avec le chemin relatif
    $projectRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName

    # Essayer d'abord le fichier corrigÃ©
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
            # Ajouter les paramÃ¨tres spÃ©cifiques Ã  l'estimation de temps
            $params.AddTimeEstimation = $true

            # Convertir le niveau de complexitÃ© si nÃ©cessaire
            if ($ComplexityLevel -eq "Auto") {
                $params.ComplexityLevel = "Medium" # Valeur par dÃ©faut
            } else {
                $params.ComplexityLevel = $ComplexityLevel
            }

            $params.Domain = $Domain

            Write-Host "Utilisation de la fonction avec estimation de temps..." -ForegroundColor Yellow
            $result = Invoke-RoadmapGranularizationWithTimeEstimation @params
        }
    }

    if (-not $useTimeEstimation) {
        # Importer la fonction Invoke-RoadmapGranularization si elle n'est pas dÃ©jÃ  disponible
        # Essayer d'abord avec le chemin relatif
        $projectRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName

        # Essayer d'abord le fichier corrigÃ©
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
                    Write-Error "La fonction Invoke-RoadmapGranularization est introuvable. Assurez-vous que le fichier Invoke-RoadmapGranularization.ps1 ou Invoke-RoadmapGranularization-Fixed.ps1 est prÃ©sent dans le rÃ©pertoire development\roadmap\parser\module\Functions\Public\"
                    exit 1
                }
            }
        }

        $result = Invoke-RoadmapGranularization @params
    }

    # Afficher un message de fin
    Write-Host "`nExÃ©cution du mode GRAN terminÃ©e." -ForegroundColor Cyan
    Write-Host "Le document a Ã©tÃ© modifiÃ© : $FilePath" -ForegroundColor Green

    # Retourner le rÃ©sultat
    return $result
}
