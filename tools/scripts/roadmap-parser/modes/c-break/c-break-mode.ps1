<#
.SYNOPSIS
    Script pour le mode C-BREAK qui permet de détecter et corriger les dépendances circulaires dans un projet.

.DESCRIPTION
    Ce script implémente le mode C-BREAK qui permet de détecter et corriger les dépendances circulaires
    dans un projet en analysant les relations entre les fichiers et modules.
    Il fait partie de la suite d'outils RoadmapParser pour la gestion de roadmaps.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à traiter (optionnel). Si non spécifié, toutes les tâches seront traitées.

.PARAMETER OutputPath
    Chemin où seront générés les fichiers de sortie. Par défaut, les fichiers sont générés dans le répertoire courant.

.PARAMETER ConfigFile
    Chemin vers un fichier de configuration personnalisé. Si non spécifié, la configuration par défaut sera utilisée.

.PARAMETER LogLevel
    Niveau de journalisation à utiliser. Les valeurs possibles sont : ERROR, WARNING, INFO, VERBOSE, DEBUG.
    Par défaut, le niveau est INFO.

.PARAMETER ProjectPath
    Chemin vers le répertoire du projet à analyser.

.PARAMETER IncludePatterns
    Tableau de motifs d'inclusion pour les fichiers à analyser (ex: "*.ps1", "*.py").

.PARAMETER ExcludePatterns
    Tableau de motifs d'exclusion pour les fichiers à ignorer (ex: "*.test.ps1", "*node_modules*").

.PARAMETER DetectionAlgorithm
    Algorithme à utiliser pour la détection des cycles. Les valeurs possibles sont : DFS, TARJAN, JOHNSON.
    Par défaut, l'algorithme est TARJAN.

.PARAMETER MaxDepth
    Profondeur maximale d'analyse des dépendances. Par défaut, la profondeur est 10.

.PARAMETER AutoFix
    Indique si les dépendances circulaires détectées doivent être corrigées automatiquement.

.PARAMETER GenerateGraph
    Indique si un graphe des dépendances doit être généré.

.PARAMETER GraphFormat
    Format du graphe à générer. Les valeurs possibles sont : DOT, MERMAID, PLANTUML, JSON.
    Par défaut, le format est DOT.

.EXAMPLE
    .\c-break-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.3.1.3" -OutputPath "output" -ProjectPath "project" -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -GenerateGraph $true

    Traite la tâche 1.3.1.3 du fichier roadmap.md, analyse les dépendances circulaires dans le répertoire "project" pour les fichiers PowerShell,
    utilise l'algorithme de Tarjan pour la détection, génère un graphe des dépendances et produit des rapports dans le répertoire "output".

.EXAMPLE
    .\c-break-mode.ps1 -FilePath "roadmap.md" -ProjectPath "project" -IncludePatterns "*.ps1","*.py" -ExcludePatterns "*node_modules*" -AutoFix $true

    Traite toutes les tâches du fichier roadmap.md, analyse les dépendances circulaires dans le répertoire "project" pour les fichiers PowerShell et Python,
    exclut les fichiers dans les répertoires node_modules, et corrige automatiquement les dépendances circulaires détectées.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Chemin vers le fichier de roadmap à traiter.")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Identifiant de la tâche à traiter (optionnel).")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin où seront générés les fichiers de sortie.")]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier de configuration personnalisé.")]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de journalisation à utiliser.")]
    [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
    [string]$LogLevel = "INFO",

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le répertoire du projet à analyser.")]
    [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Le chemin du projet n'existe pas ou n'est pas un répertoire : $_"
            }
            return $true
        })]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false, HelpMessage = "Motifs d'inclusion pour les fichiers à analyser.")]
    [ValidateNotNullOrEmpty()]
    [string[]]$IncludePatterns = @("*.ps1", "*.py", "*.js", "*.ts", "*.cs", "*.java"),

    [Parameter(Mandatory = $false, HelpMessage = "Motifs d'exclusion pour les fichiers à ignorer.")]
    [string[]]$ExcludePatterns = @("*node_modules*", "*venv*", "*__pycache__*", "*.test.*", "*.spec.*"),

    [Parameter(Mandatory = $false, HelpMessage = "Chemin spécifique dans le projet où commencer l'analyse. Par défaut, analyse tout le projet.")]
    [ValidateScript({
            if ($_ -and -not (Test-Path -Path (Join-Path -Path $ProjectPath -ChildPath $_) -ErrorAction SilentlyContinue)) {
                throw "Le chemin de départ relatif n'existe pas dans le projet : $_"
            }
            return $true
        })]
    [string]$StartPath = "",

    [Parameter(Mandatory = $false, HelpMessage = "Algorithme à utiliser pour la détection des cycles.")]
    [ValidateSet("DFS", "TARJAN", "JOHNSON")]
    [string]$DetectionAlgorithm = "TARJAN",

    [Parameter(Mandatory = $false, HelpMessage = "Profondeur maximale d'analyse des dépendances.")]
    [ValidateRange(1, 100)]
    [int]$MaxDepth = 10,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de détail minimum pour considérer un cycle comme significatif (1-5).")]
    [ValidateRange(1, 5)]
    [int]$MinimumCycleSeverity = 1,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les dépendances circulaires détectées doivent être corrigées automatiquement.")]
    [bool]$AutoFix = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Stratégie de correction à utiliser lorsque AutoFix est activé.")]
    [ValidateSet("INTERFACE_EXTRACTION", "DEPENDENCY_INVERSION", "MEDIATOR", "ABSTRACTION_LAYER", "AUTO")]
    [string]$FixStrategy = "AUTO",

    [Parameter(Mandatory = $false, HelpMessage = "Indique si un graphe des dépendances doit être généré.")]
    [bool]$GenerateGraph = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Format du graphe à générer.")]
    [ValidateSet("DOT", "MERMAID", "PLANTUML", "JSON")]
    [string]$GraphFormat = "DOT"
)

