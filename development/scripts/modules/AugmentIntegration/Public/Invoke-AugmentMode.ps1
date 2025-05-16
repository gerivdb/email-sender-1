<#
.SYNOPSIS
    Invoque un mode opérationnel dans Augment.

.DESCRIPTION
    Cette fonction permet d'invoquer un mode opérationnel dans Augment.
    Elle prend en charge différents modes, dont le mode DEV-R amélioré.

.PARAMETER Mode
    Le mode opérationnel à invoquer. Les valeurs possibles sont : GRAN, DEV-R, ARCHI, DEBUG, TEST, OPTI, REVIEW, PREDIC, C-BREAK.

.PARAMETER FilePath
    Chemin vers le fichier à traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à traiter (optionnel).

.PARAMETER UseSelection
    Indique si le script doit utiliser la sélection actuelle dans le document Augment.

.PARAMETER ChildrenFirst
    Indique si les tâches enfants doivent être traitées avant les tâches parentes (pour le mode DEV-R).

.PARAMETER StepByStep
    Indique si les tâches doivent être traitées une par une avec une pause entre chaque tâche (pour le mode DEV-R).

.PARAMETER ProjectPath
    Chemin vers le répertoire du projet.

.PARAMETER TestsPath
    Chemin vers le répertoire des tests.

.PARAMETER OutputPath
    Chemin où seront générés les fichiers de sortie.

.PARAMETER UpdateMemories
    Indique si les mémoires d'Augment doivent être mises à jour.

.PARAMETER AdditionalParams
    Paramètres supplémentaires à passer au mode.

.EXAMPLE
    Invoke-AugmentMode -Mode DEV-R -FilePath "roadmap.md" -TaskIdentifier "1.2.3"

    Invoque le mode DEV-R pour la tâche 1.2.3 du fichier roadmap.md.

.EXAMPLE
    Invoke-AugmentMode -Mode DEV-R -FilePath "roadmap.md" -UseSelection -ChildrenFirst -StepByStep

    Invoque le mode DEV-R pour la sélection actuelle dans le document Augment en commençant par les tâches enfants, avec une pause entre chaque tâche.

.NOTES
    Auteur: AugmentIntegration Team
    Version: 2.0
    Date de création: 2025-05-16
#>

function Invoke-AugmentMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Le mode opérationnel à invoquer.")]
        [ValidateSet("GRAN", "DEV-R", "ARCHI", "DEBUG", "TEST", "OPTI", "REVIEW", "PREDIC", "C-BREAK")]
        [string]$Mode,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Chemin vers le fichier à traiter.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Identifiant de la tâche à traiter (optionnel).")]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false, HelpMessage = "Indique si le script doit utiliser la sélection actuelle dans le document Augment.")]
        [switch]$UseSelection,

        [Parameter(Mandatory = $false, HelpMessage = "Indique si les tâches enfants doivent être traitées avant les tâches parentes (pour le mode DEV-R).")]
        [switch]$ChildrenFirst,

        [Parameter(Mandatory = $false, HelpMessage = "Indique si les tâches doivent être traitées une par une avec une pause entre chaque tâche (pour le mode DEV-R).")]
        [switch]$StepByStep,

        [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le répertoire du projet.")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le répertoire des tests.")]
        [string]$TestsPath,

        [Parameter(Mandatory = $false, HelpMessage = "Chemin où seront générés les fichiers de sortie.")]
        [string]$OutputPath,

        [Parameter(Mandatory = $false, HelpMessage = "Indique si les mémoires d'Augment doivent être mises à jour.")]
        [switch]$UpdateMemories,

        [Parameter(Mandatory = $false, HelpMessage = "Paramètres supplémentaires à passer au mode.")]
        [hashtable]$AdditionalParams
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier est introuvable : $FilePath"
        return $false
    }

    # Construire les paramètres communs
    $commonParams = @{
        FilePath = $FilePath
    }

    if ($TaskIdentifier) {
        $commonParams.TaskIdentifier = $TaskIdentifier
    }

    if ($ProjectPath) {
        $commonParams.ProjectPath = $ProjectPath
    }

    if ($TestsPath) {
        $commonParams.TestsPath = $TestsPath
    }

    if ($OutputPath) {
        $commonParams.OutputPath = $OutputPath
    }

    # Ajouter les paramètres supplémentaires
    if ($AdditionalParams) {
        foreach ($key in $AdditionalParams.Keys) {
            $commonParams[$key] = $AdditionalParams[$key]
        }
    }

    # Invoquer le mode approprié
    switch ($Mode) {
        "DEV-R" {
            # Chemin vers le script d'intégration du mode DEV-R pour Augment
            $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
            $moduleRoot = Split-Path -Parent $scriptPath
            $devRScriptPath = Join-Path -Path $moduleRoot -ChildPath "..\..\augment\Invoke-AugmentDevRMode.ps1"

            # Vérifier si le script existe
            if (-not (Test-Path -Path $devRScriptPath)) {
                Write-Error "Le script d'intégration du mode DEV-R pour Augment est introuvable à l'emplacement : $devRScriptPath"
                return $false
            }

            # Ajouter les paramètres spécifiques au mode DEV-R
            if ($UseSelection) {
                $commonParams.UseSelection = $true
            }

            if ($ChildrenFirst) {
                $commonParams.ChildrenFirst = $true
            }

            if ($StepByStep) {
                $commonParams.StepByStep = $true
            }

            # Exécuter le script d'intégration du mode DEV-R pour Augment
            & $devRScriptPath @commonParams
        }
        "GRAN" {
            # Chemin vers le script d'intégration du mode GRAN
            $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
            $moduleRoot = Split-Path -Parent $scriptPath
            $granScriptPath = Join-Path -Path $moduleRoot -ChildPath "..\..\roadmap\parser\modes\gran\Invoke-GranMode.ps1"

            # Vérifier si le script existe
            if (-not (Test-Path -Path $granScriptPath)) {
                Write-Error "Le script d'intégration du mode GRAN est introuvable à l'emplacement : $granScriptPath"
                return $false
            }

            # Exécuter le script d'intégration du mode GRAN
            & $granScriptPath @commonParams
        }
        # Ajouter d'autres modes ici...
        default {
            Write-Error "Mode non pris en charge : $Mode"
            return $false
        }
    }

    # Mettre à jour les mémoires d'Augment si demandé
    if ($UpdateMemories) {
        try {
            # Utiliser la fonction d'Augment pour mettre à jour les mémoires
            # Note: Cette fonction doit être implémentée dans Augment
            Update-AugmentMemories -Mode $Mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier
        } catch {
            Write-Warning "Erreur lors de la mise à jour des mémoires d'Augment : $_"
        }
    }

    return $true
}

# Fonction fictive pour mettre à jour les mémoires d'Augment
# Cette fonction doit être remplacée par la véritable implémentation dans Augment
function Update-AugmentMemories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier
    )

    # Simuler la mise à jour des mémoires dans Augment
    # Dans une véritable implémentation, cette fonction appellerait l'API d'Augment
    # pour mettre à jour les mémoires
    
    Write-Verbose "Mise à jour des mémoires d'Augment pour le mode $Mode, fichier $FilePath, tâche $TaskIdentifier"
}
