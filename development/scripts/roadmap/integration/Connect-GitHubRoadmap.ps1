# Connect-GitHubRoadmap.ps1
# Module pour intégrer les fonctionnalités de roadmap avec GitHub
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Intègre les fonctionnalités de roadmap avec GitHub.

.DESCRIPTION
    Ce module fournit des fonctions pour intégrer les fonctionnalités de roadmap avec GitHub,
    permettant de synchroniser les roadmaps avec les issues et projets GitHub.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
} else {
    Write-Error "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath"
    exit
}

if (Test-Path $generateRoadmapPath) {
    . $generateRoadmapPath
} else {
    Write-Error "Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath"
    exit
}

# Fonction pour se connecter à l'API GitHub
function Connect-GitHubApi {
    <#
    .SYNOPSIS
        Se connecte à l'API GitHub.

    .DESCRIPTION
        Cette fonction se connecte à l'API GitHub en utilisant un token d'accès personnel.

    .PARAMETER Token
        Le token d'accès personnel GitHub.

    .EXAMPLE
        Connect-GitHubApi -Token "ghp_abcdef123456"
        Se connecte à l'API GitHub avec le token spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    # Créer l'objet de connexion
    $connection = [PSCustomObject]@{
        Token   = $Token
        BaseUrl = "https://api.github.com"
        Headers = @{
            "Authorization" = "token $Token"
            "Accept"        = "application/vnd.github.v3+json"
            "User-Agent"    = "PowerShell-GitHub-Roadmap"
        }
    }

    # Tester la connexion
    try {
        $response = Invoke-RestMethod -Uri "$($connection.BaseUrl)/user" -Headers $connection.Headers -Method Get

        if ($null -ne $response -and $null -ne $response.id) {
            Write-Host "Connexion à l'API GitHub réussie. Utilisateur: $($response.login)" -ForegroundColor Green

            # Ajouter les informations de l'utilisateur à l'objet de connexion
            $connection | Add-Member -MemberType NoteProperty -Name "User" -Value $response

            return $connection
        } else {
            Write-Error "Échec de la connexion à l'API GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la connexion à l'API GitHub: $_"
        return $null
    }
}

# Fonction pour obtenir un dépôt GitHub
function Get-GitHubRepository {
    <#
    .SYNOPSIS
        Obtient un dépôt GitHub.

    .DESCRIPTION
        Cette fonction obtient un dépôt GitHub en utilisant son propriétaire et son nom.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .EXAMPLE
        Get-GitHubRepository -Connection $connection -Owner "microsoft" -Repo "PowerShell"
        Obtient le dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo
    )

    try {
        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo" -Headers $Connection.Headers -Method Get

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de l'obtention du dépôt GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de l'obtention du dépôt GitHub: $_"
        return $null
    }
}

# Fonction pour obtenir les issues d'un dépôt GitHub
function Get-GitHubIssues {
    <#
    .SYNOPSIS
        Obtient les issues d'un dépôt GitHub.

    .DESCRIPTION
        Cette fonction obtient les issues d'un dépôt GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER State
        L'état des issues à obtenir (open, closed, all).

    .PARAMETER Labels
        Les labels des issues à obtenir.

    .PARAMETER PerPage
        Le nombre d'issues à retourner par page.

    .EXAMPLE
        Get-GitHubIssues -Connection $connection -Owner "microsoft" -Repo "PowerShell" -State "open"
        Obtient les issues ouvertes du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $false)]
        [ValidateSet("open", "closed", "all")]
        [string]$State = "open",

        [Parameter(Mandatory = $false)]
        [string[]]$Labels = @(),

        [Parameter(Mandatory = $false)]
        [int]$PerPage = 100
    )

    try {
        $issues = @()
        $page = 1
        $hasMore = $true

        while ($hasMore) {
            $url = "$($Connection.BaseUrl)/repos/$Owner/$Repo/issues?state=$State&per_page=$PerPage&page=$page"

            if ($Labels.Count -gt 0) {
                $url += "&labels=$($Labels -join ',')"
            }

            $response = Invoke-RestMethod -Uri $url -Headers $Connection.Headers -Method Get

            if ($null -ne $response -and $response.Count -gt 0) {
                $issues += $response

                if ($response.Count -lt $PerPage) {
                    $hasMore = $false
                } else {
                    $page++
                }
            } else {
                $hasMore = $false
            }
        }

        return $issues
    } catch {
        Write-Error "Échec de l'obtention des issues GitHub: $_"
        return $null
    }
}

# Fonction pour créer une issue GitHub
function New-GitHubIssue {
    <#
    .SYNOPSIS
        Crée une issue GitHub.

    .DESCRIPTION
        Cette fonction crée une issue GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER Title
        Le titre de l'issue.

    .PARAMETER Body
        Le corps de l'issue.

    .PARAMETER Labels
        Les labels de l'issue.

    .PARAMETER Assignees
        Les assignés de l'issue.

    .EXAMPLE
        New-GitHubIssue -Connection $connection -Owner "microsoft" -Repo "PowerShell" -Title "Nouvelle issue" -Body "Description de l'issue"
        Crée une issue dans le dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Body = "",

        [Parameter(Mandatory = $false)]
        [string[]]$Labels = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$Assignees = @()
    )

    try {
        $body = @{
            title = $Title
        }

        if (-not [string]::IsNullOrEmpty($Body)) {
            $body.body = $Body
        }

        if ($Labels.Count -gt 0) {
            $body.labels = $Labels
        }

        if ($Assignees.Count -gt 0) {
            $body.assignees = $Assignees
        }

        $bodyJson = $body | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo/issues" -Headers $Connection.Headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création de l'issue GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création de l'issue GitHub: $_"
        return $null
    }
}

