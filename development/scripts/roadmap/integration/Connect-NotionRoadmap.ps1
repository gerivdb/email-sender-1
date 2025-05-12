# Connect-NotionRoadmap.ps1
# Module pour intégrer les fonctionnalités de roadmap avec Notion
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Intègre les fonctionnalités de roadmap avec Notion.

.DESCRIPTION
    Ce module fournit des fonctions pour intégrer les fonctionnalités de roadmap avec Notion,
    permettant de synchroniser les roadmaps avec les bases de données Notion.

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

# Fonction pour se connecter à l'API Notion
function Connect-NotionApi {
    <#
    .SYNOPSIS
        Se connecte à l'API Notion.

    .DESCRIPTION
        Cette fonction se connecte à l'API Notion en utilisant un token d'intégration.

    .PARAMETER Token
        Le token d'intégration Notion.

    .EXAMPLE
        Connect-NotionApi -Token "secret_abcdef123456"
        Se connecte à l'API Notion avec le token spécifié.

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
        BaseUrl = "https://api.notion.com/v1"
        Headers = @{
            "Authorization"  = "Bearer $Token"
            "Notion-Version" = "2022-06-28"
            "Content-Type"   = "application/json"
        }
    }

    # Tester la connexion
    try {
        $response = Invoke-RestMethod -Uri "$($connection.BaseUrl)/users/me" -Headers $connection.Headers -Method Get

        if ($null -ne $response -and $null -ne $response.id) {
            Write-Host "Connexion à l'API Notion réussie. Utilisateur: $($response.name)" -ForegroundColor Green

            # Ajouter les informations de l'utilisateur à l'objet de connexion
            $connection | Add-Member -MemberType NoteProperty -Name "User" -Value $response

            return $connection
        } else {
            Write-Error "Échec de la connexion à l'API Notion. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la connexion à l'API Notion: $_"
        return $null
    }
}

# Fonction pour obtenir une base de données Notion
function Get-NotionDatabase {
    <#
    .SYNOPSIS
        Obtient une base de données Notion.

    .DESCRIPTION
        Cette fonction obtient une base de données Notion en utilisant son ID.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion.

    .EXAMPLE
        Get-NotionDatabase -Connection $connection -DatabaseId "abcdef123456"
        Obtient la base de données Notion avec l'ID spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseId
    )

    try {
        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/databases/$DatabaseId" -Headers $Connection.Headers -Method Get

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de l'obtention de la base de données Notion. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de l'obtention de la base de données Notion: $_"
        return $null
    }
}

# Fonction pour obtenir les pages d'une base de données Notion
function Get-NotionDatabasePages {
    <#
    .SYNOPSIS
        Obtient les pages d'une base de données Notion.

    .DESCRIPTION
        Cette fonction obtient les pages d'une base de données Notion.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion.

    .PARAMETER Filter
        Le filtre à appliquer aux pages.

    .PARAMETER Sort
        Le tri à appliquer aux pages.

    .PARAMETER PageSize
        Le nombre de pages à retourner par requête.

    .EXAMPLE
        Get-NotionDatabasePages -Connection $connection -DatabaseId "abcdef123456"
        Obtient toutes les pages de la base de données Notion avec l'ID spécifié.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseId,

        [Parameter(Mandatory = $false)]
        [hashtable]$Filter = $null,

        [Parameter(Mandatory = $false)]
        [hashtable]$Sort = $null,

        [Parameter(Mandatory = $false)]
        [int]$PageSize = 100
    )

    try {
        $pages = @()
        $hasMore = $true
        $startCursor = $null

        while ($hasMore) {
            $body = @{
                page_size = $PageSize
            }

            if ($null -ne $Filter) {
                $body.filter = $Filter
            }

            if ($null -ne $Sort) {
                $body.sorts = $Sort
            }

            if ($null -ne $startCursor) {
                $body.start_cursor = $startCursor
            }

            $bodyJson = $body | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/databases/$DatabaseId/query" -Headers $Connection.Headers -Method Post -Body $bodyJson

            if ($null -ne $response -and $null -ne $response.results) {
                $pages += $response.results

                $hasMore = $response.has_more
                $startCursor = $response.next_cursor
            } else {
                $hasMore = $false
            }
        }

        return $pages
    } catch {
        Write-Error "Échec de l'obtention des pages de la base de données Notion: $_"
        return $null
    }
}

