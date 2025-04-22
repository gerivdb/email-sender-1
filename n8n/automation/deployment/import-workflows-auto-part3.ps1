<#
.SYNOPSIS
    Script d'importation automatique des workflows n8n (Partie 3 : Fonction principale d'importation).

.DESCRIPTION
    Ce script contient la fonction principale d'importation pour l'importation automatique des workflows n8n.
    Il est conçu pour être utilisé avec les autres parties du script d'importation.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables des parties précédentes
. "$PSScriptRoot\import-workflows-auto-part1.ps1"
. "$PSScriptRoot\import-workflows-auto-part2.ps1"

# Fonction principale pour importer les workflows
function Import-Workflows {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourceFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory=$false)]
        [string]$ApiUrl = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Tags = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Active = $true,
        
        [Parameter(Mandatory=$false)]
        [bool]$Recursive = $true,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupFolder = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Force = $false,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxConcurrent = 5
    )
    
    # Vérifier si le dossier source existe
    if (-not (Test-Path -Path $SourceFolder)) {
        Write-Log "Le dossier source n'existe pas: $SourceFolder" -Level "ERROR"
        return @{
            Success = 0
            Failure = 0
            Total = 0
            SuccessRate = 0
        }
    }
    
    # Obtenir la liste des fichiers à importer
    $searchOption = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
    $files = Get-ChildItem -Path $SourceFolder -Filter "*.json" -File -Recurse:$Recursive
    
    if ($files.Count -eq 0) {
        Write-Log "Aucun fichier JSON trouvé dans le dossier source: $SourceFolder" -Level "WARNING"
        return @{
            Success = 0
            Failure = 0
            Total = 0
            SuccessRate = 0
        }
    }
    
    Write-Log "Nombre de fichiers à importer: $($files.Count)" -Level "INFO"
    
    # Initialiser les compteurs
    $successCount = 0
    $failureCount = 0
    
    # Importer chaque fichier
    foreach ($file in $files) {
        Write-Log "Traitement du fichier: $($file.FullName)" -Level "INFO"
        
        # Importer le workflow selon la méthode spécifiée
        $importSuccess = Import-Workflow -FilePath $file.FullName -Method $Method -ApiKey $ApiKey -ApiUrl $ApiUrl -Tags $Tags -Active $Active
        
        # Copier le fichier vers le dossier cible si l'importation a réussi
        if ($importSuccess) {
            $copySuccess = Copy-WorkflowToTarget -SourcePath $file.FullName -TargetFolder $TargetFolder -Force $Force -BackupFolder $BackupFolder
            
            if ($copySuccess) {
                $successCount++
                Write-Log "Workflow importé avec succès: $($file.Name)" -Level "SUCCESS"
            } else {
                $failureCount++
                Write-Log "Échec de la copie du workflow: $($file.Name)" -Level "ERROR"
            }
        } else {
            $failureCount++
            Write-Log "Échec de l'importation du workflow: $($file.Name)" -Level "ERROR"
        }
    }
    
    # Calculer le taux de réussite
    $totalCount = $files.Count
    $successRate = if ($totalCount -gt 0) { [Math]::Round(($successCount / $totalCount) * 100, 2) } else { 0 }
    
    # Retourner les résultats
    return @{
        Success = $successCount
        Failure = $failureCount
        Total = $totalCount
        SuccessRate = $successRate
    }
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Import-Workflows
