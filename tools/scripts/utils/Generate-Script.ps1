<#
.SYNOPSIS
    Script de gÃ©nÃ©ration de scripts Ã  l'aide de Hygen.

.DESCRIPTION
    Ce script utilise Hygen pour gÃ©nÃ©rer diffÃ©rents types de scripts
    (scripts d'automatisation, d'analyse, de test, d'intÃ©gration).

.PARAMETER Type
    Type de script Ã  gÃ©nÃ©rer (automation, analysis, test, integration).

.PARAMETER Name
    Nom du script Ã  gÃ©nÃ©rer.

.PARAMETER Description
    Description du script.

.PARAMETER AdditionalDescription
    Description additionnelle du script.

.PARAMETER SubFolder
    Sous-dossier pour le script (pour les scripts d'analyse).

.PARAMETER ScriptToTest
    Chemin relatif du script Ã  tester (pour les scripts de test).

.PARAMETER FunctionName
    Nom de la fonction principale Ã  tester (pour les scripts de test).

.PARAMETER Author
    Auteur du script.

.PARAMETER Tags
    Tags du script.

.PARAMETER OutputFolder
    Dossier de sortie pour le script gÃ©nÃ©rÃ©. Si non spÃ©cifiÃ©, le script sera gÃ©nÃ©rÃ©
    dans le dossier par dÃ©faut selon son type.

.EXAMPLE
    .\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"
    GÃ©nÃ¨re un script d'automatisation nommÃ© "Auto-ProcessFiles".

.EXAMPLE
    .\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualitÃ© du code" -SubFolder "plugins" -Author "Jane Smith"
    GÃ©nÃ¨re un script d'analyse nommÃ© "Analyze-CodeQuality" dans le sous-dossier "plugins".

.EXAMPLE
    .\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"
    GÃ©nÃ¨re un script de test nommÃ© "Example-Script.Tests.ps1".

.EXAMPLE
    .\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intÃ©gration avec GitHub Issues" -Author "Integration Team"
    GÃ©nÃ¨re un script d'intÃ©gration nommÃ© "Sync-GitHubIssues".

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
    Date de crÃ©ation: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("automation", "analysis", "test", "integration")]
    [string]$Type,
    
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AdditionalDescription = "",
    
    [Parameter(Mandatory=$false)]
    [string]$SubFolder = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ScriptToTest = "",
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Author = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Tags = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = ""
)