# Fonction pour créer une page dans une base de données Notion
function New-NotionDatabasePage {
    <#
    .SYNOPSIS
        Crée une page dans une base de données Notion.

    .DESCRIPTION
        Cette fonction crée une page dans une base de données Notion.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion.

    .PARAMETER Properties
        Les propriétés de la page à créer.

    .PARAMETER Content
        Le contenu de la page à créer.

    .EXAMPLE
        New-NotionDatabasePage -Connection $connection -DatabaseId "abcdef123456" -Properties @{Name = @{title = @(@{text = @{content = "Nouvelle page"}})}}
        Crée une page dans la base de données Notion avec l'ID spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseId,

        [Parameter(Mandatory = $true)]
        [hashtable]$Properties,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$Content = $null
    )

    try {
        $body = @{
            parent     = @{
                database_id = $DatabaseId
            }
            properties = $Properties
        }

        if ($null -ne $Content) {
            $body.children = $Content
        }

        $bodyJson = $body | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/pages" -Headers $Connection.Headers -Method Post -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la création de la page Notion. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la création de la page Notion: $_"
        return $null
    }
}

# Fonction pour mettre à jour une page Notion
function Update-NotionPage {
    <#
    .SYNOPSIS
        Met à jour une page Notion.

    .DESCRIPTION
        Cette fonction met à jour une page Notion.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER PageId
        L'ID de la page Notion.

    .PARAMETER Properties
        Les propriétés de la page à mettre à jour.

    .EXAMPLE
        Update-NotionPage -Connection $connection -PageId "abcdef123456" -Properties @{Name = @{title = @(@{text = @{content = "Page mise à jour"}})}}
        Met à jour la page Notion avec l'ID spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$PageId,

        [Parameter(Mandatory = $true)]
        [hashtable]$Properties
    )

    try {
        $body = @{
            properties = $Properties
        }

        $bodyJson = $body | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/pages/$PageId" -Headers $Connection.Headers -Method Patch -Body $bodyJson

        if ($null -ne $response -and $null -ne $response.id) {
            return $response
        } else {
            Write-Error "Échec de la mise à jour de la page Notion. Réponse invalide."
            return $null
        }
    } catch {
        Write-Error "Échec de la mise à jour de la page Notion: $_"
        return $null
    }
}

# Fonction pour convertir une roadmap en structure Notion
function ConvertTo-NotionRoadmap {
    <#
    .SYNOPSIS
        Convertit une roadmap en structure Notion.

    .DESCRIPTION
        Cette fonction convertit une roadmap en structure Notion,
        en créant les propriétés et le contenu nécessaires pour
        créer une base de données Notion.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ParsedRoadmap
        Une roadmap déjà parsée par Parse-RoadmapFile.

    .EXAMPLE
        ConvertTo-NotionRoadmap -RoadmapPath "C:\Roadmaps\plan-dev-v8.md"
        Convertit la roadmap spécifiée en structure Notion.

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

    # Créer la structure Notion
    $notionRoadmap = [PSCustomObject]@{
        Title    = $roadmap.Title
        Database = @{
            title      = @(
                @{
                    text = @{
                        content = $roadmap.Title
                    }
                }
            )
            properties = @{
                "ID"        = @{
                    rich_text = @{}
                }
                "Title"     = @{
                    title = @{}
                }
                "Status"    = @{
                    select = @{
                        options = @(
                            @{
                                name  = "Completed"
                                color = "green"
                            },
                            @{
                                name  = "Pending"
                                color = "yellow"
                            }
                        )
                    }
                }
                "Level"     = @{
                    number = @{}
                }
                "Parent ID" = @{
                    rich_text = @{}
                }
            }
        }
        Pages    = @()
    }

    # Convertir les tâches en pages Notion
    foreach ($task in $roadmap.Tasks) {
        $page = @{
            properties = @{
                "ID"     = @{
                    rich_text = @(
                        @{
                            text = @{
                                content = $task.Id
                            }
                        }
                    )
                }
                "Title"  = @{
                    title = @(
                        @{
                            text = @{
                                content = $task.Title
                            }
                        }
                    )
                }
                "Status" = @{
                    select = @{
                        name = $task.Status
                    }
                }
                "Level"  = @{
                    number = $task.Level
                }
            }
            children   = @()
        }

        # Ajouter le parent ID si présent
        if ($task.ParentId) {
            $page.properties["Parent ID"] = @{
                rich_text = @(
                    @{
                        text = @{
                            content = $task.ParentId
                        }
                    }
                )
            }
        }

        # Ajouter la description si présente
        if ($task.Description) {
            $page.children += @{
                object    = "block"
                type      = "paragraph"
                paragraph = @{
                    rich_text = @(
                        @{
                            type = "text"
                            text = @{
                                content = $task.Description
                            }
                        }
                    )
                }
            }
        }

        $notionRoadmap.Pages += $page
    }

    return $notionRoadmap
}

