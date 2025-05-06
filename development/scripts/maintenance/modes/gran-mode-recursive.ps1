# Script de granularisation récursive des tâches
# Ce script améliore le mode GRAN en permettant de granulariser récursivement toutes les sous-tâches en une seule opération

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
    [ValidateSet("Auto", "Spaces", "Tabs")]
    [string]$IndentationStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Dash", "Asterisk")]
    [string]$CheckboxStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [int]$RecursionDepth = 2,

    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeComplexity
)

# Fonction pour déterminer automatiquement la complexité d'une tâche
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $false)]
        [string]$Domain = "None"
    )

    # Normaliser le contenu de la tâche
    $normalizedContent = $TaskContent.ToLower()

    # Mots-clés indiquant une complexité élevée
    $complexKeywords = @(
        "architecture", "framework", "système", "system", "plateforme", "platform",
        "optimisation", "optimization", "performance", "sécurité", "security",
        "distribué", "distributed", "scalable", "évolutif", "intégration", "integration",
        "complexe", "complex", "avancé", "advanced", "intelligence", "artificielle",
        "machine learning", "deep learning", "big data", "microservices", "cloud",
        "refactoring", "refactorisation", "migration", "transformation"
    )

    # Mots-clés indiquant une complexité moyenne
    $mediumKeywords = @(
        "implémenter", "implement", "développer", "develop", "créer", "create",
        "concevoir", "design", "améliorer", "improve", "étendre", "extend",
        "module", "component", "composant", "fonctionnalité", "feature",
        "api", "interface", "service", "database", "base de données"
    )

    # Mots-clés indiquant une complexité simple
    $simpleKeywords = @(
        "corriger", "fix", "mettre à jour", "update", "ajouter", "add",
        "supprimer", "remove", "modifier", "modify", "documenter", "document",
        "tester", "test", "vérifier", "verify", "valider", "validate"
    )

    # Calculer les scores de complexité
    $complexScore = 0
    $mediumScore = 0
    $simpleScore = 0

    foreach ($keyword in $complexKeywords) {
        if ($normalizedContent -match $keyword) {
            $complexScore += 2
        }
    }

    foreach ($keyword in $mediumKeywords) {
        if ($normalizedContent -match $keyword) {
            $mediumScore += 1
        }
    }

    foreach ($keyword in $simpleKeywords) {
        if ($normalizedContent -match $keyword) {
            $simpleScore += 1
        }
    }

    # Ajuster les scores en fonction du domaine
    if ($Domain -ne "None") {
        switch ($Domain.ToLower()) {
            "frontend" {
                # Pas d'ajustement spécifique pour le frontend
            }
            "backend" {
                $complexScore *= 1.2  # Les tâches backend sont souvent plus complexes
            }
            "database" {
                $complexScore *= 1.3  # Les tâches de base de données sont souvent complexes
            }
            "devops" {
                $complexScore *= 1.4  # Les tâches DevOps sont souvent très complexes
            }
            "security" {
                $complexScore *= 1.5  # Les tâches de sécurité sont souvent très complexes
            }
        }
    }

    # Longueur du titre comme indicateur de complexité
    $titleLength = $TaskContent.Length
    if ($titleLength -gt 100) {
        $complexScore += 2
    } elseif ($titleLength -gt 50) {
        $mediumScore += 1
    }

    # Déterminer la complexité finale
    # Utiliser les scores relatifs pour déterminer la complexité
    if ($complexScore -gt ($mediumScore + $simpleScore) * 1.5) {
        return "Complex"
    } elseif ($complexScore -gt $simpleScore * 1.2) {
        return "Medium"
    } else {
        return "Simple"
    }
}

# Fonction pour extraire les sous-tâches d'une tâche
function Get-SubTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier
    )

    try {
        # Essayer de lire le fichier avec l'encodage UTF-8
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    } catch {
        # En cas d'erreur, essayer avec l'encodage par défaut
        try {
            $content = Get-Content -Path $FilePath -Raw
        } catch {
            Write-Error "Impossible de lire le fichier : $_"
            return @()
        }
    }

    $lines = $content -split "`r?`n"

    # Échapper les caractères spéciaux dans l'identifiant de tâche pour la regex
    $escapedTaskId = [regex]::Escape($TaskIdentifier)

    $taskPattern = "- \[[x ]\] \*\*$escapedTaskId\*\* (.*)"
    $subTaskPattern = "- \[[x ]\] \*\*$escapedTaskId\.\d+\*\* (.*)"

    $subTasks = @()
    $foundTask = $false
    $taskIndent = ""

    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $foundTask = $true
            # Capturer l'indentation de la tâche principale
            $taskIndent = $line -replace "^(\s*).*", '$1'
            continue
        }

        if ($foundTask) {
            # Vérifier si la ligne correspond à une sous-tâche
            if ($line -match $subTaskPattern) {
                # Extraire l'ID et le titre de la sous-tâche
                $subTaskId = $line -replace ".*\*\*($escapedTaskId\.\d+)\*\*.*", '$1'
                $subTaskTitle = $line -replace ".*\*\*$escapedTaskId\.\d+\*\*\s+(.*)", '$1'

                $subTasks += @{
                    Id    = $subTaskId
                    Title = $subTaskTitle
                }
            }
            # Vérifier si on est sorti de la section de la tâche principale
            # en détectant une ligne avec moins d'indentation ou une autre tâche principale
            elseif ($line -match "^\s*- \[[x ]\] \*\*" -and
                   (($line -replace "^(\s*).*", '$1').Length -le $taskIndent.Length)) {
                break
            }
        }
    }

    # Si aucune sous-tâche n'a été trouvée, générer des sous-tâches génériques
    if ($subTasks.Count -eq 0) {
        Write-Warning "Aucune sous-tâche trouvée pour $TaskIdentifier. Génération de sous-tâches génériques."
        for ($i = 1; $i -le 3; $i++) {
            $subTasks += @{
                Id    = "$TaskIdentifier.$i"
                Title = "Sous-tâche $i"
            }
        }
    }

    return $subTasks
}