# DÃ©finir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succÃ¨s
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "âœ“ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "âœ— $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "â„¹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "âš  $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour gÃ©nÃ©rer un script
function Generate-ScriptFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Type
    )
    
    $projectRoot = Get-ProjectPath
    
    # VÃ©rifier si Hygen est installÃ©
    try {
        $hygenVersion = npx hygen --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Hygen n'est pas installÃ©. Veuillez l'installer avec 'npm install -g hygen' ou 'npm install --save-dev hygen'."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la vÃ©rification de Hygen : $_"
        return $false
    }
    
    # DÃ©terminer le gÃ©nÃ©rateur Ã  utiliser
    switch ($Type) {
        "automation" {
            Write-Info "GÃ©nÃ©ration d'un script d'automatisation..." -ForegroundColor Cyan
            $generator = "script-automation"
        }
        "analysis" {
            Write-Info "GÃ©nÃ©ration d'un script d'analyse..." -ForegroundColor Cyan
            $generator = "script-analysis"
        }
        "test" {
            Write-Info "GÃ©nÃ©ration d'un script de test..." -ForegroundColor Cyan
            $generator = "script-test"
        }
        "integration" {
            Write-Info "GÃ©nÃ©ration d'un script d'intÃ©gration..." -ForegroundColor Cyan
            $generator = "script-integration"
        }
        default {
            Write-Error "Type de script non reconnu: $Type"
            return $false
        }
    }
    
    # Construire la commande Hygen
    $hygenCommand = "npx hygen $generator new"
    
    # Ajouter les paramÃ¨tres
    $hygenParams = @()
    $hygenParams += "--name `"$Name`""
    
    if (-not [string]::IsNullOrEmpty($Description)) {
        $hygenParams += "--description `"$Description`""
    }
    
    if (-not [string]::IsNullOrEmpty($AdditionalDescription)) {
        $hygenParams += "--additionalDescription `"$AdditionalDescription`""
    }
    
    if (-not [string]::IsNullOrEmpty($SubFolder)) {
        $hygenParams += "--subFolder `"$SubFolder`""
    }
    
    if (-not [string]::IsNullOrEmpty($ScriptToTest)) {
        $hygenParams += "--scriptToTest `"$ScriptToTest`""
    }
    
    if (-not [string]::IsNullOrEmpty($FunctionName)) {
        $hygenParams += "--functionName `"$FunctionName`""
    }
    
    if (-not [string]::IsNullOrEmpty($Author)) {
        $hygenParams += "--author `"$Author`""
    }
    
    if (-not [string]::IsNullOrEmpty($Tags)) {
        $hygenParams += "--tags `"$Tags`""
    }
    
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $hygenParams += "--out-dir `"$OutputFolder`""
    }
    
    # ExÃ©cuter la commande Hygen
    $fullCommand = "$hygenCommand $($hygenParams -join ' ')"
    
    if ($PSCmdlet.ShouldProcess("Hygen", $fullCommand)) {
        try {
            Write-Info "ExÃ©cution de la commande: $fullCommand"
            
            # Changer le rÃ©pertoire de travail pour le rÃ©pertoire du projet
            $currentLocation = Get-Location
            Set-Location -Path $projectRoot
            
            # ExÃ©cuter la commande Hygen
            $output = Invoke-Expression $fullCommand
            
            # Restaurer le rÃ©pertoire de travail
            Set-Location -Path $currentLocation
            
            # VÃ©rifier si la commande a rÃ©ussi
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script gÃ©nÃ©rÃ© avec succÃ¨s"
                return $true
            }
            else {
                Write-Error "Erreur lors de la gÃ©nÃ©ration du script"
                Write-Error $output
                return $false
            }
        }
        catch {
            Write-Error "Erreur lors de l'exÃ©cution de la commande Hygen : $_"
            return $false
        }
        finally {
            # S'assurer que le rÃ©pertoire de travail est restaurÃ©
            if ((Get-Location).Path -ne $currentLocation.Path) {
                Set-Location -Path $currentLocation
            }
        }
    }
    else {
        return $true
    }
}

# Fonction principale
function Start-ScriptGeneration {
    Write-Info "GÃ©nÃ©ration d'un script de type '$Type'..."
    
    # GÃ©nÃ©rer le script
    $result = Generate-ScriptFile -Type $Type
    
    # Afficher le rÃ©sultat
    if ($result) {
        Write-Success "Script de type '$Type' gÃ©nÃ©rÃ© avec succÃ¨s"
        
        # Afficher le chemin du script gÃ©nÃ©rÃ©
        switch ($Type) {
            "automation" {
                Write-Info "Le script a Ã©tÃ© gÃ©nÃ©rÃ© dans: scripts/automation/$Name.ps1"
            }
            "analysis" {
                if ([string]::IsNullOrEmpty($SubFolder)) {
                    Write-Info "Le script a Ã©tÃ© gÃ©nÃ©rÃ© dans: scripts/analysis/$Name.ps1"
                }
                else {
                    Write-Info "Le script a Ã©tÃ© gÃ©nÃ©rÃ© dans: scripts/analysis/$SubFolder/$Name.ps1"
                }
            }
            "test" {
                Write-Info "Le script a Ã©tÃ© gÃ©nÃ©rÃ© dans: scripts/tests/$Name.Tests.ps1"
            }
            "integration" {
                Write-Info "Le script a Ã©tÃ© gÃ©nÃ©rÃ© dans: scripts/integration/$Name.ps1"
            }
        }
    }
    else {
        Write-Error "Ã‰chec de la gÃ©nÃ©ration du script de type '$Type'"
    }
    
    return $result
}

# ExÃ©cuter la gÃ©nÃ©ration du script
Start-ScriptGeneration
