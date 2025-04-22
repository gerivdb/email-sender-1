<#
.SYNOPSIS
    Script de test du template Hygen pour les workflows n8n.

.DESCRIPTION
    Ce script teste le template Hygen pour les workflows n8n en générant un workflow de test
    et en vérifiant que le workflow généré est valide et conforme aux attentes.

.PARAMETER OutputFolder
    Dossier de sortie pour le workflow généré. Par défaut, le workflow sera généré dans le dossier standard.

.PARAMETER WorkflowName
    Nom du workflow à générer. Par défaut, "test-workflow".

.PARAMETER Environment
    Environnement du workflow à générer. Par défaut, "local".

.PARAMETER Tags
    Tags du workflow à générer. Par défaut, "test, validation".

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.EXAMPLE
    .\test-workflow-template.ps1
    Teste le template Hygen pour les workflows n8n avec les valeurs par défaut.

.EXAMPLE
    .\test-workflow-template.ps1 -WorkflowName "my-test-workflow" -Environment "dev" -Tags "test, email"
    Teste le template Hygen pour les workflows n8n avec des valeurs personnalisées.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-09
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkflowName = "test-workflow",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "local",
    
    [Parameter(Mandatory=$false)]
    [string]$Tags = "test, validation",
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepGeneratedFiles = $false
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

# Fonction pour générer un workflow n8n avec Hygen
function New-N8nWorkflow {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Environment,
        
        [Parameter(Mandatory=$true)]
        [string]$Tags,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFolder = ""
    )
    
    $projectRoot = Get-ProjectPath
    
    # Déterminer le dossier de sortie
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $outputFolder = Join-Path -Path $projectRoot -ChildPath "n8n\core\workflows\$Environment"
    } else {
        $outputFolder = $OutputFolder
    }
    
    # Vérifier si le dossier de sortie existe
    if (-not (Test-Path -Path $outputFolder)) {
        if ($PSCmdlet.ShouldProcess($outputFolder, "Créer le dossier")) {
            New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
            Write-Success "Dossier de sortie créé: $outputFolder"
        }
    }
    
    # Générer le workflow
    Write-Info "Génération du workflow n8n avec Hygen..."
    
    try {
        # Changer le répertoire courant
        $currentLocation = Get-Location
        Set-Location -Path $projectRoot
        
        # Préparer les réponses pour les prompts
        $responses = @(
            $Name,
            $Environment,
            $Tags
        )
        
        # Exécuter Hygen avec les réponses
        if ($PSCmdlet.ShouldProcess("Hygen", "Générer un workflow n8n")) {
            $process = Start-Process -FilePath "npx" -ArgumentList "hygen n8n-workflow new" -NoNewWindow -PassThru -RedirectStandardInput
            
            # Attendre que le processus soit prêt
            Start-Sleep -Seconds 1
            
            # Envoyer les réponses
            foreach ($response in $responses) {
                [System.IO.StreamWriter]::new($process.StandardInput.BaseStream).WriteLine($response)
                Start-Sleep -Milliseconds 500
            }
            
            # Attendre que le processus se termine
            $process.WaitForExit()
            
            # Vérifier le code de sortie
            if ($process.ExitCode -eq 0) {
                Write-Success "Workflow n8n généré avec succès"
                
                # Déterminer le chemin du workflow généré
                $workflowPath = Join-Path -Path $outputFolder -ChildPath "$Name.json"
                
                # Vérifier si le workflow a été généré
                if (Test-Path -Path $workflowPath) {
                    Write-Success "Workflow généré: $workflowPath"
                    
                    # Revenir au répertoire d'origine
                    Set-Location -Path $currentLocation
                    
                    return $workflowPath
                } else {
                    Write-Error "Le workflow n'a pas été généré à l'emplacement attendu: $workflowPath"
                    
                    # Revenir au répertoire d'origine
                    Set-Location -Path $currentLocation
                    
                    return $null
                }
            } else {
                Write-Error "Erreur lors de la génération du workflow n8n (code: $($process.ExitCode))"
                
                # Revenir au répertoire d'origine
                Set-Location -Path $currentLocation
                
                return $null
            }
        } else {
            # Revenir au répertoire d'origine
            Set-Location -Path $currentLocation
            
            return $null
        }
    }
    catch {
        Write-Error "Erreur lors de la génération du workflow n8n: $_"
        
        # Revenir au répertoire d'origine
        Set-Location -Path $currentLocation
        
        return $null
    }
}

