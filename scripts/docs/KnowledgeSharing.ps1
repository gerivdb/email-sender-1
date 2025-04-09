# Script pour le partage des connaissances sur les erreurs

# Importer le module de documentation des erreurs
$docFormatPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDocFormat.ps1"
if (Test-Path -Path $docFormatPath) {
    . $docFormatPath
}
else {
    Write-Error "Le module de documentation des erreurs est introuvable: $docFormatPath"
    return
}

# Configuration
$KnowledgeConfig = @{
    # Dossier de la base de connaissances
    KnowledgeBaseFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase"
    
    # Dossier des articles
    ArticlesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase\Articles"
    
    # Dossier des ressources
    ResourcesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase\Resources"
    
    # Fichier d'index
    IndexFile = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase\index.md"
    
    # CatÃ©gories d'articles
    Categories = @(
        "Erreurs courantes",
        "Bonnes pratiques",
        "Tutoriels",
        "RÃ©fÃ©rences",
        "Ã‰tudes de cas"
    )
}

# Fonction pour initialiser la base de connaissances

# Script pour le partage des connaissances sur les erreurs

# Importer le module de documentation des erreurs
$docFormatPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDocFormat.ps1"
if (Test-Path -Path $docFormatPath) {
    . $docFormatPath
}
else {
    Write-Error "Le module de documentation des erreurs est introuvable: $docFormatPath"
    return
}

# Configuration
$KnowledgeConfig = @{
    # Dossier de la base de connaissances
    KnowledgeBaseFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase"
    
    # Dossier des articles
    ArticlesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase\Articles"
    
    # Dossier des ressources
    ResourcesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase\Resources"
    
    # Fichier d'index
    IndexFile = Join-Path -Path $env:TEMP -ChildPath "ErrorKnowledgeBase\index.md"
    
    # CatÃ©gories d'articles
    Categories = @(
        "Erreurs courantes",
        "Bonnes pratiques",
        "Tutoriels",
        "RÃ©fÃ©rences",
        "Ã‰tudes de cas"
    )
}

# Fonction pour initialiser la base de connaissances
function Initialize-KnowledgeBase {
    param (
        [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
        [string]$KnowledgeBaseFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ArticlesFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ResourcesFolder = ""
    )
    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($KnowledgeBaseFolder)) {
        $KnowledgeConfig.KnowledgeBaseFolder = $KnowledgeBaseFolder
        $KnowledgeConfig.IndexFile = Join-Path -Path $KnowledgeBaseFolder -ChildPath "index.md"
    }
    
    if (-not [string]::IsNullOrEmpty($ArticlesFolder)) {
        $KnowledgeConfig.ArticlesFolder = $ArticlesFolder
    }
    
    if (-not [string]::IsNullOrEmpty($ResourcesFolder)) {
        $KnowledgeConfig.ResourcesFolder = $ResourcesFolder
    }
    
    # CrÃ©er les dossiers s'ils n'existent pas
    foreach ($folder in @($KnowledgeConfig.KnowledgeBaseFolder, $KnowledgeConfig.ArticlesFolder, $KnowledgeConfig.ResourcesFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    # CrÃ©er les dossiers de catÃ©gories
    foreach ($category in $KnowledgeConfig.Categories) {
        $categoryFolder = Join-Path -Path $KnowledgeConfig.ArticlesFolder -ChildPath $category.Replace(" ", "_")
        if (-not (Test-Path -Path $categoryFolder)) {
            New-Item -Path $categoryFolder -ItemType Directory -Force | Out-Null
        }
    }
    
    # CrÃ©er le fichier d'index s'il n'existe pas
    if (-not (Test-Path -Path $KnowledgeConfig.IndexFile)) {
        $indexContent = @"
# Base de connaissances des erreurs

Cette base de connaissances contient des articles, des tutoriels et des rÃ©fÃ©rences sur les erreurs courantes et leur rÃ©solution.

## CatÃ©gories

$(foreach ($category in $KnowledgeConfig.Categories) {
    "- [$category](./$($category.Replace(" ", "_")))`n"
})

## Articles rÃ©cents

## Articles populaires

## Recherche

Utilisez la fonction de recherche pour trouver des articles spÃ©cifiques.
"@
        
        $indexContent | Set-Content -Path $KnowledgeConfig.IndexFile -Encoding UTF8
    }
    
    # Initialiser le module de documentation des erreurs
    Initialize-ErrorDocumentation
    
    return $KnowledgeConfig
}

# Fonction pour crÃ©er un nouvel article
function New-KnowledgeArticle {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "RÃ©fÃ©rences", "Ã‰tudes de cas")]
        [string]$Category,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [string]$Summary = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$RelatedArticles = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$References = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$Author = $env:USERNAME,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorDocPath = ""
    )
    
    # GÃ©nÃ©rer un ID unique
    $id = [Guid]::NewGuid().ToString().Substring(0, 8).ToUpper()
    
    # Formater le titre pour le nom de fichier
    $fileName = "$id-$($Title -replace '[^\w\-]', '_').md"
    
    # DÃ©terminer le dossier de catÃ©gorie
    $categoryFolder = Join-Path -Path $KnowledgeConfig.ArticlesFolder -ChildPath $Category.Replace(" ", "_")
    
    # DÃ©terminer le chemin de l'article
    $articlePath = Join-Path -Path $categoryFolder -ChildPath $fileName
    
    # Utiliser le rÃ©sumÃ© fourni ou gÃ©nÃ©rer un rÃ©sumÃ© Ã  partir du contenu
    if ([string]::IsNullOrEmpty($Summary)) {
        $Summary = $Content.Substring(0, [Math]::Min(200, $Content.Length)) + "..."
    }
    
    # GÃ©nÃ©rer le contenu de l'article
    $articleContent = @"
