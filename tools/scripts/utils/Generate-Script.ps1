<#
.SYNOPSIS
    Script de génération de scripts à l'aide de Hygen.

.DESCRIPTION
    Ce script utilise Hygen pour générer différents types de scripts
    (scripts d'automatisation, d'analyse, de test, d'intégration).

.PARAMETER Type
    Type de script à générer (automation, analysis, test, integration).

.PARAMETER Name
    Nom du script à générer.

.PARAMETER Description
    Description du script.

.PARAMETER AdditionalDescription
    Description additionnelle du script.

.PARAMETER SubFolder
    Sous-dossier pour le script (pour les scripts d'analyse).

.PARAMETER ScriptToTest
    Chemin relatif du script à tester (pour les scripts de test).

.PARAMETER FunctionName
    Nom de la fonction principale à tester (pour les scripts de test).

.PARAMETER Author
    Auteur du script.

.PARAMETER Tags
    Tags du script.

.PARAMETER OutputFolder
    Dossier de sortie pour le script généré. Si non spécifié, le script sera généré
    dans le dossier par défaut selon son type.

.EXAMPLE
    .\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"
    Génère un script d'automatisation nommé "Auto-ProcessFiles".

.EXAMPLE
    .\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualité du code" -SubFolder "plugins" -Author "Jane Smith"
    Génère un script d'analyse nommé "Analyze-CodeQuality" dans le sous-dossier "plugins".

.EXAMPLE
    .\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"
    Génère un script de test nommé "Example-Script.Tests.ps1".

.EXAMPLE
    .\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intégration avec GitHub Issues" -Author "Integration Team"
    Génère un script d'intégration nommé "Sync-GitHubIssues".

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
    Date de création: 2023-05-15
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

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour générer un script
function Generate-ScriptFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Type
    )
    
    $projectRoot = Get-ProjectPath
    
    # Vérifier si Hygen est installé
    try {
        $hygenVersion = npx hygen --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Hygen n'est pas installé. Veuillez l'installer avec 'npm install -g hygen' ou 'npm install --save-dev hygen'."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la vérification de Hygen : $_"
        return $false
    }
    
    # Déterminer le générateur à utiliser
    switch ($Type) {
        "automation" {
            Write-Info "Génération d'un script d'automatisation..." -ForegroundColor Cyan
            $generator = "script-automation"
        }
        "analysis" {
            Write-Info "Génération d'un script d'analyse..." -ForegroundColor Cyan
            $generator = "script-analysis"
        }
        "test" {
            Write-Info "Génération d'un script de test..." -ForegroundColor Cyan
            $generator = "script-test"
        }
        "integration" {
            Write-Info "Génération d'un script d'intégration..." -ForegroundColor Cyan
            $generator = "script-integration"
        }
        default {
            Write-Error "Type de script non reconnu: $Type"
            return $false
        }
    }
    
    # Construire la commande Hygen
    $hygenCommand = "npx hygen $generator new"
    
    # Ajouter les paramètres
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
    
    # Exécuter la commande Hygen
    $fullCommand = "$hygenCommand $($hygenParams -join ' ')"
    
    if ($PSCmdlet.ShouldProcess("Hygen", $fullCommand)) {
        try {
            Write-Info "Exécution de la commande: $fullCommand"
            
            # Changer le répertoire de travail pour le répertoire du projet
            $currentLocation = Get-Location
            Set-Location -Path $projectRoot
            
            # Exécuter la commande Hygen
            $output = Invoke-Expression $fullCommand
            
            # Restaurer le répertoire de travail
            Set-Location -Path $currentLocation
            
            # Vérifier si la commande a réussi
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script généré avec succès"
                return $true
            }
            else {
                Write-Error "Erreur lors de la génération du script"
                Write-Error $output
                return $false
            }
        }
        catch {
            Write-Error "Erreur lors de l'exécution de la commande Hygen : $_"
            return $false
        }
        finally {
            # S'assurer que le répertoire de travail est restauré
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
    Write-Info "Génération d'un script de type '$Type'..."
    
    # Générer le script
    $result = Generate-ScriptFile -Type $Type
    
    # Afficher le résultat
    if ($result) {
        Write-Success "Script de type '$Type' généré avec succès"
        
        # Afficher le chemin du script généré
        switch ($Type) {
            "automation" {
                Write-Info "Le script a été généré dans: scripts/automation/$Name.ps1"
            }
            "analysis" {
                if ([string]::IsNullOrEmpty($SubFolder)) {
                    Write-Info "Le script a été généré dans: scripts/analysis/$Name.ps1"
                }
                else {
                    Write-Info "Le script a été généré dans: scripts/analysis/$SubFolder/$Name.ps1"
                }
            }
            "test" {
                Write-Info "Le script a été généré dans: scripts/tests/$Name.Tests.ps1"
            }
            "integration" {
                Write-Info "Le script a été généré dans: scripts/integration/$Name.ps1"
            }
        }
    }
    else {
        Write-Error "Échec de la génération du script de type '$Type'"
    }
    
    return $result
}

# Exécuter la génération du script
Start-ScriptGeneration