# Fonction pour vérifier le contenu du workflow généré
function Test-WorkflowContent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$WorkflowPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Tags
    )
    
    if (-not (Test-Path -Path $WorkflowPath)) {
        Write-Error "Le workflow n'existe pas: $WorkflowPath"
        return $false
    }
    
    try {
        $content = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json
        $success = $true
        
        # Vérifier la présence du nom du workflow
        if ($content.name -eq $Name) {
            Write-Success "Le workflow contient le nom: $Name"
        } else {
            Write-Error "Le workflow ne contient pas le nom: $Name"
            $success = $false
        }
        
        # Vérifier la présence des tags
        $tagArray = $Tags -split ',' | ForEach-Object { $_.Trim() }
        $allTagsPresent = $true
        
        foreach ($tag in $tagArray) {
            if ($content.tags -contains $tag) {
                Write-Success "Le workflow contient le tag: $tag"
            } else {
                Write-Error "Le workflow ne contient pas le tag: $tag"
                $allTagsPresent = $false
            }
        }
        
        $success = $success -and $allTagsPresent
        
        # Vérifier la présence des éléments standard
        $requiredProperties = @(
            "nodes",
            "connections",
            "active",
            "settings",
            "id"
        )
        
        foreach ($property in $requiredProperties) {
            if ($null -ne $content.$property) {
                Write-Success "Le workflow contient la propriété: $property"
            } else {
                Write-Error "Le workflow ne contient pas la propriété: $property"
                $success = $false
            }
        }
        
        return $success
    }
    catch {
        Write-Error "Erreur lors de la vérification du contenu du workflow: $_"
        return $false
    }
}

# Fonction pour vérifier la validité du JSON
function Test-JsonValidity {
    param (
        [Parameter(Mandatory=$true)]
        [string]$WorkflowPath
    )
    
    if (-not (Test-Path -Path $WorkflowPath)) {
        Write-Error "Le workflow n'existe pas: $WorkflowPath"
        return $false
    }
    
    try {
        $content = Get-Content -Path $WorkflowPath -Raw
        $null = $content | ConvertFrom-Json
        Write-Success "Le workflow est un JSON valide"
        return $true
    }
    catch {
        Write-Error "Le workflow n'est pas un JSON valide: $_"
        return $false
    }
}

# Fonction pour nettoyer les fichiers générés
function Remove-GeneratedFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$WorkflowPath
    )
    
    if (-not (Test-Path -Path $WorkflowPath)) {
        Write-Warning "Le workflow n'existe pas: $WorkflowPath"
        return
    }
    
    if ($PSCmdlet.ShouldProcess($WorkflowPath, "Supprimer")) {
        Remove-Item -Path $WorkflowPath -Force
        Write-Success "Workflow supprimé: $WorkflowPath"
    }
}

# Fonction principale
function Start-TemplateTest {
    Write-Info "Test du template Hygen pour les workflows n8n..."
    
    # Générer un workflow n8n
    $workflowPath = New-N8nWorkflow -Name $WorkflowName -Environment $Environment -Tags $Tags -OutputFolder $OutputFolder
    
    if (-not $workflowPath) {
        Write-Error "Impossible de générer le workflow n8n"
        return $false
    }
    
    # Vérifier le contenu du workflow
    $contentValid = Test-WorkflowContent -WorkflowPath $workflowPath -Name $WorkflowName -Tags $Tags
    
    # Vérifier la validité du JSON
    $jsonValid = Test-JsonValidity -WorkflowPath $workflowPath
    
    # Nettoyer les fichiers générés
    if (-not $KeepGeneratedFiles) {
        Remove-GeneratedFiles -WorkflowPath $workflowPath
    } else {
        Write-Info "Les fichiers générés sont conservés: $workflowPath"
    }
    
    # Afficher le résultat global
    Write-Host "`nRésultat du test:" -ForegroundColor $infoColor
    if ($contentValid -and $jsonValid) {
        Write-Success "Le template pour les workflows n8n est valide"
        return $true
    } else {
        Write-Error "Le template pour les workflows n8n est invalide"
        return $false
    }
}

# Exécuter le test
Start-TemplateTest