# Fonction pour convertir une page Notion en tâche de roadmap
function ConvertFrom-NotionPage {
    <#
    .SYNOPSIS
        Convertit une page Notion en tâche de roadmap.

    .DESCRIPTION
        Cette fonction convertit une page Notion en tâche de roadmap,
        en extrayant les propriétés et le contenu de la page.

    .PARAMETER Page
        La page Notion à convertir.

    .EXAMPLE
        ConvertFrom-NotionPage -Page $page
        Convertit la page Notion spécifiée en tâche de roadmap.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Page
    )

    try {
        # Extraire les propriétés de la page
        $id = ""
        $title = ""
        $status = "Pending"
        $level = 1
        $parentId = ""
        $description = ""

        # Extraire l'ID
        if ($Page.properties.ID -and $Page.properties.ID.rich_text -and $Page.properties.ID.rich_text.Count -gt 0) {
            $id = $Page.properties.ID.rich_text.plain_text -join ""
        }

        # Extraire le titre
        if ($Page.properties.Title -and $Page.properties.Title.title -and $Page.properties.Title.title.Count -gt 0) {
            $title = $Page.properties.Title.title.plain_text -join ""
        }

        # Extraire le statut
        if ($Page.properties.Status -and $Page.properties.Status.select -and $Page.properties.Status.select.name) {
            $status = $Page.properties.Status.select.name
        }

        # Extraire le niveau
        if ($Page.properties.Level -and $Page.properties.Level.number) {
            $level = $Page.properties.Level.number
        }

        # Extraire le parent ID
        if ($Page.properties."Parent ID" -and $Page.properties."Parent ID".rich_text -and $Page.properties."Parent ID".rich_text.Count -gt 0) {
            $parentId = $Page.properties."Parent ID".rich_text.plain_text -join ""
        }

        # Créer l'objet tâche
        $task = [PSCustomObject]@{
            Id          = $id
            Title       = $title
            Status      = $status
            Level       = $level
            ParentId    = $parentId
            Description = $description
            Children    = @()
        }

        return $task
    } catch {
        Write-Error "Échec de la conversion de la page Notion en tâche de roadmap: $_"
        return $null
    }
}

# Fonction pour convertir une base de données Notion en roadmap
function ConvertFrom-NotionDatabase {
    <#
    .SYNOPSIS
        Convertit une base de données Notion en roadmap.

    .DESCRIPTION
        Cette fonction convertit une base de données Notion en roadmap,
        en extrayant les pages et en les convertissant en tâches.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.
        Si non spécifié, la roadmap n'est pas sauvegardée.

    .EXAMPLE
        ConvertFrom-NotionDatabase -Connection $connection -DatabaseId "abcdef123456" -OutputPath "C:\Roadmaps\notion-roadmap.md"
        Convertit la base de données Notion spécifiée en roadmap et la sauvegarde.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseId,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Obtenir la base de données
        $database = Get-NotionDatabase -Connection $Connection -DatabaseId $DatabaseId

        if ($null -eq $database) {
            Write-Error "Base de données Notion introuvable: $DatabaseId"
            return $null
        }

        # Obtenir les pages de la base de données
        $pages = Get-NotionDatabasePages -Connection $Connection -DatabaseId $DatabaseId

        if ($null -eq $pages -or $pages.Count -eq 0) {
            Write-Warning "Aucune page trouvée dans la base de données Notion: $DatabaseId"
            return $null
        }

        # Convertir les pages en tâches
        $tasks = @()
        foreach ($page in $pages) {
            $task = ConvertFrom-NotionPage -Page $page

            if ($null -ne $task) {
                $tasks += $task
            }
        }

        # Établir les relations parent-enfant
        foreach ($task in $tasks) {
            if ($task.ParentId) {
                $parent = $tasks | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1

                if ($parent) {
                    $parent.Children += $task.Id
                }
            }
        }

        # Créer l'objet roadmap
        $roadmap = [PSCustomObject]@{
            Title = $database.title.plain_text -join ""
            Tasks = $tasks
        }

        # Sauvegarder la roadmap si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            New-RoadmapFromTasks -Title $roadmap.Title -Tasks $roadmap.Tasks -OutputPath $OutputPath

            Write-Host "Roadmap sauvegardée dans: $OutputPath" -ForegroundColor Green
        }

        return $roadmap
    } catch {
        Write-Error "Échec de la conversion de la base de données Notion en roadmap: $_"
        return $null
    }
}