# Fonction pour mettre à jour une issue GitHub
function Update-GitHubIssue {
    <#
    .SYNOPSIS
        Met à jour une issue GitHub.

    .DESCRIPTION
        Cette fonction met à jour une issue GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER IssueNumber
        Le numéro de l'issue.

    .PARAMETER Title
        Le nouveau titre de l'issue.

    .PARAMETER Body
        Le nouveau corps de l'issue.

    .PARAMETER State
        Le nouvel état de l'issue (open, closed).

    .PARAMETER Labels
        Les nouveaux labels de l'issue.

    .PARAMETER Assignees
        Les nouveaux assignés de l'issue.

    .EXAMPLE
        Update-GitHubIssue -Connection $connection -Owner "microsoft" -Repo "PowerShell" -IssueNumber 123 -Title "Issue mise à jour"
        Met à jour l'issue #123 dans le dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [int]$IssueNumber,

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$Body = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("open", "closed")]
        [string]$State = "",

        [Parameter(Mandatory = $false)]
        [string[]]$Labels = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$Assignees = @()
    )

    try {
        $updateBody = @{}

        if (-not [string]::IsNullOrEmpty($Title)) {
            $updateBody.title = $Title
        }

        if (-not [string]::IsNullOrEmpty($Body)) {
            $updateBody.body = $Body
        }

        if (-not [string]::IsNullOrEmpty($State)) {
            $updateBody.state = $State
        }

        if ($Labels.Count -gt 0) {
            $updateBody.labels = $Labels
        }

        if ($Assignees.Count -gt 0) {
            $updateBody.assignees = $Assignees
        }

        $bodyJson = $updateBody | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo/issues/$IssueNumber" -Headers $Connection.Headers -Method Patch -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la mise à jour de l'issue GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la mise à jour de l'issue GitHub: $_"
        return $null
    }
}

# Fonction pour convertir une roadmap en issues GitHub
function ConvertTo-GitHubIssues {
    <#
    .SYNOPSIS
        Convertit une roadmap en issues GitHub.

    .DESCRIPTION
        Cette fonction convertit une roadmap en issues GitHub,
        en créant une structure hiérarchique d'issues liées.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ParsedRoadmap
        Une roadmap déjà parsée par Parse-RoadmapFile.

    .EXAMPLE
        ConvertTo-GitHubIssues -RoadmapPath "C:\Roadmaps\plan-dev-v8.md"
        Convertit la roadmap spécifiée en issues GitHub.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromFile")]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true, ParameterSetName = "FromParsed")]
        [PSObject]$ParsedRoadmap
    )

    # Parser la roadmap si nécessaire
    if ($PSCmdlet.ParameterSetName -eq "FromFile") {
        $roadmap = Parse-RoadmapFile -FilePath $RoadmapPath

        if ($null -eq $roadmap) {
            return $null
        }
    } else {
        $roadmap = $ParsedRoadmap
    }

    # Créer la structure GitHub
    $githubRoadmap = [PSCustomObject]@{
        Title  = $roadmap.Title
        Issues = @()
    }

    # Convertir les tâches en issues GitHub
    foreach ($task in $roadmap.Tasks) {
        $issue = [PSCustomObject]@{
            Title    = "[$($task.Id)] $($task.Title)"
            Body     = ""
            Labels   = @("roadmap")
            State    = if ($task.Status -eq "Completed") { "closed" } else { "open" }
            ParentId = $task.ParentId
            TaskId   = $task.Id
        }

        # Construire le corps de l'issue
        $body = ""

        if ($task.Description) {
            $body += "$($task.Description)`n`n"
        }

        $body += "**ID:** $($task.Id)`n"
        $body += "**Status:** $($task.Status)`n"
        $body += "**Level:** $($task.Level)`n"

        if ($task.ParentId) {
            $body += "**Parent ID:** $($task.ParentId)`n"
        }

        $issue.Body = $body

        # Ajouter des labels en fonction du niveau
        $issue.Labels += "level-$($task.Level)"

        # Ajouter un label pour le statut
        $issue.Labels += $task.Status.ToLower()

        $githubRoadmap.Issues += $issue
    }

    return $githubRoadmap
}

# Fonction pour obtenir les projets GitHub
function Get-GitHubProjects {
    <#
    .SYNOPSIS
        Obtient les projets GitHub d'un dépôt.

    .DESCRIPTION
        Cette fonction obtient les projets GitHub d'un dépôt.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER State
        L'état des projets à obtenir (open, closed, all).

    .PARAMETER PerPage
        Le nombre de projets à retourner par page.

    .EXAMPLE
        Get-GitHubProjects -Connection $connection -Owner "microsoft" -Repo "PowerShell" -State "open"
        Obtient les projets ouverts du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $false)]
        [ValidateSet("open", "closed", "all")]
        [string]$State = "open",

        [Parameter(Mandatory = $false)]
        [int]$PerPage = 100
    )

    try {
        $projects = @()
        $page = 1
        $hasMore = $true

        # Mettre à jour les en-têtes pour inclure l'en-tête d'acceptation des projets
        $headers = $Connection.Headers.Clone()
        $headers["Accept"] = "application/vnd.github.inertia-preview+json"

        while ($hasMore) {
            $url = "$($Connection.BaseUrl)/repos/$Owner/$Repo/projects?state=$State&per_page=$PerPage&page=$page"

            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

            if ($null -ne $response -and $response.Count -gt 0) {
                $projects += $response

                if ($response.Count -lt $PerPage) {
                    $hasMore = $false
                } else {
                    $page++
                }
            } else {
                $hasMore = $false
            }
        }

        return $projects
    } catch {
        Write-Error "Échec de l'obtention des projets GitHub: $_"
        return $null
    }
}

