<#
.SYNOPSIS
    Script pour le mode C-BREAK qui permet de dÃ©tecter et corriger les dÃ©pendances circulaires dans un projet.

.DESCRIPTION
    Ce script implÃ©mente le mode C-BREAK qui permet de dÃ©tecter et corriger les dÃ©pendances circulaires
    dans un projet en analysant les relations entre les fichiers et modules.
    Il fait partie de la suite d'outils RoadmapParser pour la gestion de roadmaps.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (optionnel). Si non spÃ©cifiÃ©, toutes les tÃ¢ches seront traitÃ©es.

.PARAMETER OutputPath
    Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie. Par dÃ©faut, les fichiers sont gÃ©nÃ©rÃ©s dans le rÃ©pertoire courant.

.PARAMETER ConfigFile
    Chemin vers un fichier de configuration personnalisÃ©. Si non spÃ©cifiÃ©, la configuration par dÃ©faut sera utilisÃ©e.

.PARAMETER LogLevel
    Niveau de journalisation Ã  utiliser. Les valeurs possibles sont : ERROR, WARNING, INFO, VERBOSE, DEBUG.
    Par dÃ©faut, le niveau est INFO.

.PARAMETER ProjectPath
    Chemin vers le rÃ©pertoire du projet Ã  analyser.

.PARAMETER IncludePatterns
    Tableau de motifs d'inclusion pour les fichiers Ã  analyser (ex: "*.ps1", "*.py").

.PARAMETER ExcludePatterns
    Tableau de motifs d'exclusion pour les fichiers Ã  ignorer (ex: "*.test.ps1", "*node_modules*").

.PARAMETER DetectionAlgorithm
    Algorithme Ã  utiliser pour la dÃ©tection des cycles. Les valeurs possibles sont : DFS, TARJAN, JOHNSON.
    Par dÃ©faut, l'algorithme est TARJAN.

.PARAMETER MaxDepth
    Profondeur maximale d'analyse des dÃ©pendances. Par dÃ©faut, la profondeur est 10.

.PARAMETER AutoFix
    Indique si les dÃ©pendances circulaires dÃ©tectÃ©es doivent Ãªtre corrigÃ©es automatiquement.

.PARAMETER GenerateGraph
    Indique si un graphe des dÃ©pendances doit Ãªtre gÃ©nÃ©rÃ©.

.PARAMETER GraphFormat
    Format du graphe Ã  gÃ©nÃ©rer. Les valeurs possibles sont : DOT, MERMAID, PLANTUML, JSON.
    Par dÃ©faut, le format est DOT.

.EXAMPLE
    .\c-break-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.3.1.3" -OutputPath "output" -ProjectPath "project" -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -GenerateGraph $true

    Traite la tÃ¢che 1.3.1.3 du fichier roadmap.md, analyse les dÃ©pendances circulaires dans le rÃ©pertoire "project" pour les fichiers PowerShell,
    utilise l'algorithme de Tarjan pour la dÃ©tection, gÃ©nÃ¨re un graphe des dÃ©pendances et produit des rapports dans le rÃ©pertoire "output".

.EXAMPLE
    .\c-break-mode.ps1 -FilePath "roadmap.md" -ProjectPath "project" -IncludePatterns "*.ps1","*.py" -ExcludePatterns "*node_modules*" -AutoFix $true

    Traite toutes les tÃ¢ches du fichier roadmap.md, analyse les dÃ©pendances circulaires dans le rÃ©pertoire "project" pour les fichiers PowerShell et Python,
    exclut les fichiers dans les rÃ©pertoires node_modules, et corrige automatiquement les dÃ©pendances circulaires dÃ©tectÃ©es.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Chemin vers le fichier de roadmap Ã  traiter.")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Identifiant de la tÃ¢che Ã  traiter (optionnel).")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie.")]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier de configuration personnalisÃ©.")]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de journalisation Ã  utiliser.")]
    [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
    [string]$LogLevel = "INFO",

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le rÃ©pertoire du projet Ã  analyser.")]
    [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Le chemin du projet n'existe pas ou n'est pas un rÃ©pertoire : $_"
            }
            return $true
        })]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false, HelpMessage = "Motifs d'inclusion pour les fichiers Ã  analyser.")]
    [ValidateNotNullOrEmpty()]
    [string[]]$IncludePatterns = @("*.ps1", "*.py", "*.js", "*.ts", "*.cs", "*.java"),

    [Parameter(Mandatory = $false, HelpMessage = "Motifs d'exclusion pour les fichiers Ã  ignorer.")]
    [string[]]$ExcludePatterns = @("*node_modules*", "*venv*", "*__pycache__*", "*.test.*", "*.spec.*"),

    [Parameter(Mandatory = $false, HelpMessage = "Chemin spÃ©cifique dans le projet oÃ¹ commencer l'analyse. Par dÃ©faut, analyse tout le projet.")]
    [ValidateScript({
            if ($_ -and -not (Test-Path -Path (Join-Path -Path $ProjectPath -ChildPath $_) -ErrorAction SilentlyContinue)) {
                throw "Le chemin de dÃ©part relatif n'existe pas dans le projet : $_"
            }
            return $true
        })]
    [string]$StartPath = "",

    [Parameter(Mandatory = $false, HelpMessage = "Algorithme Ã  utiliser pour la dÃ©tection des cycles.")]
    [ValidateSet("DFS", "TARJAN", "JOHNSON")]
    [string]$DetectionAlgorithm = "TARJAN",

    [Parameter(Mandatory = $false, HelpMessage = "Profondeur maximale d'analyse des dÃ©pendances.")]
    [ValidateRange(1, 100)]
    [int]$MaxDepth = 10,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de dÃ©tail minimum pour considÃ©rer un cycle comme significatif (1-5).")]
    [ValidateRange(1, 5)]
    [int]$MinimumCycleSeverity = 1,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les dÃ©pendances circulaires dÃ©tectÃ©es doivent Ãªtre corrigÃ©es automatiquement.")]
    [bool]$AutoFix = $false,

    [Parameter(Mandatory = $false, HelpMessage = "StratÃ©gie de correction Ã  utiliser lorsque AutoFix est activÃ©.")]
    [ValidateSet("INTERFACE_EXTRACTION", "DEPENDENCY_INVERSION", "MEDIATOR", "ABSTRACTION_LAYER", "AUTO")]
    [string]$FixStrategy = "AUTO",

    [Parameter(Mandatory = $false, HelpMessage = "Indique si un graphe des dÃ©pendances doit Ãªtre gÃ©nÃ©rÃ©.")]
    [bool]$GenerateGraph = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Format du graphe Ã  gÃ©nÃ©rer.")]
    [ValidateSet("DOT", "MERMAID", "PLANTUML", "JSON")]
    [string]$GraphFormat = "DOT"
)

