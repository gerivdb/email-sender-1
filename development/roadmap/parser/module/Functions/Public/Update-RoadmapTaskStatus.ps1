<#
.SYNOPSIS
    Met Ã  jour le statut d'une tÃ¢che dans un fichier de roadmap.

.DESCRIPTION
    Cette fonction met Ã  jour le statut d'une tÃ¢che dans un fichier de roadmap en modifiant
    la case Ã  cocher correspondante. Elle peut marquer une tÃ¢che comme terminÃ©e ou en cours.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  mettre Ã  jour (par exemple, "1.2.1.3.2.3").

.PARAMETER Status
    Statut Ã  appliquer Ã  la tÃ¢che. Valeurs possibles : "Completed", "InProgress".
    Par dÃ©faut : "Completed".

.EXAMPLE
    Update-RoadmapTaskStatus -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Status "Completed"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>
function Update-RoadmapTaskStatus {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Completed", "InProgress")]
        [string]$Status = "Completed"
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8
    
    # Trouver la ligne contenant la tÃ¢che Ã  mettre Ã  jour
    $taskLineIndex = -1
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"
    
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskLinePattern) {
            $taskLineIndex = $i
            break
        }
    }
    
    if ($taskLineIndex -eq -1) {
        throw "TÃ¢che avec l'identifiant '$TaskIdentifier' non trouvÃ©e dans le fichier."
    }
    
    # Modifier la case Ã  cocher selon le statut demandÃ©
    $taskLine = $content[$taskLineIndex]
    $newTaskLine = $taskLine
    
    if ($Status -eq "Completed") {
        # Remplacer "[ ]" par "[x]"
        $newTaskLine = $taskLine -replace "\[\s*\]", "[x]"
    } else {
        # Remplacer "[x]" par "[ ]"
        $newTaskLine = $taskLine -replace "\[\s*x\s*\]", "[ ]"
    }
    
    # Si la ligne n'a pas changÃ©, c'est que le statut est dÃ©jÃ  correct
    if ($newTaskLine -eq $taskLine) {
        Write-Verbose "La tÃ¢che '$TaskIdentifier' a dÃ©jÃ  le statut '$Status'."
        return
    }
    
    # Mettre Ã  jour le contenu
    $content[$taskLineIndex] = $newTaskLine
    
    # Ã‰crire le contenu modifiÃ© dans le fichier
    if ($PSCmdlet.ShouldProcess($FilePath, "Mettre Ã  jour le statut de la tÃ¢che '$TaskIdentifier' Ã  '$Status'")) {
        $content | Set-Content -Path $FilePath -Encoding UTF8
        Write-Output "Statut de la tÃ¢che '$TaskIdentifier' mis Ã  jour Ã  '$Status'."
    }
}
