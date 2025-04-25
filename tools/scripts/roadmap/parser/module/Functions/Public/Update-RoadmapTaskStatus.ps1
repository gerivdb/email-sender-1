<#
.SYNOPSIS
    Met à jour le statut d'une tâche dans un fichier de roadmap.

.DESCRIPTION
    Cette fonction met à jour le statut d'une tâche dans un fichier de roadmap en modifiant
    la case à cocher correspondante. Elle peut marquer une tâche comme terminée ou en cours.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à mettre à jour (par exemple, "1.2.1.3.2.3").

.PARAMETER Status
    Statut à appliquer à la tâche. Valeurs possibles : "Completed", "InProgress".
    Par défaut : "Completed".

.EXAMPLE
    Update-RoadmapTaskStatus -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Status "Completed"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
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

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spécifié n'existe pas : $FilePath"
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8
    
    # Trouver la ligne contenant la tâche à mettre à jour
    $taskLineIndex = -1
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"
    
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskLinePattern) {
            $taskLineIndex = $i
            break
        }
    }
    
    if ($taskLineIndex -eq -1) {
        throw "Tâche avec l'identifiant '$TaskIdentifier' non trouvée dans le fichier."
    }
    
    # Modifier la case à cocher selon le statut demandé
    $taskLine = $content[$taskLineIndex]
    $newTaskLine = $taskLine
    
    if ($Status -eq "Completed") {
        # Remplacer "[ ]" par "[x]"
        $newTaskLine = $taskLine -replace "\[\s*\]", "[x]"
    } else {
        # Remplacer "[x]" par "[ ]"
        $newTaskLine = $taskLine -replace "\[\s*x\s*\]", "[ ]"
    }
    
    # Si la ligne n'a pas changé, c'est que le statut est déjà correct
    if ($newTaskLine -eq $taskLine) {
        Write-Verbose "La tâche '$TaskIdentifier' a déjà le statut '$Status'."
        return
    }
    
    # Mettre à jour le contenu
    $content[$taskLineIndex] = $newTaskLine
    
    # Écrire le contenu modifié dans le fichier
    if ($PSCmdlet.ShouldProcess($FilePath, "Mettre à jour le statut de la tâche '$TaskIdentifier' à '$Status'")) {
        $content | Set-Content -Path $FilePath -Encoding UTF8
        Write-Output "Statut de la tâche '$TaskIdentifier' mis à jour à '$Status'."
    }
}
