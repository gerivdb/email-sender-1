<#
.SYNOPSIS
    Met Ã  jour les cases Ã  cocher dans le document actif pour les tÃ¢ches implÃ©mentÃ©es et testÃ©es Ã  100%.
    Version amÃ©liorÃ©e avec support UTF-8 avec BOM.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tÃ¢ches qui ont Ã©tÃ© implÃ©mentÃ©es
    et testÃ©es avec succÃ¨s Ã  100%, puis coche automatiquement les cases correspondantes.
    Cette version amÃ©liorÃ©e garantit que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM
    et prÃ©serve correctement les caractÃ¨res accentuÃ©s et l'indentation.

.PARAMETER DocumentPath
    Chemin vers le document actif Ã  mettre Ã  jour.

.PARAMETER ImplementationResults
    RÃ©sultats de l'implÃ©mentation des tÃ¢ches (hashtable).

.PARAMETER TestResults
    RÃ©sultats des tests des tÃ¢ches (hashtable).

.EXAMPLE
    Update-ActiveDocumentCheckboxes-Enhanced -DocumentPath "document.md" -ImplementationResults $implResults -TestResults $testResults

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃ©ation: 2023-09-15
    Date de mise Ã  jour: 2025-05-01 - AmÃ©lioration de l'encodage UTF-8 avec BOM
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

    # VÃ©rifier que le document existe
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document spÃ©cifiÃ© n'existe pas : $DocumentPath"
        return 0
    }

    try {
        # Lire le contenu du document avec l'encodage appropriÃ©
        # Utiliser [System.IO.File]::ReadAllLines pour garantir la dÃ©tection correcte de l'encodage
        $content = [System.IO.File]::ReadAllLines($DocumentPath)
        $modified = $false
        $tasksUpdated = 0

        # Parcourir chaque ligne du document
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]

            # Rechercher les lignes avec des cases Ã  cocher non cochÃ©es
            if ($line -match '^\s*-\s+\[\s*\]') {
                # Extraire le texte de la tÃ¢che en prÃ©servant l'indentation
                $indentation = [regex]::Match($line, '^\s*').Value
                $taskText = $line -replace '^\s*-\s+\[\s*\]\s*', ''

                # Rechercher cette tÃ¢che dans les rÃ©sultats d'implÃ©mentation et de tests
                $taskFound = $false
                $taskComplete = $false
                $matchedTaskId = $null

                # Essayer de trouver l'ID de la tÃ¢che dans le texte
                foreach ($taskId in $ImplementationResults.Keys) {
                    # Ã‰chapper les caractÃ¨res spÃ©ciaux dans l'ID de la tÃ¢che pour la regex
                    $escapedTaskId = [regex]::Escape($taskId)

                    # VÃ©rifier diffÃ©rents formats possibles d'ID de tÃ¢che dans le texte
                    if ($taskText -match "^\*\*$escapedTaskId\*\*" -or
                        $taskText -match "^$escapedTaskId\s" -or
                        $taskText -match "^$escapedTaskId$" -or
                        $taskText -match "\[$escapedTaskId\]" -or
                        $taskText -match "\($escapedTaskId\)" -or
                        # Format spÃ©cifique pour les IDs longs
                        $taskText -match "\*\*$escapedTaskId\*\*") {

                        $taskFound = $true
                        $matchedTaskId = $taskId

                        # VÃ©rifier si l'implÃ©mentation et les tests sont Ã  100%
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

                # Si aucun ID n'a Ã©tÃ© trouvÃ©, essayer de faire correspondre par titre
                if (-not $taskFound) {
                    foreach ($taskId in $ImplementationResults.Keys) {
                        $implementationResult = $ImplementationResults[$taskId]

                        # VÃ©rifier si le titre de la tÃ¢che correspond
                        if ($implementationResult.TaskTitle -and $taskText -match [regex]::Escape($implementationResult.TaskTitle)) {
                            $taskFound = $true
                            $matchedTaskId = $taskId

                            # VÃ©rifier si l'implÃ©mentation et les tests sont Ã  100%
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

                # Si la tÃ¢che a Ã©tÃ© trouvÃ©e et est complÃ¨te, mettre Ã  jour la case Ã  cocher
                if ($taskFound -and $taskComplete) {
                    # Mettre Ã  jour la case Ã  cocher en prÃ©servant l'indentation et le texte complet
                    $newLine = $line -replace '^\s*-\s+\[\s*\]', "$indentation- [x]"
                    $content[$i] = $newLine
                    $modified = $true
                    $tasksUpdated++

                    Write-Verbose "Case Ã  cocher mise Ã  jour pour la tÃ¢che : $taskText (ID: $matchedTaskId)"
                }
            }
        }

        # Enregistrer les modifications si nÃ©cessaire
        if ($modified -and $PSCmdlet.ShouldProcess($DocumentPath, "Mettre Ã  jour les cases Ã  cocher")) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($DocumentPath, $content, $utf8WithBom)

            # VÃ©rifier que le fichier a bien Ã©tÃ© enregistrÃ© en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($DocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas Ã©tÃ© correctement enregistrÃ© en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($DocumentPath)
                [System.IO.File]::WriteAllText($DocumentPath, $content, $utf8WithBom)
            }

            Write-Output "$tasksUpdated cases Ã  cocher mises Ã  jour dans le document : $DocumentPath"
        } else {
            Write-Output "$tasksUpdated cases Ã  cocher seraient mises Ã  jour dans le document : $DocumentPath (mode simulation)"
        }

        return $tasksUpdated
    }
    catch {
        Write-Error "Erreur lors de la mise Ã  jour des cases Ã  cocher : $_"
        return 0
    }
}
