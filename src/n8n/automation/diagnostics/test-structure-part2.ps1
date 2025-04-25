<#
.SYNOPSIS
    Script de test structurel pour n8n (Partie 2 : Fonctions de test de structure).

.DESCRIPTION
    Ce script contient les fonctions de test de structure pour le test structurel de n8n.
    Il est conçu pour être utilisé avec les autres parties du script de test structurel.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables de la partie 1
. "$PSScriptRoot\test-structure-part1.ps1"

# Fonction pour tester la structure des dossiers
function Test-FolderStructure {
    param (
        [Parameter(Mandatory=$true)]
        [array]$ExpectedFolders,
        
        [Parameter(Mandatory=$false)]
        [bool]$FixIssues = $false
    )
    
    $results = @{
        Tested = 0
        Passed = 0
        Failed = 0
        Fixed = 0
        Issues = @()
    }
    
    foreach ($folder in $ExpectedFolders) {
        $results.Tested++
        
        if (Test-Path -Path $folder) {
            $results.Passed++
            Write-Log "Dossier présent: $folder" -Level "INFO"
        } else {
            $results.Failed++
            $issue = @{
                Type = "MissingFolder"
                Path = $folder
                Fixed = $false
                Message = "Dossier manquant: $folder"
            }
            
            Write-Log $issue.Message -Level "WARNING"
            
            if ($FixIssues) {
                try {
                    New-Item -Path $folder -ItemType Directory -Force | Out-Null
                    $issue.Fixed = $true
                    $results.Fixed++
                    Write-Log "Dossier créé: $folder" -Level "SUCCESS"
                } catch {
                    $issue.Message += " (Échec de la création: $_)"
                    Write-Log "Échec de la création du dossier $folder : $_" -Level "ERROR"
                }
            }
            
            $results.Issues += $issue
        }
    }
    
    return $results
}

# Fonction pour tester la présence des fichiers
function Test-FileStructure {
    param (
        [Parameter(Mandatory=$true)]
        [array]$ExpectedFiles,
        
        [Parameter(Mandatory=$false)]
        [bool]$FixIssues = $false
    )
    
    $results = @{
        Tested = 0
        Passed = 0
        Failed = 0
        Fixed = 0
        Issues = @()
    }
    
    foreach ($file in $ExpectedFiles) {
        $results.Tested++
        
        if (Test-Path -Path $file) {
            $results.Passed++
            Write-Log "Fichier présent: $file" -Level "INFO"
        } else {
            $results.Failed++
            $issue = @{
                Type = "MissingFile"
                Path = $file
                Fixed = $false
                Message = "Fichier manquant: $file"
            }
            
            Write-Log $issue.Message -Level "WARNING"
            
            if ($FixIssues) {
                try {
                    # Créer le dossier parent s'il n'existe pas
                    $parentFolder = Split-Path -Path $file -Parent
                    if (-not (Test-Path -Path $parentFolder)) {
                        New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
                    }
                    
                    # Créer un fichier vide
                    New-Item -Path $file -ItemType File -Force | Out-Null
                    $issue.Fixed = $true
                    $results.Fixed++
                    Write-Log "Fichier créé (vide): $file" -Level "SUCCESS"
                } catch {
                    $issue.Message += " (Échec de la création: $_)"
                    Write-Log "Échec de la création du fichier $file : $_" -Level "ERROR"
                }
            }
            
            $results.Issues += $issue
        }
    }
    
    return $results
}