# Fonction pour créer un projet GitHub
function New-GitHubProject {
    <#
    .SYNOPSIS
        Crée un projet GitHub.

    .DESCRIPTION
        Cette fonction crée un projet GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER Name
        Le nom du projet.

    .PARAMETER Body
        La description du projet.

    .EXAMPLE
        New-GitHubProject -Connection $connection -Owner "microsoft" -Repo "PowerShell" -Name "Nouveau projet" -Body "Description du projet"
        Crée un projet dans le dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Body = ""
    )

    try {
        # Mettre à jour les en-têtes pour inclure l'en-tête d'acceptation des projets
        $headers = $Connection.Headers.Clone()
        $headers["Accept"] = "application/vnd.github.inertia-preview+json"

        $projectBody = @{
            name = $Name
        }

        if (-not [string]::IsNullOrEmpty($Body)) {
            $projectBody.body = $Body
        }

        $bodyJson = $projectBody | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo/projects" -Headers $headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création du projet GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création du projet GitHub: $_"
        return $null
    }
}

# Fonction pour obtenir les colonnes d'un projet GitHub
function Get-GitHubProjectColumns {
    <#
    .SYNOPSIS
        Obtient les colonnes d'un projet GitHub.

    .DESCRIPTION
        Cette fonction obtient les colonnes d'un projet GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER ProjectId
        L'ID du projet GitHub.

    .PARAMETER PerPage
        Le nombre de colonnes à retourner par page.

    .EXAMPLE
        Get-GitHubProjectColumns -Connection $connection -ProjectId 1234567
        Obtient les colonnes du projet GitHub avec l'ID spécifié.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [int]$ProjectId,

        [Parameter(Mandatory = $false)]
        [int]$PerPage = 100
    )

    try {
        $columns = @()
        $page = 1
        $hasMore = $true

        # Mettre à jour les en-têtes pour inclure l'en-tête d'acceptation des projets
        $headers = $Connection.Headers.Clone()
        $headers["Accept"] = "application/vnd.github.inertia-preview+json"

        while ($hasMore) {
            $url = "$($Connection.BaseUrl)/projects/$ProjectId/columns?per_page=$PerPage&page=$page"

            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

            if ($null -ne $response -and $response.Count -gt 0) {
                $columns += $response

                if ($response.Count -lt $PerPage) {
                    $hasMore = $false
                } else {
                    $page++
                }
            } else {
                $hasMore = $false
            }
        }

        return $columns
    } catch {
        Write-Error "Échec de l'obtention des colonnes du projet GitHub: $_"
        return $null
    }
}

# Fonction pour créer une colonne dans un projet GitHub
function New-GitHubProjectColumn {
    <#
    .SYNOPSIS
        Crée une colonne dans un projet GitHub.

    .DESCRIPTION
        Cette fonction crée une colonne dans un projet GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER ProjectId
        L'ID du projet GitHub.

    .PARAMETER Name
        Le nom de la colonne.

    .EXAMPLE
        New-GitHubProjectColumn -Connection $connection -ProjectId 1234567 -Name "À faire"
        Crée une colonne dans le projet GitHub avec l'ID spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [int]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        # Mettre à jour les en-têtes pour inclure l'en-tête d'acceptation des projets
        $headers = $Connection.Headers.Clone()
        $headers["Accept"] = "application/vnd.github.inertia-preview+json"

        $body = @{
            name = $Name
        }

        $bodyJson = $body | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/projects/$ProjectId/columns" -Headers $headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création de la colonne du projet GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création de la colonne du projet GitHub: $_"
        return $null
    }
}

# Fonction pour obtenir les cartes d'une colonne de projet GitHub
function Get-GitHubProjectCards {
    <#
    .SYNOPSIS
        Obtient les cartes d'une colonne de projet GitHub.

    .DESCRIPTION
        Cette fonction obtient les cartes d'une colonne de projet GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER ColumnId
        L'ID de la colonne du projet GitHub.

    .PARAMETER PerPage
        Le nombre de cartes à retourner par page.

    .EXAMPLE
        Get-GitHubProjectCards -Connection $connection -ColumnId 1234567
        Obtient les cartes de la colonne du projet GitHub avec l'ID spécifié.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [int]$ColumnId,

        [Parameter(Mandatory = $false)]
        [int]$PerPage = 100
    )

    try {
        $cards = @()
        $page = 1
        $hasMore = $true

        # Mettre à jour les en-têtes pour inclure l'en-tête d'acceptation des projets
        $headers = $Connection.Headers.Clone()
        $headers["Accept"] = "application/vnd.github.inertia-preview+json"

        while ($hasMore) {
            $url = "$($Connection.BaseUrl)/projects/columns/$ColumnId/cards?per_page=$PerPage&page=$page"

            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

            if ($null -ne $response -and $response.Count -gt 0) {
                $cards += $response

                if ($response.Count -lt $PerPage) {
                    $hasMore = $false
                } else {
                    $page++
                }
            } else {
                $hasMore = $false
            }
        }

        return $cards
    } catch {
        Write-Error "Échec de l'obtention des cartes de la colonne du projet GitHub: $_"
        return $null
    }
}

# Fonction pour créer une carte dans une colonne de projet GitHub
function New-GitHubProjectCard {
    <#
    .SYNOPSIS
        Crée une carte dans une colonne de projet GitHub.

    .DESCRIPTION
        Cette fonction crée une carte dans une colonne de projet GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER ColumnId
        L'ID de la colonne du projet GitHub.

    .PARAMETER ContentId
        L'ID du contenu à associer à la carte (issue ou pull request).

    .PARAMETER ContentType
        Le type de contenu à associer à la carte (Issue ou PullRequest).

    .PARAMETER Note
        La note à ajouter à la carte (si aucun contenu n'est associé).

    .EXAMPLE
        New-GitHubProjectCard -Connection $connection -ColumnId 1234567 -ContentId 89012 -ContentType "Issue"
        Crée une carte associée à une issue dans la colonne du projet GitHub avec l'ID spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [int]$ColumnId,

        [Parameter(Mandatory = $false, ParameterSetName = "Content")]
        [int]$ContentId,

        [Parameter(Mandatory = $false, ParameterSetName = "Content")]
        [ValidateSet("Issue", "PullRequest")]
        [string]$ContentType = "Issue",

        [Parameter(Mandatory = $false, ParameterSetName = "Note")]
        [string]$Note = ""
    )

    try {
        # Mettre à jour les en-têtes pour inclure l'en-tête d'acceptation des projets
        $headers = $Connection.Headers.Clone()
        $headers["Accept"] = "application/vnd.github.inertia-preview+json"

        $body = @{}

        if ($PSCmdlet.ParameterSetName -eq "Content") {
            $body.content_id = $ContentId
            $body.content_type = $ContentType
        } else {
            $body.note = $Note
        }

        $bodyJson = $body | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/projects/columns/$ColumnId/cards" -Headers $headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création de la carte du projet GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création de la carte du projet GitHub: $_"
        return $null
    }
}

