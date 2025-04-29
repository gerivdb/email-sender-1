<#
.SYNOPSIS
    Catégorise les compétences par domaine.

.DESCRIPTION
    Ce script analyse la liste des compétences extraites et les catégorise par domaine
    (développement, sécurité, etc.) pour une meilleure organisation et analyse.

.PARAMETER SkillsListPath
    Chemin vers le fichier de la liste des compétences extraites.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la liste des compétences catégorisées.

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\categorize-skills.ps1 -SkillsListPath "data\planning\skills-list.md" -OutputPath "data\planning\skills-categorized.md"
    Catégorise les compétences par domaine et génère un fichier Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-10
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

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $SkillsListPath)) {
    Write-Error "Le fichier de la liste des compétences n'existe pas : $SkillsListPath"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour extraire les compétences de la liste Markdown
function Extract-SkillsFromList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownContent
    )

    $skills = @()
    
    # Utiliser une expression régulière pour extraire les compétences
    $skillPattern = '\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'
    
    $skillMatches = [regex]::Matches($MarkdownContent, $skillPattern)
    foreach ($skillMatch in $skillMatches) {
        $category = $skillMatch.Groups[1].Value.Trim()
        $skill = $skillMatch.Groups[2].Value.Trim()
        $level = $skillMatch.Groups[3].Value.Trim()
        $justification = $skillMatch.Groups[4].Value.Trim()
        
        # Vérifier que ce n'est pas une ligne d'en-tête de tableau
        if ($category -ne "Catégorie" -and $skill -ne "Compétence" -and $level -ne "Niveau" -and $justification -ne "Justification") {
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

# Fonction pour catégoriser les compétences par domaine
function Categorize-SkillsByDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills
    )

    # Définir les domaines et les mots-clés associés
    $domains = @{
        "Développement" = @(
            "Développement", "Programmation", "Code", "Codage", "Conception", "Architecture", 
            "Refactoring", "Tests", "Débogage", "Optimisation", "Performance", "API", 
            "Framework", "Bibliothèque", "Module", "Composant", "Fonction", "Classe", 
            "Objet", "Interface", "Implémentation", "Intégration", "Déploiement", "CI/CD",
            "PowerShell", "Python", "JavaScript", "HTML", "CSS", "SQL", "JSON", "YAML",
            "XML", "REST", "GraphQL", "SOAP", "Web", "Frontend", "Backend", "Fullstack"
        )
        "Sécurité" = @(
            "Sécurité", "Cryptographie", "Chiffrement", "Authentification", "Autorisation",
            "Identité", "Accès", "Vulnérabilité", "Menace", "Risque", "Audit", "Conformité",
            "Confidentialité", "Intégrité", "Disponibilité", "Firewall", "VPN", "SSL", "TLS",
            "HTTPS", "Certificat", "Token", "JWT", "OAuth", "SAML", "LDAP", "Active Directory",
            "Pentest", "Hacking", "Injection", "XSS", "CSRF", "SSRF", "IDOR", "RCE"
        )
        "Base de données" = @(
            "Base de données", "SQL", "NoSQL", "Relationnel", "Document", "Clé-valeur",
            "Graphe", "Colonne", "Table", "Requête", "Index", "Transaction", "ACID",
            "Normalisation", "Dénormalisation", "Jointure", "Agrégation", "Projection",
            "Sélection", "Insertion", "Mise à jour", "Suppression", "Migration", "Schéma",
            "Modèle", "ORM", "JDBC", "ODBC", "ADO.NET", "Entity Framework", "Hibernate",
            "SQLAlchemy", "MongoDB", "PostgreSQL", "MySQL", "SQL Server", "Oracle", "Redis"
        )
        "Infrastructure" = @(
            "Infrastructure", "Serveur", "Client", "Réseau", "Cloud", "Virtualisation",
            "Conteneur", "Docker", "Kubernetes", "Orchestration", "Automatisation",
            "Provisionnement", "Configuration", "Déploiement", "Scalabilité", "Haute disponibilité",
            "Résilience", "Tolérance aux pannes", "Reprise après sinistre", "Sauvegarde",
            "Restauration", "Monitoring", "Logging", "Alerting", "Métriques", "Télémétrie",
            "DevOps", "SRE", "IaC", "Terraform", "Ansible", "Chef", "Puppet", "AWS", "Azure", "GCP"
        )
        "Gestion de projet" = @(
            "Gestion de projet", "Agile", "Scrum", "Kanban", "Waterfall", "Sprint", "Backlog",
            "User Story", "Tâche", "Estimation", "Planification", "Priorisation", "Roadmap",
            "Milestone", "Livrable", "Deadline", "Échéance", "Réunion", "Revue", "Rétrospective",
            "Stand-up", "Coordination", "Collaboration", "Communication", "Documentation",
            "Rapport", "Suivi", "Mesure", "KPI", "Métrique", "Objectif", "SMART", "ROI"
        )
        "Analyse et conception" = @(
            "Analyse", "Conception", "Modélisation", "UML", "Diagramme", "Cas d'utilisation",
            "User Story", "Exigence", "Spécification", "Fonctionnalité", "Non-fonctionnel",
            "Qualité", "Performance", "Scalabilité", "Maintenabilité", "Testabilité",
            "Réutilisabilité", "Extensibilité", "Modularité", "Couplage", "Cohésion",
            "Abstraction", "Encapsulation", "Héritage", "Polymorphisme", "Interface",
            "Design Pattern", "Architecture", "Microservices", "Monolithique", "SOA", "DDD"
        )
        "Tests et qualité" = @(
            "Test", "Qualité", "Assurance qualité", "Contrôle qualité", "Validation",
            "Vérification", "Unitaire", "Intégration", "Système", "Acceptation", "Fonctionnel",
            "Non-fonctionnel", "Performance", "Charge", "Stress", "Endurance", "Sécurité",
            "Régression", "Smoke", "Sanity", "Exploratoire", "Automatisation", "Manuel",
            "TDD", "BDD", "ATDD", "Mocking", "Stubbing", "Assertion", "Coverage", "Mutation",
            "Revue de code", "Inspection", "Audit", "Bug", "Défaut", "Erreur", "Anomalie"
        )
    }
    
    # Fonction pour déterminer le domaine d'une compétence
    function Get-SkillDomain {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Skill,
            
            [Parameter(Mandatory = $true)]
            [string]$Category,
            
            [Parameter(Mandatory = $true)]
            [string]$Justification
        )
        
        # Combiner les informations pour une meilleure détection
        $combinedText = "$Skill $Category $Justification"
        
        # Vérifier chaque domaine
        foreach ($domain in $domains.Keys) {
            foreach ($keyword in $domains[$domain]) {
                if ($combinedText -match $keyword) {
                    return $domain
                }
            }
        }
        
        # Si aucun domaine n'est détecté, utiliser la catégorie comme domaine
        return $Category
    }
    
    # Catégoriser chaque compétence
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

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CategorizedSkills
    )

    $markdown = "# Compétences Catégorisées par Domaine`n`n"
    $markdown += "Ce document présente les compétences requises catégorisées par domaine pour une meilleure organisation et analyse.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    $domains = $CategorizedSkills | Select-Object -Property Domain -Unique | Sort-Object -Property Domain
    
    foreach ($domain in $domains) {
        $markdown += "- [$($domain.Domain)](#$($domain.Domain.ToLower().Replace(' ', '-').Replace('é', 'e').Replace('è', 'e').Replace('à', 'a')))`n"
    }
    
    $markdown += "- [Résumé](#résumé)`n"
    
    # Compétences par domaine
    foreach ($domain in $domains) {
        $markdown += "`n## <a name='$($domain.Domain.ToLower().Replace(' ', '-').Replace('é', 'e').Replace('è', 'e').Replace('à', 'a'))'></a>$($domain.Domain)`n`n"
        
        $domainSkills = $CategorizedSkills | Where-Object { $_.Domain -eq $domain.Domain }
        $categories = $domainSkills | Select-Object -Property Category -Unique | Sort-Object -Property Category
        
        foreach ($category in $categories) {
            $markdown += "### $($category.Category)`n`n"
            $markdown += "| Compétence | Niveau | Justification |`n"
            $markdown += "|------------|--------|---------------|`n"
            
            $categorySkills = $domainSkills | Where-Object { $_.Category -eq $category.Category } | Sort-Object -Property Skill
            
            foreach ($skill in $categorySkills) {
                $markdown += "| $($skill.Skill) | $($skill.Level) | $($skill.Justification) |`n"
            }
            
            $markdown += "`n"
        }
    }
    
    # Résumé
    $markdown += "## <a name='résumé'></a>Résumé`n`n"
    
    $totalSkills = $CategorizedSkills.Count
    $uniqueSkills = $CategorizedSkills | Select-Object -Property Skill -Unique | Measure-Object | Select-Object -ExpandProperty Count
    
    $markdown += "**Nombre total de compétences :** $totalSkills`n`n"
    $markdown += "**Nombre de compétences uniques :** $uniqueSkills`n`n"
    
    $markdown += "### Répartition par Domaine`n`n"
    $markdown += "| Domaine | Nombre de Compétences | Pourcentage |`n"
    $markdown += "|---------|----------------------|-------------|`n"
    
    $domainCounts = $CategorizedSkills | Group-Object -Property Domain | Sort-Object -Property Count -Descending
    
    foreach ($domainCount in $domainCounts) {
        $percentage = [Math]::Round(($domainCount.Count / $totalSkills) * 100, 1)
        $markdown += "| $($domainCount.Name) | $($domainCount.Count) | $percentage% |`n"
    }
    
    $markdown += "`n### Répartition par Niveau d'Expertise`n`n"
    $markdown += "| Niveau | Nombre de Compétences | Pourcentage |`n"
    $markdown += "|--------|----------------------|-------------|`n"
    
    $levelCounts = $CategorizedSkills | Group-Object -Property Level | Sort-Object -Property Count -Descending
    
    foreach ($levelCount in $levelCounts) {
        $percentage = [Math]::Round(($levelCount.Count / $totalSkills) * 100, 1)
        $markdown += "| $($levelCount.Name) | $($levelCount.Count) | $percentage% |`n"
    }
    
    $markdown += "`n### Compétences les Plus Demandées`n`n"
    $markdown += "| Compétence | Domaine | Occurrences | Pourcentage |`n"
    $markdown += "|------------|---------|-------------|-------------|`n"
    
    $skillCounts = $CategorizedSkills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 10
    
    foreach ($skillCount in $skillCounts) {
        $percentage = [Math]::Round(($skillCount.Count / $totalSkills) * 100, 1)
        $domain = ($CategorizedSkills | Where-Object { $_.Skill -eq $skillCount.Name } | Select-Object -First 1).Domain
        $markdown += "| $($skillCount.Name) | $domain | $($skillCount.Count) | $percentage% |`n"
    }
    
    return $markdown
}

