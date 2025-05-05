<#
.SYNOPSIS
    Module de service de validation pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctionnalitÃ©s pour valider les gestionnaires
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

#region Fonctions privÃ©es

<#
.SYNOPSIS
    Ã‰crit un message dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message dans le journal avec un niveau de gravitÃ© spÃ©cifiÃ©.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Level
    Le niveau de gravitÃ© du message (Debug, Info, Warning, Error).

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

    # DÃ©finir les niveaux de journalisation
    $logLevels = @{
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # DÃ©finir la couleur en fonction du niveau
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
    VÃ©rifie la syntaxe d'un script PowerShell.

.DESCRIPTION
    Cette fonction vÃ©rifie la syntaxe d'un script PowerShell.

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
        # VÃ©rifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ValidationLog -Message "Le fichier n'existe pas : $Path" -Level Error
            return $false
        }

        # VÃ©rifier l'extension du fichier
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()
        if ($script:PowerShellExtensions -notcontains $extension) {
            Write-ValidationLog -Message "Le fichier n'est pas un script PowerShell valide : $Path" -Level Error
            return $false
        }

        # Charger le contenu du fichier
        $content = Get-Content -Path $Path -Raw
        
        # VÃ©rifier la syntaxe du script
        $errors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
        
        if ($errors -and $errors.Count -gt 0) {
            foreach ($error in $errors) {
                Write-ValidationLog -Message "Erreur de syntaxe Ã  la ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber) : $($error.Message)" -Level Error
            }
            return $false
        }
        
        return $true
    }
    catch {
        Write-ValidationLog -Message "Erreur lors de la vÃ©rification de la syntaxe du script : $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    VÃ©rifie les fonctions requises dans un script PowerShell.

.DESCRIPTION
    Cette fonction vÃ©rifie si un script PowerShell contient les fonctions requises.

.PARAMETER Path
    Le chemin vers le script PowerShell.

.PARAMETER RequiredFunctions
    Les fonctions requises Ã  vÃ©rifier. Peut contenir des caractÃ¨res gÃ©nÃ©riques.

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
        # VÃ©rifier que le fichier existe
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
            Write-ValidationLog -Message "Erreurs de syntaxe dÃ©tectÃ©es lors de l'analyse des fonctions" -Level Error
            return $false
        }
        
        # Extraire les fonctions dÃ©finies dans le script
        $functionDefinitions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $functionNames = $functionDefinitions | ForEach-Object { $_.Name }
        
        # VÃ©rifier chaque fonction requise
        $missingFunctions = @()
        foreach ($requiredFunction in $RequiredFunctions) {
            $found = $false
            
            # GÃ©rer les caractÃ¨res gÃ©nÃ©riques
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
        Write-ValidationLog -Message "Erreur lors de la vÃ©rification des fonctions requises : $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    ExÃ©cute un test fonctionnel sur un script PowerShell.

.DESCRIPTION
    Cette fonction exÃ©cute un test fonctionnel sur un script PowerShell.

.PARAMETER Path
    Le chemin vers le script PowerShell.

.PARAMETER TestParameters
    Les paramÃ¨tres de test.

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
        # VÃ©rifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ValidationLog -Message "Le fichier n'existe pas : $Path" -Level Error
            return $false
        }

        # Construire la commande de test
        $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Path`""
        
        # Ajouter les paramÃ¨tres de test
        foreach ($key in $TestParameters.Keys) {
            $value = $TestParameters[$key]
            
            # GÃ©rer les types de valeurs
            if ($value -is [string]) {
                $command += " -$key `"$value`""
            } elseif ($value -is [bool] -and $value) {
                $command += " -$key"
            } elseif ($value -is [int] -or $value -is [double]) {
                $command += " -$key $value"
            }
        }
        
        # ExÃ©cuter la commande dans un processus sÃ©parÃ©
        Write-ValidationLog -Message "ExÃ©cution du test fonctionnel : $command" -Level Debug
        
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            Write-ValidationLog -Message "Le test fonctionnel a Ã©chouÃ© avec le code de sortie : $($process.ExitCode)" -Level Warning
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
    Cette fonction valide un gestionnaire en vÃ©rifiant sa syntaxe, ses fonctions requises et sa fonctionnalitÃ©.

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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ValidationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-ValidationLog -Message "Validation du gestionnaire '$managerName'..." -Level Info

    # VÃ©rifier la syntaxe du script
    Write-ValidationLog -Message "VÃ©rification de la syntaxe..." -Level Debug
    if (-not (Test-ScriptSyntax -Path $Path)) {
        Write-ValidationLog -Message "La validation de la syntaxe a Ã©chouÃ©" -Level Error
        return $false
    }
    Write-ValidationLog -Message "Syntaxe valide" -Level Debug

    # VÃ©rifier les fonctions requises
    if (-not ($ValidationOptions.SkipRequiredFunctionsCheck)) {
        Write-ValidationLog -Message "VÃ©rification des fonctions requises..." -Level Debug
        
        # DÃ©terminer les fonctions requises
        $requiredFunctions = $script:StandardRequiredFunctions
        if ($ValidationOptions.RequiredFunctions) {
            $requiredFunctions = $ValidationOptions.RequiredFunctions
        }
        
        # Remplacer les caractÃ¨res gÃ©nÃ©riques par le nom du gestionnaire
        $requiredFunctions = $requiredFunctions | ForEach-Object { $_ -replace '\*', $managerName }
        
        if (-not (Test-RequiredFunctions -Path $Path -RequiredFunctions $requiredFunctions)) {
            Write-ValidationLog -Message "La validation des fonctions requises a Ã©chouÃ©" -Level Warning
            
            # Ne pas Ã©chouer si l'option IgnoreMissingFunctions est activÃ©e
            if (-not $ValidationOptions.IgnoreMissingFunctions) {
                return $false
            }
        }
        Write-ValidationLog -Message "Fonctions requises validÃ©es" -Level Debug
    }

    # Effectuer un test fonctionnel
    if (-not ($ValidationOptions.SkipFunctionalTest)) {
        Write-ValidationLog -Message "ExÃ©cution du test fonctionnel..." -Level Debug
        
        # DÃ©terminer les paramÃ¨tres de test
        $testParameters = @{ Command = "Status" }
        if ($ValidationOptions.TestParameters) {
            $testParameters = $ValidationOptions.TestParameters
        }
        
        if (-not (Test-ScriptFunctionality -Path $Path -TestParameters $testParameters)) {
            Write-ValidationLog -Message "Le test fonctionnel a Ã©chouÃ©" -Level Warning
            
            # Ne pas Ã©chouer si l'option IgnoreFunctionalTestFailure est activÃ©e
            if (-not $ValidationOptions.IgnoreFunctionalTestFailure) {
                return $false
            }
        }
        Write-ValidationLog -Message "Test fonctionnel rÃ©ussi" -Level Debug
    }

    # Toutes les validations ont rÃ©ussi
    Write-ValidationLog -Message "Le gestionnaire '$managerName' est valide" -Level Info
    return $true
}

