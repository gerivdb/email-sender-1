<#
.SYNOPSIS
    Script de vérification de la présence des workflows n8n (Partie 3 : Fonction principale).

.DESCRIPTION
    Ce script contient la fonction principale pour la vérification de la présence des workflows n8n.
    Il est conçu pour être utilisé avec les autres parties du script de vérification.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables des parties précédentes
. "$PSScriptRoot\verify-workflows-part1.ps1"
. "$PSScriptRoot\verify-workflows-part2.ps1"

# Fonction principale pour vérifier la présence des workflows
function Verify-Workflows {
    param (
        [Parameter(Mandatory=$false)]
        [string]$WorkflowFolder = $script:CommonParams.WorkflowFolder,
        
        [Parameter(Mandatory=$false)]
        [string]$ReferenceFolder = $script:CommonParams.ReferenceFolder,
        
        [Parameter(Mandatory=$false)]
        [bool]$ApiMethod = $script:CommonParams.ApiMethod,
        
        [Parameter(Mandatory=$false)]
        [string]$Hostname = $script:CommonParams.Hostname,
        
        [Parameter(Mandatory=$false)]
        [int]$Port = $script:CommonParams.Port,
        
        [Parameter(Mandatory=$false)]
        [string]$Protocol = $script:CommonParams.Protocol,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $script:CommonParams.ApiKey,
        
        [Parameter(Mandatory=$false)]
        [bool]$Recursive = $script:CommonParams.Recursive,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile = $script:CommonParams.OutputFile,
        
        [Parameter(Mandatory=$false)]
        [int]$DetailLevel = $script:CommonParams.DetailLevel
    )
    
    # Afficher les informations de démarrage
    Write-Log "=== Vérification de la présence des workflows n8n ===" -Level "INFO"
    Write-Log "Dossier des workflows: $WorkflowFolder" -Level "INFO"
    Write-Log "Dossier de référence: $ReferenceFolder" -Level "INFO"
    Write-Log "Méthode API: $ApiMethod" -Level "INFO"
    
    if ($ApiMethod) {
        Write-Log "URL de l'API: $Protocol`://$Hostname`:$Port/api/v1/workflows" -Level "INFO"
    }
    
    # Obtenir les workflows de référence
    Write-Log "Récupération des workflows de référence..." -Level "INFO"
    $referenceWorkflows = Get-WorkflowsFromFolder -FolderPath $ReferenceFolder -Recursive $Recursive
    
    if ($referenceWorkflows.Count -eq 0) {
        Write-Log "Aucun workflow de référence trouvé dans le dossier: $ReferenceFolder" -Level "WARNING"
        return @{
            MissingWorkflows = @()
            PresentWorkflows = @()
            ReferenceCount = 0
            TargetCount = 0
            MissingCount = 0
            PresentCount = 0
        }
    }
    
    Write-Log "Nombre de workflows de référence: $($referenceWorkflows.Count)" -Level "INFO"
    
    # Obtenir les workflows cibles
    $targetWorkflows = @()
    
    if ($ApiMethod) {
        # Récupérer l'API Key si nécessaire
        if ([string]::IsNullOrEmpty($ApiKey)) {
            $ApiKey = Get-ApiKeyFromConfig
            if ([string]::IsNullOrEmpty($ApiKey)) {
                Write-Log "Aucune API Key trouvée. La vérification via API échouera." -Level "ERROR"
                return @{
                    MissingWorkflows = $referenceWorkflows
                    PresentWorkflows = @()
                    ReferenceCount = $referenceWorkflows.Count
                    TargetCount = 0
                    MissingCount = $referenceWorkflows.Count
                    PresentCount = 0
                }
            }
        }
        
        # Construire l'URL de l'API
        $apiUrl = "$Protocol`://$Hostname`:$Port/api/v1/workflows"
        
        # Obtenir les workflows via l'API
        Write-Log "Récupération des workflows via API..." -Level "INFO"
        $targetWorkflows = Get-WorkflowsFromApi -ApiUrl $apiUrl -ApiKey $ApiKey
    } else {
        # Obtenir les workflows depuis le dossier
        Write-Log "Récupération des workflows depuis le dossier: $WorkflowFolder" -Level "INFO"
        $targetWorkflows = Get-WorkflowsFromFolder -FolderPath $WorkflowFolder -Recursive $Recursive
    }
    
    if ($targetWorkflows.Count -eq 0) {
        Write-Log "Aucun workflow cible trouvé." -Level "WARNING"
        
        # Tous les workflows de référence sont manquants
        $result = @{
            MissingWorkflows = $referenceWorkflows
            PresentWorkflows = @()
            ReferenceCount = $referenceWorkflows.Count
            TargetCount = 0
            MissingCount = $referenceWorkflows.Count
            PresentCount = 0
        }
        
        # Enregistrer les résultats dans un fichier
        if (-not [string]::IsNullOrEmpty($OutputFile)) {
            $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding utf8
            Write-Log "Résultats enregistrés dans le fichier: $OutputFile" -Level "INFO"
        }
        
        # Envoyer une notification
        $subject = "Vérification des workflows n8n: $($referenceWorkflows.Count) workflows manquants"
        $message = "Aucun workflow cible trouvé. Tous les workflows de référence ($($referenceWorkflows.Count)) sont manquants."
        Send-WorkflowNotification -Subject $subject -Message $message -Level "ERROR"
        
        return $result
    }
    
    Write-Log "Nombre de workflows cibles: $($targetWorkflows.Count)" -Level "INFO"
    
    # Comparer les workflows
    Write-Log "Comparaison des workflows..." -Level "INFO"
    $comparisonResult = Compare-WorkflowLists -ReferenceWorkflows $referenceWorkflows -TargetWorkflows $targetWorkflows
    
    # Afficher les résultats
    $missingCount = $comparisonResult.MissingWorkflows.Count
    $presentCount = $comparisonResult.PresentWorkflows.Count
    
    Write-Log "Nombre de workflows manquants: $missingCount" -Level $(if ($missingCount -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Log "Nombre de workflows présents: $presentCount" -Level "INFO"
    
    # Afficher les détails des workflows manquants
    if ($missingCount -gt 0) {
        Write-Log "`n=== Workflows manquants ===" -Level "WARNING"
        
        foreach ($workflow in $comparisonResult.MissingWorkflows) {
            Write-Log "  - $($workflow.Name) (Fichier: $($workflow.ReferenceFilePath))" -Level "WARNING"
        }
    }
    
    # Afficher les détails des workflows présents si le niveau de détail est suffisant
    if ($DetailLevel -ge 3 -and $presentCount -gt 0) {
        Write-Log "`n=== Workflows présents ===" -Level "INFO"
        
        foreach ($workflow in $comparisonResult.PresentWorkflows) {
            $status = if ($workflow.Active) { "Actif" } else { "Inactif" }
            $newerStatus = if ($workflow.IsNewer) { " (Référence plus récente)" } else { "" }
            Write-Log "  - $($workflow.Name) ($status)$newerStatus" -Level "INFO"
        }
    }
    
    # Enregistrer les résultats dans un fichier
    if (-not [string]::IsNullOrEmpty($OutputFile)) {
        $result = @{
            MissingWorkflows = $comparisonResult.MissingWorkflows
            PresentWorkflows = $comparisonResult.PresentWorkflows
            ReferenceCount = $referenceWorkflows.Count
            TargetCount = $targetWorkflows.Count
            MissingCount = $missingCount
            PresentCount = $presentCount
        }
        
        $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding utf8
        Write-Log "Résultats enregistrés dans le fichier: $OutputFile" -Level "INFO"
    }
    
    # Envoyer une notification si des workflows sont manquants
    if ($missingCount -gt 0) {
        $subject = "Vérification des workflows n8n: $missingCount workflows manquants"
        $message = "La vérification a détecté $missingCount workflows manquants sur un total de $($referenceWorkflows.Count) workflows de référence.`n`n"
        $message += "Workflows manquants:`n"
        
        foreach ($workflow in $comparisonResult.MissingWorkflows) {
            $message += "- $($workflow.Name)`n"
        }
        
        $level = if ($missingCount -ge ($referenceWorkflows.Count / 2)) { "ERROR" } else { "WARNING" }
        Send-WorkflowNotification -Subject $subject -Message $message -Level $level
    }
    
    # Retourner les résultats
    return @{
        MissingWorkflows = $comparisonResult.MissingWorkflows
        PresentWorkflows = $comparisonResult.PresentWorkflows
        ReferenceCount = $referenceWorkflows.Count
        TargetCount = $targetWorkflows.Count
        MissingCount = $missingCount
        PresentCount = $presentCount
    }
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Verify-Workflows
