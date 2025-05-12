# Import-ExportNotion.ps1
# Module pour importer et exporter des bases de données Notion
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Importe et exporte des bases de données Notion.

.DESCRIPTION
    Ce module fournit des fonctions pour importer et exporter des bases de données Notion,
    permettant de sauvegarder et restaurer des roadmaps dans Notion.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$connectNotionRoadmapPath = Join-Path -Path $scriptPath -ChildPath "Connect-NotionRoadmap.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

if (Test-Path $connectNotionRoadmapPath) {
    . $connectNotionRoadmapPath
} else {
    Write-Error "Module Connect-NotionRoadmap.ps1 introuvable à l'emplacement: $connectNotionRoadmapPath"
    exit
}

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

# Fonction pour exporter une base de données Notion
function Export-NotionDatabase {
    <#
    .SYNOPSIS
        Exporte une base de données Notion.

    .DESCRIPTION
        Cette fonction exporte une base de données Notion vers un fichier JSON,
        permettant de sauvegarder la structure et le contenu de la base de données.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion à exporter.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier JSON.
        Si non spécifié, le fichier est sauvegardé dans le dossier courant.

    .PARAMETER IncludeContent
        Indique si le contenu des pages doit être inclus dans l'export.
        Par défaut, seules les propriétés des pages sont exportées.

    .EXAMPLE
        Export-NotionDatabase -Connection $connection -DatabaseId "abcdef123456" -OutputPath "C:\Exports\notion-database.json"
        Exporte la base de données Notion spécifiée vers le fichier JSON spécifié.

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
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent = $false
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
        }
        
        # Créer l'objet d'export
        $export = [PSCustomObject]@{
            Database = $database
            Pages = @()
        }
        
        # Ajouter les pages à l'export
        foreach ($page in $pages) {
            $exportPage = [PSCustomObject]@{
                Id = $page.id
                Properties = $page.properties
            }
            
            # Ajouter le contenu de la page si demandé
            if ($IncludeContent) {
                # Obtenir le contenu de la page
                $pageContent = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/blocks/$($page.id)/children" -Headers $Connection.Headers -Method Get
                
                if ($null -ne $pageContent -and $null -ne $pageContent.results) {
                    $exportPage | Add-Member -MemberType NoteProperty -Name "Content" -Value $pageContent.results
                }
            }
            
            $export.Pages += $exportPage
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $databaseTitle = $database.title.plain_text -join "-"
            if ([string]::IsNullOrEmpty($databaseTitle)) {
                $databaseTitle = "notion-database"
            }
            $OutputPath = Join-Path -Path (Get-Location) -ChildPath "$databaseTitle-$DatabaseId.json"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder l'export dans un fichier JSON
        $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Host "Base de données Notion exportée vers: $OutputPath" -ForegroundColor Green
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            DatabaseId = $DatabaseId
            Title = $database.title.plain_text -join " "
            PageCount = $pages.Count
            OutputPath = $OutputPath
        }
        
        return $result
    } catch {
        Write-Error "Échec de l'export de la base de données Notion: $_"
        return $null
    }
}

