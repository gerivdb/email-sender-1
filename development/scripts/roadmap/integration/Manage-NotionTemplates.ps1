# Manage-NotionTemplates.ps1
# Module pour gérer les templates Notion
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Gère les templates Notion pour les roadmaps.

.DESCRIPTION
    Ce module fournit des fonctions pour gérer les templates Notion pour les roadmaps,
    permettant de créer, modifier et appliquer des templates pour les bases de données Notion.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$connectNotionRoadmapPath = Join-Path -Path $scriptPath -ChildPath "Connect-NotionRoadmap.ps1"
$importExportNotionPath = Join-Path -Path $scriptPath -ChildPath "Import-ExportNotion.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

if (Test-Path $connectNotionRoadmapPath) {
    . $connectNotionRoadmapPath
} else {
    Write-Error "Module Connect-NotionRoadmap.ps1 introuvable à l'emplacement: $connectNotionRoadmapPath"
    exit
}

if (Test-Path $importExportNotionPath) {
    . $importExportNotionPath
} else {
    Write-Error "Module Import-ExportNotion.ps1 introuvable à l'emplacement: $importExportNotionPath"
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

# Fonction pour créer un template Notion à partir d'une base de données existante
function New-NotionTemplate {
    <#
    .SYNOPSIS
        Crée un template Notion à partir d'une base de données existante.

    .DESCRIPTION
        Cette fonction crée un template Notion à partir d'une base de données existante,
        en sauvegardant la structure et les propriétés de la base de données.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion à utiliser comme template.

    .PARAMETER TemplateName
        Le nom du template.

    .PARAMETER TemplateDescription
        La description du template.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier de template.
        Si non spécifié, le fichier est sauvegardé dans le dossier des templates.

    .PARAMETER IncludeContent
        Indique si le contenu des pages doit être inclus dans le template.
        Par défaut, seules les propriétés des pages sont incluses.

    .EXAMPLE
        New-NotionTemplate -Connection $connection -DatabaseId "abcdef123456" -TemplateName "Roadmap Template" -TemplateDescription "Template for roadmaps"
        Crée un template Notion à partir de la base de données spécifiée.

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
        [string]$TemplateName,

        [Parameter(Mandatory = $false)]
        [string]$TemplateDescription = "",

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
        
        # Créer l'objet de template
        $template = [PSCustomObject]@{
            Name = $TemplateName
            Description = $TemplateDescription
            CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Database = $database
            Pages = @()
        }
        
        # Ajouter les pages au template
        foreach ($page in $pages) {
            $templatePage = [PSCustomObject]@{
                Properties = $page.properties
            }
            
            # Ajouter le contenu de la page si demandé
            if ($IncludeContent) {
                # Obtenir le contenu de la page
                $pageContent = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/blocks/$($page.id)/children" -Headers $Connection.Headers -Method Get
                
                if ($null -ne $pageContent -and $null -ne $pageContent.results) {
                    $templatePage | Add-Member -MemberType NoteProperty -Name "Content" -Value $pageContent.results
                }
            }
            
            $template.Pages += $templatePage
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $templatesDir = Join-Path -Path $scriptPath -ChildPath "templates"
            
            if (-not (Test-Path $templatesDir)) {
                New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
            }
            
            $OutputPath = Join-Path -Path $templatesDir -ChildPath "$($TemplateName -replace '[\\/:*?"<>|]', '_').json"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder le template dans un fichier JSON
        $template | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Host "Template Notion créé: $OutputPath" -ForegroundColor Green
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            TemplateName = $TemplateName
            TemplateDescription = $TemplateDescription
            DatabaseId = $DatabaseId
            PageCount = $pages.Count
            OutputPath = $OutputPath
        }
        
        return $result
    } catch {
        Write-Error "Échec de la création du template Notion: $_"
        return $null
    }
}

