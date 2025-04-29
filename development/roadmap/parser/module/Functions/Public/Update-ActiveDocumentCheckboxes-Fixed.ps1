<#
.SYNOPSIS
    Met à jour les cases à cocher dans le document actif pour les tâches implémentées et testées à 100%.
    Version corrigée avec support UTF-8 avec BOM.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tâches qui ont été implémentées
    et testées avec succès à 100%, puis coche automatiquement les cases correspondantes.
    Cette version corrigée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM
    et préserve correctement les caractères accentués et l'indentation.

.PARAMETER DocumentPath
    Chemin vers le document actif à mettre à jour.

.PARAMETER ImplementationResults
    Résultats de l'implémentation des tâches (hashtable).

.PARAMETER TestResults
    Résultats des tests des tâches (hashtable).

.EXAMPLE
    Update-ActiveDocumentCheckboxes -DocumentPath "document.md" -ImplementationResults $implResults -TestResults $testResults

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.2
    Date de création: 2023-09-15
    Date de mise à jour: 2025-05-02 - Correction des problèmes d'encodage et des expressions régulières
#>
function Update-ActiveDocumentCheckboxes {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DocumentPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$ImplementationResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$TestResults
    )

    # Vérifier que le document existe
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document spécifié n'existe pas : $DocumentPath"
        return 0
    }

    try {
        # Lire le contenu du document
        $content = Get-Content -Path $DocumentPath -Encoding UTF8
        $tasksUpdated = 0

        # Pour chaque tâche vérifiée
        foreach ($taskId in $ImplementationResults.Keys) {
            # Si la tâche est implémentée à 100% et testée avec succès à 100%
            if ($ImplementationResults[$taskId].ImplementationComplete -and 
                $TestResults[$taskId].TestsComplete -and 
                $TestResults[$taskId].TestsSuccessful) {
                
                # Rechercher la tâche dans le document actif (différents formats possibles)
                $taskPatterns = @(
                    "- \[ \] \*\*$taskId\*\*",
                    "- \[ \] $taskId",
                    "- \[ \] .*$taskId.*"
                )

                foreach ($taskPattern in $taskPatterns) {
                    $taskReplacement = $taskPattern -replace "\[ \]", "[x]"

                    # Mettre à jour la case à cocher
                    $newContent = @()
                    $updated = $false
                    
                    foreach ($line in $content) {
                        if ($line -match $taskPattern -and -not $updated) {
                            $newLine = $line -replace "\[ \]", "[x]"
                            $newContent += $newLine
                            $tasksUpdated++
                            $updated = $true
                            Write-Host "  Tâche $taskId : Case à cocher mise à jour" -ForegroundColor Green
                        } else {
                            $newContent += $line
                        }
                    }

                    # Si le contenu a changé, c'est que la tâche a été trouvée et mise à jour
                    if ($updated) {
                        $content = $newContent
                        break  # Sortir de la boucle des patterns une fois la tâche trouvée
                    }
                }
            }
        }

        # Si des tâches ont été mises à jour, enregistrer le document
        if ($tasksUpdated -gt 0) {
            if ($PSCmdlet.ShouldProcess($DocumentPath, "Mettre à jour les cases à cocher")) {
                # Mode force, appliquer les modifications sans confirmation
                $content | Set-Content -Path $DocumentPath -Encoding UTF8
                Write-Host "  $tasksUpdated tâches ont été mises à jour dans le document actif." -ForegroundColor Green
            } else {
                # Mode simulation, afficher les modifications sans les appliquer
                Write-Host "  $tasksUpdated tâches seraient mises à jour dans le document actif (mode simulation)." -ForegroundColor Yellow
                Write-Host "  Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Aucune tâche à mettre à jour dans le document actif." -ForegroundColor Yellow
        }
        
        return $tasksUpdated
    }
    catch {
        Write-Error "Erreur lors de la mise à jour des cases à cocher : $_"
        return 0
    }
}
