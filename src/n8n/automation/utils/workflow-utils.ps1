<#
.SYNOPSIS
    Utilitaires pour manipuler les workflows n8n.

.DESCRIPTION
    Ce script contient des fonctions pour manipuler les workflows n8n.
    Il est utilisé par les scripts de synchronisation.
#>

# Fonction pour corriger un workflow
function Fix-Workflow {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow
    )

    # Vérifier si le workflow a un ID
    if (-not $Workflow.id) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "id" -Value ([guid]::NewGuid().ToString()) -Force
    }

    # Vérifier si le workflow a une date de création
    if (-not $Workflow.createdAt) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "createdAt" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ") -Force
    }

    # Vérifier si le workflow a une date de mise à jour
    if (-not $Workflow.updatedAt) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "updatedAt" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ") -Force
    }

    # Vérifier si le workflow a un ID de version
    if (-not $Workflow.versionId) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "versionId" -Value ([guid]::NewGuid().ToString()) -Force
    }

    # Vérifier si le workflow a un état d'activation
    if ($null -eq $Workflow.active) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "active" -Value $false -Force
    }

    # Vérifier si le workflow a des paramètres
    if (-not $Workflow.settings) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "settings" -Value @{
            executionOrder       = "v1"
            saveManualExecutions = $true
            callerPolicy         = "workflowsFromSameOwner"
            errorWorkflow        = ""
        } -Force
    }

    # Vérifier si le workflow a des données statiques
    if ($null -eq $Workflow.staticData) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "staticData" -Value $null -Force
    }

    # Vérifier si le workflow a un compteur de déclenchements
    if ($null -eq $Workflow.triggerCount) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "triggerCount" -Value 0 -Force
    }

    # Vérifier si le workflow a des données épinglées
    if ($null -eq $Workflow.pinData) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "pinData" -Value @{} -Force
    }

    # Vérifier si le workflow a des tags
    if ($null -eq $Workflow.tags) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "tags" -Value @() -Force
    }

    return $Workflow
}

# Fonction pour obtenir l'environnement d'un workflow à partir de ses tags
function Get-WorkflowEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultEnvironment = "local"
    )
    
    if ($Workflow.tags -and $Workflow.tags.Count -gt 0) {
        foreach ($tag in $Workflow.tags) {
            if ($tag.name -eq "ide") {
                return "ide"
            } elseif ($tag.name -eq "local") {
                return "local"
            } elseif ($tag.name -eq "archive") {
                return "archive"
            }
        }
    }
    
    return $DefaultEnvironment
}

# Fonction pour ajouter un tag à un workflow
function Add-WorkflowTag {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow,
        
        [Parameter(Mandatory = $true)]
        [string]$TagName
    )
    
    # Vérifier si le workflow a des tags
    if ($null -eq $Workflow.tags) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "tags" -Value @() -Force
    }
    
    # Vérifier si le tag existe déjà
    $tagExists = $false
    foreach ($tag in $Workflow.tags) {
        if ($tag.name -eq $TagName) {
            $tagExists = $true
            break
        }
    }
    
    # Ajouter le tag s'il n'existe pas
    if (-not $tagExists) {
        $newTag = @{
            id = [guid]::NewGuid().ToString()
            name = $TagName
        }
        
        $Workflow.tags += $newTag
    }
    
    return $Workflow
}

# Fonction pour supprimer un tag d'un workflow
function Remove-WorkflowTag {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow,
        
        [Parameter(Mandatory = $true)]
        [string]$TagName
    )
    
    # Vérifier si le workflow a des tags
    if ($null -eq $Workflow.tags -or $Workflow.tags.Count -eq 0) {
        return $Workflow
    }
    
    # Supprimer le tag s'il existe
    $newTags = @()
    foreach ($tag in $Workflow.tags) {
        if ($tag.name -ne $TagName) {
            $newTags += $tag
        }
    }
    
    $Workflow.tags = $newTags
    
    return $Workflow
}

# Fonction pour obtenir le nom de fichier d'un workflow
function Get-WorkflowFileName {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow
    )
    
    # Utiliser le nom du workflow pour créer le nom de fichier
    $fileName = "$($Workflow.name -replace '[^\w\-\.]', '_').json"
    
    return $fileName
}