# Fonction pour convertir une base de données Notion en roadmap
function ConvertFrom-NotionRoadmap {
    <#
    .SYNOPSIS
        Convertit une base de données Notion en roadmap.

    .DESCRIPTION
        Cette fonction convertit une base de données Notion en roadmap,
        en extrayant les tâches et leur hiérarchie.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.
        Si non spécifié, la roadmap n'est pas sauvegardée.

    .EXAMPLE
        ConvertFrom-NotionRoadmap -Connection $connection -DatabaseId "abcdef123456" -OutputPath "C:\Roadmaps\notion-roadmap.md"
        Convertit la base de données Notion spécifiée en roadmap et la sauvegarde.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseId,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Obtenir la base de données
        $database = Get-NotionDatabase -Connection $Connection -DatabaseId $DatabaseId

        if ($null -eq $database) {
            Write-Error "Base de données Notion introuvable: $DatabaseId"
            return $null
        }

        # Obtenir les pages de la base de données
        $pages = Get-NotionDatabasePages -Connection $Connection -DatabaseId $DatabaseId

        if ($null -eq $pages -or $pages.Count -eq 0) {
            Write-Error "Aucune page trouvée dans la base de données Notion: $DatabaseId"
            return $null
        }

        # Créer la structure de la roadmap
        $roadmap = [PSCustomObject]@{
            Title    = $database.title.plain_text -join " "
            FilePath = $OutputPath
            Tasks    = @()
        }

        # Convertir les pages en tâches
        foreach ($page in $pages) {
            # Extraire les propriétés de la page
            $taskId = ""
            $title = ""
            $status = "Pending"
            $level = 1
            $parentId = $null
            $description = ""

            # Extraire l'ID de la tâche
            if ($page.properties.ID -and $page.properties.ID.rich_text -and $page.properties.ID.rich_text.Count -gt 0) {
                $taskId = $page.properties.ID.rich_text.plain_text -join ""
            }

            # Extraire le titre
            if ($page.properties.Title -and $page.properties.Title.title -and $page.properties.Title.title.Count -gt 0) {
                $title = $page.properties.Title.title.plain_text -join ""
            }

            # Extraire le statut
            if ($page.properties.Status -and $page.properties.Status.select -and $page.properties.Status.select.name) {
                $status = $page.properties.Status.select.name
            }

            # Extraire le niveau
            if ($page.properties.Level -and $page.properties.Level.number) {
                $level = $page.properties.Level.number
            }

            # Extraire le parent ID
            if ($page.properties."Parent ID" -and $page.properties."Parent ID".rich_text -and $page.properties."Parent ID".rich_text.Count -gt 0) {
                $parentId = $page.properties."Parent ID".rich_text.plain_text -join ""
            }

            # Créer la tâche
            $task = [PSCustomObject]@{
                Id          = $taskId
                Title       = $title
                Status      = $status
                Level       = $level
                ParentId    = $parentId
                Description = $description
                Children    = @()
            }

            $roadmap.Tasks += $task
        }

        # Établir les relations parent-enfant
        foreach ($task in $roadmap.Tasks) {
            if ($task.ParentId) {
                $parent = $roadmap.Tasks | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1
                if ($parent) {
                    $parent.Children += $task.Id
                }
            }
        }

        # Sauvegarder la roadmap si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }

            # Générer le contenu markdown
            $markdown = "# $($roadmap.Title)`n`n"

            # Fonction récursive pour ajouter les tâches
            function Add-TasksToMarkdown {
                param (
                    [string]$SectionId,
                    [PSObject[]]$Tasks,
                    [int]$Indent = 0
                )

                $sectionTasks = $Tasks | Where-Object { $_.Id -like "$SectionId.*" -and $_.Id.Split('.').Count -eq $SectionId.Split('.').Count + 1 } | Sort-Object -Property Id

                $result = ""
                foreach ($task in $sectionTasks) {
                    $indentation = "  " * $Indent
                    $checkbox = if ($task.Status -eq "Completed") { "[x]" } else { "[ ]" }

                    $result += "$indentation- $checkbox **$($task.Id)** $($task.Title)`n"

                    if ($task.Description) {
                        $result += "$indentation  $($task.Description)`n"
                    }

                    # Ajouter récursivement les sous-tâches
                    $result += Add-TasksToMarkdown -SectionId $task.Id -Tasks $Tasks -Indent ($Indent + 1)
                }

                return $result
            }

            # Ajouter les sections principales
            $sections = $roadmap.Tasks | Where-Object { $_.Id -match "^\d+$" } | Sort-Object -Property Id

            foreach ($section in $sections) {
                $markdown += "## $($section.Id) $($section.Title)`n"

                if ($section.Description) {
                    $markdown += "$($section.Description)`n`n"
                }

                # Ajouter les tâches de cette section
                $markdown += Add-TasksToMarkdown -SectionId $section.Id -Tasks $roadmap.Tasks

                $markdown += "`n"
            }

            # Écrire le contenu dans le fichier
            $markdown | Out-File -FilePath $OutputPath -Encoding utf8

            Write-Host "Roadmap sauvegardée dans: $OutputPath" -ForegroundColor Green
        }

        return $roadmap
    } catch {
        Write-Error "Échec de la conversion de la base de données Notion en roadmap: $_"
        return $null
    }
}

