<#
.SYNOPSIS
    Met Ã  jour les cases Ã  cocher dans le document actif pour les tÃ¢ches implÃ©mentÃ©es et testÃ©es Ã  100%.
    Version corrigÃ©e avec support UTF-8 avec BOM.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tÃ¢ches qui ont Ã©tÃ© implÃ©mentÃ©es
    et testÃ©es avec succÃ¨s Ã  100%, puis coche automatiquement les cases correspondantes.
    Cette version corrigÃ©e garantit que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM
    et prÃ©serve correctement les caractÃ¨res accentuÃ©s et l'indentation.

.PARAMETER DocumentPath
    Chemin vers le document actif Ã  mettre Ã  jour.

.PARAMETER ImplementationResults
    RÃ©sultats de l'implÃ©mentation des tÃ¢ches (hashtable).

.PARAMETER TestResults
    RÃ©sultats des tests des tÃ¢ches (hashtable).

.EXAMPLE
    Update-ActiveDocumentCheckboxes -DocumentPath "document.md" -ImplementationResults $implResults -TestResults $testResults

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.2
    Date de crÃ©ation: 2023-09-15
    Date de mise Ã  jour: 2025-05-02 - Correction des problÃ¨mes d'encodage et des expressions rÃ©guliÃ¨res
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

    # VÃ©rifier que le document existe
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document spÃ©cifiÃ© n'existe pas : $DocumentPath"
        return 0
    }

    try {
        # Lire le contenu du document
        $content = Get-Content -Path $DocumentPath -Encoding UTF8
        $tasksUpdated = 0

        # Pour chaque tÃ¢che vÃ©rifiÃ©e
        foreach ($taskId in $ImplementationResults.Keys) {
            # Si la tÃ¢che est implÃ©mentÃ©e Ã  100% et testÃ©e avec succÃ¨s Ã  100%
            if ($ImplementationResults[$taskId].ImplementationComplete -and 
                $TestResults[$taskId].TestsComplete -and 
                $TestResults[$taskId].TestsSuccessful) {
                
                # Rechercher la tÃ¢che dans le document actif (diffÃ©rents formats possibles)
                $taskPatterns = @(
                    "- \[ \] \*\*$taskId\*\*",
                    "- \[ \] $taskId",
                    "- \[ \] .*$taskId.*"
                )

                foreach ($taskPattern in $taskPatterns) {
                    $taskReplacement = $taskPattern -replace "\[ \]", "[x]"

                    # Mettre Ã  jour la case Ã  cocher
                    $newContent = @()
                    $updated = $false
                    
                    foreach ($line in $content) {
                        if ($line -match $taskPattern -and -not $updated) {
                            $newLine = $line -replace "\[ \]", "[x]"
                            $newContent += $newLine
                            $tasksUpdated++
                            $updated = $true
                            Write-Host "  TÃ¢che $taskId : Case Ã  cocher mise Ã  jour" -ForegroundColor Green
                        } else {
                            $newContent += $line
                        }
                    }

                    # Si le contenu a changÃ©, c'est que la tÃ¢che a Ã©tÃ© trouvÃ©e et mise Ã  jour
                    if ($updated) {
                        $content = $newContent
                        break  # Sortir de la boucle des patterns une fois la tÃ¢che trouvÃ©e
                    }
                }
            }
        }

        # Si des tÃ¢ches ont Ã©tÃ© mises Ã  jour, enregistrer le document
        if ($tasksUpdated -gt 0) {
            if ($PSCmdlet.ShouldProcess($DocumentPath, "Mettre Ã  jour les cases Ã  cocher")) {
                # Mode force, appliquer les modifications sans confirmation
                $content | Set-Content -Path $DocumentPath -Encoding UTF8
                Write-Host "  $tasksUpdated tÃ¢ches ont Ã©tÃ© mises Ã  jour dans le document actif." -ForegroundColor Green
            } else {
                # Mode simulation, afficher les modifications sans les appliquer
                Write-Host "  $tasksUpdated tÃ¢ches seraient mises Ã  jour dans le document actif (mode simulation)." -ForegroundColor Yellow
                Write-Host "  Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Aucune tÃ¢che Ã  mettre Ã  jour dans le document actif." -ForegroundColor Yellow
        }
        
        return $tasksUpdated
    }
    catch {
        Write-Error "Erreur lors de la mise Ã  jour des cases Ã  cocher : $_"
        return 0
    }
}