# Fonction pour appliquer un template Notion
function Apply-NotionTemplate {
    <#
    .SYNOPSIS
        Applique un template Notion.

    .DESCRIPTION
        Cette fonction applique un template Notion, en créant une nouvelle base de données
        ou en mettant à jour une base de données existante.

    .PARAMETER Connection
        La connexion à l'API Notion créée par Connect-NotionApi.

    .PARAMETER TemplatePath
        Le chemin du fichier de template.

    .PARAMETER ParentPageId
        L'ID de la page parent où créer la base de données.
        Requis si DatabaseId n'est pas spécifié.

    .PARAMETER DatabaseId
        L'ID de la base de données Notion existante à mettre à jour.
        Si non spécifié, une nouvelle base de données est créée.

    .PARAMETER IncludeContent
        Indique si le contenu des pages doit être inclus dans l'application du template.
        Par défaut, seules les propriétés des pages sont incluses.

    .EXAMPLE
        Apply-NotionTemplate -Connection $connection -TemplatePath "C:\Templates\roadmap-template.json" -ParentPageId "abcdef123456"
        Applique le template Notion spécifié en créant une nouvelle base de données.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$TemplatePath,

        [Parameter(Mandatory = $false)]
        [string]$ParentPageId = "",

        [Parameter(Mandatory = $false)]
        [string]$DatabaseId = "",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent = $false
    )

    try {
        # Vérifier les paramètres
        if ([string]::IsNullOrEmpty($DatabaseId) -and [string]::IsNullOrEmpty($ParentPageId)) {
            Write-Error "Vous devez spécifier soit DatabaseId, soit ParentPageId."
            return $null
        }
        
        # Vérifier que le fichier de template existe
        if (-not (Test-Path $TemplatePath)) {
            Write-Error "Le fichier de template n'existe pas: $TemplatePath"
            return $null
        }
        
        # Charger le fichier JSON
        $template = Get-Content -Path $TemplatePath -Raw | ConvertFrom-Json
        
        if ($null -eq $template -or $null -eq $template.Database) {
            Write-Error "Le fichier de template ne contient pas de base de données Notion valide."
            return $null
        }
        
        # Créer ou mettre à jour la base de données
        if ([string]::IsNullOrEmpty($DatabaseId)) {
            # Créer une nouvelle base de données
            $body = @{
                parent = @{
                    page_id = $ParentPageId
                }
                title = $template.Database.title
                properties = $template.Database.properties
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
                title = $template.Database.title
                properties = $template.Database.properties
            }
            
            $bodyJson = $body | ConvertTo-Json -Depth 10
            
            $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/databases/$DatabaseId" -Headers $Connection.Headers -Method Patch -Body $bodyJson
            
            if ($null -eq $response -or $null -eq $response.id) {
                Write-Error "Échec de la mise à jour de la base de données Notion. Réponse invalide."
                return $null
            }
            
            Write-Host "Base de données Notion mise à jour avec succès. ID: $DatabaseId" -ForegroundColor Green
        }
        
        # Créer les pages à partir du template
        $pagesCreated = 0
        
        if ($null -ne $template.Pages -and $template.Pages.Count -gt 0) {
            foreach ($page in $template.Pages) {
                # Créer une nouvelle page
                $body = @{
                    parent = @{
                        database_id = $DatabaseId
                    }
                    properties = $page.Properties
                }
                
                # Ajouter le contenu si demandé
                if ($IncludeContent -and $null -ne $page.Content) {
                    $body.children = $page.Content
                }
                
                $bodyJson = $body | ConvertTo-Json -Depth 10
                
                $response = Invoke-RestMethod -Uri "$($Connection.BaseUrl)/pages" -Headers $Connection.Headers -Method Post -Body $bodyJson
                
                if ($null -ne $response -and $null -ne $response.id) {
                    $pagesCreated++
                }
            }
        }
        
        Write-Host "Application du template terminée. Pages créées: $pagesCreated" -ForegroundColor Green
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            TemplateName = $template.Name
            TemplateDescription = $template.Description
            DatabaseId = $DatabaseId
            PagesCreated = $pagesCreated
        }
        
        return $result
    } catch {
        Write-Error "Échec de l'application du template Notion: $_"
        return $null
    }
}

# Fonction pour lister les templates Notion disponibles
function Get-NotionTemplates {
    <#
    .SYNOPSIS
        Liste les templates Notion disponibles.

    .DESCRIPTION
        Cette fonction liste les templates Notion disponibles dans le dossier des templates.

    .PARAMETER TemplatesDir
        Le dossier contenant les templates.
        Si non spécifié, le dossier par défaut est utilisé.

    .EXAMPLE
        Get-NotionTemplates
        Liste les templates Notion disponibles dans le dossier par défaut.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TemplatesDir = ""
    )

    try {
        # Déterminer le dossier des templates
        if ([string]::IsNullOrEmpty($TemplatesDir)) {
            $TemplatesDir = Join-Path -Path $scriptPath -ChildPath "templates"
        }
        
        # Vérifier que le dossier existe
        if (-not (Test-Path $TemplatesDir)) {
            Write-Warning "Le dossier des templates n'existe pas: $TemplatesDir"
            return @()
        }
        
        # Obtenir les fichiers de template
        $templateFiles = Get-ChildItem -Path $TemplatesDir -Filter "*.json"
        
        if ($null -eq $templateFiles -or $templateFiles.Count -eq 0) {
            Write-Warning "Aucun template trouvé dans le dossier: $TemplatesDir"
            return @()
        }
        
        # Créer les objets de template
        $templates = @()
        
        foreach ($file in $templateFiles) {
            try {
                $template = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                
                if ($null -ne $template -and $null -ne $template.Name) {
                    $templates += [PSCustomObject]@{
                        Name = $template.Name
                        Description = $template.Description
                        CreatedAt = $template.CreatedAt
                        Path = $file.FullName
                        PageCount = if ($null -ne $template.Pages) { $template.Pages.Count } else { 0 }
                    }
                }
            } catch {
                Write-Warning "Échec du chargement du template: $($file.FullName). Erreur: $_"
            }
        }
        
        return $templates
    } catch {
        Write-Error "Échec de la liste des templates Notion: $_"
        return @()
    }
}
