<#
.SYNOPSIS
    Script de test du script d'utilitaire Generate-N8nComponent.ps1.

.DESCRIPTION
    Ce script teste le script d'utilitaire Generate-N8nComponent.ps1 en vérifiant
    qu'il peut générer correctement des composants n8n via différentes méthodes.

.PARAMETER OutputFolder
    Dossier de sortie pour les composants générés. Par défaut, les composants seront générés dans les dossiers standard.

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.PARAMETER Interactive
    Si spécifié, le script sera exécuté en mode interactif, permettant à l'utilisateur de répondre aux prompts.

.EXAMPLE
    .\test-generate-component.ps1
    Teste le script Generate-N8nComponent.ps1 en mode non interactif.

.EXAMPLE
    .\test-generate-component.ps1 -Interactive
    Teste le script Generate-N8nComponent.ps1 en mode interactif.

.EXAMPLE
    .\test-generate-component.ps1 -KeepGeneratedFiles
    Teste le script Generate-N8nComponent.ps1 et conserve les fichiers générés.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-10
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepGeneratedFiles = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Interactive = $false
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
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour tester le script Generate-N8nComponent.ps1 avec des paramètres
function Test-GenerateComponentWithParams {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComponentType,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFolder = ""
    )
    
    $projectRoot = Get-ProjectPath
    $scriptPath = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\utils\Generate-N8nComponent.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Error "Le script Generate-N8nComponent.ps1 n'existe pas: $scriptPath"
        return $false
    }
    
    # Déterminer le dossier de sortie
    $outputFolderParam = ""
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $outputFolderParam = "-OutputFolder '$OutputFolder'"
    }
    
    # Exécuter le script avec les paramètres
    Write-Info "Exécution du script Generate-N8nComponent.ps1 avec les paramètres..."
    
    try {
        if ($PSCmdlet.ShouldProcess($scriptPath, "Exécuter avec paramètres")) {
            $command = "& '$scriptPath' -Type '$ComponentType' -Name '$Name' -Category '$Category' -Description '$Description' $outputFolderParam -WhatIf"
            
            Write-Info "Commande: $command"
            
            $output = Invoke-Expression $command 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script exécuté avec succès"
                
                # Vérifier si le script a généré le composant (en mode WhatIf)
                if ($output -match "WhatIf: Génération d'un composant de type $ComponentType") {
                    Write-Success "Le script a correctement simulé la génération du composant"
                    return $true
                } else {
                    Write-Error "Le script n'a pas correctement simulé la génération du composant"
                    return $false
                }
            } else {
                Write-Error "Erreur lors de l'exécution du script (code: $LASTEXITCODE)"
                return $false
            }
        } else {
            return $true
        }
    }
    catch {
        Write-Error "Erreur lors de l'exécution du script: $_"
        return $false
    }
}

# Fonction pour tester le script Generate-N8nComponent.ps1 en mode interactif
function Test-GenerateComponentInteractive {
    param (
        [Parameter(Mandatory=$false)]
        [string]$OutputFolder = ""
    )
    
    if (-not $Interactive) {
        Write-Warning "Le mode interactif n'est pas activé, ce test sera ignoré"
        return $true
    }
    
    $projectRoot = Get-ProjectPath
    $scriptPath = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\utils\Generate-N8nComponent.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Error "Le script Generate-N8nComponent.ps1 n'existe pas: $scriptPath"
        return $false
    }
    
    # Déterminer le dossier de sortie
    $outputFolderParam = ""
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $outputFolderParam = "-OutputFolder '$OutputFolder'"
    }
    
    # Exécuter le script en mode interactif
    Write-Info "Exécution du script Generate-N8nComponent.ps1 en mode interactif..."
    Write-Info "Veuillez répondre aux prompts pour générer un composant de test"
    
    try {
        if ($PSCmdlet.ShouldProcess($scriptPath, "Exécuter en mode interactif")) {
            $command = "& '$scriptPath' $outputFolderParam"
            
            Write-Info "Commande: $command"
            
            Invoke-Expression $command
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script exécuté avec succès en mode interactif"
                
                # Demander à l'utilisateur si le test a réussi
                $confirmation = Read-Host "Le composant a-t-il été généré correctement? (O/N)"
                if ($confirmation -eq "O" -or $confirmation -eq "o") {
                    Write-Success "Test interactif réussi"
                    return $true
                } else {
                    Write-Error "Test interactif échoué"
                    return $false
                }
            } else {
                Write-Error "Erreur lors de l'exécution du script en mode interactif (code: $LASTEXITCODE)"
                return $false
            }
        } else {
            return $true
        }
    }
    catch {
        Write-Error "Erreur lors de l'exécution du script en mode interactif: $_"
        return $false
    }
}

# Fonction pour tester les différents types de composants
function Test-AllComponentTypes {
    $results = @{}
    
    # Tester le type script
    Write-Info "`nTest du type script..."
    $results["script"] = Test-GenerateComponentWithParams -ComponentType "script" -Name "Test-Script" -Category "test" -Description "Script de test" -OutputFolder $OutputFolder
    
    # Tester le type workflow
    Write-Info "`nTest du type workflow..."
    $results["workflow"] = Test-GenerateComponentWithParams -ComponentType "workflow" -Name "test-workflow" -Category "local" -Description "Workflow de test" -OutputFolder $OutputFolder
    
    # Tester le type doc
    Write-Info "`nTest du type doc..."
    $results["doc"] = Test-GenerateComponentWithParams -ComponentType "doc" -Name "test-doc" -Category "guides" -Description "Document de test" -OutputFolder $OutputFolder
    
    # Tester le type integration
    Write-Info "`nTest du type integration..."
    $results["integration"] = Test-GenerateComponentWithParams -ComponentType "integration" -Name "Test-Integration" -Category "mcp" -Description "Intégration de test" -OutputFolder $OutputFolder
    
    # Afficher le résultat global
    Write-Host "`nRésultat des tests par type de composant:" -ForegroundColor $infoColor
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "Réussi" } else { "Échoué" }
        Write-Host "- Type $key : $status" -ForegroundColor $(if ($results[$key]) { $successColor } else { $errorColor })
    }
    
    return $results.Values -notcontains $false
}

# Fonction pour tester le script en mode interactif
function Test-InteractiveMode {
    if ($Interactive) {
        Write-Info "`nTest du mode interactif..."
        return Test-GenerateComponentInteractive -OutputFolder $OutputFolder
    } else {
        Write-Info "`nTest du mode interactif ignoré (utilisez -Interactive pour l'activer)"
        return $true
    }
}

# Fonction principale
function Start-UtilityTest {
    Write-Info "Test du script d'utilitaire Generate-N8nComponent.ps1..."
    
    # Tester tous les types de composants
    $typesValid = Test-AllComponentTypes
    
    # Tester le mode interactif
    $interactiveValid = Test-InteractiveMode
    
    # Afficher le résultat global
    Write-Host "`nRésultat du test:" -ForegroundColor $infoColor
    if ($typesValid -and $interactiveValid) {
        Write-Success "Le script Generate-N8nComponent.ps1 est valide"
        return $true
    } else {
        Write-Error "Le script Generate-N8nComponent.ps1 est invalide"
        return $false
    }
}

# Exécuter le test
Start-UtilityTest