#region Initialisation

# Chemin vers le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "module"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module RoadmapParser est introuvable à l'emplacement : $modulePath"
    exit 1
}

# Importer les fonctions communes
$commonFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\CommonFunctions.ps1"
if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
    Write-Host "Fonctions communes importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions communes est introuvable à l'emplacement : $commonFunctionsPath"
    exit 1
}

# Importer les fonctions de journalisation
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"
if (Test-Path -Path $loggingFunctionsPath) {
    . $loggingFunctionsPath
    Write-Host "Fonctions de journalisation importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de journalisation est introuvable à l'emplacement : $loggingFunctionsPath"
    exit 1
}

# Configurer la journalisation
Set-LoggingLevel -Level $LogLevel

# Importer les fonctions de validation
$validationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ValidationFunctions.ps1"
if (Test-Path -Path $validationFunctionsPath) {
    . $validationFunctionsPath
    Write-Host "Fonctions de validation importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de validation est introuvable à l'emplacement : $validationFunctionsPath"
    exit 1
}

# Importer les fonctions de gestion des erreurs
$errorHandlingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ErrorHandlingFunctions.ps1"
if (Test-Path -Path $errorHandlingFunctionsPath) {
    . $errorHandlingFunctionsPath
    Write-Host "Fonctions de gestion des erreurs importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de gestion des erreurs est introuvable à l'emplacement : $errorHandlingFunctionsPath"
    exit 1
}

# Importer les fonctions de configuration
$configurationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"
if (Test-Path -Path $configurationFunctionsPath) {
    . $configurationFunctionsPath
    Write-Host "Fonctions de configuration importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de configuration est introuvable à l'emplacement : $configurationFunctionsPath"
    exit 1
}

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapCycleDetection.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapCycleDetection importée." -ForegroundColor Green
} else {
    Write-LogError "Le fichier de fonction du mode est introuvable à l'emplacement : $modeFunctionPath"
    Write-LogError "Veuillez créer ce fichier avant d'utiliser le mode C-BREAK."
    exit 1
}

# Charger la configuration
$config = Get-DefaultConfiguration
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    $customConfig = Get-Configuration -ConfigFile $ConfigFile
    $config = Merge-Configuration -DefaultConfig $config -CustomConfig $customConfig
    Write-LogInfo "Configuration personnalisée chargée depuis : $ConfigFile"
} else {
    Write-LogInfo "Configuration par défaut utilisée."
}

#endregion

#region Validation des entrées

# Vérifier si le fichier de roadmap existe
Assert-ValidFile -FilePath $FilePath -FileType ".md" -ParameterName "FilePath" -ErrorMessage "Le fichier de roadmap est introuvable ou n'est pas un fichier Markdown : $FilePath"

# Vérifier si le répertoire du projet existe
Assert-ValidDirectory -DirectoryPath $ProjectPath -ParameterName "ProjectPath" -ErrorMessage "Le répertoire du projet est introuvable : $ProjectPath"

# Vérifier si le répertoire de sortie existe, sinon le créer
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le répertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-LogInfo "Répertoire de sortie créé : $OutputPath"
    } else {
        Write-LogWarning "Création du répertoire de sortie annulée : $OutputPath"
        exit 0
    }
}

# Vérifier si l'identifiant de tâche est valide
if ($TaskIdentifier) {
    Assert-ValidTaskIdentifier -TaskIdentifier $TaskIdentifier -ParameterName "TaskIdentifier" -ErrorMessage "L'identifiant de tâche n'est pas valide : $TaskIdentifier. Il doit être au format 'X.Y.Z'."
}

