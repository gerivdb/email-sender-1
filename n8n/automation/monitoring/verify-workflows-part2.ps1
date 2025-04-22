<#
.SYNOPSIS
    Script de vérification de la présence des workflows n8n (Partie 2 : Fonctions de vérification).

.DESCRIPTION
    Ce script contient les fonctions de vérification pour la vérification de la présence des workflows n8n.
    Il est conçu pour être utilisé avec les autres parties du script de vérification.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables de la partie 1
. "$PSScriptRoot\verify-workflows-part1.ps1"

# Fonction pour obtenir les workflows depuis un dossier
function Get-WorkflowsFromFolder {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory=$false)]
        [bool]$Recursive = $true
    )
    
    # Vérifier si le dossier existe
    if (-not (Test-Path -Path $FolderPath)) {
        Write-Log "Le dossier n'existe pas: $FolderPath" -Level "ERROR"
        return @()
    }
    
    # Obtenir la liste des fichiers JSON
    $files = Get-ChildItem -Path $FolderPath -Filter "*.json" -File -Recurse:$Recursive
    
    # Analyser chaque fichier pour extraire les informations du workflow
    $workflows = @()
    
    foreach ($file in $files) {
        try {
            # Lire le contenu du fichier
            $content = Get-Content -Path $file.FullName -Raw
            
            # Vérifier si le contenu est un JSON valide
            $workflow = $content | ConvertFrom-Json
            
            # Vérifier si le fichier contient un workflow n8n valide
            if (-not $workflow.name -or -not $workflow.nodes) {
                Write-Log "Le fichier ne semble pas être un workflow n8n valide: $($file.FullName)" -Level "WARNING"
                continue
            }
            
            # Ajouter le workflow à la liste
            $workflows += [PSCustomObject]@{
                Name = $workflow.name
                Id = if ($workflow.id) { $workflow.id } else { "" }
                Active = if ($workflow.active) { $workflow.active } else { $false }
                FilePath = $file.FullName
                FileName = $file.Name
                LastModified = $file.LastWriteTime
                Size = $file.Length
                NodeCount = $workflow.nodes.Count
            }
        } catch {
            Write-Log "Erreur lors de l'analyse du fichier $($file.FullName): $_" -Level "ERROR"
        }
    }
    
    return $workflows
}

# Fonction pour obtenir les workflows via l'API
function Get-WorkflowsFromApi {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ApiUrl,
        
        [Parameter(Mandatory=$true)]
        [string]$ApiKey
    )
    
    try {
        # Préparer les en-têtes
        $headers = @{
            "Accept" = "application/json"
            "X-N8N-API-KEY" = $ApiKey
        }
        
        # Envoyer la requête
        $response = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers $headers
        
        # Analyser la réponse
        $workflows = @()
        
        foreach ($workflow in $response) {
            $workflows += [PSCustomObject]@{
                Name = $workflow.name
                Id = $workflow.id
                Active = $workflow.active
                FilePath = ""
                FileName = ""
                LastModified = [DateTime]::Parse($workflow.updatedAt)
                Size = 0
                NodeCount = $workflow.nodes.Count
            }
        }
        
        return $workflows
    } catch {
        Write-Log "Erreur lors de la récupération des workflows via API: $_" -Level "ERROR"
        
        # Afficher des informations supplémentaires sur l'erreur
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Log "Code d'état HTTP: $statusCode ($statusDescription)" -Level "ERROR"
            
            # Essayer de lire le corps de la réponse d'erreur
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
                
                if (-not [string]::IsNullOrEmpty($responseBody)) {
                    Write-Log "Corps de la réponse: $responseBody" -Level "ERROR"
                }
            } catch {
                # Ignorer les erreurs lors de la lecture du corps de la réponse
            }
        }
        
        return @()
    }
}

# Fonction pour comparer deux listes de workflows
function Compare-WorkflowLists {
    param (
        [Parameter(Mandatory=$true)]
        [array]$ReferenceWorkflows,
        
        [Parameter(Mandatory=$true)]
        [array]$TargetWorkflows
    )
    
    # Créer un dictionnaire des workflows cibles pour une recherche plus rapide
    $targetWorkflowsDict = @{}
    foreach ($workflow in $TargetWorkflows) {
        $targetWorkflowsDict[$workflow.Name] = $workflow
    }
    
    # Comparer les workflows
    $missingWorkflows = @()
    $presentWorkflows = @()
    
    foreach ($refWorkflow in $ReferenceWorkflows) {
        if ($targetWorkflowsDict.ContainsKey($refWorkflow.Name)) {
            # Le workflow est présent
            $presentWorkflows += [PSCustomObject]@{
                Name = $refWorkflow.Name
                ReferenceFilePath = $refWorkflow.FilePath
                TargetFilePath = $targetWorkflowsDict[$refWorkflow.Name].FilePath
                ReferenceLastModified = $refWorkflow.LastModified
                TargetLastModified = $targetWorkflowsDict[$refWorkflow.Name].LastModified
                IsNewer = $refWorkflow.LastModified -gt $targetWorkflowsDict[$refWorkflow.Name].LastModified
                Active = $targetWorkflowsDict[$refWorkflow.Name].Active
            }
        } else {
            # Le workflow est manquant
            $missingWorkflows += [PSCustomObject]@{
                Name = $refWorkflow.Name
                ReferenceFilePath = $refWorkflow.FilePath
                ReferenceLastModified = $refWorkflow.LastModified
                NodeCount = $refWorkflow.NodeCount
            }
        }
    }
    
    return @{
        MissingWorkflows = $missingWorkflows
        PresentWorkflows = $presentWorkflows
    }
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Get-WorkflowsFromFolder, Get-WorkflowsFromApi, Compare-WorkflowLists
