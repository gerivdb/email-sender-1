<#
.SYNOPSIS
    CatÃ©gorise les compÃ©tences par domaine.

.DESCRIPTION
    Ce script analyse la liste des compÃ©tences extraites et les catÃ©gorise par domaine
    (dÃ©veloppement, sÃ©curitÃ©, etc.) pour une meilleure organisation et analyse.

.PARAMETER SkillsListPath
    Chemin vers le fichier de la liste des compÃ©tences extraites.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la liste des compÃ©tences catÃ©gorisÃ©es.

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\categorize-skills.ps1 -SkillsListPath "data\planning\skills-list.md" -OutputPath "data\planning\skills-categorized.md"
    CatÃ©gorise les compÃ©tences par domaine et gÃ©nÃ¨re un fichier Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-10
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SkillsListPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Markdown")]
    [string]$Format = "Markdown"
)

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $SkillsListPath)) {
    Write-Error "Le fichier de la liste des compÃ©tences n'existe pas : $SkillsListPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour extraire les compÃ©tences de la liste Markdown
function Export-SkillsFromList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownContent
    )

    $skills = @()
    
    # Utiliser une expression rÃ©guliÃ¨re pour extraire les compÃ©tences
    $skillPattern = '\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'
    
    $skillMatches = [regex]::Matches($MarkdownContent, $skillPattern)
    foreach ($skillMatch in $skillMatches) {
        $category = $skillMatch.Groups[1].Value.Trim()
        $skill = $skillMatch.Groups[2].Value.Trim()
        $level = $skillMatch.Groups[3].Value.Trim()
        $justification = $skillMatch.Groups[4].Value.Trim()
        
        # VÃ©rifier que ce n'est pas une ligne d'en-tÃªte de tableau
        if ($category -ne "CatÃ©gorie" -and $skill -ne "CompÃ©tence" -and $level -ne "Niveau" -and $justification -ne "Justification") {
            $skills += [PSCustomObject]@{
                Category = $category
                Skill = $skill
                Level = $level
                Justification = $justification
            }
        }
    }
    
    return $skills
}