#endregion

#region Traitement principal

Write-LogInfo "Début du traitement du mode C-BREAK."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "Tâche à traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tâches seront traitées."
}
Write-LogInfo "Répertoire du projet : $ProjectPath"
if ($StartPath) {
    Write-LogInfo "Chemin de départ dans le projet : $StartPath"
}
Write-LogInfo "Répertoire de sortie : $OutputPath"
Write-LogInfo "Filtres d'inclusion : $($IncludePatterns -join ', ')"
Write-LogInfo "Filtres d'exclusion : $($ExcludePatterns -join ', ')"
Write-LogInfo "Algorithme de détection : $DetectionAlgorithm"
Write-LogInfo "Profondeur maximale d'analyse : $MaxDepth"
Write-LogInfo "Sévérité minimale des cycles : $MinimumCycleSeverity"
Write-LogInfo "Correction automatique : $($AutoFix ? 'Activée' : 'Désactivée')"
if ($AutoFix) {
    Write-LogInfo "Stratégie de correction : $FixStrategy"
}
Write-LogInfo "Génération de graphe : $($GenerateGraph ? 'Activée' : 'Désactivée')"
if ($GenerateGraph) {
    Write-LogInfo "Format du graphe : $GraphFormat"
}

# Appeler la fonction principale du mode
try {
    $params = @{
        FilePath             = $FilePath
        ProjectPath          = $ProjectPath
        OutputPath           = $OutputPath
        IncludePatterns      = $IncludePatterns
        ExcludePatterns      = $ExcludePatterns
        StartPath            = $StartPath
        DetectionAlgorithm   = $DetectionAlgorithm
        MaxDepth             = $MaxDepth
        MinimumCycleSeverity = $MinimumCycleSeverity
        AutoFix              = $AutoFix
        FixStrategy          = $FixStrategy
        GenerateGraph        = $GenerateGraph
        GraphFormat          = $GraphFormat
    }

    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }

    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapCycleDetection", "Exécuter avec les paramètres spécifiés")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapCycleDetection @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exécution du mode C-BREAK." -ExitOnError $false

        # Traiter les résultats
        if ($result) {
            Write-LogInfo "Traitement terminé avec succès."

            # Afficher un résumé des résultats
            Write-Host "`nRésumé des résultats :" -ForegroundColor Yellow
            Write-Host "  - Nombre de fichiers analysés : $($result.FilesAnalyzed)" -ForegroundColor Green
            Write-Host "  - Nombre de cycles détectés : $($result.CyclesDetected)" -ForegroundColor $(if ($result.CyclesDetected -eq 0) { "Green" } else { "Red" })

            if ($AutoFix) {
                Write-Host "  - Nombre de cycles corrigés : $($result.CyclesFixed)" -ForegroundColor $(if ($result.CyclesFixed -eq $result.CyclesDetected) { "Green" } else { "Yellow" })
            }

            # Afficher les cycles détectés
            if ($result.Cycles -and $result.Cycles.Count -gt 0) {
                Write-Host "`nCycles de dépendances détectés :" -ForegroundColor Red
                foreach ($cycle in $result.Cycles) {
                    Write-Host "  - Cycle de $($cycle.Length) fichiers (Sévérité: $($cycle.Severity)):" -ForegroundColor Red
                    for ($i = 0; $i -lt $cycle.Files.Count - 1; $i++) {
                        $sourceFile = Split-Path -Leaf $cycle.Files[$i]
                        $targetFile = Split-Path -Leaf $cycle.Files[$i + 1]
                        Write-Host "    $sourceFile -> $targetFile" -ForegroundColor Gray
                    }
                }
            }

            # Indiquer les fichiers générés
            if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
                Write-Host "`nFichiers générés :" -ForegroundColor Yellow
                foreach ($file in $result.OutputFiles) {
                    Write-Host "  - $file" -ForegroundColor Gray
                }
            }

            # Mettre à jour la roadmap si une tâche a été spécifiée
            if ($TaskIdentifier -and $result.Success) {
                if ($PSCmdlet.ShouldProcess("Update-RoadmapTask", "Mettre à jour l'état de la tâche $TaskIdentifier")) {
                    Update-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -Completed $true -BackupFile $true
                    Write-LogInfo "Tâche $TaskIdentifier marquée comme complétée dans la roadmap."
                }
            }
        } else {
            Write-LogWarning "Aucun résultat n'a été retourné par la fonction Invoke-RoadmapCycleDetection."
        }
    } else {
        Write-LogWarning "Exécution de Invoke-RoadmapCycleDetection annulée."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode C-BREAK." -ExitOnError $true
}

Write-LogInfo "Fin du traitement du mode C-BREAK."

#endregion

# Retourner les résultats
return $result