#region Initialisation

# Chemin vers le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "module"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module RoadmapParser est introuvable Ã  l'emplacement : $modulePath"
    exit 1
}

# Importer les fonctions communes
$commonFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\CommonFunctions.ps1"
if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
    Write-Host "Fonctions communes importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions communes est introuvable Ã  l'emplacement : $commonFunctionsPath"
    exit 1
}

# Importer les fonctions de journalisation
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"
if (Test-Path -Path $loggingFunctionsPath) {
    . $loggingFunctionsPath
    Write-Host "Fonctions de journalisation importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de journalisation est introuvable Ã  l'emplacement : $loggingFunctionsPath"
    exit 1
}

# Configurer la journalisation
Set-LoggingLevel -Level $LogLevel

# Importer les fonctions de validation
$validationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ValidationFunctions.ps1"
if (Test-Path -Path $validationFunctionsPath) {
    . $validationFunctionsPath
    Write-Host "Fonctions de validation importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de validation est introuvable Ã  l'emplacement : $validationFunctionsPath"
    exit 1
}

# Importer les fonctions de gestion des erreurs
$errorHandlingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ErrorHandlingFunctions.ps1"
if (Test-Path -Path $errorHandlingFunctionsPath) {
    . $errorHandlingFunctionsPath
    Write-Host "Fonctions de gestion des erreurs importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de gestion des erreurs est introuvable Ã  l'emplacement : $errorHandlingFunctionsPath"
    exit 1
}

# Importer les fonctions de configuration
$configurationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"
if (Test-Path -Path $configurationFunctionsPath) {
    . $configurationFunctionsPath
    Write-Host "Fonctions de configuration importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de configuration est introuvable Ã  l'emplacement : $configurationFunctionsPath"
    exit 1
}

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapCycleDetection.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapCycleDetection importÃ©e." -ForegroundColor Green
} else {
    Write-LogError "Le fichier de fonction du mode est introuvable Ã  l'emplacement : $modeFunctionPath"
    Write-LogError "Veuillez crÃ©er ce fichier avant d'utiliser le mode C-BREAK."
    exit 1
}

# Charger la configuration
$config = Get-DefaultConfiguration
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    $customConfig = Get-Configuration -ConfigFile $ConfigFile
    $config = Merge-Configuration -DefaultConfig $config -CustomConfig $customConfig
    Write-LogInfo "Configuration personnalisÃ©e chargÃ©e depuis : $ConfigFile"
} else {
    Write-LogInfo "Configuration par dÃ©faut utilisÃ©e."
}

#endregion

#region Validation des entrÃ©es

# VÃ©rifier si le fichier de roadmap existe
Assert-ValidFile -FilePath $FilePath -FileType ".md" -ParameterName "FilePath" -ErrorMessage "Le fichier de roadmap est introuvable ou n'est pas un fichier Markdown : $FilePath"

# VÃ©rifier si le rÃ©pertoire du projet existe
Assert-ValidDirectory -DirectoryPath $ProjectPath -ParameterName "ProjectPath" -ErrorMessage "Le rÃ©pertoire du projet est introuvable : $ProjectPath"

# VÃ©rifier si le rÃ©pertoire de sortie existe, sinon le crÃ©er
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le rÃ©pertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-LogInfo "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath"
    } else {
        Write-LogWarning "CrÃ©ation du rÃ©pertoire de sortie annulÃ©e : $OutputPath"
        exit 0
    }
}

