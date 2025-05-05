<#
.SYNOPSIS
    Script de gÃƒÂ©nÃƒÂ©ration de scripts ÃƒÂ  l'aide de Hygen.

.DESCRIPTION
    Ce script utilise Hygen pour gÃƒÂ©nÃƒÂ©rer diffÃƒÂ©rents types de scripts
    (scripts d'automatisation, d'analyse, de test, d'intÃƒÂ©gration).

.PARAMETER Type
    Type de script ÃƒÂ  gÃƒÂ©nÃƒÂ©rer (automation, analysis, test, integration).

.PARAMETER Name
    Nom du script ÃƒÂ  gÃƒÂ©nÃƒÂ©rer.

.PARAMETER Description
    Description du script.

.PARAMETER AdditionalDescription
    Description additionnelle du script.

.PARAMETER SubFolder
    Sous-dossier pour le script (pour les scripts d'analyse).

.PARAMETER ScriptToTest
    Chemin relatif du script ÃƒÂ  tester (pour les scripts de test).

.PARAMETER FunctionName
    Nom de la fonction principale ÃƒÂ  tester (pour les scripts de test).

.PARAMETER Author
    Auteur du script.

.PARAMETER Tags
    Tags du script.

.PARAMETER OutputFolder
    Dossier de sortie pour le script gÃƒÂ©nÃƒÂ©rÃƒÂ©. Si non spÃƒÂ©cifiÃƒÂ©, le script sera gÃƒÂ©nÃƒÂ©rÃƒÂ©
    dans le dossier par dÃƒÂ©faut selon son type.

.EXAMPLE
    .\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"
    GÃƒÂ©nÃƒÂ¨re un script d'automatisation nommÃƒÂ© "Auto-ProcessFiles".

.EXAMPLE
    .\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualitÃƒÂ© du code" -SubFolder "plugins" -Author "Jane Smith"
    GÃƒÂ©nÃƒÂ¨re un script d'analyse nommÃƒÂ© "Analyze-CodeQuality" dans le sous-dossier "plugins".

.EXAMPLE
    .\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"
    GÃƒÂ©nÃƒÂ¨re un script de test nommÃƒÂ© "Example-Script.Tests.ps1".

.EXAMPLE
    .\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intÃƒÂ©gration avec GitHub Issues" -Author "Integration Team"
    GÃƒÂ©nÃƒÂ¨re un script d'intÃƒÂ©gration nommÃƒÂ© "Sync-GitHubIssues".

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
    Date de crÃƒÂ©ation: 2023-05-15
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

# DÃƒÂ©finir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succÃƒÂ¨s
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "Ã¢Å“â€œ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "Ã¢Å“â€” $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "Ã¢â€žÂ¹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "Ã¢Å¡Â  $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour gÃƒÂ©nÃƒÂ©rer un script
function Generate-ScriptFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Type
    )
    
    $projectRoot = Get-ProjectPath
    
    # VÃƒÂ©rifier si Hygen est installÃƒÂ©
    try {
        $hygenVersion = npx hygen --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Hygen n'est pas installÃƒÂ©. Veuillez l'installer avec 'npm install -g hygen' ou 'npm install --save-dev hygen'."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la vÃƒÂ©rification de Hygen : $_"
        return $false
    }
    
    # DÃƒÂ©terminer le gÃƒÂ©nÃƒÂ©rateur ÃƒÂ  utiliser
    switch ($Type) {
        "automation" {
            Write-Info "GÃƒÂ©nÃƒÂ©ration d'un script d'automatisation..." -ForegroundColor Cyan
            $generator = "script-automation"
        }
        "analysis" {
            Write-Info "GÃƒÂ©nÃƒÂ©ration d'un script d'analyse..." -ForegroundColor Cyan
            $generator = "script-analysis"
        }
        "test" {
            Write-Info "GÃƒÂ©nÃƒÂ©ration d'un script de test..." -ForegroundColor Cyan
            $generator = "script-test"
        }
        "integration" {
            Write-Info "GÃƒÂ©nÃƒÂ©ration d'un script d'intÃƒÂ©gration..." -ForegroundColor Cyan
            $generator = "script-integration"
        }
        default {
            Write-Error "Type de script non reconnu: $Type"
            return $false
        }
    }
    
    # Construire la commande Hygen
    $hygenCommand = "npx hygen $generator new"
    
    # Ajouter les paramÃƒÂ¨tres
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
    
    # ExÃƒÂ©cuter la commande Hygen
    $fullCommand = "$hygenCommand $($hygenParams -join ' ')"
    
    if ($PSCmdlet.ShouldProcess("Hygen", $fullCommand)) {
        try {
            Write-Info "ExÃƒÂ©cution de la commande: $fullCommand"
            
            # Changer le rÃƒÂ©pertoire de travail pour le rÃƒÂ©pertoire du projet
            $currentLocation = Get-Location
            Set-Location -Path $projectRoot
            
            # ExÃƒÂ©cuter la commande Hygen
            $output = Invoke-Expression $fullCommand
            
            # Restaurer le rÃƒÂ©pertoire de travail
            Set-Location -Path $currentLocation
            
            # VÃƒÂ©rifier si la commande a rÃƒÂ©ussi
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s"
                return $true
            }
            else {
                Write-Error "Erreur lors de la gÃƒÂ©nÃƒÂ©ration du script"
                Write-Error $output
                return $false
            }
        }
        catch {
            Write-Error "Erreur lors de l'exÃƒÂ©cution de la commande Hygen : $_"
            return $false
        }
        finally {
            # S'assurer que le rÃƒÂ©pertoire de travail est restaurÃƒÂ©
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
    Write-Info "GÃƒÂ©nÃƒÂ©ration d'un script de type '$Type'..."
    
    # GÃƒÂ©nÃƒÂ©rer le script
    $result = Generate-ScriptFile -Type $Type
    
    # Afficher le rÃƒÂ©sultat
    if ($result) {
        Write-Success "Script de type '$Type' gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s"
        
        # Afficher le chemin du script gÃƒÂ©nÃƒÂ©rÃƒÂ©
        switch ($Type) {
            "automation" {
                Write-Info "Le script a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ© dans: development/scripts/automation/$Name.ps1"
            }
            "analysis" {
                if ([string]::IsNullOrEmpty($SubFolder)) {
                    Write-Info "Le script a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ© dans: development/scripts/analysis/$Name.ps1"
                }
                else {
                    Write-Info "Le script a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ© dans: development/scripts/analysis/$SubFolder/$Name.ps1"
                }
            }
            "test" {
                Write-Info "Le script a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ© dans: development/scripts/development/testing/tests/$Name.Tests.ps1"
            }
            "integration" {
                Write-Info "Le script a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ© dans: development/scripts/integration/$Name.ps1"
            }
        }
    }
    else {
        Write-Error "Ãƒâ€°chec de la gÃƒÂ©nÃƒÂ©ration du script de type '$Type'"
    }
    
    return $result
}

# ExÃƒÂ©cuter la gÃƒÂ©nÃƒÂ©ration du script
Start-ScriptGeneration