# Fonction pour importer une base de données Notion
function Import-NotionDatabase {
    <#
    .SYNOPSIS
        Importe une base de données Notion.

    .DESCRIPTION
        Cette fonction importe une base de données Notion à partir d'un fichier JSON,
        permettant de restaurer la structure et le contenu de la base de données.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER InputPath
        Le chemin du fichier JSON contenant la base de données à importer.

    .PARAMETER ParentPageId
        L'ID de la page parent où créer la base de données.
        Requis si DatabaseId n'est pas spécifié.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion existante à mettre à jour.
        Si non spécifié, une nouvelle base de données est créée.

    .PARAMETER ImportContent
        Indique si le contenu des pages doit être importé.
        Par défaut, seules les propriétés des pages sont importées.

    .EXAMPLE
        Import-NotionDatabase -Connection $connection -InputPath "C:\Exports\notion-database.json" -ParentPageId "abcdef123456"
        Importe la base de données Notion à partir du fichier JSON spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$ParentPageId = "",

        [Parameter(Mandatory = $false)]
        [string]$DatabaseId = "",

        [Parameter(Mandatory = $false)]
        [switch]$ImportContent = $false
    )

    try {
        # Vérifier les paramètres
        if ([string]::IsNullOrEmpty($DatabaseId) -and [string]::IsNullOrEmpty($ParentPageId)) {
            Write-Error "Vous devez spécifier soit DatabaseId, soit ParentPageId."
            return $null
        }
        
        # Vérifier que le fichier d'entrée existe
        if (-not (Test-Path $InputPath)) {
            Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
            return $null
        }
        
        # Charger le fichier JSON
        $import = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
        
        if ($null -eq $import -or $null -eq $import.Database) {
            Write-Error "Le fichier d'entrée ne contient pas de base de données Notion valide."
            return $null
        }
        
        # Créer ou mettre à jour la base de données
        if ([string]::IsNullOrEmpty($DatabaseId)) {
            # Créer une nouvelle base de données
            $body = @{
                parent = @{
                    page_id = $ParentPageId
                }
                title = $import.Database.title
                properties = $import.Database.properties
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
                title = $import.Database.title
                properties = $import.Database.properties
            }
            
            $bodyJson = $body | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/databases/$DatabaseId" -Headers $Connection.Headers -Method Patch -Body $bodyJson
            
            if ($null -eq $response -or $null -eq $response.id) {
                Write-Error "Échec de la mise à jour de la base de données Notion. Réponse invalide."
                return $null
            }
            
            Write-Host "Base de données Notion mise à jour avec succès. ID: $DatabaseId" -ForegroundColor Green
        }
        
        # Importer les pages
        $pagesCreated = 0
        $pagesUpdated = 0
        
        if ($null -ne $import.Pages -and $import.Pages.Count -gt 0) {
            # Obtenir les pages existantes
            $existingPages = Get-NotionDatabasePages -Connection $Connection -DatabaseId $DatabaseId
            
            foreach ($page in $import.Pages) {
                # Vérifier si la page existe déjà
                $existingPage = $null
                if ($null -ne $existingPages -and $existingPages.Count -gt 0) {
                    $existingPage = $existingPages | Where-Object { $_.id -eq $page.Id } | Select-Object -First 1
                }
                
                if ($null -eq $existingPage) {
                    # Créer une nouvelle page
                    $body = @{
                        parent = @{
                            database_id = $DatabaseId
                        }
                        properties = $page.Properties
                    }
                    
                    # Ajouter le contenu si demandé
                    if ($ImportContent -and $null -ne $page.Content) {
                        $body.children = $page.Content
                    }
                    
                    $bodyJson = $body | ConvertTo-Json -Depth 10
                    
                    $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/pages" -Headers $Connection.Headers -Method Post -Body $bodyJson
                    
                    if ($null -ne $response -and $null -ne $response.id) {
                        $pagesCreated++
                    }
                } else {
                    # Mettre à jour la page existante
                    $body = @{
                        properties = $page.Properties
                    }
                    
                    $bodyJson = $body | ConvertTo-Json -Depth 10
                    
                    $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/pages/$($existingPage.id)" -Headers $Connection.Headers -Method Patch -Body $bodyJson
                    
                    if ($null -ne $response -and $null -ne $response.id) {
                        $pagesUpdated++
                    }
                    
                    # Mettre à jour le contenu si demandé
                    if ($ImportContent -and $null -ne $page.Content) {
                        # Supprimer le contenu existant
                        $existingBlocks = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/blocks/$($existingPage.id)/children" -Headers $Connection.Headers -Method Get
                        
                        if ($null -ne $existingBlocks -and $null -ne $existingBlocks.results) {
                            foreach ($block in $existingBlocks.results) {
                                Invoke-RestMethod -Uri "$($Connection.BaseUrl)/blocks/$($block.id)" -Headers $Connection.Headers -Method Delete
                            }
                        }
                        
                        # Ajouter le nouveau contenu
                        $body = @{
                            children = $page.Content
                        }
                        
                        $bodyJson = $body | ConvertTo-Json -Depth 10
                        
                        Invoke-RestMethod -Uri "$($Connection.BaseUrl)/blocks/$($existingPage.id)/children" -Headers $Connection.Headers -Method Patch -Body $bodyJson
                    }
                }
            }
        }
        
        Write-Host "Import terminé. Pages créées: $pagesCreated, Pages mises à jour: $pagesUpdated" -ForegroundColor Green
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            DatabaseId = $DatabaseId
            Title = $import.Database.title.plain_text -join " "
            PagesCreated = $pagesCreated
            PagesUpdated = $pagesUpdated
        }
        
        return $result
    } catch {
        Write-Error "Échec de l'import de la base de données Notion: $_"
        return $null
    }
}

