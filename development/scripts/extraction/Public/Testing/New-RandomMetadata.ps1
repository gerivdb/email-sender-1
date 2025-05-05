<#
.SYNOPSIS
    Génère des métadonnées aléatoires réalistes pour les tests.

.DESCRIPTION
    Cette fonction génère des métadonnées aléatoires réalistes qui peuvent être utilisées
    pour les tests de performance et de fonctionnalité du module d'extraction.
    Elle permet de personnaliser les champs, la distribution et d'autres caractéristiques des métadonnées.

.PARAMETER Fields
    Liste des champs de métadonnées à générer. Si non spécifié, tous les champs disponibles seront générés.
    Champs disponibles: Author, Category, Tags, Source, CreatedDate, ModifiedDate, Version, Status, Priority,
    Department, Location, Keywords, Language, FileType, FileSize, AccessLevel, Owner, Group, ExpirationDate,
    Classification.

.PARAMETER Distribution
    Hashtable définissant la distribution des valeurs pour certains champs.
    Par exemple: @{ "Category" = @{ "Document" = 0.4; "Email" = 0.3; "Rapport" = 0.2; "Autre" = 0.1 } }

.PARAMETER Complexity
    Niveau de complexité des métadonnées (1-10). Influence la variété et la richesse des métadonnées.
    1-3: Métadonnées simples avec peu de variété
    4-7: Métadonnées intermédiaires avec une variété modérée
    8-10: Métadonnées complexes avec une grande variété
    Par défaut: 5.

.PARAMETER IncludeCustomFields
    Si spécifié, inclut des champs personnalisés dans les métadonnées générées.

.PARAMETER CustomFieldCount
    Nombre de champs personnalisés à générer si IncludeCustomFields est spécifié. Par défaut: 3.

.PARAMETER RandomSeed
    Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
    des métadonnées identiques à chaque exécution avec la même graine.

.EXAMPLE
    $metadata = New-RandomMetadata -Fields @("Author", "Category", "Tags", "CreatedDate") -Complexity 7

.EXAMPLE
    $distribution = @{ "Category" = @{ "Document" = 0.4; "Email" = 0.3; "Rapport" = 0.2; "Autre" = 0.1 } }
    $metadata = New-RandomMetadata -Distribution $distribution -IncludeCustomFields -RandomSeed 12345

.NOTES
    Cette fonction est conçue pour les tests et ne doit pas être utilisée en production.
