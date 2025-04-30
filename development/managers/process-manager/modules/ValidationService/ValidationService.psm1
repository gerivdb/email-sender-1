<#
.SYNOPSIS
    Module de service de validation pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctionnalités pour valider les gestionnaires
    avant leur enregistrement dans le Process Manager.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

#region Variables globales

# Fonctions requises pour un gestionnaire standard
$script:StandardRequiredFunctions = @(
    "Start-*",
    "Stop-*",
    "Get-*Status"
)

# Extensions de fichiers PowerShell valides
$script:PowerShellExtensions = @(
    ".ps1",
    ".psm1"
)

#endregion

#region Fonctions privées

<#
.SYNOPSIS
    Écrit un message dans le journal.

.DESCRIPTION
    Cette fonction écrit un message dans le journal avec un niveau de gravité spécifié.

.PARAMETER Message
    Le message à écrire dans le journal.

.PARAMETER Level
    Le niveau de gravité du message (Debug, Info, Warning, Error).

.EXAMPLE
    Write-ValidationLog -Message "Validation du gestionnaire 'ModeManager'" -Level Info
#>
function Write-ValidationLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )

    # Définir les niveaux de journalisation
    $logLevels = @{
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # Définir la couleur en fonction du niveau
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [ValidationService] $Message"
    Write-Host $logMessage -ForegroundColor $color
}

<#
.SYNOPSIS
    Vérifie la syntaxe d'un script PowerShell.

.DESCRIPTION
    Cette fonction vérifie la syntaxe d'un script PowerShell.

.PARAMETER Path
    Le chemin vers le script PowerShell.

.EXAMPLE
    $result = Test-ScriptSyntax -Path "path/to/script.ps1"