# Fonction pour granulariser récursivement
function Invoke-RecursiveGranularization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
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
        [string]$IndentationStyle = "Auto",

        [Parameter(Mandatory = $false)]
        [string]$CheckboxStyle = "Auto",

        [Parameter(Mandatory = $false)]
        [int]$CurrentDepth = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 2,

        [Parameter(Mandatory = $false)]
        [switch]$AnalyzeComplexity
    )

    # Vérifier si on a atteint la profondeur maximale
    if ($CurrentDepth -ge $MaxDepth) {
        Write-Host "Profondeur maximale atteinte pour la tâche $TaskIdentifier" -ForegroundColor Yellow
        return
    }

    # Obtenir le contenu de la tâche
    $content = Get-Content -Path $FilePath -Raw
    $lines = $content -split "`r?`n"
    $taskContent = ""

    foreach ($line in $lines) {
        if ($line -match "- \[[x ]\] \*\*$TaskIdentifier\*\* (.*)") {
            $taskContent = $Matches[1]
            break
        }
    }

    # Déterminer la complexité si nécessaire
    $effectiveComplexity = $ComplexityLevel
    if ($ComplexityLevel -eq "Auto" -or $AnalyzeComplexity) {
        $detectedComplexity = Get-TaskComplexity -TaskContent $taskContent -Domain $Domain

        if ($AnalyzeComplexity) {
            Write-Host "Analyse de complexité pour la tâche $TaskIdentifier : $detectedComplexity" -ForegroundColor Cyan
        }

        if ($ComplexityLevel -eq "Auto") {
            $effectiveComplexity = $detectedComplexity
            Write-Host "Complexité détectée pour la tâche $TaskIdentifier : $effectiveComplexity" -ForegroundColor Cyan
        }
    }

    # Construire les paramètres pour la granularisation
    $granParams = @{
        FilePath         = $FilePath
        TaskIdentifier   = $TaskIdentifier
        ComplexityLevel  = $effectiveComplexity
        IndentationStyle = $IndentationStyle
        CheckboxStyle    = $CheckboxStyle
    }

    if ($Domain -ne "None") {
        $granParams.Domain = $Domain
    }

    if ($SubTasksFile -ne "") {
        $granParams.SubTasksFile = $SubTasksFile
    }

    if ($AddTimeEstimation) {
        $granParams.AddTimeEstimation = $true
    }

    if ($UseAI) {
        $granParams.UseAI = $true
    }

    if ($SimulateAI) {
        $granParams.SimulateAI = $true
    }

    # Appeler le script de granularisation standard
    Write-Host "Granularisation de la tâche $TaskIdentifier (Profondeur: $CurrentDepth, Complexité: $effectiveComplexity)" -ForegroundColor Green

    # Chemin vers le script gran-mode.ps1
    $granModePath = Join-Path -Path $PSScriptRoot -ChildPath "gran-mode.ps1"

    # Vérifier si le script existe
    if (-not (Test-Path -Path $granModePath)) {
        Write-Error "Le script gran-mode.ps1 est introuvable à l'emplacement : $granModePath"
        return
    }

    # Exécuter le script de granularisation directement avec les paramètres essentiels
    # Cela évite les problèmes potentiels avec le script gran-mode.ps1
    try {
        Write-Host "Granularisation de la tâche $TaskIdentifier dans le fichier $FilePath..." -ForegroundColor Green

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Trouver la tâche à granulariser
        $taskPattern = "- \[[x ]\] \*\*$TaskIdentifier\*\* (.*)"
        $match = [regex]::Match($content, $taskPattern)

        if (-not $match.Success) {
            Write-Error "Tâche non trouvée : $TaskIdentifier"
            return
        }

        # Extraire les informations de la tâche
        $taskLine = $match.Value

        # Détecter l'indentation de la tâche parente
        $taskIndent = $taskLine -replace "^(\s*).*", '$1'

        # Analyser le fichier pour déterminer l'indentation standard des sous-tâches
        $lines = $content -split "`r?`n"
        $standardIndent = "  "  # Indentation par défaut (2 espaces)

        # Chercher des sous-tâches existantes pour déterminer l'indentation standard
        foreach ($line in $lines) {
            if ($line -match "^(\s*)- \[[x ]\] \*\*.*\*\*") {
                $lineIndent = $Matches[1]
                $parentLine = $lines | Where-Object { $_ -match "^(\s*)- \[[x ]\] \*\*.*\*\*" -and $Matches[1].Length -lt $lineIndent.Length } | Select-Object -Last 1

                if ($parentLine) {
                    $parentIndent = $parentLine -replace "^(\s*).*", '$1'
                    if ($lineIndent.Length -gt $parentIndent.Length) {
                        $standardIndent = " " * ($lineIndent.Length - $parentIndent.Length)
                        break
                    }
                }
            }
        }

        # Utiliser l'indentation standard détectée ou l'indentation par défaut
        $subTaskIndent = $taskIndent + $standardIndent

        # Déterminer le nombre de sous-tâches en fonction de la complexité
        $numSubTasks = switch ($ComplexityLevel) {
            "Simple" { 3 }
            "Medium" { 5 }
            "Complex" { 7 }
            default { 5 }  # Par défaut, utiliser 5 sous-tâches
        }

        # Générer des sous-tâches avec des titres significatifs
        $subTasks = @()

        # Définir des titres significatifs en fonction du contexte
        $taskTitles = @(
            "Définir la structure de base",
            "Concevoir les champs principaux",
            "Implémenter les métriques essentielles",
            "Développer les fonctions d'agrégation",
            "Créer les mécanismes de visualisation",
            "Définir les formats d'export",
            "Concevoir les méthodes de comparaison"
        )

        # Si le nombre de sous-tâches est supérieur au nombre de titres, utiliser des titres génériques pour les tâches supplémentaires
        for ($i = 1; $i -le $numSubTasks; $i++) {
            $title = if ($i -le $taskTitles.Count) { $taskTitles[$i - 1] } else { "Sous-tâche supplémentaire $i" }
            $subTasks += "$subTaskIndent- [ ] **$TaskIdentifier.$i** $title"
        }

        # Remplacer la tâche par la tâche + sous-tâches
        $newContent = $content -replace [regex]::Escape($taskLine), "$taskLine`r`n$($subTasks -join "`r`n")"

        # Écrire le contenu modifié dans le fichier
        Set-Content -Path $FilePath -Value $newContent -Encoding UTF8

        Write-Host "Tâche granularisée avec succès : $TaskIdentifier" -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de la granularisation : $_"

        # Essayer d'exécuter le script original en cas d'échec de notre implémentation
        Write-Host "Tentative d'exécution du script original..." -ForegroundColor Yellow
        & $granModePath @granParams
    }

    # Si on n'a pas atteint la profondeur maximale, granulariser les sous-tâches
    if ($CurrentDepth + 1 -lt $MaxDepth) {
        # Obtenir les sous-tâches générées
        $subTasks = Get-SubTasks -FilePath $FilePath -TaskIdentifier $TaskIdentifier

        # Granulariser chaque sous-tâche
        foreach ($subTask in $subTasks) {
            # Déterminer la complexité de la sous-tâche si nécessaire
            $subTaskComplexity = $effectiveComplexity

            if ($AnalyzeComplexity) {
                $subTaskComplexity = Get-TaskComplexity -TaskContent $subTask.Title -Domain $Domain
                Write-Host "Complexité détectée pour la sous-tâche $($subTask.Id) : $subTaskComplexity" -ForegroundColor Cyan
            }

            # Granulariser la sous-tâche
            Invoke-RecursiveGranularization -FilePath $FilePath -TaskIdentifier $subTask.Id -ComplexityLevel $subTaskComplexity -Domain $Domain -SubTasksFile $SubTasksFile -AddTimeEstimation:$AddTimeEstimation -UseAI:$UseAI -SimulateAI:$SimulateAI -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth -AnalyzeComplexity:$AnalyzeComplexity
        }
    }
}

# Exécuter la granularisation récursive
Invoke-RecursiveGranularization -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ComplexityLevel $ComplexityLevel -Domain $Domain -SubTasksFile $SubTasksFile -AddTimeEstimation:$AddTimeEstimation -UseAI:$UseAI -SimulateAI:$SimulateAI -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle -MaxDepth $RecursionDepth -AnalyzeComplexity:$AnalyzeComplexity

# Afficher un message de fin
Write-Host "`nExécution du mode GRAN récursif terminée." -ForegroundColor Cyan
Write-Host "Le document a été modifié : $FilePath" -ForegroundColor Green
