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
    
    # Catégories d'articles
    Categories = @(
        "Erreurs courantes",
        "Bonnes pratiques",
        "Tutoriels",
        "Références",
        "Études de cas"
    )
}

# Fonction pour initialiser la base de connaissances
function Initialize-KnowledgeBase {
    param (
        [Parameter(Mandatory = $false)]
        [string]$KnowledgeBaseFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ArticlesFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ResourcesFolder = ""
    )
    
    # Mettre à jour la configuration
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
    
    # Créer les dossiers s'ils n'existent pas
    foreach ($folder in @($KnowledgeConfig.KnowledgeBaseFolder, $KnowledgeConfig.ArticlesFolder, $KnowledgeConfig.ResourcesFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    # Créer les dossiers de catégories
    foreach ($category in $KnowledgeConfig.Categories) {
        $categoryFolder = Join-Path -Path $KnowledgeConfig.ArticlesFolder -ChildPath $category.Replace(" ", "_")
        if (-not (Test-Path -Path $categoryFolder)) {
            New-Item -Path $categoryFolder -ItemType Directory -Force | Out-Null
        }
    }
    
    # Créer le fichier d'index s'il n'existe pas
    if (-not (Test-Path -Path $KnowledgeConfig.IndexFile)) {
        $indexContent = @"
# Base de connaissances des erreurs

Cette base de connaissances contient des articles, des tutoriels et des références sur les erreurs courantes et leur résolution.

## Catégories

$(foreach ($category in $KnowledgeConfig.Categories) {
    "- [$category](./$($category.Replace(" ", "_")))`n"
})

## Articles récents

## Articles populaires

## Recherche

Utilisez la fonction de recherche pour trouver des articles spécifiques.
"@
        
        $indexContent | Set-Content -Path $KnowledgeConfig.IndexFile -Encoding UTF8
    }
    
    # Initialiser le module de documentation des erreurs
    Initialize-ErrorDocumentation
    
    return $KnowledgeConfig
}

# Fonction pour créer un nouvel article
function New-KnowledgeArticle {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "Références", "Études de cas")]
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
    
    # Générer un ID unique
    $id = [Guid]::NewGuid().ToString().Substring(0, 8).ToUpper()
    
    # Formater le titre pour le nom de fichier
    $fileName = "$id-$($Title -replace '[^\w\-]', '_').md"
    
    # Déterminer le dossier de catégorie
    $categoryFolder = Join-Path -Path $KnowledgeConfig.ArticlesFolder -ChildPath $Category.Replace(" ", "_")
    
    # Déterminer le chemin de l'article
    $articlePath = Join-Path -Path $categoryFolder -ChildPath $fileName
    
    # Utiliser le résumé fourni ou générer un résumé à partir du contenu
    if ([string]::IsNullOrEmpty($Summary)) {
        $Summary = $Content.Substring(0, [Math]::Min(200, $Content.Length)) + "..."
    }
    
    # Générer le contenu de l'article
    $articleContent = @"
# $Title

- **ID**: $id
- **Catégorie**: $Category
- **Date**: $(Get-Date -Format "yyyy-MM-dd")
- **Auteur**: $Author
- **Tags**: $(if ($Tags.Count -gt 0) { $Tags -join ", " } else { "Aucun" })

## Résumé

$Summary

## Contenu

$Content

$(if ($RelatedArticles.Count -gt 0) {
    "## Articles connexes`n`n" + ($RelatedArticles | ForEach-Object { "- $_`n" })
} else { "" })

$(if ($References.Count -gt 0) {
    "## Références`n`n" + ($References | ForEach-Object { "- $_`n" })
} else { "" })

$(if (-not [string]::IsNullOrEmpty($ErrorDocPath)) {
    "## Documentation d'erreur associée`n`n[Voir la documentation d'erreur]($ErrorDocPath)`n"
} else { "" })

---
Dernière mise à jour: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    # Enregistrer l'article
    $articleContent | Set-Content -Path $articlePath -Encoding UTF8
    
    # Mettre à jour l'index
    Update-KnowledgeBaseIndex -NewArticlePath $articlePath
    
    return @{
        ID = $id
        Title = $Title
        Category = $Category
        Path = $articlePath
    }
}