#>
function New-RandomMetadata {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Fields,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Distribution = @{},
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Complexity = 5,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCustomFields,
        
        [Parameter(Mandatory = $false)]
        [int]$CustomFieldCount = 3,
        
        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )
    
    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }
    
    # Définir les champs disponibles et leurs valeurs possibles
    $availableFields = @{
        "Author" = @{
            Values = @(
                "Jean Dupont", "Marie Martin", "Pierre Durand", "Sophie Lefebvre", "Thomas Bernard",
                "Julie Robert", "Nicolas Petit", "Isabelle Dubois", "François Moreau", "Catherine Simon",
                "David Leroy", "Nathalie Roux", "Philippe Fournier", "Christine Morel", "Stéphane Girard",
                "Valérie Lambert", "Olivier Bonnet", "Caroline Mercier", "Frédéric Perrin", "Sylvie Gautier"
            )
            Distribution = @{}  # Sera rempli automatiquement avec une distribution uniforme
        }
        "Category" = @{
            Values = @(
                "Document", "Rapport", "Présentation", "Email", "Note", "Contrat", "Facture",
                "Formulaire", "Manuel", "Procédure", "Mémo", "Lettre", "Devis", "Commande",
                "Livraison", "Réclamation", "Projet", "Étude", "Analyse", "Synthèse"
            )
            Distribution = @{}
        }
        "Tags" = @{
            Values = @(
                "important", "urgent", "confidentiel", "archive", "brouillon", "final", "révision",
                "validation", "référence", "template", "projet", "client", "interne", "externe",
                "technique", "commercial", "juridique", "financier", "administratif", "ressources humaines",
                "marketing", "vente", "production", "qualité", "recherche", "développement", "formation",
                "communication", "stratégie", "opérationnel"
            )
            MinCount = 0
            MaxCount = 5
        }
        "Source" = @{
            Values = @(
                "Email", "Web", "Scanner", "API", "Base de données", "Import manuel", "Système externe",
                "Application mobile", "Formulaire web", "Service tiers", "FTP", "Partage réseau",
                "Cloud", "Extraction automatique", "Saisie manuelle", "Import CSV", "Import Excel",
                "Capture OCR", "Téléchargement", "Synchronisation"
            )
            Distribution = @{}
        }
        "CreatedDate" = @{
            MinDaysAgo = 0
            MaxDaysAgo = 365
        }
        "ModifiedDate" = @{
            MinDaysAfterCreation = 0
            MaxDaysAfterCreation = 30
        }
        "Version" = @{
            MajorMin = 1
            MajorMax = 3
            MinorMin = 0
            MinorMax = 9
            PatchMin = 0
            PatchMax = 9
        }
        "Status" = @{
            Values = @(
                "Brouillon", "En révision", "Validé", "Publié", "Archivé", "Obsolète",
                "En attente", "Rejeté", "Approuvé", "En cours", "Terminé", "Annulé",
                "Suspendu", "Reporté", "Planifié", "Non démarré", "En test", "En déploiement",
                "En maintenance", "Déprécié"
            )
            Distribution = @{}
        }
        "Priority" = @{
            Values = @(
                "Basse", "Normale", "Haute", "Critique", "Urgente",
                "Très basse", "Très haute", "Optionnelle", "Requise", "Essentielle"
            )
            Distribution = @{}
        }
        "Department" = @{
            Values = @(
                "Informatique", "Ressources Humaines", "Finance", "Marketing", "Ventes",
                "Production", "Recherche et Développement", "Juridique", "Qualité", "Direction",
                "Communication", "Achats", "Logistique", "Service client", "Formation",
                "Comptabilité", "Audit", "Sécurité", "Maintenance", "Administration"
            )
            Distribution = @{}
        }
        "Location" = @{
            Values = @(
                "Paris", "Lyon", "Marseille", "Bordeaux", "Lille", "Toulouse", "Nantes", "Strasbourg",
                "Montpellier", "Nice", "Rennes", "Grenoble", "Toulon", "Angers", "Dijon", "Le Mans",
                "Clermont-Ferrand", "Amiens", "Limoges", "Tours"
            )
            Distribution = @{}
        }
        "Keywords" = @{
            Values = @(
                "analyse", "rapport", "étude", "projet", "client", "produit", "service", "marché",
                "stratégie", "objectif", "résultat", "performance", "budget", "prévision", "tendance",
                "croissance", "innovation", "qualité", "processus", "méthode", "outil", "ressource",
                "compétence", "formation", "développement", "amélioration", "optimisation", "solution",
                "problème", "risque", "opportunité", "décision", "action", "plan", "programme", "calendrier",
                "délai", "coût", "bénéfice", "rentabilité", "investissement", "financement", "trésorerie"
            )
            MinCount = 0
            MaxCount = 8
        }
        "Language" = @{
            Values = @(
                "fr", "en", "de", "es", "it", "pt", "nl", "ru", "zh", "ja",
                "ar", "pl", "sv", "da", "fi", "no", "tr", "el", "cs", "hu"
            )
            Distribution = @{
                "fr" = 0.6
                "en" = 0.3
                "de" = 0.03
                "es" = 0.03
                "it" = 0.02
                "pt" = 0.02
            }
        }
        "FileType" = @{
            Values = @(
                "PDF", "DOCX", "XLSX", "PPTX", "TXT", "CSV", "JSON", "XML", "HTML", "MD",
                "JPG", "PNG", "GIF", "SVG", "MP3", "MP4", "WAV", "AVI", "ZIP", "RAR"
            )
            Distribution = @{
                "PDF" = 0.3
                "DOCX" = 0.2
                "XLSX" = 0.15
                "PPTX" = 0.1
                "TXT" = 0.05
                "JSON" = 0.05
                "XML" = 0.05
                "HTML" = 0.05
                "JPG" = 0.03
                "PNG" = 0.02
            }
        }
        "FileSize" = @{
            MinKB = 10
            MaxKB = 10000
        }
        "AccessLevel" = @{
            Values = @(
                "Public", "Interne", "Confidentiel", "Restreint", "Privé",
                "Tous", "Département", "Équipe", "Individuel", "Administrateur"
            )
            Distribution = @{
                "Public" = 0.1
                "Interne" = 0.3
                "Confidentiel" = 0.3
                "Restreint" = 0.2
                "Privé" = 0.1
            }
        }
        "Owner" = @{
            Values = @(
                "admin", "system", "user1", "user2", "user3", "user4", "user5",
                "manager1", "manager2", "director1", "director2", "guest", "service",
                "backup", "archive", "temp", "test", "dev", "prod", "support"
            )
            Distribution = @{}
        }
        "Group" = @{
            Values = @(
                "Administrateurs", "Utilisateurs", "Invités", "Développeurs", "Testeurs",
                "Managers", "Directeurs", "Support", "Maintenance", "Sécurité",
                "RH", "Finance", "Marketing", "Ventes", "Production", "R&D", "Juridique",
                "Qualité", "Communication", "Formation"
            )
            Distribution = @{}
        }
        "ExpirationDate" = @{
            MinDaysFromNow = 30
            MaxDaysFromNow = 730
        }
        "Classification" = @{
            Values = @(
                "Non classifié", "Diffusion restreinte", "Confidentiel", "Secret", "Très secret",
                "Public", "Interne", "Privé", "Sensible", "Critique"
            )
            Distribution = @{
                "Non classifié" = 0.2
                "Diffusion restreinte" = 0.3
                "Confidentiel" = 0.3
                "Secret" = 0.15
                "Très secret" = 0.05
            }
        }
    }
    
    # Initialiser les distributions uniformes pour les champs qui n'en ont pas
    foreach ($field in $availableFields.Keys) {
        if ($availableFields[$field].ContainsKey("Values") -and $availableFields[$field].ContainsKey("Distribution") -and $availableFields[$field].Distribution.Count -eq 0) {
            $distribution = @{}
            $uniformProbability = 1.0 / $availableFields[$field].Values.Count
            
            foreach ($value in $availableFields[$field].Values) {
                $distribution[$value] = $uniformProbability
            }
            
            $availableFields[$field].Distribution = $distribution
        }
    }
    
    # Appliquer les distributions personnalisées
    foreach ($field in $Distribution.Keys) {
        if ($availableFields.ContainsKey($field) -and $availableFields[$field].ContainsKey("Distribution")) {
            $availableFields[$field].Distribution = $Distribution[$field]
        }
    }
    
    # Si aucun champ n'est spécifié, sélectionner des champs en fonction de la complexité
    if (-not $Fields -or $Fields.Count -eq 0) {
        $fieldCount = [Math]::Max(3, [Math]::Min(10, $Complexity * 2))
        $allFields = $availableFields.Keys | Sort-Object { $random.Next() }
        $Fields = $allFields | Select-Object -First $fieldCount
    }
    
    # Générer les métadonnées
    $metadata = @{}
    
    foreach ($field in $Fields) {
        if ($availableFields.ContainsKey($field)) {
            $fieldDef = $availableFields[$field]
            
            $value = switch ($field) {
                "Author" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($author in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$author]
                        if ($r -lt $cumulative) {
                            $author
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Category" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($category in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$category]
                        if ($r -lt $cumulative) {
                            $category
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Tags" {
                    # Déterminer le nombre de tags
                    $minTags = [Math]::Max(0, [Math]::Min($fieldDef.MinCount, $Complexity - 1))
                    $maxTags = [Math]::Max(1, [Math]::Min($fieldDef.MaxCount, $Complexity + 2))
                    $tagCount = $random.Next($minTags, $maxTags + 1)
                    
                    # Sélectionner des tags aléatoires
                    $selectedTags = @()
                    $availableTags = $fieldDef.Values | Sort-Object { $random.Next() }
                    
                    for ($i = 0; $i -lt $tagCount; $i++) {
                        if ($i -lt $availableTags.Count) {
                            $selectedTags += $availableTags[$i]
                        }
                    }
                    
                    $selectedTags
                }
                "Source" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($source in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$source]
                        if ($r -lt $cumulative) {
                            $source
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "CreatedDate" {
                    $daysAgo = $random.Next($fieldDef.MinDaysAgo, $fieldDef.MaxDaysAgo + 1)
                    (Get-Date).AddDays(-$daysAgo)
                }
                "ModifiedDate" {
                    if ($metadata.ContainsKey("CreatedDate")) {
                        $createdDate = $metadata["CreatedDate"]
                        $daysAfterCreation = $random.Next($fieldDef.MinDaysAfterCreation, $fieldDef.MaxDaysAfterCreation + 1)
                        $createdDate.AddDays($daysAfterCreation)
                    }
                    else {
                        $daysAgo = $random.Next(0, 30)
                        (Get-Date).AddDays(-$daysAgo)
                    }
                }
                "Version" {
                    $major = $random.Next($fieldDef.MajorMin, $fieldDef.MajorMax + 1)
                    $minor = $random.Next($fieldDef.MinorMin, $fieldDef.MinorMax + 1)
                    $patch = $random.Next($fieldDef.PatchMin, $fieldDef.PatchMax + 1)
                    "$major.$minor.$patch"
                }
                "Status" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($status in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$status]
                        if ($r -lt $cumulative) {
                            $status
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Priority" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($priority in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$priority]
                        if ($r -lt $cumulative) {
                            $priority
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Department" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($department in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$department]
                        if ($r -lt $cumulative) {
                            $department
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Location" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($location in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$location]
                        if ($r -lt $cumulative) {
                            $location
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Keywords" {
                    # Déterminer le nombre de mots-clés
                    $minKeywords = [Math]::Max(0, [Math]::Min($fieldDef.MinCount, $Complexity - 1))
                    $maxKeywords = [Math]::Max(1, [Math]::Min($fieldDef.MaxCount, $Complexity + 2))
                    $keywordCount = $random.Next($minKeywords, $maxKeywords + 1)
                    
                    # Sélectionner des mots-clés aléatoires
                    $selectedKeywords = @()
                    $availableKeywords = $fieldDef.Values | Sort-Object { $random.Next() }
                    
                    for ($i = 0; $i -lt $keywordCount; $i++) {
                        if ($i -lt $availableKeywords.Count) {
                            $selectedKeywords += $availableKeywords[$i]
                        }
                    }
                    
                    $selectedKeywords
                }
                "Language" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($language in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$language]
                        if ($r -lt $cumulative) {
                            $language
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "FileType" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($fileType in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$fileType]
                        if ($r -lt $cumulative) {
                            $fileType
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "FileSize" {
                    $sizeKB = $random.Next($fieldDef.MinKB, $fieldDef.MaxKB + 1)
                    $sizeKB
                }
                "AccessLevel" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($accessLevel in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$accessLevel]
                        if ($r -lt $cumulative) {
                            $accessLevel
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Owner" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($owner in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$owner]
                        if ($r -lt $cumulative) {
                            $owner
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "Group" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($group in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$group]
                        if ($r -lt $cumulative) {
                            $group
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                "ExpirationDate" {
                    $daysFromNow = $random.Next($fieldDef.MinDaysFromNow, $fieldDef.MaxDaysFromNow + 1)
                    (Get-Date).AddDays($daysFromNow)
                }
                "Classification" {
                    # Sélectionner une valeur selon la distribution
                    $r = $random.NextDouble()
                    $cumulative = 0
                    
                    foreach ($classification in $fieldDef.Distribution.Keys) {
                        $cumulative += $fieldDef.Distribution[$classification]
                        if ($r -lt $cumulative) {
                            $classification
                            break
                        }
                    }
                    
                    # Fallback si aucune valeur n'est sélectionnée
                    if ($cumulative -eq 0 -or $r -ge $cumulative) {
                        $fieldDef.Values[$random.Next(0, $fieldDef.Values.Count)]
                    }
                }
                default {
                    # Valeur par défaut pour les champs non reconnus
                    "Valeur pour $field"
                }
            }
            
            $metadata[$field] = $value
        }
    }
    
    # Ajouter des champs personnalisés si demandé
    if ($IncludeCustomFields) {
        $customFieldCount = [Math]::Min($CustomFieldCount, $Complexity)
        
        $customFieldPrefixes = @("Custom", "X-", "Meta", "User", "App", "Ext", "Prop", "Data", "Info", "Attr")
        $customFieldSuffixes = @("Value", "Data", "Info", "Property", "Attribute", "Field", "Parameter", "Setting", "Config", "Option")
        
        for ($i = 1; $i -le $customFieldCount; $i++) {
            $prefixIndex = $random.Next(0, $customFieldPrefixes.Count)
            $suffixIndex = $random.Next(0, $customFieldSuffixes.Count)
            $customFieldName = "$($customFieldPrefixes[$prefixIndex])$($i)$($customFieldSuffixes[$suffixIndex])"
            
            # Générer une valeur aléatoire pour le champ personnalisé
            $valueType = $random.Next(0, 4)
            $customValue = switch ($valueType) {
                0 { "CustomValue-$($random.Next(1, 1000))" }  # Chaîne
                1 { $random.Next(1, 10000) }                  # Nombre
                2 { $random.Next(0, 2) -eq 1 }                # Booléen
                3 {                                           # Date
                    $daysAgo = $random.Next(-365, 365)
                    (Get-Date).AddDays($daysAgo)
                }
            }
            
            $metadata[$customFieldName] = $customValue
        }
    }
    
    return $metadata
}

# Exporter la fonction
Export-ModuleMember -Function New-RandomMetadata