# $Title

- **ID**: $id
- **CatÃ©gorie**: $Category
- **Date**: $(Get-Date -Format "yyyy-MM-dd")
- **Auteur**: $Author
- **Tags**: $(if ($Tags.Count -gt 0) { $Tags -join ", " } else { "Aucun" })

## RÃ©sumÃ©

$Summary

## Contenu

$Content

$(if ($RelatedArticles.Count -gt 0) {
    "## Articles connexes`n`n" + ($RelatedArticles | ForEach-Object { "- $_`n" })
} else { "" })

$(if ($References.Count -gt 0) {
    "## RÃ©fÃ©rences`n`n" + ($References | ForEach-Object { "- $_`n" })
} else { "" })

$(if (-not [string]::IsNullOrEmpty($ErrorDocPath)) {
    "## Documentation d'erreur associÃ©e`n`n[Voir la documentation d'erreur]($ErrorDocPath)`n"
} else { "" })

---
DerniÃ¨re mise Ã  jour: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    # Enregistrer l'article
    $articleContent | Set-Content -Path $articlePath -Encoding UTF8
    
    # Mettre Ã  jour l'index
    Update-KnowledgeBaseIndex -NewArticlePath $articlePath
    
    return @{
        ID = $id
        Title = $Title
        Category = $Category
        Path = $articlePath
    }
}