#>
function Test-ScriptSyntax {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ValidationLog -Message "Le fichier n'existe pas : $Path" -Level Error
            return $false
        }

        # Vérifier l'extension du fichier
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()
        if ($script:PowerShellExtensions -notcontains $extension) {
            Write-ValidationLog -Message "Le fichier n'est pas un script PowerShell valide : $Path" -Level Error
            return $false
        }

        # Charger le contenu du fichier
        $content = Get-Content -Path $Path -Raw
        
        # Vérifier la syntaxe du script
        $errors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
        
        if ($errors -and $errors.Count -gt 0) {
            foreach ($error in $errors) {
                Write-ValidationLog -Message "Erreur de syntaxe à la ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber) : $($error.Message)" -Level Error
            }
            return $false
        }
        
        return $true
    }
    catch {
        Write-ValidationLog -Message "Erreur lors de la vérification de la syntaxe du script : $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Vérifie les fonctions requises dans un script PowerShell.

.DESCRIPTION
    Cette fonction vérifie si un script PowerShell contient les fonctions requises.

.PARAMETER Path
    Le chemin vers le script PowerShell.

.PARAMETER RequiredFunctions
    Les fonctions requises à vérifier. Peut contenir des caractères génériques.

.EXAMPLE
    $result = Test-RequiredFunctions -Path "path/to/script.ps1" -RequiredFunctions @("Start-*", "Stop-*")
#>
function Test-RequiredFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$RequiredFunctions
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ValidationLog -Message "Le fichier n'existe pas : $Path" -Level Error
            return $false
        }

        # Charger le contenu du fichier
        $content = Get-Content -Path $Path -Raw
        
        # Analyser le script pour extraire les fonctions
        $errors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
        
        if ($errors -and $errors.Count -gt 0) {
            Write-ValidationLog -Message "Erreurs de syntaxe détectées lors de l'analyse des fonctions" -Level Error
            return $false
        }
        
        # Extraire les fonctions définies dans le script
        $functionDefinitions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $functionNames = $functionDefinitions | ForEach-Object { $_.Name }
        
        # Vérifier chaque fonction requise
        $missingFunctions = @()
        foreach ($requiredFunction in $RequiredFunctions) {
            $found = $false
            
            # Gérer les caractères génériques
            if ($requiredFunction -match '\*') {
                $pattern = "^" + [regex]::Escape($requiredFunction).Replace('\*', '.*') + "$"
                $found = $functionNames | Where-Object { $_ -match $pattern } | Select-Object -First 1
            } else {
                $found = $functionNames -contains $requiredFunction
            }
            
            if (-not $found) {
                $missingFunctions += $requiredFunction
            }
        }
        
        if ($missingFunctions.Count -gt 0) {
            Write-ValidationLog -Message "Fonctions requises manquantes : $($missingFunctions -join ', ')" -Level Warning
            return $false
        }
        
        return $true
    }
    catch {
        Write-ValidationLog -Message "Erreur lors de la vérification des fonctions requises : $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Exécute un test fonctionnel sur un script PowerShell.

.DESCRIPTION
    Cette fonction exécute un test fonctionnel sur un script PowerShell.

.PARAMETER Path
    Le chemin vers le script PowerShell.

.PARAMETER TestParameters
    Les paramètres de test.

.EXAMPLE
    $result = Test-ScriptFunctionality -Path "path/to/script.ps1" -TestParameters @{ Command = "Status" }
#>
function Test-ScriptFunctionality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$TestParameters = @{}
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ValidationLog -Message "Le fichier n'existe pas : $Path" -Level Error
            return $false
        }

        # Construire la commande de test
        $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Path`""
        
        # Ajouter les paramètres de test
        foreach ($key in $TestParameters.Keys) {
            $value = $TestParameters[$key]
            
            # Gérer les types de valeurs
            if ($value -is [string]) {
                $command += " -$key `"$value`""
            } elseif ($value -is [bool] -and $value) {
                $command += " -$key"
            } elseif ($value -is [int] -or $value -is [double]) {
                $command += " -$key $value"
            }
        }
        
        # Exécuter la commande dans un processus séparé
        Write-ValidationLog -Message "Exécution du test fonctionnel : $command" -Level Debug
        
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            Write-ValidationLog -Message "Le test fonctionnel a échoué avec le code de sortie : $($process.ExitCode)" -Level Warning
            return $false
        }
        
        return $true
    }
    catch {
        Write-ValidationLog -Message "Erreur lors du test fonctionnel : $_" -Level Error
        return $false
    }
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Valide un gestionnaire.

.DESCRIPTION
    Cette fonction valide un gestionnaire en vérifiant sa syntaxe, ses fonctions requises et sa fonctionnalité.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER ValidationOptions
    Les options de validation.

.EXAMPLE
    $result = Test-ManagerValidity -Path "development\managers\mode-manager\scripts\mode-manager.ps1"

.EXAMPLE
    $result = Test-ManagerValidity -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -ValidationOptions @{ SkipFunctionalTest = $true }