# Fonction pour générer le rapport au format CSV
function Generate-CsvReport {
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

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
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

# Lire le contenu de la liste des compétences
$listContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compétences de la liste
$skills = Extract-SkillsFromList -MarkdownContent $listContent

# Catégoriser les compétences par domaine
$categorizedSkills = Categorize-SkillsByDomain -Skills $skills

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -CategorizedSkills $categorizedSkills
    }
    "CSV" {
        $reportContent = Generate-CsvReport -CategorizedSkills $categorizedSkills
    }
    "JSON" {
        $reportContent = Generate-JsonReport -CategorizedSkills $categorizedSkills
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Compétences catégorisées avec succès : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de la catégorisation des compétences :"
Write-Host "------------------------------------------"

$totalSkills = $categorizedSkills.Count
$uniqueSkills = $categorizedSkills | Select-Object -Property Skill -Unique | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "  Nombre total de compétences : $totalSkills"
Write-Host "  Nombre de compétences uniques : $uniqueSkills"

$domains = $categorizedSkills | Group-Object -Property Domain | Sort-Object -Property Count -Descending

Write-Host "`nRépartition par domaine :"
foreach ($domain in $domains) {
    $percentage = [Math]::Round(($domain.Count / $totalSkills) * 100, 1)
    Write-Host "  $($domain.Name) : $($domain.Count) compétences ($percentage%)"
}

$levels = $categorizedSkills | Group-Object -Property Level | Sort-Object -Property Count -Descending

Write-Host "`nRépartition par niveau d'expertise :"
foreach ($level in $levels) {
    $percentage = [Math]::Round(($level.Count / $totalSkills) * 100, 1)
    Write-Host "  $($level.Name) : $($level.Count) compétences ($percentage%)"
}