# Fonction pour catÃ©goriser les compÃ©tences par domaine
function Group-SkillsByDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills
    )

    # DÃ©finir les domaines et les mots-clÃ©s associÃ©s
    $domains = @{
        "DÃ©veloppement" = @(
            "DÃ©veloppement", "Programmation", "Code", "Codage", "Conception", "Architecture", 
            "Refactoring", "Tests", "DÃ©bogage", "Optimisation", "Performance", "API", 
            "Framework", "BibliothÃ¨que", "Module", "Composant", "Fonction", "Classe", 
            "Objet", "Interface", "ImplÃ©mentation", "IntÃ©gration", "DÃ©ploiement", "CI/CD",
            "PowerShell", "Python", "JavaScript", "HTML", "CSS", "SQL", "JSON", "YAML",
            "XML", "REST", "GraphQL", "SOAP", "Web", "Frontend", "Backend", "Fullstack"
        )
        "SÃ©curitÃ©" = @(
            "SÃ©curitÃ©", "Cryptographie", "Chiffrement", "Authentification", "Autorisation",
            "IdentitÃ©", "AccÃ¨s", "VulnÃ©rabilitÃ©", "Menace", "Risque", "Audit", "ConformitÃ©",
            "ConfidentialitÃ©", "IntÃ©gritÃ©", "DisponibilitÃ©", "Firewall", "VPN", "SSL", "TLS",
            "HTTPS", "Certificat", "Token", "JWT", "OAuth", "SAML", "LDAP", "Active Directory",
            "Pentest", "Hacking", "Injection", "XSS", "CSRF", "SSRF", "IDOR", "RCE"
        )
        "Base de donnÃ©es" = @(
            "Base de donnÃ©es", "SQL", "NoSQL", "Relationnel", "Document", "ClÃ©-valeur",
            "Graphe", "Colonne", "Table", "RequÃªte", "Index", "Transaction", "ACID",
            "Normalisation", "DÃ©normalisation", "Jointure", "AgrÃ©gation", "Projection",
            "SÃ©lection", "Insertion", "Mise Ã  jour", "Suppression", "Migration", "SchÃ©ma",
            "ModÃ¨le", "ORM", "JDBC", "ODBC", "ADO.NET", "Entity Framework", "Hibernate",
            "SQLAlchemy", "MongoDB", "PostgreSQL", "MySQL", "SQL Server", "Oracle", "Redis"
        )
        "Infrastructure" = @(
            "Infrastructure", "Serveur", "Client", "RÃ©seau", "Cloud", "Virtualisation",
            "Conteneur", "Docker", "Kubernetes", "Orchestration", "Automatisation",
            "Provisionnement", "Configuration", "DÃ©ploiement", "ScalabilitÃ©", "Haute disponibilitÃ©",
            "RÃ©silience", "TolÃ©rance aux pannes", "Reprise aprÃ¨s sinistre", "Sauvegarde",
            "Restauration", "Monitoring", "Logging", "Alerting", "MÃ©triques", "TÃ©lÃ©mÃ©trie",
            "DevOps", "SRE", "IaC", "Terraform", "Ansible", "Chef", "Puppet", "AWS", "Azure", "GCP"
        )
        "Gestion de projet" = @(
            "Gestion de projet", "Agile", "Scrum", "Kanban", "Waterfall", "Sprint", "Backlog",
            "User Story", "TÃ¢che", "Estimation", "Planification", "Priorisation", "Roadmap",
            "Milestone", "Livrable", "Deadline", "Ã‰chÃ©ance", "RÃ©union", "Revue", "RÃ©trospective",
            "Stand-up", "Coordination", "Collaboration", "Communication", "Documentation",
            "Rapport", "Suivi", "Mesure", "KPI", "MÃ©trique", "Objectif", "SMART", "ROI"
        )
        "Analyse et conception" = @(
            "Analyse", "Conception", "ModÃ©lisation", "UML", "Diagramme", "Cas d'utilisation",
            "User Story", "Exigence", "SpÃ©cification", "FonctionnalitÃ©", "Non-fonctionnel",
            "QualitÃ©", "Performance", "ScalabilitÃ©", "MaintenabilitÃ©", "TestabilitÃ©",
            "RÃ©utilisabilitÃ©", "ExtensibilitÃ©", "ModularitÃ©", "Couplage", "CohÃ©sion",
            "Abstraction", "Encapsulation", "HÃ©ritage", "Polymorphisme", "Interface",
            "Design Pattern", "Architecture", "Microservices", "Monolithique", "SOA", "DDD"
        )
        "Tests et qualitÃ©" = @(
            "Test", "QualitÃ©", "Assurance qualitÃ©", "ContrÃ´le qualitÃ©", "Validation",
            "VÃ©rification", "Unitaire", "IntÃ©gration", "SystÃ¨me", "Acceptation", "Fonctionnel",
            "Non-fonctionnel", "Performance", "Charge", "Stress", "Endurance", "SÃ©curitÃ©",
            "RÃ©gression", "Smoke", "Sanity", "Exploratoire", "Automatisation", "Manuel",
            "TDD", "BDD", "ATDD", "Mocking", "Stubbing", "Assertion", "Coverage", "Mutation",
            "Revue de code", "Inspection", "Audit", "Bug", "DÃ©faut", "Erreur", "Anomalie"
        )
    }
    
    # Fonction pour dÃ©terminer le domaine d'une compÃ©tence
    function Get-SkillDomain {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Skill,
            
            [Parameter(Mandatory = $true)]
            [string]$Category,
            
            [Parameter(Mandatory = $true)]
            [string]$Justification
        )
        
        # Combiner les informations pour une meilleure dÃ©tection
        $combinedText = "$Skill $Category $Justification"
        
        # VÃ©rifier chaque domaine
        foreach ($domain in $domains.Keys) {
            foreach ($keyword in $domains[$domain]) {
                if ($combinedText -match $keyword) {
                    return $domain
                }
            }
        }
        
        # Si aucun domaine n'est dÃ©tectÃ©, utiliser la catÃ©gorie comme domaine
        return $Category
    }
    
    # CatÃ©goriser chaque compÃ©tence
    $categorizedSkills = $Skills | ForEach-Object {
        $domain = Get-SkillDomain -Skill $_.Skill -Category $_.Category -Justification $_.Justification
        
        [PSCustomObject]@{
            Domain = $domain
            Category = $_.Category
            Skill = $_.Skill
            Level = $_.Level
            Justification = $_.Justification
        }
    }
    
    return $categorizedSkills
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function New-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CategorizedSkills
    )

    $markdown = "# CompÃ©tences CatÃ©gorisÃ©es par Domaine`n`n"
    $markdown += "Ce document prÃ©sente les compÃ©tences requises catÃ©gorisÃ©es par domaine pour une meilleure organisation et analyse.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    
    $domains = $CategorizedSkills | Select-Object -Property Domain -Unique | Sort-Object -Property Domain
    
    foreach ($domain in $domains) {
        $markdown += "- [$($domain.Domain)](#$($domain.Domain.ToLower().Replace(' ', '-').Replace('Ã©', 'e').Replace('Ã¨', 'e').Replace('Ã ', 'a')))`n"
    }
    
    $markdown += "- [RÃ©sumÃ©](#rÃ©sumÃ©)`n"
    
    # CompÃ©tences par domaine
    foreach ($domain in $domains) {
        $markdown += "`n## <a name='$($domain.Domain.ToLower().Replace(' ', '-').Replace('Ã©', 'e').Replace('Ã¨', 'e').Replace('Ã ', 'a'))'></a>$($domain.Domain)`n`n"
        
        $domainSkills = $CategorizedSkills | Where-Object { $_.Domain -eq $domain.Domain }
        $categories = $domainSkills | Select-Object -Property Category -Unique | Sort-Object -Property Category
        
        foreach ($category in $categories) {
            $markdown += "### $($category.Category)`n`n"
            $markdown += "| CompÃ©tence | Niveau | Justification |`n"
            $markdown += "|------------|--------|---------------|`n"
            
            $categorySkills = $domainSkills | Where-Object { $_.Category -eq $category.Category } | Sort-Object -Property Skill
            
            foreach ($skill in $categorySkills) {
                $markdown += "| $($skill.Skill) | $($skill.Level) | $($skill.Justification) |`n"
            }
            
            $markdown += "`n"
        }
    }
    
    # RÃ©sumÃ©
    $markdown += "## <a name='rÃ©sumÃ©'></a>RÃ©sumÃ©`n`n"
    
    $totalSkills = $CategorizedSkills.Count
    $uniqueSkills = $CategorizedSkills | Select-Object -Property Skill -Unique | Measure-Object | Select-Object -ExpandProperty Count
    
    $markdown += "**Nombre total de compÃ©tences :** $totalSkills`n`n"
    $markdown += "**Nombre de compÃ©tences uniques :** $uniqueSkills`n`n"
    
    $markdown += "### RÃ©partition par Domaine`n`n"
    $markdown += "| Domaine | Nombre de CompÃ©tences | Pourcentage |`n"
    $markdown += "|---------|----------------------|-------------|`n"
    
    $domainCounts = $CategorizedSkills | Group-Object -Property Domain | Sort-Object -Property Count -Descending
    
    foreach ($domainCount in $domainCounts) {
        $percentage = [Math]::Round(($domainCount.Count / $totalSkills) * 100, 1)
        $markdown += "| $($domainCount.Name) | $($domainCount.Count) | $percentage% |`n"
    }
    
    $markdown += "`n### RÃ©partition par Niveau d'Expertise`n`n"
    $markdown += "| Niveau | Nombre de CompÃ©tences | Pourcentage |`n"
    $markdown += "|--------|----------------------|-------------|`n"
    
    $levelCounts = $CategorizedSkills | Group-Object -Property Level | Sort-Object -Property Count -Descending
    
    foreach ($levelCount in $levelCounts) {
        $percentage = [Math]::Round(($levelCount.Count / $totalSkills) * 100, 1)
        $markdown += "| $($levelCount.Name) | $($levelCount.Count) | $percentage% |`n"
    }
    
    $markdown += "`n### CompÃ©tences les Plus DemandÃ©es`n`n"
    $markdown += "| CompÃ©tence | Domaine | Occurrences | Pourcentage |`n"
    $markdown += "|------------|---------|-------------|-------------|`n"
    
    $skillCounts = $CategorizedSkills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 10
    
    foreach ($skillCount in $skillCounts) {
        $percentage = [Math]::Round(($skillCount.Count / $totalSkills) * 100, 1)
        $domain = ($CategorizedSkills | Where-Object { $_.Skill -eq $skillCount.Name } | Select-Object -First 1).Domain
        $markdown += "| $($skillCount.Name) | $domain | $($skillCount.Count) | $percentage% |`n"
    }
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function New-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CategorizedSkills
    )

    $csv = "Domain,Category,Skill,Level,Justification`n"
    
    foreach ($skill in $CategorizedSkills) {
        $csv += "$($skill.Domain),$($skill.Category),$($skill.Skill),$($skill.Level),$($skill.Justification)`n"
    }
    
    return $csv
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function New-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CategorizedSkills
    )

    $totalSkills = $CategorizedSkills.Count
    $uniqueSkills = $CategorizedSkills | Select-Object -Property Skill -Unique | Measure-Object | Select-Object -ExpandProperty Count
    
    $domainCounts = $CategorizedSkills | Group-Object -Property Domain | Sort-Object -Property Count -Descending | ForEach-Object {
        $percentage = [Math]::Round(($_.Count / $totalSkills) * 100, 1)
        
        [PSCustomObject]@{
            Domain = $_.Name
            Count = $_.Count
            Percentage = $percentage
        }
    }
    
    $levelCounts = $CategorizedSkills | Group-Object -Property Level | Sort-Object -Property Count -Descending | ForEach-Object {
        $percentage = [Math]::Round(($_.Count / $totalSkills) * 100, 1)
        
        [PSCustomObject]@{
            Level = $_.Name
            Count = $_.Count
            Percentage = $percentage
        }
    }
    
    $skillCounts = $CategorizedSkills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 10 | ForEach-Object {
        $percentage = [Math]::Round(($_.Count / $totalSkills) * 100, 1)
        $domain = ($CategorizedSkills | Where-Object { $_.Skill -eq $_.Name } | Select-Object -First 1).Domain
        
        [PSCustomObject]@{
            Skill = $_.Name
            Domain = $domain
            Count = $_.Count
            Percentage = $percentage
        }
    }
    
    $domains = $CategorizedSkills | Select-Object -Property Domain -Unique | Sort-Object -Property Domain | ForEach-Object {
        $domainName = $_.Domain
        $domainSkills = $CategorizedSkills | Where-Object { $_.Domain -eq $domainName }
        $categories = $domainSkills | Select-Object -Property Category -Unique | Sort-Object -Property Category | ForEach-Object {
            $categoryName = $_.Category
            $categorySkills = $domainSkills | Where-Object { $_.Category -eq $categoryName } | Sort-Object -Property Skill
            
            [PSCustomObject]@{
                Category = $categoryName
                Skills = $categorySkills
            }
        }
        
        [PSCustomObject]@{
            Domain = $domainName
            Categories = $categories
        }
    }
    
    $jsonData = [PSCustomObject]@{
        Summary = [PSCustomObject]@{
            TotalSkills = $totalSkills
            UniqueSkills = $uniqueSkills
            DomainDistribution = $domainCounts
            LevelDistribution = $levelCounts
            TopSkills = $skillCounts
        }
        Domains = $domains
    }
    
    return $jsonData | ConvertTo-Json -Depth 10
}

