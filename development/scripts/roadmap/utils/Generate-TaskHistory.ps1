# Generate-TaskHistory.ps1
# Script pour générer des historiques de modifications pour les tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des historiques de modifications pour les tâches.

.DESCRIPTION
    Ce script fournit des fonctions pour générer des historiques de modifications pour les tâches,
    en tenant compte des statuts, des pourcentages d'avancement et des dates.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour générer une entrée d'historique pour une tâche
function New-TaskHistoryEntry {
    <#
    .SYNOPSIS
        Génère une entrée d'historique pour une tâche.

    .DESCRIPTION
        Cette fonction génère une entrée d'historique pour une tâche, avec une date, un utilisateur,
        un statut avant et après, un pourcentage d'avancement avant et après, et un commentaire.

    .PARAMETER Date
        La date de la modification. Si non spécifiée, une date aléatoire sera générée.

    .PARAMETER User
        L'utilisateur qui a effectué la modification. Si non spécifié, un utilisateur aléatoire sera généré.

    .PARAMETER OldStatus
        Le statut de la tâche avant la modification. Si non spécifié, un statut aléatoire sera généré.

    .PARAMETER NewStatus
        Le statut de la tâche après la modification. Si non spécifié, un statut aléatoire sera généré.

    .PARAMETER OldProgress
        Le pourcentage d'avancement de la tâche avant la modification. Si non spécifié, un pourcentage aléatoire sera généré.

    .PARAMETER NewProgress
        Le pourcentage d'avancement de la tâche après la modification. Si non spécifié, un pourcentage aléatoire sera généré.

    .PARAMETER Comment
        Le commentaire associé à la modification. Si non spécifié, un commentaire aléatoire sera généré.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des entrées identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-TaskHistoryEntry
        Génère une entrée d'historique aléatoire.

    .EXAMPLE
        New-TaskHistoryEntry -OldStatus "NotStarted" -NewStatus "InProgress" -OldProgress 0 -NewProgress 25
        Génère une entrée d'historique pour une tâche qui passe de "NotStarted" à "InProgress".

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [DateTime]$Date = $null,

        [Parameter(Mandatory = $false)]
        [string]$User = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$OldStatus = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$NewStatus = $null,

        [Parameter(Mandatory = $false)]
        [int]$OldProgress = $null,

        [Parameter(Mandatory = $false)]
        [int]$NewProgress = $null,

        [Parameter(Mandatory = $false)]
        [string]$Comment = $null,

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Générer une date aléatoire si non spécifiée
    if (-not $PSBoundParameters.ContainsKey('Date')) {
        $startDate = (Get-Date).AddMonths(-3)
        $endDate = Get-Date
        $range = ($endDate - $startDate).TotalDays
        $randomDays = $random.Next(0, [int]$range)
        $Date = $startDate.AddDays($randomDays)
    }

    # Générer un utilisateur aléatoire si non spécifié
    if ($null -eq $User) {
        $users = @("admin", "developer", "manager", "tester", "designer", "product_owner", "scrum_master")
        $User = $users[$random.Next(0, $users.Count)]
    }

    # Générer un statut aléatoire si non spécifié
    if ($null -eq $OldStatus) {
        $statuses = @("NotStarted", "InProgress", "Blocked")
        $OldStatus = $statuses[$random.Next(0, $statuses.Count)]
    }

    # Générer un nouveau statut aléatoire si non spécifié
    if ($null -eq $NewStatus) {
        $validTransitions = @{
            "NotStarted" = @("InProgress", "Blocked")
            "InProgress" = @("Completed", "Blocked")
            "Completed"  = @("InProgress")
            "Blocked"    = @("InProgress", "NotStarted")
        }

        $possibleTransitions = $validTransitions[$OldStatus]
        $NewStatus = $possibleTransitions[$random.Next(0, $possibleTransitions.Count)]
    }

    # Générer un pourcentage d'avancement aléatoire si non spécifié
    if ($null -eq $OldProgress) {
        $OldProgress = switch ($OldStatus) {
            "NotStarted" { 0 }
            "InProgress" { $random.Next(1, 99) }
            "Completed" { 100 }
            "Blocked" { $random.Next(0, 90) }
        }
    }

    # Générer un nouveau pourcentage d'avancement aléatoire si non spécifié
    if ($null -eq $NewProgress) {
        $NewProgress = switch ($NewStatus) {
            "NotStarted" { 0 }
            "InProgress" {
                if ($OldProgress -lt 90) {
                    $random.Next($OldProgress + 1, [Math]::Min($OldProgress + 30, 99))
                } else {
                    $random.Next($OldProgress, 99)
                }
            }
            "Completed" { 100 }
            "Blocked" { $OldProgress }
        }
    }

    # Générer un commentaire aléatoire si non spécifié
    if ($null -eq $Comment) {
        $comments = @(
            "Mise à jour du statut",
            "Progression de la tâche",
            "Mise à jour de l'avancement",
            "Modification du statut suite à la réunion d'équipe",
            "Ajustement de l'avancement",
            "Mise à jour après revue",
            "Modification suite au feedback",
            "Ajustement après discussion",
            "Mise à jour hebdomadaire",
            "Modification suite à la planification"
        )

        $statusComments = @{
            "NotStarted" = @(
                "Tâche en attente",
                "Tâche pas encore démarrée",
                "En attente de ressources",
                "Planifiée pour plus tard"
            )
            "InProgress" = @(
                "Travail en cours",
                "Développement en cours",
                "Implémentation en cours",
                "Avancement régulier"
            )
            "Completed"  = @(
                "Tâche terminée",
                "Travail complété",
                "Objectif atteint",
                "Développement terminé"
            )
            "Blocked"    = @(
                "Tâche bloquée par un problème technique",
                "En attente de résolution d'un blocage",
                "Bloquée par une dépendance",
                "Problème identifié, travail suspendu"
            )
        }

        $transitionComments = @{
            "NotStarted_InProgress" = @(
                "Début du travail sur la tâche",
                "Démarrage de l'implémentation",
                "Commencement du développement",
                "Initiation du travail"
            )
            "InProgress_Completed"  = @(
                "Finalisation du développement",
                "Travail terminé avec succès",
                "Implémentation terminée",
                "Objectifs atteints"
            )
            "InProgress_Blocked"    = @(
                "Blocage rencontré pendant le développement",
                "Problème technique identifié",
                "Dépendance bloquante identifiée",
                "Suspension du travail due à un obstacle"
            )
            "Blocked_InProgress"    = @(
                "Résolution du blocage",
                "Contournement trouvé",
                "Reprise du travail après résolution",
                "Obstacle surmonté"
            )
            "Completed_InProgress"  = @(
                "Réouverture suite à feedback",
                "Corrections nécessaires identifiées",
                "Ajustements requis",
                "Modifications supplémentaires nécessaires"
            )
        }

        # Sélectionner un commentaire en fonction de la transition de statut
        $transitionKey = "${OldStatus}_${NewStatus}"
        if ($statusComments.ContainsKey($NewStatus)) {
            $statusSpecificComments = $statusComments[$NewStatus]
            $comments += $statusSpecificComments
        }
        if ($transitionComments.ContainsKey($transitionKey)) {
            $transitionSpecificComments = $transitionComments[$transitionKey]
            $comments += $transitionSpecificComments
        }

        $Comment = $comments[$random.Next(0, $comments.Count)]
    }

    # Créer et retourner l'entrée d'historique
    return [PSCustomObject]@{
        Date        = $Date
        User        = $User
        OldStatus   = $OldStatus
        NewStatus   = $NewStatus
        OldProgress = $OldProgress
        NewProgress = $NewProgress
        Comment     = $Comment
    }
}

