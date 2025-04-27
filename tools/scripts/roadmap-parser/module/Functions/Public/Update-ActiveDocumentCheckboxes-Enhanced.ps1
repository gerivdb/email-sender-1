<#
.SYNOPSIS
    Met à jour les cases à cocher dans le document actif pour les tâches implémentées et testées à 100%.
    Version améliorée avec support UTF-8 avec BOM.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tâches qui ont été implémentées
    et testées avec succès à 100%, puis coche automatiquement les cases correspondantes.
    Cette version améliorée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM
    et préserve correctement les caractères accentués et l'indentation.

.PARAMETER DocumentPath
    Chemin vers le document actif à mettre à jour.

.PARAMETER ImplementationResults
    Résultats de l'implémentation des tâches (hashtable).

.PARAMETER TestResults
    Résultats des tests des tâches (hashtable).

.EXAMPLE
    Update-ActiveDocumentCheckboxes-Enhanced -DocumentPath "document.md" -ImplementationResults $implResults -TestResults $testResults

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de création: 2023-09-15
    Date de mise à jour: 2025-05-01 - Amélioration de l'encodage UTF-8 avec BOM
#>
function Update-ActiveDocumentCheckboxes-Enhanced {
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
        # Lire le contenu du document avec l'encodage approprié
        # Utiliser [System.IO.File]::ReadAllLines pour garantir la détection correcte de l'encodage
        $content = [System.IO.File]::ReadAllLines($DocumentPath)
        $modified = $false
        $tasksUpdated = 0

        # Parcourir chaque ligne du document
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]

            # Rechercher les lignes avec des cases à cocher non cochées
            if ($line -match '^\s*-\s+\[\s*\]') {
                # Extraire le texte de la tâche en préservant l'indentation
                $indentation = [regex]::Match($line, '^\s*').Value
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
                        # Format spécifique pour les IDs longs
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
                    # Mettre à jour la case à cocher en préservant l'indentation et le texte complet
                    $newLine = $line -replace '^\s*-\s+\[\s*\]', "$indentation- [x]"
                    $content[$i] = $newLine
                    $modified = $true
                    $tasksUpdated++

                    Write-Verbose "Case à cocher mise à jour pour la tâche : $taskText (ID: $matchedTaskId)"
                }
            }
        }

        # Enregistrer les modifications si nécessaire
        if ($modified -and $PSCmdlet.ShouldProcess($DocumentPath, "Mettre à jour les cases à cocher")) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($DocumentPath, $content, $utf8WithBom)

            # Vérifier que le fichier a bien été enregistré en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($DocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas été correctement enregistré en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($DocumentPath)
                [System.IO.File]::WriteAllText($DocumentPath, $content, $utf8WithBom)
            }

            Write-Output "$tasksUpdated cases à cocher mises à jour dans le document : $DocumentPath"
        } else {
            Write-Output "$tasksUpdated cases à cocher seraient mises à jour dans le document : $DocumentPath (mode simulation)"
        }

        return $tasksUpdated
    }
    catch {
        Write-Error "Erreur lors de la mise à jour des cases à cocher : $_"
        return 0
    }
}