# Fonction pour exporter une roadmap Notion vers un fichier Markdown
function Export-NotionToMarkdown {
    <#
    .SYNOPSIS
        Exporte une base de données Notion vers un fichier Markdown.

    .DESCRIPTION
        Cette fonction exporte une base de données Notion vers un fichier Markdown,
        permettant de créer une roadmap à partir d'une base de données Notion.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion à exporter.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier Markdown.
        Si non spécifié, le fichier est sauvegardé dans le dossier courant.

    .EXAMPLE
        Export-NotionToMarkdown -Connection $connection -DatabaseId "abcdef123456" -OutputPath "C:\Roadmaps\notion-roadmap.md"
        Exporte la base de données Notion spécifiée vers le fichier Markdown spécifié.

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
        # Utiliser la fonction ConvertFrom-NotionRoadmap pour convertir la base de données en roadmap
        $roadmap = ConvertFrom-NotionRoadmap -Connection $Connection -DatabaseId $DatabaseId -OutputPath $OutputPath
        
        if ($null -eq $roadmap) {
            return $null
        }
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            DatabaseId = $DatabaseId
            Title = $roadmap.Title
            TaskCount = $roadmap.Tasks.Count
            OutputPath = $OutputPath
        }
        
        return $result
    } catch {
        Write-Error "Échec de l'export de la base de données Notion vers Markdown: $_"
        return $null
    }
}

# Fonction pour importer un fichier Markdown vers une base de données Notion
function Import-MarkdownToNotion {
    <#
    .SYNOPSIS
        Importe un fichier Markdown vers une base de données Notion.

    .DESCRIPTION
        Cette fonction importe un fichier Markdown vers une base de données Notion,
        permettant de créer une base de données Notion à partir d'une roadmap.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER InputPath
        Le chemin du fichier Markdown à importer.

    .PARAMETER ParentPageId
        L'ID de la page parent où créer la base de données.
        Requis si DatabaseId n'est pas spécifié.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion existante à mettre à jour.
        Si non spécifié, une nouvelle base de données est créée.

    .EXAMPLE
        Import-MarkdownToNotion -Connection $connection -InputPath "C:\Roadmaps\roadmap.md" -ParentPageId "abcdef123456"
        Importe le fichier Markdown spécifié vers une nouvelle base de données Notion.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$ParentPageId = "",

        [Parameter(Mandatory = $false)]
        [string]$DatabaseId = ""
    )

    try {
        # Vérifier les paramètres
        if ([string]::IsNullOrEmpty($DatabaseId) -and [string]::IsNullOrEmpty($ParentPageId)) {
            Write-Error "Vous devez spécifier soit DatabaseId, soit ParentPageId."
            return $null
        }
        
        # Vérifier que le fichier d'entrée existe
        if (-not (Test-Path $InputPath)) {
            Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
            return $null
        }
        
        # Utiliser la fonction Sync-RoadmapToNotion pour importer le fichier Markdown
        $result = Sync-RoadmapToNotion -Connection $Connection -RoadmapPath $InputPath -DatabaseId $DatabaseId -ParentPageId $ParentPageId
        
        return $result
    } catch {
        Write-Error "Échec de l'import du fichier Markdown vers Notion: $_"
        return $null
    }
}