# Fonction pour tester la présence des scripts
function Test-ScriptStructure {
    param (
        [Parameter(Mandatory=$true)]
        [array]$ExpectedScripts,
        
        [Parameter(Mandatory=$false)]
        [bool]$FixIssues = $false
    )
    
    $results = @{
        Tested = 0
        Passed = 0
        Failed = 0
        Fixed = 0
        Issues = @()
    }
    
    foreach ($script in $ExpectedScripts) {
        $results.Tested++
        
        if (Test-Path -Path $script) {
            # Vérifier si le fichier est un script PowerShell valide
            $isValid = $true
            
            try {
                $scriptContent = Get-Content -Path $script -Raw
                $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)
            } catch {
                $isValid = $false
                $results.Failed++
                $issue = @{
                    Type = "InvalidScript"
                    Path = $script
                    Fixed = $false
                    Message = "Script invalide: $script (Erreur de syntaxe: $_)"
                }
                
                Write-Log $issue.Message -Level "ERROR"
                $results.Issues += $issue
            }
            
            if ($isValid) {
                $results.Passed++
                Write-Log "Script présent et valide: $script" -Level "INFO"
            }
        } else {
            $results.Failed++
            $issue = @{
                Type = "MissingScript"
                Path = $script
                Fixed = $false
                Message = "Script manquant: $script"
            }
            
            Write-Log $issue.Message -Level "WARNING"
            
            if ($FixIssues) {
                try {
                    # Créer le dossier parent s'il n'existe pas
                    $parentFolder = Split-Path -Path $script -Parent
                    if (-not (Test-Path -Path $parentFolder)) {
                        New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
                    }
                    
                    # Créer un script vide
                    $scriptContent = @"
<#
.SYNOPSIS
    Script généré automatiquement.

.DESCRIPTION
    Ce script a été généré automatiquement par le test structurel.
    Veuillez remplacer ce contenu par le code réel.

.NOTES
    Version:        1.0
    Author:         Système de test structurel
    Creation Date:  $(Get-Date -Format "yyyy-MM-dd")
#>

# Contenu à remplacer
Write-Host "Ce script a été généré automatiquement. Veuillez remplacer ce contenu par le code réel."
"@
                    
                    Set-Content -Path $script -Value $scriptContent -Encoding UTF8
                    $issue.Fixed = $true
                    $results.Fixed++
                    Write-Log "Script créé (modèle): $script" -Level "SUCCESS"
                } catch {
                    $issue.Message += " (Échec de la création: $_)"
                    Write-Log "Échec de la création du script $script : $_" -Level "ERROR"
                }
            }
            
            $results.Issues += $issue
        }
    }
    
    return $results
}

# Fonction pour tester la structure des workflows
function Test-WorkflowStructure {
    param (
        [Parameter(Mandatory=$true)]
        [string]$WorkflowFolder,
        
        [Parameter(Mandatory=$false)]
        [bool]$FixIssues = $false
    )
    
    $results = @{
        Tested = 0
        Passed = 0
        Failed = 0
        Fixed = 0
        Issues = @()
    }
    
    # Vérifier si le dossier des workflows existe
    if (-not (Test-Path -Path $WorkflowFolder)) {
        $results.Failed++
        $issue = @{
            Type = "MissingFolder"
            Path = $WorkflowFolder
            Fixed = $false
            Message = "Dossier des workflows manquant: $WorkflowFolder"
        }
        
        Write-Log $issue.Message -Level "WARNING"
        
        if ($FixIssues) {
            try {
                New-Item -Path $WorkflowFolder -ItemType Directory -Force | Out-Null
                $issue.Fixed = $true
                $results.Fixed++
                Write-Log "Dossier des workflows créé: $WorkflowFolder" -Level "SUCCESS"
            } catch {
                $issue.Message += " (Échec de la création: $_)"
                Write-Log "Échec de la création du dossier des workflows $WorkflowFolder : $_" -Level "ERROR"
            }
        }
        
        $results.Issues += $issue
        return $results
    }
    
    # Obtenir la liste des fichiers de workflow
    $workflowFiles = Get-ChildItem -Path $WorkflowFolder -Filter "*.json" -File
    
    if ($workflowFiles.Count -eq 0) {
        Write-Log "Aucun fichier de workflow trouvé dans le dossier: $WorkflowFolder" -Level "WARNING"
        return $results
    }
    
    Write-Log "Nombre de fichiers de workflow trouvés: $($workflowFiles.Count)" -Level "INFO"
    
    # Tester chaque fichier de workflow
    foreach ($file in $workflowFiles) {
        $results.Tested++
        
        try {
            # Lire le contenu du fichier
            $content = Get-Content -Path $file.FullName -Raw
            
            # Vérifier si le contenu est un JSON valide
            $workflow = $content | ConvertFrom-Json
            
            # Vérifier si le fichier contient un workflow n8n valide
            if (-not $workflow.name -or -not $workflow.nodes) {
                $results.Failed++
                $issue = @{
                    Type = "InvalidWorkflow"
                    Path = $file.FullName
                    Fixed = $false
                    Message = "Workflow invalide: $($file.Name) (Propriétés manquantes: name ou nodes)"
                }
                
                Write-Log $issue.Message -Level "WARNING"
                $results.Issues += $issue
            } else {
                $results.Passed++
                Write-Log "Workflow valide: $($file.Name)" -Level "INFO"
            }
        } catch {
            $results.Failed++
            $issue = @{
                Type = "InvalidJson"
                Path = $file.FullName
                Fixed = $false
                Message = "JSON invalide: $($file.Name) (Erreur: $_)"
            }
            
            Write-Log $issue.Message -Level "WARNING"
            $results.Issues += $issue
        }
    }
    
    return $results
}