# VÃ©rifier si l'identifiant de tÃ¢che est valide
if ($TaskIdentifier) {
    Assert-ValidTaskIdentifier -TaskIdentifier $TaskIdentifier -ParameterName "TaskIdentifier" -ErrorMessage "L'identifiant de tÃ¢che n'est pas valide : $TaskIdentifier. Il doit Ãªtre au format 'X.Y.Z'."
}

#endregion

#region Traitement principal

Write-LogInfo "DÃ©but du traitement du mode C-BREAK."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "TÃ¢che Ã  traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tÃ¢ches seront traitÃ©es."
}
Write-LogInfo "RÃ©pertoire du projet : $ProjectPath"
if ($StartPath) {
    Write-LogInfo "Chemin de dÃ©part dans le projet : $StartPath"
}
Write-LogInfo "RÃ©pertoire de sortie : $OutputPath"
Write-LogInfo "Filtres d'inclusion : $($IncludePatterns -join ', ')"
Write-LogInfo "Filtres d'exclusion : $($ExcludePatterns -join ', ')"
Write-LogInfo "Algorithme de dÃ©tection : $DetectionAlgorithm"
Write-LogInfo "Profondeur maximale d'analyse : $MaxDepth"
Write-LogInfo "SÃ©vÃ©ritÃ© minimale des cycles : $MinimumCycleSeverity"
Write-LogInfo "Correction automatique : $($AutoFix ? 'ActivÃ©e' : 'DÃ©sactivÃ©e')"
if ($AutoFix) {
    Write-LogInfo "StratÃ©gie de correction : $FixStrategy"
}
Write-LogInfo "GÃ©nÃ©ration de graphe : $($GenerateGraph ? 'ActivÃ©e' : 'DÃ©sactivÃ©e')"
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

    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapCycleDetection", "ExÃ©cuter avec les paramÃ¨tres spÃ©cifiÃ©s")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapCycleDetection @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exÃ©cution du mode C-BREAK." -ExitOnError $false

        # Traiter les rÃ©sultats
        if ($result) {
            Write-LogInfo "Traitement terminÃ© avec succÃ¨s."

            # Afficher un rÃ©sumÃ© des rÃ©sultats
            Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Yellow
            Write-Host "  - Nombre de fichiers analysÃ©s : $($result.FilesAnalyzed)" -ForegroundColor Green
            Write-Host "  - Nombre de cycles dÃ©tectÃ©s : $($result.CyclesDetected)" -ForegroundColor $(if ($result.CyclesDetected -eq 0) { "Green" } else { "Red" })

            if ($AutoFix) {
                Write-Host "  - Nombre de cycles corrigÃ©s : $($result.CyclesFixed)" -ForegroundColor $(if ($result.CyclesFixed -eq $result.CyclesDetected) { "Green" } else { "Yellow" })
            }

            # Afficher les cycles dÃ©tectÃ©s
            if ($result.Cycles -and $result.Cycles.Count -gt 0) {
                Write-Host "`nCycles de dÃ©pendances dÃ©tectÃ©s :" -ForegroundColor Red
                foreach ($cycle in $result.Cycles) {
                    Write-Host "  - Cycle de $($cycle.Length) fichiers (SÃ©vÃ©ritÃ©: $($cycle.Severity)):" -ForegroundColor Red
                    for ($i = 0; $i -lt $cycle.Files.Count - 1; $i++) {
                        $sourceFile = Split-Path -Leaf $cycle.Files[$i]
                        $targetFile = Split-Path -Leaf $cycle.Files[$i + 1]
                        Write-Host "    $sourceFile -> $targetFile" -ForegroundColor Gray
                    }
                }
            }

            # Indiquer les fichiers gÃ©nÃ©rÃ©s
            if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
                Write-Host "`nFichiers gÃ©nÃ©rÃ©s :" -ForegroundColor Yellow
                foreach ($file in $result.OutputFiles) {
                    Write-Host "  - $file" -ForegroundColor Gray
                }
            }

            # Mettre Ã  jour la roadmap si une tÃ¢che a Ã©tÃ© spÃ©cifiÃ©e
            if ($TaskIdentifier -and $result.Success) {
                if ($PSCmdlet.ShouldProcess("Update-RoadmapTask", "Mettre Ã  jour l'Ã©tat de la tÃ¢che $TaskIdentifier")) {
                    Update-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -Completed $true -BackupFile $true
                    Write-LogInfo "TÃ¢che $TaskIdentifier marquÃ©e comme complÃ©tÃ©e dans la roadmap."
                }
            }
        } else {
            Write-LogWarning "Aucun rÃ©sultat n'a Ã©tÃ© retournÃ© par la fonction Invoke-RoadmapCycleDetection."
        }
    } else {
        Write-LogWarning "ExÃ©cution de Invoke-RoadmapCycleDetection annulÃ©e."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode C-BREAK." -ExitOnError $true
}

Write-LogInfo "Fin du traitement du mode C-BREAK."

#endregion

# Retourner les rÃ©sultats
return $result
