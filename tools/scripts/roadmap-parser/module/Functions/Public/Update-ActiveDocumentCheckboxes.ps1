<#
.SYNOPSIS
    Met à jour les cases à cocher dans le document actif pour les tâches implémentées et testées à 100%.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tâches qui ont été implémentées
    et testées avec succès à 100%, puis coche automatiquement les cases correspondantes.

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
    Version: 1.0
    Date de création: 2023-09-15
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
        return
    }

    try {
        # Lire le contenu du document
        $content = Get-Content -Path $DocumentPath -Encoding UTF8
        $modified = $false
        $tasksUpdated = 0

        # Parcourir chaque ligne du document
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]

            # Rechercher les lignes avec des cases à cocher non cochées
            if ($line -match '^\s*-\s+\[\s*\]') {
                # Extraire le texte de la tâche
                $taskText = $line -replace '^\s*-\s+\[\s*\]\s*', ''

                # Rechercher cette tâche dans les résultats d'implémentation et de tests
                $taskFound = $false
                $taskComplete = $false
                $matchedTaskId = $null

                # Essayer de trouver l'ID de la tâche dans le texte
                foreach ($taskId in $ImplementationResults.Keys) {
                    # Échapper les caractères spéciaux dans l'ID de la tâche pour la regex
                    $escapedTaskId = [regex]::Escape($taskId)

                    # Vérifier différents formats possibles d'ID de tâche dans le texte
                    if ($taskText -match "^\*\*$escapedTaskId\*\*" -or
                        $taskText -match "^$escapedTaskId\s" -or
                        $taskText -match "^$escapedTaskId$" -or
                        $taskText -match "\[$escapedTaskId\]" -or
                        $taskText -match "\($escapedTaskId\)" -or
                        # Format spécifique pour les IDs longs comme "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.1"
                        $taskText -match "\*\*$escapedTaskId\*\*") {

                        $taskFound = $true
                        $matchedTaskId = $taskId

                        # Vérifier si l'implémentation et les tests sont à 100%
                        $implementationResult = $ImplementationResults[$taskId]
                        $testResult = $TestResults[$taskId]

                        if ($implementationResult.ImplementationComplete -and
                            $testResult.TestsComplete -and
                            $testResult.TestsSuccessful) {
                            $taskComplete = $true
                        }

                        break
                    }
                }

                # Si aucun ID n'a été trouvé, essayer de faire correspondre par titre
                if (-not $taskFound) {
                    foreach ($taskId in $ImplementationResults.Keys) {
                        $implementationResult = $ImplementationResults[$taskId]

                        # Vérifier si le titre de la tâche correspond
                        if ($implementationResult.TaskTitle -and $taskText -match [regex]::Escape($implementationResult.TaskTitle)) {
                            $taskFound = $true
                            $matchedTaskId = $taskId

                            # Vérifier si l'implémentation et les tests sont à 100%
                            $testResult = $TestResults[$taskId]

                            if ($implementationResult.ImplementationComplete -and
                                $testResult.TestsComplete -and
                                $testResult.TestsSuccessful) {
                                $taskComplete = $true
                            }

                            break
                        }
                    }
                }

                # Si la tâche a été trouvée et est complète, mettre à jour la case à cocher
                if ($taskFound -and $taskComplete) {
                    # Mettre à jour la case à cocher
                    $newLine = $line -replace '^\s*-\s+\[\s*\]', '- [x]'
                    $content[$i] = $newLine
                    $modified = $true
                    $tasksUpdated++

                    Write-Verbose "Case à cocher mise à jour pour la tâche : $taskText (ID: $matchedTaskId)"
                }
            }
        }

        # Enregistrer les modifications si nécessaire
        if ($modified -and $PSCmdlet.ShouldProcess($DocumentPath, "Mettre à jour les cases à cocher")) {
            $content | Set-Content -Path $DocumentPath -Encoding UTF8
            Write-Output "$tasksUpdated cases à cocher mises à jour dans le document : $DocumentPath"
        } else {
            Write-Output "Aucune case à cocher n'a été mise à jour dans le document : $DocumentPath"
        }
    }
    catch {
        Write-Error "Erreur lors de la mise à jour des cases à cocher : $_"
    }
}