# Fonction pour générer un historique complet pour une tâche
function New-TaskHistory {
    <#
    .SYNOPSIS
        Génère un historique complet pour une tâche.

    .DESCRIPTION
        Cette fonction génère un historique complet pour une tâche, avec plusieurs entrées
        représentant l'évolution de la tâche dans le temps.

    .PARAMETER TaskId
        L'identifiant de la tâche.

    .PARAMETER TaskTitle
        Le titre de la tâche.

    .PARAMETER StartDate
        La date de début de l'historique. Si non spécifiée, une date aléatoire sera générée.

    .PARAMETER EndDate
        La date de fin de l'historique. Si non spécifiée, la date actuelle sera utilisée.

    .PARAMETER EntryCount
        Le nombre d'entrées à générer. Si non spécifié, un nombre aléatoire sera généré.

    .PARAMETER FinalStatus
        Le statut final de la tâche. Si non spécifié, un statut aléatoire sera généré.

    .PARAMETER FinalProgress
        Le pourcentage d'avancement final de la tâche. Si non spécifié, un pourcentage cohérent avec le statut final sera généré.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des historiques identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X"
        Génère un historique aléatoire pour la tâche spécifiée.

    .EXAMPLE
        New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X" -FinalStatus "Completed" -FinalProgress 100
        Génère un historique pour une tâche complétée.

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskId,

        [Parameter(Mandatory = $true)]
        [string]$TaskTitle,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = $null,

        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date),

        [Parameter(Mandatory = $false)]
        [int]$EntryCount = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$FinalStatus = $null,

        [Parameter(Mandatory = $false)]
        [int]$FinalProgress = $null,

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Générer une date de début aléatoire si non spécifiée
    if (-not $PSBoundParameters.ContainsKey('StartDate')) {
        $StartDate = (Get-Date).AddMonths(-6)
    }

    # Générer un nombre d'entrées aléatoire si non spécifié
    if ($null -eq $EntryCount) {
        $EntryCount = $random.Next(3, 10)
    }

    # Générer un statut final aléatoire si non spécifié
    if ($null -eq $FinalStatus) {
        $statuses = @("NotStarted", "InProgress", "Completed", "Blocked")
        $FinalStatus = $statuses[$random.Next(0, $statuses.Count)]
    }

    # Générer un pourcentage d'avancement final aléatoire si non spécifié
    if ($null -eq $FinalProgress) {
        $FinalProgress = switch ($FinalStatus) {
            "NotStarted" { 0 }
            "InProgress" { $random.Next(1, 99) }
            "Completed" { 100 }
            "Blocked" { $random.Next(0, 90) }
        }
    }

    # Créer l'historique
    $history = [PSCustomObject]@{
        TaskId    = $TaskId
        TaskTitle = $TaskTitle
        Entries   = @()
    }

    # Générer les entrées d'historique
    $currentStatus = "NotStarted"
    $currentProgress = 0

    # Calculer l'intervalle de temps entre les entrées
    $timeRange = ($EndDate - $StartDate).TotalDays
    $timeInterval = $timeRange / $EntryCount

    for ($i = 0; $i -lt $EntryCount; $i++) {
        # Déterminer le statut et le pourcentage d'avancement pour cette entrée
        $newStatus = $currentStatus
        $newProgress = $currentProgress

        # Pour la dernière entrée, utiliser le statut et le pourcentage d'avancement finaux
        if ($i -eq $EntryCount - 1) {
            $newStatus = $FinalStatus
            $newProgress = $FinalProgress
        } else {
            # Déterminer le nouveau statut en fonction de la progression
            if ($i -eq 0) {
                # Première entrée : passer de NotStarted à InProgress
                $newStatus = "InProgress"
                $newProgress = $random.Next(1, 30)
            } elseif ($i -lt $EntryCount - 2) {
                # Entrées intermédiaires : progression régulière
                $progressIncrement = $random.Next(5, 20)
                $newProgress = [Math]::Min($currentProgress + $progressIncrement, 99)

                # Possibilité de blocage temporaire
                if ($random.Next(0, 10) -eq 0) {
                    $newStatus = "Blocked"
                } elseif ($currentStatus -eq "Blocked") {
                    $newStatus = "InProgress"
                } else {
                    $newStatus = "InProgress"
                }
            } else {
                # Avant-dernière entrée : préparer pour le statut final
                if ($FinalStatus -eq "Completed") {
                    $newProgress = $random.Next(80, 99)
                    $newStatus = "InProgress"
                } elseif ($FinalStatus -eq "Blocked") {
                    $newStatus = "Blocked"
                    $newProgress = $FinalProgress
                } else {
                    $newProgress = [Math]::Min($currentProgress + $random.Next(5, 15), $FinalProgress)
                    $newStatus = $FinalStatus
                }
            }
        }

        # Calculer la date pour cette entrée
        $entryDate = $StartDate.AddDays($timeInterval * $i)

        # Générer l'entrée d'historique
        $entryParams = @{
            Date        = $entryDate
            OldStatus   = $currentStatus
            NewStatus   = $newStatus
            OldProgress = $currentProgress
            NewProgress = $newProgress
        }

        if ($null -ne $RandomSeed) {
            $entryParams.RandomSeed = $RandomSeed + $i
        }

        $entry = New-TaskHistoryEntry @entryParams

        # Ajouter l'entrée à l'historique
        $history.Entries += $entry

        # Mettre à jour le statut et le pourcentage d'avancement courants
        $currentStatus = $newStatus
        $currentProgress = $newProgress
    }

    return $history
}