# Fonction pour mettre à jour l'index de la base de connaissances
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
                $summary = if ($content -match "Résumé\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
                
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
    
    # Trier les articles par date (les plus récents en premier)
    $recentArticles = $articles | Sort-Object -Property Date -Descending | Select-Object -First 5
    
    # Générer la section des articles récents
    $recentArticlesContent = "## Articles récents`n`n"
    
    foreach ($article in $recentArticles) {
        $relativePath = $article.Path.Replace($KnowledgeConfig.KnowledgeBaseFolder, ".").Replace("\", "/")
        $recentArticlesContent += "- [$($article.Title)]($relativePath) - $($article.Date)`n"
    }
    
    # Mettre à jour la section des articles récents dans l'index
    $indexContent = if ($indexContent -match "## Articles récents\s*\n(.*?)(?=\n+##|\n*$)") {
        $indexContent -replace "## Articles récents\s*\n(.*?)(?=\n+##|\n*$)", "$recentArticlesContent`n"
    }
    else {
        $indexContent + "`n$recentArticlesContent`n"
    }
    
    # Enregistrer l'index
    $indexContent | Set-Content -Path $KnowledgeConfig.IndexFile -Encoding UTF8
    
    # Mettre en évidence le nouvel article si spécifié
    if (-not [string]::IsNullOrEmpty($NewArticlePath)) {
        Write-Host "Nouvel article ajouté: $NewArticlePath"
    }
    
    return $KnowledgeConfig.IndexFile
}

# Fonction pour rechercher dans la base de connaissances
function Search-KnowledgeBase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "Références", "Études de cas")]
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
                
                # Vérifier si l'article correspond aux critères
                $match = $true
                
                if (-not [string]::IsNullOrEmpty($SearchTerm) -and $content -notmatch [regex]::Escape($SearchTerm)) {
                    $match = $false
                }
                
                # Vérifier les tags
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
                
                # Vérifier les dates
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
                
                # Ajouter l'article aux résultats s'il correspond
                if ($match) {
                    $title = if ($content -match "# (.+)") { $Matches[1] } else { $article.BaseName }
                    $id = if ($content -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
                    $date = if ($content -match "Date:\s*(.+)") { $Matches[1] } else { "" }
                    $author = if ($content -match "Auteur:\s*(.+)") { $Matches[1] } else { "" }
                    $tags = if ($content -match "Tags:\s*(.+)") { $Matches[1] } else { "" }
                    $summary = if ($content -match "Résumé\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
                    
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
    
    # Trier les résultats par date
    $articles = $articles | Sort-Object -Property Date -Descending
    
    return $articles
}

# Fonction pour générer un rapport HTML des articles
function New-KnowledgeBaseReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de la base de connaissances",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "Références", "Études de cas")]
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
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "KnowledgeBaseReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Générer le HTML
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
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <p>Nombre total d'articles: $($articles.Count)</p>
            $(if (-not [string]::IsNullOrEmpty($Category)) { "<p>Catégorie: $Category</p>" })
            $(if ($Tags.Count -gt 0) { "<p>Tags: $($Tags -join ", ")</p>" })
            $(if ($StartDate -ne $null) { "<p>Date de début: $($StartDate.ToString('yyyy-MM-dd'))</p>" })
            $(if ($EndDate -ne $null) { "<p>Date de fin: $($EndDate.ToString('yyyy-MM-dd'))</p>" })
        </div>
        
        <h2>Articles</h2>
        
        $(foreach ($article in $articles) {
            "<div class='article'>
                <h3>$($article.Title)</h3>
                <div class='article-meta'>
                    <span>ID: $($article.ID)</span> |
                    <span>Catégorie: $($article.Category)</span> |
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
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour créer un article à partir d'une documentation d'erreur
function New-KnowledgeArticleFromErrorDoc {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorDocPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs courantes", "Bonnes pratiques", "Tutoriels", "Références", "Études de cas")]
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
    
    # Vérifier si le document d'erreur existe
    if (-not (Test-Path -Path $ErrorDocPath)) {
        Write-Error "Le document d'erreur n'existe pas: $ErrorDocPath"
        return $null
    }
    
    # Charger le document d'erreur
    $errorDoc = Get-Content -Path $ErrorDocPath -Raw
    
    # Extraire les informations du document
    $title = if ($errorDoc -match "# (.+)") { $Matches[1] } else { "Article sur une erreur" }
    $id = if ($errorDoc -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
    $severity = if ($errorDoc -match "Sévérité:\s*(.+)") { $Matches[1] } else { "" }
    $description = if ($errorDoc -match "Description\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    $rootCause = if ($errorDoc -match "Cause racine\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    $solution = if ($errorDoc -match "Solution\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    $preventionSteps = if ($errorDoc -match "Étapes de prévention\s*\n+(.+?)(?=\n+##|\n*$)") { $Matches[1].Trim() } else { "" }
    
    # Générer le contenu de l'article
    $content = @"
## Description du problème

$description

## Cause racine

$rootCause

## Solution

$solution

## Prévention

$preventionSteps

$AdditionalContent
"@
    
    # Créer l'article
    $article = New-KnowledgeArticle -Title $title -Category $Category -Content $content `
        -Tags $Tags -RelatedArticles $RelatedArticles -References $References -ErrorDocPath $ErrorDocPath
    
    return $article
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-KnowledgeBase, New-KnowledgeArticle, Update-KnowledgeBaseIndex, Search-KnowledgeBase
Export-ModuleMember -Function New-KnowledgeBaseReport, New-KnowledgeArticleFromErrorDoc