# Fonction pour synchroniser une roadmap avec Notion
function Sync-RoadmapToNotion {
    <#
    .SYNOPSIS
        Synchronise une roadmap avec Notion.

    .DESCRIPTION
        Cette fonction synchronise une roadmap avec Notion,
        en créant ou mettant à jour une base de données Notion.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion existante.
        Si non spécifié, une nouvelle base de données sera créée.

    .PARAMETER ParentPageId
        L'ID de la page parent pour la nouvelle base de données.
        Requis si DatabaseId n'est pas spécifié.

    .EXAMPLE
        Sync-RoadmapToNotion -Connection $connection -RoadmapPath "C:\Roadmaps\plan-dev-v8.md" -ParentPageId "abcdef123456"
        Synchronise la roadmap spécifiée avec une nouvelle base de données Notion.

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

        [Parameter(Mandatory = $false)]
        [string]$DatabaseId = "",

        [Parameter(Mandatory = $false)]
        [string]$ParentPageId = ""
    )

    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($DatabaseId) -and [string]::IsNullOrEmpty($ParentPageId)) {
        Write-Error "Vous devez spécifier soit DatabaseId, soit ParentPageId."
        return $null
    }

    # Convertir la roadmap en structure Notion
    $notionRoadmap = ConvertTo-NotionRoadmap -RoadmapPath $RoadmapPath

    if ($null -eq $notionRoadmap) {
        return $null
    }

    try {
        # Créer ou mettre à jour la base de données
        if ([string]::IsNullOrEmpty($DatabaseId)) {
            # Créer une nouvelle base de données
            $body = @{
                parent     = @{
                    page_id = $ParentPageId
                }
                title      = $notionRoadmap.Database.title
                properties = $notionRoadmap.Database.properties
            }

            $bodyJson = $body | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/databases" -Headers $Connection.Headers -Method Post -Body $bodyJson

            if ($null -eq $response -or $null -eq $response.id) {
                Write-Error "Échec de la création de la base de données Notion. Réponse invalide."
                return $null
            }

            $DatabaseId = $response.id
            Write-Host "Base de données Notion créée avec succès. ID: $DatabaseId" -ForegroundColor Green
        } else {
            # Mettre à jour la base de données existante
            $body = @{
                title      = $notionRoadmap.Database.title
                properties = $notionRoadmap.Database.properties
            }

            $bodyJson = $body | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/databases/$DatabaseId" -Headers $Connection.Headers -Method Patch -Body $bodyJson

            if ($null -eq $response -or $null -eq $response.id) {
                Write-Error "Échec de la mise à jour de la base de données Notion. Réponse invalide."
                return $null
            }

            Write-Host "Base de données Notion mise à jour avec succès. ID: $DatabaseId" -ForegroundColor Green
        }

        # Obtenir les pages existantes
        $existingPages = Get-NotionDatabasePages -Connection $Connection -DatabaseId $DatabaseId

        # Créer ou mettre à jour les pages
        foreach ($page in $notionRoadmap.Pages) {
            $taskId = $page.properties.ID.rich_text[0].text.content
            $existingPage = $existingPages | Where-Object { $_.properties.ID.rich_text.plain_text -eq $taskId } | Select-Object -First 1

            if ($null -eq $existingPage) {
                # Créer une nouvelle page
                $response = New-NotionDatabasePage -Connection $Connection -DatabaseId $DatabaseId -Properties $page.properties -Content $page.children

                if ($null -eq $response -or $null -eq $response.id) {
                    Write-Warning "Échec de la création de la page Notion pour la tâche $taskId."
                }
            } else {
                # Mettre à jour la page existante
                $response = Update-NotionPage -Connection $Connection -PageId $existingPage.id -Properties $page.properties

                if ($null -eq $response -or $null -eq $response.id) {
                    Write-Warning "Échec de la mise à jour de la page Notion pour la tâche $taskId."
                }
            }
        }

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            DatabaseId = $DatabaseId
            Title      = $notionRoadmap.Title
            TaskCount  = $notionRoadmap.Pages.Count
        }

        return $result
    } catch {
        Write-Error "Échec de la synchronisation de la roadmap avec Notion: $_"
        return $null
    }
}