<#
.SYNOPSIS
    VÃ©rifie l'interface d'un gestionnaire.

.DESCRIPTION
    Cette fonction vÃ©rifie si un gestionnaire implÃ©mente les fonctions requises pour une interface spÃ©cifique.

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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ValidationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-ValidationLog -Message "VÃ©rification de l'interface du gestionnaire '$managerName'..." -Level Info

    # Si aucune fonction requise n'est spÃ©cifiÃ©e, utiliser les fonctions standard
    if ($RequiredFunctions.Count -eq 0) {
        $RequiredFunctions = $script:StandardRequiredFunctions | ForEach-Object { $_ -replace '\*', $managerName }
    }

    # VÃ©rifier les fonctions requises
    if (-not (Test-RequiredFunctions -Path $Path -RequiredFunctions $RequiredFunctions)) {
        Write-ValidationLog -Message "Le gestionnaire '$managerName' n'implÃ©mente pas l'interface requise" -Level Warning
        return $false
    }

    # Interface valide
    Write-ValidationLog -Message "Le gestionnaire '$managerName' implÃ©mente l'interface requise" -Level Info
    return $true
}

<#
.SYNOPSIS
    Teste la fonctionnalitÃ© d'un gestionnaire.

.DESCRIPTION
    Cette fonction teste la fonctionnalitÃ© d'un gestionnaire en exÃ©cutant des commandes spÃ©cifiques.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER TestParameters
    Les paramÃ¨tres de test.

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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ValidationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-ValidationLog -Message "Test de la fonctionnalitÃ© du gestionnaire '$managerName'..." -Level Info

    # ExÃ©cuter le test fonctionnel
    if (-not (Test-ScriptFunctionality -Path $Path -TestParameters $TestParameters)) {
        Write-ValidationLog -Message "Le test de fonctionnalitÃ© du gestionnaire '$managerName' a Ã©chouÃ©" -Level Warning
        return $false
    }

    # Test rÃ©ussi
    Write-ValidationLog -Message "Le test de fonctionnalitÃ© du gestionnaire '$managerName' a rÃ©ussi" -Level Info
    return $true
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-ManagerValidity, Test-ManagerInterface, Test-ManagerFunctionality