# Fonction pour mettre Ã  jour l'index de la base de connaissances
function Update-KnowledgeBaseIndex {
    param (
        [Parameter(Mandatory = $false)]
        [string]$NewArticlePath = ""
    )
    
    # Charger l'index
    $indexContent = Get-Content -Path $KnowledgeConfig.IndexFile -Raw
    
    # Obtenir tous les articles
    $articles = @()
    
    foreach ($category in $KnowledgeConfig.Categories) {
        $categoryFolder = Join-Path -Path $KnowledgeConfig.ArticlesFolder -ChildPath $category.Replace(" ", "_")
        
        if (Test-Path -Path $categoryFolder) {
            $categoryArticles = Get-ChildItem -Path $categoryFolder -Filter "*.md"
            
            foreach ($article in $categoryArticles) {
                $content = Get-Content -Path $article.FullName -Raw
                
                $title = if ($content -match "# (.+)") { $Matches[1] } else { $article.BaseName }
                $id = if ($content -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
                $date = if ($content -match "Date:\s*(.+)") { $Matches[1] } else { "" }
                $summary = if ($content -match "RÃ©sumÃ©\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
                
                $articles += [PSCustomObject]@{
                    Title = $title
                    ID = $id
                    Category = $category
                    Date = $date
                    Path = $article.FullName
                    Summary = $summary
                }
            }
        }
    }
    
    # Trier les articles par date (les plus rÃ©cents en premier)
    $recentArticles = $articles | Sort-Object -Property Date -Descending | Select-Object -First 5
    
    # GÃ©nÃ©rer la section des articles rÃ©cents
    $recentArticlesContent = "## Articles rÃ©cents`n`n"
    
    foreach ($article in $recentArticles) {
        $relativePath = $article.Path.Replace($KnowledgeConfig.KnowledgeBaseFolder, ".").Replace("\", "/")
        $recentArticlesContent += "- [$($article.Title)]($relativePath) - $($article.Date)`n"
    }
    
    # Mettre Ã  jour la section des articles rÃ©cents dans l'index
    $indexContent = if ($indexContent -match "## Articles rÃ©cents\s*\n(.*?)(?=\n+##|\n*$)") {
        $indexContent -replace "## Articles rÃ©cents\s*\n(.*?)(?=\n+##|\n*$)", "$recentArticlesContent`n"
    }
    else {
        $indexContent + "`n$recentArticlesContent`n"
    }
    
    # Enregistrer l'index
    $indexContent | Set-Content -Path $KnowledgeConfig.IndexFile -Encoding UTF8
    
    # Mettre en Ã©vidence le nouvel article si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($NewArticlePath)) {
        Write-Host "Nouvel article ajoutÃ©: $NewArticlePath"
    }
    
    return $KnowledgeConfig.IndexFile
}

# Fonction pour rechercher dans la base de connaissances
function Search-KnowledgeBase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "RÃ©fÃ©rences", "Ã‰tudes de cas")]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )
    
    # Obtenir tous les articles
    $articles = @()
    
    foreach ($cat in $KnowledgeConfig.Categories) {
        if (-not [string]::IsNullOrEmpty($Category) -and $cat -ne $Category) {
            continue
        }
        
        $categoryFolder = Join-Path -Path $KnowledgeConfig.ArticlesFolder -ChildPath $cat.Replace(" ", "_")
        
        if (Test-Path -Path $categoryFolder) {
            $categoryArticles = Get-ChildItem -Path $categoryFolder -Filter "*.md"
            
            foreach ($article in $categoryArticles) {
                $content = Get-Content -Path $article.FullName -Raw
                
                # VÃ©rifier si l'article correspond aux critÃ¨res
                $match = $true
                
                if (-not [string]::IsNullOrEmpty($SearchTerm) -and $content -notmatch [regex]::Escape($SearchTerm)) {
                    $match = $false
                }
                
                # VÃ©rifier les tags
                if ($Tags.Count -gt 0) {
                    $articleTags = if ($content -match "Tags:\s*(.+)") { $Matches[1] } else { "" }
                    
                    $tagMatch = $false
                    foreach ($tag in $Tags) {
                        if ($articleTags -match [regex]::Escape($tag)) {
                            $tagMatch = $true
                            break
                        }
                    }
                    
                    if (-not $tagMatch) {
                        $match = $false
                    }
                }
                
                # VÃ©rifier les dates
                if ($StartDate -ne $null -or $EndDate -ne $null) {
                    $articleDate = if ($content -match "Date:\s*(\d{4}-\d{2}-\d{2})") { $Matches[1] } else { "" }
                    
                    if (-not [string]::IsNullOrEmpty($articleDate)) {
                        $date = [DateTime]::Parse($articleDate)
                        
                        if ($StartDate -ne $null -and $date -lt $StartDate) {
                            $match = $false
                        }
                        
                        if ($EndDate -ne $null -and $date -gt $EndDate) {
                            $match = $false
                        }
                    }
                }
                
                # Ajouter l'article aux rÃ©sultats s'il correspond
                if ($match) {
                    $title = if ($content -match "# (.+)") { $Matches[1] } else { $article.BaseName }
                    $id = if ($content -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
                    $date = if ($content -match "Date:\s*(.+)") { $Matches[1] } else { "" }
                    $author = if ($content -match "Auteur:\s*(.+)") { $Matches[1] } else { "" }
                    $tags = if ($content -match "Tags:\s*(.+)") { $Matches[1] } else { "" }
                    $summary = if ($content -match "RÃ©sumÃ©\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
                    
                    $articles += [PSCustomObject]@{
                        Title = $title
                        ID = $id
                        Category = $cat
                        Date = $date
                        Author = $author
                        Tags = $tags
                        Summary = $summary
                        Path = $article.FullName
                    }
                }
            }
        }
    }
    
    # Trier les rÃ©sultats par date
    $articles = $articles | Sort-Object -Property Date -Descending
    
    return $articles
}

# Fonction pour gÃ©nÃ©rer un rapport HTML des articles
function New-KnowledgeBaseReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de la base de connaissances",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "RÃ©fÃ©rences", "Ã‰tudes de cas")]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Rechercher les articles
    $articles = Search-KnowledgeBase -SearchTerm "" -Category $Category -Tags $Tags -StartDate $StartDate -EndDate $EndDate
    
    # DÃ©terminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "KnowledgeBaseReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .article {
            margin-bottom: 30px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .article h3 {
            margin-top: 0;
            margin-bottom: 10px;
        }
        
        .article-meta {
            font-size: 14px;
            color: #666;
            margin-bottom: 10px;
        }
        
        .article-summary {
            margin-bottom: 10px;
        }
        
        .article-link {
            display: inline-block;
            margin-top: 10px;
            color: #4caf50;
            text-decoration: none;
        }
        
        .article-link:hover {
            text-decoration: underline;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <p>Nombre total d'articles: $($articles.Count)</p>
            $(if (-not [string]::IsNullOrEmpty($Category)) { "<p>CatÃ©gorie: $Category</p>" })
            $(if ($Tags.Count -gt 0) { "<p>Tags: $($Tags -join ", ")</p>" })
            $(if ($StartDate -ne $null) { "<p>Date de dÃ©but: $($StartDate.ToString('yyyy-MM-dd'))</p>" })
            $(if ($EndDate -ne $null) { "<p>Date de fin: $($EndDate.ToString('yyyy-MM-dd'))</p>" })
        </div>
        
        <h2>Articles</h2>
        
        $(foreach ($article in $articles) {
            "<div class='article'>
                <h3>$($article.Title)</h3>
                <div class='article-meta'>
                    <span>ID: $($article.ID)</span> |
                    <span>CatÃ©gorie: $($article.Category)</span> |
                    <span>Date: $($article.Date)</span> |
                    <span>Auteur: $($article.Author)</span>
                </div>
                <div class='article-meta'>
                    <span>Tags: $($article.Tags)</span>
                </div>
                <div class='article-summary'>
                    $($article.Summary)
                </div>
                <a href='file:///$($article.Path.Replace('\', '/'))' class='article-link' target='_blank'>Lire l'article complet</a>
            </div>"
        })
        
        <div class="footer">
            <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandÃ©
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour crÃ©er un article Ã  partir d'une documentation d'erreur
function New-KnowledgeArticleFromErrorDoc {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorDocPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "RÃ©fÃ©rences", "Ã‰tudes de cas")]
        [string]$Category = "Erreurs courantes",
        
        [Parameter(Mandatory = $false)]
        [string]$AdditionalContent = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$RelatedArticles = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$References = @()
    )
    
    # VÃ©rifier si le document d'erreur existe
    if (-not (Test-Path -Path $ErrorDocPath)) {
        Write-Error "Le document d'erreur n'existe pas: $ErrorDocPath"
        return $null
    }
    
    # Charger le document d'erreur
    $errorDoc = Get-Content -Path $ErrorDocPath -Raw
    
    # Extraire les informations du document
    $title = if ($errorDoc -match "# (.+)") { $Matches[1] } else { "Article sur une erreur" }
    $id = if ($errorDoc -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
    $severity = if ($errorDoc -match "SÃ©vÃ©ritÃ©:\s*(.+)") { $Matches[1] } else { "" }
    $description = if ($errorDoc -match "Description\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    $rootCause = if ($errorDoc -match "Cause racine\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    $solution = if ($errorDoc -match "Solution\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    $preventionSteps = if ($errorDoc -match "Ã‰tapes de prÃ©vention\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    
    # GÃ©nÃ©rer le contenu de l'article
    $content = @"
## Description du problÃ¨me

$description

## Cause racine

$rootCause

## Solution

$solution

## PrÃ©vention

$preventionSteps

$AdditionalContent
"@
    
    # CrÃ©er l'article
    $article = New-KnowledgeArticle -Title $title -Category $Category -Content $content `
        -Tags $Tags -RelatedArticles $RelatedArticles -References $References -ErrorDocPath $ErrorDocPath
    
    return $article
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-KnowledgeBase, New-KnowledgeArticle, Update-KnowledgeBaseIndex, Search-KnowledgeBase
Export-ModuleMember -Function New-KnowledgeBaseReport, New-KnowledgeArticleFromErrorDoc

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