# Lire le contenu de la liste des compÃ©tences
$listContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compÃ©tences de la liste
$skills = Export-SkillsFromList -MarkdownContent $listContent

# CatÃ©goriser les compÃ©tences par domaine
$categorizedSkills = Group-SkillsByDomain -Skills $skills

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = New-MarkdownReport -CategorizedSkills $categorizedSkills
    }
    "CSV" {
        $reportContent = New-CsvReport -CategorizedSkills $categorizedSkills
    }
    "JSON" {
        $reportContent = New-JsonReport -CategorizedSkills $categorizedSkills
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "CompÃ©tences catÃ©gorisÃ©es avec succÃ¨s : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de la catÃ©gorisation des compÃ©tences :"
Write-Host "------------------------------------------"

$totalSkills = $categorizedSkills.Count
$uniqueSkills = $categorizedSkills | Select-Object -Property Skill -Unique | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "  Nombre total de compÃ©tences : $totalSkills"
Write-Host "  Nombre de compÃ©tences uniques : $uniqueSkills"

$domains = $categorizedSkills | Group-Object -Property Domain | Sort-Object -Property Count -Descending

Write-Host "`nRÃ©partition par domaine :"
foreach ($domain in $domains) {
    $percentage = [Math]::Round(($domain.Count / $totalSkills) * 100, 1)
    Write-Host "  $($domain.Name) : $($domain.Count) compÃ©tences ($percentage%)"
}

$levels = $categorizedSkills | Group-Object -Property Level | Sort-Object -Property Count -Descending

Write-Host "`nRÃ©partition par niveau d'expertise :"
foreach ($level in $levels) {
    $percentage = [Math]::Round(($level.Count / $totalSkills) * 100, 1)
    Write-Host "  $($level.Name) : $($level.Count) compÃ©tences ($percentage%)"
}


