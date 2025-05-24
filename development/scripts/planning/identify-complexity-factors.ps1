[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown")]
    [string]$Format = "Markdown"
)

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir les catÃ©gories de facteurs de complexitÃ©
$complexityFactors = @{
    "TechnicalComplexity" = @{
        "Description" = "Facteurs liÃ©s Ã  la complexitÃ© technique de l'amÃ©lioration"
        "Factors" = @(
            @{
                "Name" = "ComplexitÃ© algorithmique"
                "Description" = "ComplexitÃ© des algorithmes et des structures de donnÃ©es nÃ©cessaires"
                "Examples" = @(
                    "Algorithmes simples (boucles, conditions) = complexitÃ© faible",
                    "Algorithmes de tri ou de recherche = complexitÃ© moyenne",
                    "Algorithmes d'optimisation ou d'apprentissage = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.20
            },
            @{
                "Name" = "IntÃ©gration avec des systÃ¨mes existants"
                "Description" = "Niveau d'intÃ©gration requis avec les systÃ¨mes existants"
                "Examples" = @(
                    "Aucune intÃ©gration = complexitÃ© faible",
                    "IntÃ©gration avec un systÃ¨me interne = complexitÃ© moyenne",
                    "IntÃ©gration avec plusieurs systÃ¨mes externes = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "DÃ©pendances techniques"
                "Description" = "Nombre et complexitÃ© des dÃ©pendances techniques"
                "Examples" = @(
                    "Aucune dÃ©pendance externe = complexitÃ© faible",
                    "Quelques dÃ©pendances bien documentÃ©es = complexitÃ© moyenne",
                    "Nombreuses dÃ©pendances ou dÃ©pendances complexes = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "NouveautÃ© technologique"
                "Description" = "DegrÃ© de nouveautÃ© des technologies utilisÃ©es"
                "Examples" = @(
                    "Technologies bien maÃ®trisÃ©es = complexitÃ© faible",
                    "Technologies partiellement maÃ®trisÃ©es = complexitÃ© moyenne",
                    "Technologies nouvelles ou peu maÃ®trisÃ©es = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "SÃ©curitÃ©"
                "Description" = "Exigences de sÃ©curitÃ© associÃ©es Ã  l'amÃ©lioration"
                "Examples" = @(
                    "Aucune exigence de sÃ©curitÃ© particuliÃ¨re = complexitÃ© faible",
                    "Authentification et autorisation standard = complexitÃ© moyenne",
                    "Chiffrement, protection contre les attaques avancÃ©es = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.10
            }
        )
    },
    "FunctionalComplexity" = @{
        "Description" = "Facteurs liÃ©s Ã  la complexitÃ© fonctionnelle de l'amÃ©lioration"
        "Factors" = @(
            @{
                "Name" = "Nombre de fonctionnalitÃ©s"
                "Description" = "Nombre de fonctionnalitÃ©s Ã  implÃ©menter"
                "Examples" = @(
                    "Une seule fonctionnalitÃ© simple = complexitÃ© faible",
                    "Plusieurs fonctionnalitÃ©s liÃ©es = complexitÃ© moyenne",
                    "Nombreuses fonctionnalitÃ©s interdÃ©pendantes = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "ComplexitÃ© des rÃ¨gles mÃ©tier"
                "Description" = "ComplexitÃ© des rÃ¨gles mÃ©tier Ã  implÃ©menter"
                "Examples" = @(
                    "RÃ¨gles mÃ©tier simples et directes = complexitÃ© faible",
                    "RÃ¨gles mÃ©tier avec quelques conditions = complexitÃ© moyenne",
                    "RÃ¨gles mÃ©tier complexes avec nombreuses exceptions = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "Interface utilisateur"
                "Description" = "ComplexitÃ© de l'interface utilisateur Ã  dÃ©velopper"
                "Examples" = @(
                    "Pas d'interface utilisateur ou interface simple = complexitÃ© faible",
                    "Interface utilisateur avec quelques Ã©crans = complexitÃ© moyenne",
                    "Interface utilisateur complexe avec nombreuses interactions = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Gestion des donnÃ©es"
                "Description" = "ComplexitÃ© de la gestion des donnÃ©es"
                "Examples" = @(
                    "DonnÃ©es simples sans persistance = complexitÃ© faible",
                    "DonnÃ©es structurÃ©es avec persistance simple = complexitÃ© moyenne",
                    "DonnÃ©es complexes avec relations multiples = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Traitement asynchrone"
                "Description" = "NÃ©cessitÃ© de traitement asynchrone ou parallÃ¨le"
                "Examples" = @(
                    "Traitement synchrone uniquement = complexitÃ© faible",
                    "Quelques opÃ©rations asynchrones simples = complexitÃ© moyenne",
                    "Traitement massivement parallÃ¨le ou distribuÃ© = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.10
            }
        )
    },
    "ProjectComplexity" = @{
        "Description" = "Facteurs liÃ©s Ã  la complexitÃ© du projet"
        "Factors" = @(
            @{
                "Name" = "Taille de l'Ã©quipe"
                "Description" = "Nombre de personnes impliquÃ©es dans le dÃ©veloppement"
                "Examples" = @(
                    "Une seule personne = complexitÃ© faible",
                    "Petite Ã©quipe (2-5 personnes) = complexitÃ© moyenne",
                    "Grande Ã©quipe (plus de 5 personnes) = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Distribution gÃ©ographique"
                "Description" = "Distribution gÃ©ographique de l'Ã©quipe"
                "Examples" = @(
                    "Ã‰quipe co-localisÃ©e = complexitÃ© faible",
                    "Ã‰quipe distribuÃ©e dans un mÃªme fuseau horaire = complexitÃ© moyenne",
                    "Ã‰quipe distribuÃ©e globalement = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Contraintes de temps"
                "Description" = "Contraintes de temps pour la livraison"
                "Examples" = @(
                    "Pas de contrainte de temps stricte = complexitÃ© faible",
                    "DÃ©lai raisonnable mais fixe = complexitÃ© moyenne",
                    "DÃ©lai trÃ¨s court ou critique = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "DÃ©pendances externes"
                "Description" = "DÃ©pendances vis-Ã -vis d'Ã©quipes ou de fournisseurs externes"
                "Examples" = @(
                    "Aucune dÃ©pendance externe = complexitÃ© faible",
                    "Quelques dÃ©pendances externes bien dÃ©finies = complexitÃ© moyenne",
                    "Nombreuses dÃ©pendances externes ou mal dÃ©finies = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "CriticitÃ©"
                "Description" = "Niveau de criticitÃ© de l'amÃ©lioration pour l'entreprise"
                "Examples" = @(
                    "Faible impact en cas d'Ã©chec = complexitÃ© faible",
                    "Impact modÃ©rÃ© en cas d'Ã©chec = complexitÃ© moyenne",
                    "Impact majeur en cas d'Ã©chec = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            }
        )
    },
    "QualityComplexity" = @{
        "Description" = "Facteurs liÃ©s aux exigences de qualitÃ©"
        "Factors" = @(
            @{
                "Name" = "Exigences de performance"
                "Description" = "Niveau d'exigence en termes de performance"
                "Examples" = @(
                    "Pas d'exigence particuliÃ¨re de performance = complexitÃ© faible",
                    "Exigences de performance modÃ©rÃ©es = complexitÃ© moyenne",
                    "Exigences de performance Ã©levÃ©es ou critiques = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Exigences de fiabilitÃ©"
                "Description" = "Niveau d'exigence en termes de fiabilitÃ©"
                "Examples" = @(
                    "TolÃ©rance aux erreurs acceptable = complexitÃ© faible",
                    "Haute disponibilitÃ© requise = complexitÃ© moyenne",
                    "ZÃ©ro temps d'arrÃªt requis = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Exigences de testabilitÃ©"
                "Description" = "FacilitÃ© Ã  tester l'amÃ©lioration"
                "Examples" = @(
                    "Tests simples et directs = complexitÃ© faible",
                    "Tests nÃ©cessitant des mocks ou des stubs = complexitÃ© moyenne",
                    "Tests nÃ©cessitant des environnements complexes = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Exigences de maintenabilitÃ©"
                "Description" = "Niveau d'exigence en termes de maintenabilitÃ©"
                "Examples" = @(
                    "Code jetable ou Ã  usage unique = complexitÃ© faible",
                    "Code devant Ãªtre maintenu Ã  moyen terme = complexitÃ© moyenne",
                    "Code critique devant Ãªtre maintenu Ã  long terme = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Exigences de documentation"
                "Description" = "Niveau d'exigence en termes de documentation"
                "Examples" = @(
                    "Documentation minimale requise = complexitÃ© faible",
                    "Documentation standard requise = complexitÃ© moyenne",
                    "Documentation exhaustive requise = complexitÃ© Ã©levÃ©e"
                )
                "Weight" = 0.05
            }
        )
    }
}

# Fonction pour gÃ©nÃ©rer le document au format Markdown
function New-MarkdownDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ComplexityFactors
    )

    $markdown = "# Facteurs InfluenÃ§ant la ComplexitÃ© des AmÃ©liorations`n`n"
    $markdown += "Ce document identifie et dÃ©crit les facteurs qui influencent la complexitÃ© des amÃ©liorations logicielles. "
    $markdown += "Ces facteurs servent de base pour l'estimation de l'effort requis pour implÃ©menter les amÃ©liorations.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    
    foreach ($category in $ComplexityFactors.Keys) {
        $markdown += "- [$($ComplexityFactors[$category].Description)](#$($category.ToLower()))`n"
    }
    
    $markdown += "`n## Utilisation`n`n"
    $markdown += "Pour chaque amÃ©lioration Ã  estimer, Ã©valuez sa complexitÃ© selon chacun des facteurs listÃ©s ci-dessous. "
    $markdown += "Attribuez un score de 1 (complexitÃ© faible) Ã  5 (complexitÃ© Ã©levÃ©e) pour chaque facteur, puis calculez "
    $markdown += "un score pondÃ©rÃ© en utilisant les poids indiquÃ©s.`n`n"
    
    $markdown += "La formule gÃ©nÃ©rale est :`n`n"
    $markdown += "````n"
    $markdown += "Score de complexitÃ© = Somme(Score du facteur * Poids du facteur)`n"
    $markdown += "````n`n"
    
    foreach ($category in $ComplexityFactors.Keys) {
        $markdown += "## <a name='$($category.ToLower())'></a>$($ComplexityFactors[$category].Description)`n`n"
        
        foreach ($factor in $ComplexityFactors[$category].Factors) {
            $markdown += "### $($factor.Name) (Poids: $($factor.Weight))`n`n"
            $markdown += "$($factor.Description)`n`n"
            
            $markdown += "**Exemples :**`n`n"
            foreach ($example in $factor.Examples) {
                $markdown += "- $example`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Matrice d'Ã‰valuation`n`n"
    $markdown += "| Niveau | Description | Score |`n"
    $markdown += "|--------|-------------|-------|`n"
    $markdown += "| TrÃ¨s faible | ComplexitÃ© minimale, solution directe | 1 |`n"
    $markdown += "| Faible | ComplexitÃ© lÃ©gÃ¨rement supÃ©rieure Ã  la moyenne, quelques dÃ©fis | 2 |`n"
    $markdown += "| Moyen | ComplexitÃ© moyenne, dÃ©fis modÃ©rÃ©s | 3 |`n"
    $markdown += "| Ã‰levÃ© | ComplexitÃ© significative, dÃ©fis importants | 4 |`n"
    $markdown += "| TrÃ¨s Ã©levÃ© | ComplexitÃ© extrÃªme, dÃ©fis majeurs | 5 |`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le document au format JSON
function New-JsonDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ComplexityFactors
    )

    $jsonObject = @{
        Title = "Facteurs InfluenÃ§ant la ComplexitÃ© des AmÃ©liorations"
        Description = "Ce document identifie et dÃ©crit les facteurs qui influencent la complexitÃ© des amÃ©liorations logicielles. Ces facteurs servent de base pour l'estimation de l'effort requis pour implÃ©menter les amÃ©liorations."
        Categories = @{}
        EvaluationMatrix = @(
            @{
                Level = "TrÃ¨s faible"
                Description = "ComplexitÃ© minimale, solution directe"
                Score = 1
            },
            @{
                Level = "Faible"
                Description = "ComplexitÃ© lÃ©gÃ¨rement supÃ©rieure Ã  la moyenne, quelques dÃ©fis"
                Score = 2
            },
            @{
                Level = "Moyen"
                Description = "ComplexitÃ© moyenne, dÃ©fis modÃ©rÃ©s"
                Score = 3
            },
            @{
                Level = "Ã‰levÃ©"
                Description = "ComplexitÃ© significative, dÃ©fis importants"
                Score = 4
            },
            @{
                Level = "TrÃ¨s Ã©levÃ©"
                Description = "ComplexitÃ© extrÃªme, dÃ©fis majeurs"
                Score = 5
            }
        )
    }
    
    foreach ($category in $ComplexityFactors.Keys) {
        $jsonObject.Categories[$category] = @{
            Description = $ComplexityFactors[$category].Description
            Factors = $ComplexityFactors[$category].Factors
        }
    }
    
    return $jsonObject | ConvertTo-Json -Depth 10
}

# GÃ©nÃ©rer le document dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $documentContent = New-MarkdownDocument -ComplexityFactors $complexityFactors
    }
    "JSON" {
        $documentContent = New-JsonDocument -ComplexityFactors $complexityFactors
    }
}

# Enregistrer le document
try {
    $documentContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Document des facteurs de complexitÃ© gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du document : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des facteurs de complexitÃ© :"
Write-Host "--------------------------------"

$totalFactors = 0
foreach ($category in $complexityFactors.Keys) {
    $categoryFactors = $complexityFactors[$category].Factors.Count
    $totalFactors += $categoryFactors
    Write-Host "  $($complexityFactors[$category].Description) : $categoryFactors facteurs"
}

Write-Host "  Total : $totalFactors facteurs"