# Fonction pour synchroniser une roadmap avec un projet GitHub
function Sync-RoadmapToGitHubProject {
    <#
    .SYNOPSIS
        Synchronise une roadmap avec un projet GitHub.

    .DESCRIPTION
        Cette fonction synchronise une roadmap avec un projet GitHub,
        en créant ou mettant à jour un projet et ses colonnes.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER ProjectName
        Le nom du projet GitHub.
        Si non spécifié, le titre de la roadmap est utilisé.

    .PARAMETER ProjectId
        L'ID du projet GitHub existant.
        Si non spécifié, un nouveau projet est créé.

    .PARAMETER CreateIssues
        Indique si les issues doivent être créées pour les tâches de la roadmap.
        Par défaut, les issues sont créées.

    .EXAMPLE
        Sync-RoadmapToGitHubProject -Connection $connection -RoadmapPath "C:\Roadmaps\plan-dev-v8.md" -Owner "microsoft" -Repo "PowerShell"
        Synchronise la roadmap spécifiée avec un projet GitHub dans le dépôt microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = "",

        [Parameter(Mandatory = $false)]
        [int]$ProjectId = 0,

        [Parameter(Mandatory = $false)]
        [switch]$CreateIssues
    )

    try {
        # Vérifier que le dépôt existe
        $repository = Get-GitHubRepository -Connection $Connection -Owner $Owner -Repo $Repo

        if ($null -eq $repository) {
            Write-Error "Le dépôt GitHub $Owner/$Repo n'existe pas ou n'est pas accessible."
            return $null
        }

        # Parser la roadmap
        $roadmap = Parse-RoadmapFile -FilePath $RoadmapPath

        if ($null -eq $roadmap) {
            Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
            return $null
        }

        # Déterminer le nom du projet
        if ([string]::IsNullOrEmpty($ProjectName)) {
            $ProjectName = $roadmap.Title
        }

        # Créer ou obtenir le projet
        $project = $null

        if ($ProjectId -eq 0) {
            # Vérifier si un projet avec ce nom existe déjà
            $projects = Get-GitHubProjects -Connection $Connection -Owner $Owner -Repo $Repo

            if ($null -ne $projects) {
                $project = $projects | Where-Object { $_.name -eq $ProjectName } | Select-Object -First 1
            }

            if ($null -eq $project) {
                # Créer un nouveau projet
                $project = New-GitHubProject -Connection $Connection -Owner $Owner -Repo $Repo -Name $ProjectName -Body "Roadmap: $($roadmap.Title)"

                if ($null -eq $project) {
                    Write-Error "Échec de la création du projet GitHub."
                    return $null
                }

                Write-Host "Projet GitHub créé: $($project.name) (ID: $($project.id))" -ForegroundColor Green
            } else {
                Write-Host "Projet GitHub existant trouvé: $($project.name) (ID: $($project.id))" -ForegroundColor Green
            }
        } else {
            # Obtenir le projet existant
            $headers = $Connection.Headers.Clone()
            $headers["Accept"] = "application/vnd.github.inertia-preview+json"

            try {
                $project = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/projects/$ProjectId" -Headers $headers -Method Get

                if ($null -eq $project -or $null -eq $project.id) {
                    Write-Error "Le projet GitHub avec l'ID $ProjectId n'existe pas ou n'est pas accessible."
                    return $null
                }

                Write-Host "Projet GitHub existant trouvé: $($project.name) (ID: $($project.id))" -ForegroundColor Green
            } catch {
                Write-Error "Échec de l'obtention du projet GitHub avec l'ID $ProjectId : $($_.Exception.Message)"
                return $null
            }
        }

        # Créer les colonnes du projet
        $columns = Get-GitHubProjectColumns -Connection $Connection -ProjectId $project.id

        $todoColumn = $columns | Where-Object { $_.name -eq "À faire" -or $_.name -eq "To Do" } | Select-Object -First 1
        $inProgressColumn = $columns | Where-Object { $_.name -eq "En cours" -or $_.name -eq "In Progress" } | Select-Object -First 1
        $doneColumn = $columns | Where-Object { $_.name -eq "Terminé" -or $_.name -eq "Done" } | Select-Object -First 1

        if ($null -eq $todoColumn) {
            $todoColumn = New-GitHubProjectColumn -Connection $Connection -ProjectId $project.id -Name "À faire"

            if ($null -eq $todoColumn) {
                Write-Error "Échec de la création de la colonne 'À faire'."
                return $null
            }

            Write-Host "Colonne 'À faire' créée (ID: $($todoColumn.id))" -ForegroundColor Green
        }

        if ($null -eq $inProgressColumn) {
            $inProgressColumn = New-GitHubProjectColumn -Connection $Connection -ProjectId $project.id -Name "En cours"

            if ($null -eq $inProgressColumn) {
                Write-Error "Échec de la création de la colonne 'En cours'."
                return $null
            }

            Write-Host "Colonne 'En cours' créée (ID: $($inProgressColumn.id))" -ForegroundColor Green
        }

        if ($null -eq $doneColumn) {
            $doneColumn = New-GitHubProjectColumn -Connection $Connection -ProjectId $project.id -Name "Terminé"

            if ($null -eq $doneColumn) {
                Write-Error "Échec de la création de la colonne 'Terminé'."
                return $null
            }

            Write-Host "Colonne 'Terminé' créée (ID: $($doneColumn.id))" -ForegroundColor Green
        }

        # Créer les issues et les cartes
        $issuesCreated = 0
        $issuesUpdated = 0
        $cardsCreated = 0

        if ($CreateIssues) {
            # Convertir la roadmap en issues
            $githubRoadmap = ConvertTo-GitHubIssues -ParsedRoadmap $roadmap

            if ($null -eq $githubRoadmap) {
                Write-Error "Échec de la conversion de la roadmap en issues GitHub."
                return $null
            }

            # Obtenir les issues existantes avec le label "roadmap"
            $existingIssues = Get-GitHubIssues -Connection $Connection -Owner $Owner -Repo $Repo -State "all" -Labels @("roadmap")

            # Créer un dictionnaire pour stocker les correspondances entre les IDs de tâches et les numéros d'issues
            $taskToIssueMap = @{}

            # Parcourir les issues existantes pour trouver les correspondances
            foreach ($issue in $existingIssues) {
                # Extraire l'ID de tâche du titre de l'issue
                if ($issue.title -match "\[([\d\.]+)\]") {
                    $taskId = $matches[1]
                    $taskToIssueMap[$taskId] = $issue
                }
            }

            # Créer ou mettre à jour les issues
            foreach ($issue in $githubRoadmap.Issues) {
                $existingIssue = $null

                if ($taskToIssueMap.ContainsKey($issue.TaskId)) {
                    # Mettre à jour l'issue existante
                    $existingIssue = $taskToIssueMap[$issue.TaskId]

                    $response = Update-GitHubIssue -Connection $Connection -Owner $Owner -Repo $Repo -IssueNumber $existingIssue.number -Title $issue.Title -Body $issue.Body -State $issue.State -Labels $issue.Labels

                    if ($null -ne $response) {
                        $issuesUpdated++
                        $existingIssue = $response
                    }
                } else {
                    # Créer une nouvelle issue
                    $response = New-GitHubIssue -Connection $Connection -Owner $Owner -Repo $Repo -Title $issue.Title -Body $issue.Body -Labels $issue.Labels

                    if ($null -ne $response) {
                        $issuesCreated++
                        $existingIssue = $response
                        $taskToIssueMap[$issue.TaskId] = $existingIssue
                    }
                }

                # Ajouter l'issue au projet
                if ($null -ne $existingIssue) {
                    # Déterminer la colonne appropriée
                    $column = $null

                    if ($issue.State -eq "closed") {
                        $column = $doneColumn
                    } else {
                        # Vérifier si l'issue est déjà dans une colonne
                        $todoCards = Get-GitHubProjectCards -Connection $Connection -ColumnId $todoColumn.id
                        $inProgressCards = Get-GitHubProjectCards -Connection $Connection -ColumnId $inProgressColumn.id
                        $doneCards = Get-GitHubProjectCards -Connection $Connection -ColumnId $doneColumn.id

                        $allCards = @($todoCards) + @($inProgressCards) + @($doneCards)
                        $existingCard = $allCards | Where-Object { $_.content_url -eq $existingIssue.url } | Select-Object -First 1

                        if ($null -ne $existingCard) {
                            # La carte existe déjà, ne pas la recréer
                            continue
                        }

                        # Déterminer la colonne en fonction du statut de la tâche
                        if ($issue.State -eq "open") {
                            $column = $todoColumn
                        }
                    }

                    if ($null -ne $column) {
                        $card = New-GitHubProjectCard -Connection $Connection -ColumnId $column.id -ContentId $existingIssue.id -ContentType "Issue"

                        if ($null -ne $card) {
                            $cardsCreated++
                        }
                    }
                }
            }
        }

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Repository    = "$Owner/$Repo"
            Project       = $project
            IssuesCreated = $issuesCreated
            IssuesUpdated = $issuesUpdated
            CardsCreated  = $cardsCreated
        }

        return $result
    } catch {
        Write-Error "Échec de la synchronisation de la roadmap avec le projet GitHub: $_"
        return $null
    }
}