# Fonction pour mettre à jour l'historique d'une tâche en fonction des changements de statut
function Update-TaskHistoryFromStatus {
    <#
    .SYNOPSIS
        Met à jour l'historique d'une tâche en fonction des changements de statut.

    .DESCRIPTION
        Cette fonction met à jour l'historique d'une tâche en fonction des changements de statut,
        en ajoutant une nouvelle entrée d'historique pour chaque changement.

    .PARAMETER TaskHistory
        L'historique de la tâche à mettre à jour.

    .PARAMETER NewStatus
        Le nouveau statut de la tâche.

    .PARAMETER NewProgress
        Le nouveau pourcentage d'avancement de la tâche. Si non spécifié, un pourcentage cohérent avec le nouveau statut sera généré.

    .PARAMETER Comment
        Le commentaire associé à la modification. Si non spécifié, un commentaire aléatoire sera généré.

    .PARAMETER User
        L'utilisateur qui a effectué la modification. Si non spécifié, un utilisateur aléatoire sera généré.

    .PARAMETER Date
        La date de la modification. Si non spécifiée, la date actuelle sera utilisée.

    .EXAMPLE
        $history = New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X"
        Update-TaskHistoryFromStatus -TaskHistory $history -NewStatus "Completed" -NewProgress 100 -Comment "Travail terminé"
        Met à jour l'historique d'une tâche en ajoutant une entrée pour un changement de statut à "Completed".

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$TaskHistory,

        [Parameter(Mandatory = $true)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$NewStatus,

        [Parameter(Mandatory = $false)]
        [int]$NewProgress = $null,

        [Parameter(Mandatory = $false)]
        [string]$Comment = $null,

        [Parameter(Mandatory = $false)]
        [string]$User = $null,

        [Parameter(Mandatory = $false)]
        [DateTime]$Date = (Get-Date)
    )

    # Déterminer le statut et le pourcentage d'avancement actuels
    $currentStatus = "NotStarted"
    $currentProgress = 0

    if ($TaskHistory.Entries.Count -gt 0) {
        $lastEntry = $TaskHistory.Entries[$TaskHistory.Entries.Count - 1]
        $currentStatus = $lastEntry.NewStatus
        $currentProgress = $lastEntry.NewProgress
    }

    # Générer un pourcentage d'avancement cohérent avec le nouveau statut si non spécifié
    if ($null -eq $NewProgress) {
        $NewProgress = switch ($NewStatus) {
            "NotStarted" { 0 }
            "InProgress" {
                if ($currentProgress -lt 90) {
                    $currentProgress + (Get-Random -Minimum 5 -Maximum 20)
                } else {
                    $currentProgress
                }
            }
            "Completed" { 100 }
            "Blocked" { $currentProgress }
        }
    }

    # Créer une nouvelle entrée d'historique
    $entry = New-TaskHistoryEntry -Date $Date -User $User -OldStatus $currentStatus -NewStatus $NewStatus -OldProgress $currentProgress -NewProgress $NewProgress -Comment $Comment

    # Ajouter l'entrée à l'historique
    $TaskHistory.Entries += $entry

    return $TaskHistory
}