# Fonction pour tester la structure de configuration
function Test-ConfigStructure {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFolder,
        
        [Parameter(Mandatory=$false)]
        [bool]$FixIssues = $false
    )
    
    $results = @{
        Tested = 0
        Passed = 0
        Failed = 0
        Fixed = 0
        Issues = @()
    }
    
    # Vérifier si le dossier de configuration existe
    if (-not (Test-Path -Path $ConfigFolder)) {
        $results.Failed++
        $issue = @{
            Type = "MissingFolder"
            Path = $ConfigFolder
            Fixed = $false
            Message = "Dossier de configuration manquant: $ConfigFolder"
        }
        
        Write-Log $issue.Message -Level "WARNING"
        
        if ($FixIssues) {
            try {
                New-Item -Path $ConfigFolder -ItemType Directory -Force | Out-Null
                $issue.Fixed = $true
                $results.Fixed++
                Write-Log "Dossier de configuration créé: $ConfigFolder" -Level "SUCCESS"
            } catch {
                $issue.Message += " (Échec de la création: $_)"
                Write-Log "Échec de la création du dossier de configuration $ConfigFolder : $_" -Level "ERROR"
            }
        }
        
        $results.Issues += $issue
        return $results
    }
    
    # Vérifier la présence du fichier de configuration des notifications
    $notificationConfigFile = Join-Path -Path $ConfigFolder -ChildPath "notification-config.json"
    $results.Tested++
    
    if (Test-Path -Path $notificationConfigFile) {
        try {
            # Lire le contenu du fichier
            $content = Get-Content -Path $notificationConfigFile -Raw
            
            # Vérifier si le contenu est un JSON valide
            $config = $content | ConvertFrom-Json
            
            # Vérifier si le fichier contient une configuration valide
            if (-not $config.Email -or -not $config.Teams -or -not $config.Slack) {
                $results.Failed++
                $issue = @{
                    Type = "InvalidConfig"
                    Path = $notificationConfigFile
                    Fixed = $false
                    Message = "Configuration des notifications invalide: Propriétés manquantes (Email, Teams ou Slack)"
                }
                
                Write-Log $issue.Message -Level "WARNING"
                $results.Issues += $issue
            } else {
                $results.Passed++
                Write-Log "Configuration des notifications valide" -Level "INFO"
            }
        } catch {
            $results.Failed++
            $issue = @{
                Type = "InvalidJson"
                Path = $notificationConfigFile
                Fixed = $false
                Message = "JSON invalide dans la configuration des notifications: $_"
            }
            
            Write-Log $issue.Message -Level "WARNING"
            $results.Issues += $issue
        }
    } else {
        $results.Failed++
        $issue = @{
            Type = "MissingFile"
            Path = $notificationConfigFile
            Fixed = $false
            Message = "Fichier de configuration des notifications manquant: $notificationConfigFile"
        }
        
        Write-Log $issue.Message -Level "WARNING"
        
        if ($FixIssues) {
            try {
                # Créer un fichier de configuration par défaut
                $defaultConfig = @{
                    Email = @{
                        Enabled = $false
                        SmtpServer = "smtp.example.com"
                        SmtpPort = 587
                        UseSsl = $true
                        Sender = "n8n@example.com"
                        Recipients = @("admin@example.com")
                        Username = ""
                        Password = ""
                    }
                    Teams = @{
                        Enabled = $false
                        WebhookUrl = "https://outlook.office.com/webhook/..."
                    }
                    Slack = @{
                        Enabled = $false
                        WebhookUrl = "https://hooks.slack.com/services/..."
                    }
                }
                
                $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $notificationConfigFile -Encoding UTF8
                $issue.Fixed = $true
                $results.Fixed++
                Write-Log "Fichier de configuration des notifications créé: $notificationConfigFile" -Level "SUCCESS"
            } catch {
                $issue.Message += " (Échec de la création: $_)"
                Write-Log "Échec de la création du fichier de configuration des notifications: $_" -Level "ERROR"
            }
        }
        
        $results.Issues += $issue
    }
    
    return $results
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Test-FolderStructure, Test-FileStructure, Test-ScriptStructure, Test-WorkflowStructure, Test-ConfigStructure