# Fonction pour obtenir les pull requests d'un dépôt GitHub
function Get-GitHubPullRequests {
    <#
    .SYNOPSIS
        Obtient les pull requests d'un dépôt GitHub.

    .DESCRIPTION
        Cette fonction obtient les pull requests d'un dépôt GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER State
        L'état des pull requests à obtenir (open, closed, all).

    .PARAMETER PerPage
        Le nombre de pull requests à retourner par page.

    .EXAMPLE
        Get-GitHubPullRequests -Connection $connection -Owner "microsoft" -Repo "PowerShell" -State "open"
        Obtient les pull requests ouvertes du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $false)]
        [ValidateSet("open", "closed", "all")]
        [string]$State = "open",

        [Parameter(Mandatory = $false)]
        [int]$PerPage = 100
    )

    try {
        $pullRequests = @()
        $page = 1
        $hasMore = $true

        while ($hasMore) {
            $url = "$($Connection.BaseUrl)/repos/$Owner/$Repo/pulls?state=$State&per_page=$PerPage&page=$page"

            $response = Invoke-RestMethod -Uri $url -Headers $Connection.Headers -Method Get

            if ($null -ne $response -and $response.Count -gt 0) {
                $pullRequests += $response

                if ($response.Count -lt $PerPage) {
                    $hasMore = $false
                } else {
                    $page++
                }
            } else {
                $hasMore = $false
            }
        }

        return $pullRequests
    } catch {
        Write-Error "Échec de l'obtention des pull requests GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour créer une pull request GitHub
function New-GitHubPullRequest {
    <#
    .SYNOPSIS
        Crée une pull request GitHub.

    .DESCRIPTION
        Cette fonction crée une pull request GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER Title
        Le titre de la pull request.

    .PARAMETER Body
        La description de la pull request.

    .PARAMETER Head
        La branche source de la pull request.

    .PARAMETER Base
        La branche cible de la pull request.

    .PARAMETER Draft
        Indique si la pull request est un brouillon.

    .EXAMPLE
        New-GitHubPullRequest -Connection $connection -Owner "microsoft" -Repo "PowerShell" -Title "Nouvelle fonctionnalité" -Body "Description de la fonctionnalité" -Head "feature-branch" -Base "main"
        Crée une pull request dans le dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Body = "",

        [Parameter(Mandatory = $true)]
        [string]$Head,

        [Parameter(Mandatory = $true)]
        [string]$Base,

        [Parameter(Mandatory = $false)]
        [switch]$Draft
    )

    try {
        $prBody = @{
            title = $Title
            head  = $Head
            base  = $Base
        }

        if (-not [string]::IsNullOrEmpty($Body)) {
            $prBody.body = $Body
        }

        if ($Draft) {
            $prBody.draft = $true
        }

        $bodyJson = $prBody | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo/pulls" -Headers $Connection.Headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création de la pull request GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création de la pull request GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour obtenir les reviews d'une pull request GitHub
function Get-GitHubPullRequestReviews {
    <#
    .SYNOPSIS
        Obtient les reviews d'une pull request GitHub.

    .DESCRIPTION
        Cette fonction obtient les reviews d'une pull request GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER PullRequestNumber
        Le numéro de la pull request.

    .PARAMETER PerPage
        Le nombre de reviews à retourner par page.

    .EXAMPLE
        Get-GitHubPullRequestReviews -Connection $connection -Owner "microsoft" -Repo "PowerShell" -PullRequestNumber 123
        Obtient les reviews de la pull request #123 du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,

        [Parameter(Mandatory = $false)]
        [int]$PerPage = 100
    )

    try {
        $reviews = @()
        $page = 1
        $hasMore = $true

        while ($hasMore) {
            $url = "$($Connection.BaseUrl)/repos/$Owner/$Repo/pulls/$PullRequestNumber/reviews?per_page=$PerPage&page=$page"

            $response = Invoke-RestMethod -Uri $url -Headers $Connection.Headers -Method Get

            if ($null -ne $response -and $response.Count -gt 0) {
                $reviews += $response

                if ($response.Count -lt $PerPage) {
                    $hasMore = $false
                } else {
                    $page++
                }
            } else {
                $hasMore = $false
            }
        }

        return $reviews
    } catch {
        Write-Error "Échec de l'obtention des reviews de la pull request GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour créer une review pour une pull request GitHub
function New-GitHubPullRequestReview {
    <#
    .SYNOPSIS
        Crée une review pour une pull request GitHub.

    .DESCRIPTION
        Cette fonction crée une review pour une pull request GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER PullRequestNumber
        Le numéro de la pull request.

    .PARAMETER Body
        Le commentaire de la review.

    .PARAMETER Event
        L'événement de la review (APPROVE, REQUEST_CHANGES, COMMENT).

    .PARAMETER Comments
        Les commentaires sur des lignes spécifiques.

    .EXAMPLE
        New-GitHubPullRequestReview -Connection $connection -Owner "microsoft" -Repo "PowerShell" -PullRequestNumber 123 -Body "Looks good!" -Event "APPROVE"
        Crée une review approuvant la pull request #123 du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,

        [Parameter(Mandatory = $false)]
        [string]$Body = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("APPROVE", "REQUEST_CHANGES", "COMMENT")]
        [string]$Event = "COMMENT",

        [Parameter(Mandatory = $false)]
        [PSObject[]]$Comments = @()
    )

    try {
        $reviewBody = @{}

        if (-not [string]::IsNullOrEmpty($Body)) {
            $reviewBody.body = $Body
        }

        if (-not [string]::IsNullOrEmpty($Event)) {
            $reviewBody.event = $Event
        }

        if ($Comments.Count -gt 0) {
            $reviewBody.comments = $Comments
        }

        $bodyJson = $reviewBody | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo/pulls/$PullRequestNumber/reviews" -Headers $Connection.Headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création de la review pour la pull request GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création de la review pour la pull request GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour obtenir les commentaires d'une pull request GitHub
function Get-GitHubPullRequestComments {
    <#
    .SYNOPSIS
        Obtient les commentaires d'une pull request GitHub.

    .DESCRIPTION
        Cette fonction obtient les commentaires d'une pull request GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER PullRequestNumber
        Le numéro de la pull request.

    .PARAMETER PerPage
        Le nombre de commentaires à retourner par page.

    .EXAMPLE
        Get-GitHubPullRequestComments -Connection $connection -Owner "microsoft" -Repo "PowerShell" -PullRequestNumber 123
        Obtient les commentaires de la pull request #123 du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,

        [Parameter(Mandatory = $false)]
        [int]$PerPage = 100
    )

    try {
        $comments = @()
        $page = 1
        $hasMore = $true

        while ($hasMore) {
            $url = "$($Connection.BaseUrl)/repos/$Owner/$Repo/pulls/$PullRequestNumber/comments?per_page=$PerPage&page=$page"

            $response = Invoke-RestMethod -Uri $url -Headers $Connection.Headers -Method Get

            if ($null -ne $response -and $response.Count -gt 0) {
                $comments += $response

                if ($response.Count -lt $PerPage) {
                    $hasMore = $false
                } else {
                    $page++
                }
            } else {
                $hasMore = $false
            }
        }

        return $comments
    } catch {
        Write-Error "Échec de l'obtention des commentaires de la pull request GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour créer un commentaire sur une pull request GitHub
function New-GitHubPullRequestComment {
    <#
    .SYNOPSIS
        Crée un commentaire sur une pull request GitHub.

    .DESCRIPTION
        Cette fonction crée un commentaire sur une pull request GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER PullRequestNumber
        Le numéro de la pull request.

    .PARAMETER Body
        Le contenu du commentaire.

    .PARAMETER CommitId
        L'ID du commit sur lequel commenter.

    .PARAMETER Path
        Le chemin du fichier sur lequel commenter.

    .PARAMETER Position
        La position dans le fichier sur laquelle commenter.

    .EXAMPLE
        New-GitHubPullRequestComment -Connection $connection -Owner "microsoft" -Repo "PowerShell" -PullRequestNumber 123 -Body "This looks good!" -CommitId "abc123" -Path "README.md" -Position 5
        Crée un commentaire sur la pull request #123 du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $true)]
        [string]$CommitId,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [int]$Position
    )

    try {
        $commentBody = @{
            body      = $Body
            commit_id = $CommitId
            path      = $Path
            position  = $Position
        }

        $bodyJson = $commentBody | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo/pulls/$PullRequestNumber/comments" -Headers $Connection.Headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création du commentaire sur la pull request GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création du commentaire sur la pull request GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour lier une issue à une pull request GitHub
function Add-GitHubPullRequestIssueLink {
    <#
    .SYNOPSIS
        Lie une issue à une pull request GitHub.

    .DESCRIPTION
        Cette fonction lie une issue à une pull request GitHub en ajoutant un commentaire avec une référence à l'issue.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER PullRequestNumber
        Le numéro de la pull request.

    .PARAMETER IssueNumber
        Le numéro de l'issue à lier.

    .EXAMPLE
        Add-GitHubPullRequestIssueLink -Connection $connection -Owner "microsoft" -Repo "PowerShell" -PullRequestNumber 123 -IssueNumber 456
        Lie l'issue #456 à la pull request #123 du dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,

        [Parameter(Mandatory = $true)]
        [int]$IssueNumber
    )

    try {
        # Ajouter un commentaire à la pull request pour lier l'issue
        $body = @{
            body = "Resolves #$IssueNumber"
        }

        $bodyJson = $body | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/repos/$Owner/$Repo/issues/$PullRequestNumber/comments" -Headers $Connection.Headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la liaison de l'issue à la pull request GitHub. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la liaison de l'issue à la pull request GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour synchroniser une roadmap avec les pull requests GitHub
function Sync-RoadmapToGitHubPullRequests {
    <#
    .SYNOPSIS
        Synchronise une roadmap avec les pull requests GitHub.

    .DESCRIPTION
        Cette fonction synchronise une roadmap avec les pull requests GitHub,
        en créant des pull requests pour les tâches de la roadmap et en les liant aux issues correspondantes.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER BaseBranch
        La branche cible des pull requests.

    .PARAMETER HeadBranchPrefix
        Le préfixe à utiliser pour les branches source des pull requests.

    .PARAMETER CreateIssues
        Indique si les issues doivent être créées pour les tâches de la roadmap.
        Par défaut, les issues sont créées.

    .EXAMPLE
        Sync-RoadmapToGitHubPullRequests -Connection $connection -RoadmapPath "C:\Roadmaps\plan-dev-v8.md" -Owner "microsoft" -Repo "PowerShell" -BaseBranch "main" -HeadBranchPrefix "feature/"
        Synchronise la roadmap spécifiée avec les pull requests GitHub dans le dépôt microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$BaseBranch,

        [Parameter(Mandatory = $false)]
        [string]$HeadBranchPrefix = "feature/",

        [Parameter(Mandatory = $false)]
        [switch]$CreateIssues
    )

    try {
        # Vérifier que le dépôt existe
        $repository = Get-GitHubRepository -Connection $Connection -Owner $Owner -Repo $Repo

        if ($null -eq $repository) {
            Write-Error "Le dépôt GitHub $Owner/$Repo n'existe pas ou n'est pas accessible."
            return $null
        }

        # Parser la roadmap
        $roadmap = Parse-RoadmapFile -FilePath $RoadmapPath

        if ($null -eq $roadmap) {
            Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
            return $null
        }

        # Créer les issues si nécessaire
        $issueMap = @{}

        if ($CreateIssues) {
            # Convertir la roadmap en issues
            $githubRoadmap = ConvertTo-GitHubIssues -ParsedRoadmap $roadmap

            if ($null -eq $githubRoadmap) {
                Write-Error "Échec de la conversion de la roadmap en issues GitHub."
                return $null
            }

            # Obtenir les issues existantes avec le label "roadmap"
            $existingIssues = Get-GitHubIssues -Connection $Connection -Owner $Owner -Repo $Repo -State "all" -Labels @("roadmap")

            # Créer un dictionnaire pour stocker les correspondances entre les IDs de tâches et les numéros d'issues
            foreach ($issue in $existingIssues) {
                # Extraire l'ID de tâche du titre de l'issue
                if ($issue.title -match "\[([\d\.]+)\]") {
                    $taskId = $matches[1]
                    $issueMap[$taskId] = $issue.number
                }
            }

            # Créer ou mettre à jour les issues
            foreach ($issue in $githubRoadmap.Issues) {
                if (-not $issueMap.ContainsKey($issue.TaskId)) {
                    # Créer une nouvelle issue
                    $response = New-GitHubIssue -Connection $Connection -Owner $Owner -Repo $Repo -Title $issue.Title -Body $issue.Body -Labels $issue.Labels

                    if ($null -ne $response) {
                        $issueMap[$issue.TaskId] = $response.number
                    }
                }
            }
        }

        # Obtenir les pull requests existantes
        $existingPullRequests = Get-GitHubPullRequests -Connection $Connection -Owner $Owner -Repo $Repo -State "all"

        # Créer un dictionnaire pour stocker les correspondances entre les IDs de tâches et les numéros de pull requests
        $prMap = @{}

        foreach ($pr in $existingPullRequests) {
            # Extraire l'ID de tâche du titre de la pull request
            if ($pr.title -match "\[([\d\.]+)\]") {
                $taskId = $matches[1]
                $prMap[$taskId] = $pr.number
            }
        }

        # Créer les pull requests pour les tâches en cours
        $pullRequestsCreated = 0
        $pullRequestsLinked = 0

        foreach ($task in $roadmap.Tasks) {
            # Ne créer des pull requests que pour les tâches en cours
            if ($task.Status -eq "Pending") {
                # Vérifier si une pull request existe déjà pour cette tâche
                if (-not $prMap.ContainsKey($task.Id)) {
                    # Créer une branche pour la tâche
                    $branchName = "$HeadBranchPrefix$($task.Id -replace '\.', '-')"

                    # Créer une pull request
                    $prTitle = "[$($task.Id)] $($task.Title)"
                    $prBody = "Implémentation de la tâche $($task.Id): $($task.Title)`n`n"

                    if ($task.Description) {
                        $prBody += "$($task.Description)`n`n"
                    }

                    # Ajouter une référence à l'issue si elle existe
                    if ($issueMap.ContainsKey($task.Id)) {
                        $prBody += "Resolves #$($issueMap[$task.Id])"
                    }

                    # Créer la pull request
                    $pr = New-GitHubPullRequest -Connection $Connection -Owner $Owner -Repo $Repo -Title $prTitle -Body $prBody -Head $branchName -Base $BaseBranch -Draft

                    if ($null -ne $pr) {
                        $pullRequestsCreated++
                        $prMap[$task.Id] = $pr.number

                        # Lier la pull request à l'issue si elle existe
                        if ($issueMap.ContainsKey($task.Id)) {
                            $link = Add-GitHubPullRequestIssueLink -Connection $Connection -Owner $Owner -Repo $Repo -PullRequestNumber $pr.number -IssueNumber $issueMap[$task.Id]

                            if ($null -ne $link) {
                                $pullRequestsLinked++
                            }
                        }
                    }
                }
            }
        }

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Repository          = "$Owner/$Repo"
            BaseBranch          = $BaseBranch
            HeadBranchPrefix    = $HeadBranchPrefix
            PullRequestsCreated = $pullRequestsCreated
            PullRequestsLinked  = $pullRequestsLinked
        }

        return $result
    } catch {
        Write-Error "Échec de la synchronisation de la roadmap avec les pull requests GitHub: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour synchroniser une roadmap avec GitHub
function Sync-RoadmapToGitHub {
    <#
    .SYNOPSIS
        Synchronise une roadmap avec GitHub.

    .DESCRIPTION
        Cette fonction synchronise une roadmap avec GitHub,
        en créant ou mettant à jour des issues GitHub.

    .PARAMETER Connection
        La connexion à l'API GitHub créée par Connect-GitHubApi.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER Owner
        Le propriétaire du dépôt GitHub.

    .PARAMETER Repo
        Le nom du dépôt GitHub.

    .PARAMETER LabelPrefix
        Le préfixe à utiliser pour les labels des issues.

    .EXAMPLE
        Sync-RoadmapToGitHub -Connection $connection -RoadmapPath "C:\Roadmaps\plan-dev-v8.md" -Owner "microsoft" -Repo "PowerShell"
        Synchronise la roadmap spécifiée avec le dépôt GitHub microsoft/PowerShell.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $false)]
        [string]$LabelPrefix = "roadmap"
    )

    # Convertir la roadmap en issues GitHub
    $githubRoadmap = ConvertTo-GitHubIssues -RoadmapPath $RoadmapPath

    if ($null -eq $githubRoadmap) {
        return $null
    }

    try {
        # Vérifier que le dépôt existe
        $repository = Get-GitHubRepository -Connection $Connection -Owner $Owner -Repo $Repo

        if ($null -eq $repository) {
            Write-Error "Le dépôt GitHub $Owner/$Repo n'existe pas ou n'est pas accessible."
            return $null
        }

        # Obtenir les issues existantes avec le label "roadmap"
        $existingIssues = Get-GitHubIssues -Connection $Connection -Owner $Owner -Repo $Repo -State "all" -Labels @($LabelPrefix)

        # Créer un dictionnaire pour stocker les correspondances entre les IDs de tâches et les numéros d'issues
        $taskToIssueMap = @{}

        # Parcourir les issues existantes pour trouver les correspondances
        foreach ($issue in $existingIssues) {
            # Extraire l'ID de tâche du titre de l'issue
            if ($issue.title -match "\[([\d\.]+)\]") {
                $taskId = $matches[1]
                $taskToIssueMap[$taskId] = $issue.number
            }
        }

        # Créer ou mettre à jour les issues
        $createdIssues = 0
        $updatedIssues = 0

        foreach ($issue in $githubRoadmap.Issues) {
            if ($taskToIssueMap.ContainsKey($issue.TaskId)) {
                # Mettre à jour l'issue existante
                $issueNumber = $taskToIssueMap[$issue.TaskId]

                $response = Update-GitHubIssue -Connection $Connection -Owner $Owner -Repo $Repo -IssueNumber $issueNumber -Title $issue.Title -Body $issue.Body -State $issue.State -Labels $issue.Labels

                if ($null -ne $response) {
                    $updatedIssues++
                }
            } else {
                # Créer une nouvelle issue
                $response = New-GitHubIssue -Connection $Connection -Owner $Owner -Repo $Repo -Title $issue.Title -Body $issue.Body -Labels $issue.Labels

                if ($null -ne $response) {
                    $createdIssues++
                    $taskToIssueMap[$issue.TaskId] = $response.number
                }
            }
        }

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Repository    = "$Owner/$Repo"
            Title         = $githubRoadmap.Title
            TotalIssues   = $githubRoadmap.Issues.Count
            CreatedIssues = $createdIssues
            UpdatedIssues = $updatedIssues
        }

        return $result
    } catch {
        Write-Error "Échec de la synchronisation de la roadmap avec GitHub: $_"
        return $null
    }
}