# Fonction pour synchroniser bidirectionnellement une roadmap avec Notion
function Sync-RoadmapBidirectional {
    <#
    .SYNOPSIS
        Synchronise bidirectionnellement une roadmap avec Notion.

    .DESCRIPTION
        Cette fonction synchronise bidirectionnellement une roadmap avec Notion,
        en mettant à jour la roadmap locale avec les modifications de Notion et
        en mettant à jour Notion avec les modifications de la roadmap locale.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion.

    .PARAMETER ParentPageId
        L'ID de la page parent pour la nouvelle base de données.
        Requis si DatabaseId n'est pas spécifié.

    .PARAMETER Direction
        La direction de la synchronisation:
        - ToNotion: Synchronise la roadmap locale vers Notion
        - FromNotion: Synchronise Notion vers la roadmap locale
        - Both: Synchronise dans les deux directions (par défaut)

    .PARAMETER ConflictResolution
        La stratégie de résolution des conflits:
        - Local: Priorité à la roadmap locale
        - Remote: Priorité à Notion
        - Newer: Priorité à la version la plus récente
        - Ask: Demander à l'utilisateur (par défaut)

    .EXAMPLE
        Sync-RoadmapBidirectional -Connection $connection -RoadmapPath "C:\Roadmaps\plan-dev-v8.md" -DatabaseId "abcdef123456"
        Synchronise bidirectionnellement la roadmap spécifiée avec la base de données Notion.

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

        [Parameter(Mandatory = $false)]
        [string]$DatabaseId = "",

        [Parameter(Mandatory = $false)]
        [string]$ParentPageId = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("ToNotion", "FromNotion", "Both")]
        [string]$Direction = "Both",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Local", "Remote", "Newer", "Ask")]
        [string]$ConflictResolution = "Ask"
    )

    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($DatabaseId) -and [string]::IsNullOrEmpty($ParentPageId)) {
        Write-Error "Vous devez spécifier soit DatabaseId, soit ParentPageId."
        return $null
    }

    # Vérifier que le fichier de roadmap existe
    if (-not (Test-Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
        return $null
    }

    try {
        # Étape 1: Charger la roadmap locale
        $localRoadmap = Parse-RoadmapFile -FilePath $RoadmapPath

        if ($null -eq $localRoadmap) {
            Write-Error "Échec du chargement de la roadmap locale: $RoadmapPath"
            return $null
        }

        Write-Host "Roadmap locale chargée: $($localRoadmap.Title)" -ForegroundColor Green
        Write-Host "Nombre de tâches locales: $($localRoadmap.Tasks.Count)" -ForegroundColor Green

        # Étape 2: Si la base de données Notion n'existe pas, la créer
        if ([string]::IsNullOrEmpty($DatabaseId)) {
            Write-Host "Création d'une nouvelle base de données Notion..." -ForegroundColor Cyan

            $result = Sync-RoadmapToNotion -Connection $Connection -RoadmapPath $RoadmapPath -ParentPageId $ParentPageId

            if ($null -eq $result) {
                Write-Error "Échec de la création de la base de données Notion."
                return $null
            }

            $DatabaseId = $result.DatabaseId
            Write-Host "Base de données Notion créée: $DatabaseId" -ForegroundColor Green

            # Si la direction est ToNotion, nous avons terminé
            if ($Direction -eq "ToNotion") {
                return $result
            }
        }
        # Si la direction est ToNotion, synchroniser la roadmap locale vers Notion
        elseif ($Direction -eq "ToNotion") {
            Write-Host "Synchronisation de la roadmap locale vers Notion..." -ForegroundColor Cyan

            $result = Sync-RoadmapToNotion -Connection $Connection -RoadmapPath $RoadmapPath -DatabaseId $DatabaseId

            if ($null -eq $result) {
                Write-Error "Échec de la synchronisation de la roadmap locale vers Notion."
                return $null
            }

            Write-Host "Synchronisation vers Notion réussie!" -ForegroundColor Green
            return $result
        }

        # Étape 3: Charger la roadmap depuis Notion
        Write-Host "Chargement de la roadmap depuis Notion..." -ForegroundColor Cyan

        $tempPath = [System.IO.Path]::GetTempFileName() + ".md"
        $remoteRoadmap = ConvertFrom-NotionRoadmap -Connection $Connection -DatabaseId $DatabaseId -OutputPath $tempPath

        if ($null -eq $remoteRoadmap) {
            Write-Error "Échec du chargement de la roadmap depuis Notion."
            return $null
        }

        Write-Host "Roadmap Notion chargée: $($remoteRoadmap.Title)" -ForegroundColor Green
        Write-Host "Nombre de tâches Notion: $($remoteRoadmap.Tasks.Count)" -ForegroundColor Green

        # Si la direction est FromNotion, copier la roadmap Notion vers la roadmap locale
        if ($Direction -eq "FromNotion") {
            Write-Host "Copie de la roadmap Notion vers la roadmap locale..." -ForegroundColor Cyan

            Copy-Item -Path $tempPath -Destination $RoadmapPath -Force

            Write-Host "Synchronisation depuis Notion réussie!" -ForegroundColor Green

            # Créer l'objet de résultat
            $result = [PSCustomObject]@{
                RoadmapPath = $RoadmapPath
                DatabaseId  = $DatabaseId
                Title       = $remoteRoadmap.Title
                TaskCount   = $remoteRoadmap.Tasks.Count
            }

            return $result
        }

        # Étape 4: Fusionner les roadmaps
        Write-Host "Fusion des roadmaps..." -ForegroundColor Cyan

        # Créer un dictionnaire des tâches locales par ID
        $localTasksById = @{}
        foreach ($task in $localRoadmap.Tasks) {
            $localTasksById[$task.Id] = $task
        }

        # Créer un dictionnaire des tâches distantes par ID
        $remoteTasksById = @{}
        foreach ($task in $remoteRoadmap.Tasks) {
            $remoteTasksById[$task.Id] = $task
        }

        # Identifier les tâches à ajouter, mettre à jour ou supprimer
        $tasksToAdd = @()
        $tasksToDelete = @()
        $conflicts = @()

        # Tâches présentes dans la roadmap distante mais pas dans la roadmap locale
        foreach ($taskId in $remoteTasksById.Keys) {
            if (-not $localTasksById.ContainsKey($taskId)) {
                $tasksToAdd += $remoteTasksById[$taskId]
            }
        }

        # Tâches présentes dans les deux roadmaps
        foreach ($taskId in $localTasksById.Keys) {
            if ($remoteTasksById.ContainsKey($taskId)) {
                $localTask = $localTasksById[$taskId]
                $remoteTask = $remoteTasksById[$taskId]

                # Vérifier s'il y a un conflit
                if ($localTask.Status -ne $remoteTask.Status -or $localTask.Title -ne $remoteTask.Title) {
                    $conflicts += [PSCustomObject]@{
                        Id     = $taskId
                        Local  = $localTask
                        Remote = $remoteTask
                    }
                }
            }
            # Tâches présentes dans la roadmap locale mais pas dans la roadmap distante
            else {
                $tasksToDelete += $localTasksById[$taskId]
            }
        }

        # Afficher un résumé des modifications
        Write-Host "Résumé des modifications:" -ForegroundColor Yellow
        Write-Host "  Tâches à ajouter: $($tasksToAdd.Count)" -ForegroundColor Gray
        Write-Host "  Tâches à supprimer: $($tasksToDelete.Count)" -ForegroundColor Gray
        Write-Host "  Conflits: $($conflicts.Count)" -ForegroundColor Gray

        # Résoudre les conflits
        $resolvedConflicts = @()

        if ($conflicts.Count -gt 0) {
            Write-Host "Résolution des conflits..." -ForegroundColor Yellow

            foreach ($conflict in $conflicts) {
                $taskId = $conflict.Id
                $localTask = $conflict.Local
                $remoteTask = $conflict.Remote

                Write-Host "  Conflit pour la tâche $($taskId):" -ForegroundColor Yellow
                Write-Host "    Local: $($localTask.Title) - $($localTask.Status)" -ForegroundColor Gray
                Write-Host "    Remote: $($remoteTask.Title) - $($remoteTask.Status)" -ForegroundColor Gray

                $resolution = $ConflictResolution

                if ($resolution -eq "Ask") {
                    Write-Host "    Résolution (L: Local, R: Remote, N: Newer): " -ForegroundColor Yellow -NoNewline
                    $choice = Read-Host

                    switch ($choice.ToUpper()) {
                        "L" { $resolution = "Local" }
                        "R" { $resolution = "Remote" }
                        "N" { $resolution = "Newer" }
                        default { $resolution = "Local" }
                    }
                }

                switch ($resolution) {
                    "Local" {
                        $resolvedConflicts += [PSCustomObject]@{
                            Id         = $taskId
                            Resolution = "Local"
                            Task       = $localTask
                        }
                    }
                    "Remote" {
                        $resolvedConflicts += [PSCustomObject]@{
                            Id         = $taskId
                            Resolution = "Remote"
                            Task       = $remoteTask
                        }

                        # Mettre à jour la tâche locale
                        $localTasksById[$taskId].Title = $remoteTask.Title
                        $localTasksById[$taskId].Status = $remoteTask.Status
                        $localTasksById[$taskId].Description = $remoteTask.Description
                    }
                    "Newer" {
                        # Dans cette implémentation simple, nous choisissons toujours la version distante
                        # Dans une implémentation plus avancée, nous pourrions comparer les dates de modification
                        $resolvedConflicts += [PSCustomObject]@{
                            Id         = $taskId
                            Resolution = "Remote"
                            Task       = $remoteTask
                        }

                        # Mettre à jour la tâche locale
                        $localTasksById[$taskId].Title = $remoteTask.Title
                        $localTasksById[$taskId].Status = $remoteTask.Status
                        $localTasksById[$taskId].Description = $remoteTask.Description
                    }
                }
            }
        }

        # Mettre à jour la roadmap locale
        $updatedTasks = @()

        # Ajouter les tâches existantes (avec les conflits résolus)
        foreach ($taskId in $localTasksById.Keys) {
            if (-not ($tasksToDelete | Where-Object { $_.Id -eq $taskId })) {
                $updatedTasks += $localTasksById[$taskId]
            }
        }

        # Ajouter les nouvelles tâches
        foreach ($task in $tasksToAdd) {
            $updatedTasks += $task
        }

        # Créer la roadmap mise à jour
        $updatedRoadmap = [PSCustomObject]@{
            Title    = $localRoadmap.Title
            FilePath = $RoadmapPath
            Tasks    = $updatedTasks
        }

        # Sauvegarder la roadmap mise à jour
        $outputPath = $RoadmapPath

        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $outputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Générer le contenu markdown
        $markdown = "# $($updatedRoadmap.Title)`n`n"

        # Fonction récursive pour ajouter les tâches
        function Add-TasksToMarkdown {
            param (
                [string]$SectionId,
                [PSObject[]]$Tasks,
                [int]$Indent = 0
            )

            $sectionTasks = $Tasks | Where-Object { $_.Id -like "$SectionId.*" -and $_.Id.Split('.').Count -eq $SectionId.Split('.').Count + 1 } | Sort-Object -Property Id

            $result = ""
            foreach ($task in $sectionTasks) {
                $indentation = "  " * $Indent
                $checkbox = if ($task.Status -eq "Completed") { "[x]" } else { "[ ]" }

                $result += "$indentation- $checkbox **$($task.Id)** $($task.Title)`n"

                if ($task.Description) {
                    $result += "$indentation  $($task.Description)`n"
                }

                # Ajouter récursivement les sous-tâches
                $result += Add-TasksToMarkdown -SectionId $task.Id -Tasks $Tasks -Indent ($Indent + 1)
            }

            return $result
        }

        # Ajouter les sections principales
        $sections = $updatedRoadmap.Tasks | Where-Object { $_.Id -match "^\d+$" } | Sort-Object -Property Id

        foreach ($section in $sections) {
            $markdown += "## $($section.Id) $($section.Title)`n"

            if ($section.Description) {
                $markdown += "$($section.Description)`n`n"
            }

            # Ajouter les tâches de cette section
            $markdown += Add-TasksToMarkdown -SectionId $section.Id -Tasks $updatedRoadmap.Tasks

            $markdown += "`n"
        }

        # Écrire le contenu dans le fichier
        $markdown | Out-File -FilePath $outputPath -Encoding utf8

        Write-Host "Roadmap mise à jour sauvegardée dans: $outputPath" -ForegroundColor Green

        # Synchroniser la roadmap mise à jour avec Notion
        Write-Host "Synchronisation de la roadmap mise à jour avec Notion..." -ForegroundColor Cyan

        $result = Sync-RoadmapToNotion -Connection $Connection -RoadmapPath $outputPath -DatabaseId $DatabaseId

        if ($null -eq $result) {
            Write-Error "Échec de la synchronisation de la roadmap mise à jour avec Notion."
            return $null
        }

        Write-Host "Synchronisation bidirectionnelle réussie!" -ForegroundColor Green

        # Ajouter des informations supplémentaires au résultat
        $result | Add-Member -MemberType NoteProperty -Name "TasksAdded" -Value $tasksToAdd.Count
        $result | Add-Member -MemberType NoteProperty -Name "TasksDeleted" -Value $tasksToDelete.Count
        $result | Add-Member -MemberType NoteProperty -Name "Conflicts" -Value $conflicts.Count
        $result | Add-Member -MemberType NoteProperty -Name "ResolvedConflicts" -Value $resolvedConflicts.Count

        return $result
    } catch {
        Write-Error "Échec de la synchronisation bidirectionnelle: $_"
        return $null
    } finally {
        # Nettoyer les fichiers temporaires
        if (Test-Path $tempPath) {
            Remove-Item -Path $tempPath -Force
        }
    }
}