#>
function Test-ManagerValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationOptions = @{}
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ValidationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-ValidationLog -Message "Validation du gestionnaire '$managerName'..." -Level Info

    # Vérifier la syntaxe du script
    Write-ValidationLog -Message "Vérification de la syntaxe..." -Level Debug
    if (-not (Test-ScriptSyntax -Path $Path)) {
        Write-ValidationLog -Message "La validation de la syntaxe a échoué" -Level Error
        return $false
    }
    Write-ValidationLog -Message "Syntaxe valide" -Level Debug

    # Vérifier les fonctions requises
    if (-not ($ValidationOptions.SkipRequiredFunctionsCheck)) {
        Write-ValidationLog -Message "Vérification des fonctions requises..." -Level Debug
        
        # Déterminer les fonctions requises
        $requiredFunctions = $script:StandardRequiredFunctions
        if ($ValidationOptions.RequiredFunctions) {
            $requiredFunctions = $ValidationOptions.RequiredFunctions
        }
        
        # Remplacer les caractères génériques par le nom du gestionnaire
        $requiredFunctions = $requiredFunctions | ForEach-Object { $_ -replace '\*', $managerName }
        
        if (-not (Test-RequiredFunctions -Path $Path -RequiredFunctions $requiredFunctions)) {
            Write-ValidationLog -Message "La validation des fonctions requises a échoué" -Level Warning
            
            # Ne pas échouer si l'option IgnoreMissingFunctions est activée
            if (-not $ValidationOptions.IgnoreMissingFunctions) {
                return $false
            }
        }
        Write-ValidationLog -Message "Fonctions requises validées" -Level Debug
    }

    # Effectuer un test fonctionnel
    if (-not ($ValidationOptions.SkipFunctionalTest)) {
        Write-ValidationLog -Message "Exécution du test fonctionnel..." -Level Debug
        
        # Déterminer les paramètres de test
        $testParameters = @{ Command = "Status" }
        if ($ValidationOptions.TestParameters) {
            $testParameters = $ValidationOptions.TestParameters
        }
        
        if (-not (Test-ScriptFunctionality -Path $Path -TestParameters $testParameters)) {
            Write-ValidationLog -Message "Le test fonctionnel a échoué" -Level Warning
            
            # Ne pas échouer si l'option IgnoreFunctionalTestFailure est activée
            if (-not $ValidationOptions.IgnoreFunctionalTestFailure) {
                return $false
            }
        }
        Write-ValidationLog -Message "Test fonctionnel réussi" -Level Debug
    }

    # Toutes les validations ont réussi
    Write-ValidationLog -Message "Le gestionnaire '$managerName' est valide" -Level Info
    return $true
}

<#
.SYNOPSIS
    Vérifie l'interface d'un gestionnaire.

.DESCRIPTION
    Cette fonction vérifie si un gestionnaire implémente les fonctions requises pour une interface spécifique.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER RequiredFunctions
    Les fonctions requises pour l'interface.

.EXAMPLE
    $result = Test-ManagerInterface -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -RequiredFunctions @("Start-ModeManager", "Stop-ModeManager")
#>
function Test-ManagerInterface {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$RequiredFunctions = @()
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ValidationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-ValidationLog -Message "Vérification de l'interface du gestionnaire '$managerName'..." -Level Info

    # Si aucune fonction requise n'est spécifiée, utiliser les fonctions standard
    if ($RequiredFunctions.Count -eq 0) {
        $RequiredFunctions = $script:StandardRequiredFunctions | ForEach-Object { $_ -replace '\*', $managerName }
    }

    # Vérifier les fonctions requises
    if (-not (Test-RequiredFunctions -Path $Path -RequiredFunctions $RequiredFunctions)) {
        Write-ValidationLog -Message "Le gestionnaire '$managerName' n'implémente pas l'interface requise" -Level Warning
        return $false
    }

    # Interface valide
    Write-ValidationLog -Message "Le gestionnaire '$managerName' implémente l'interface requise" -Level Info
    return $true
}

<#
.SYNOPSIS
    Teste la fonctionnalité d'un gestionnaire.

.DESCRIPTION
    Cette fonction teste la fonctionnalité d'un gestionnaire en exécutant des commandes spécifiques.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER TestParameters
    Les paramètres de test.

.EXAMPLE
    $result = Test-ManagerFunctionality -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -TestParameters @{ Command = "Status" }
#>
function Test-ManagerFunctionality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$TestParameters = @{ Command = "Status" }
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ValidationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-ValidationLog -Message "Test de la fonctionnalité du gestionnaire '$managerName'..." -Level Info

    # Exécuter le test fonctionnel
    if (-not (Test-ScriptFunctionality -Path $Path -TestParameters $TestParameters)) {
        Write-ValidationLog -Message "Le test de fonctionnalité du gestionnaire '$managerName' a échoué" -Level Warning
        return $false
    }

    # Test réussi
    Write-ValidationLog -Message "Le test de fonctionnalité du gestionnaire '$managerName' a réussi" -Level Info
    return $true
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-ManagerValidity, Test-ManagerInterface, Test-ManagerFunctionality
