# Classify-TasksAutomatically.ps1
# Script pour classifier automatiquement les tâches en fonction de leur contenu
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Classifie automatiquement les tâches en fonction de leur contenu.

.DESCRIPTION
    Ce script fournit des fonctions pour classifier automatiquement les tâches en fonction de leur contenu,
    de leur position hiérarchique et de leurs dépendances.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Définir la taxonomie des tâches
$taskTaxonomy = @{
    "Planning"      = @{
        Description   = "Tâches de planification et d'organisation"
        SubCategories = @{
            "Analyse"      = "Analyse des besoins et des exigences"
            "Conception"   = "Conception et architecture"
            "Estimation"   = "Estimation des efforts et des délais"
            "Coordination" = "Coordination et gestion de projet"
        }
    }
    "Développement" = @{
        Description   = "Tâches de développement et d'implémentation"
        SubCategories = @{
            "Frontend"        = "Développement frontend"
            "Backend"         = "Développement backend"
            "API"             = "Développement d'API"
            "Base de données" = "Développement de base de données"
            "Infrastructure"  = "Développement d'infrastructure"
        }
    }
    "Test"          = @{
        Description   = "Tâches de test et de validation"
        SubCategories = @{
            "Unitaire"    = "Tests unitaires"
            "Intégration" = "Tests d'intégration"
            "Système"     = "Tests système"
            "Performance" = "Tests de performance"
            "Sécurité"    = "Tests de sécurité"
        }
    }
    "Documentation" = @{
        Description   = "Tâches de documentation"
        SubCategories = @{
            "Technique"   = "Documentation technique"
            "Utilisateur" = "Documentation utilisateur"
            "API"         = "Documentation d'API"
            "Processus"   = "Documentation des processus"
        }
    }
    "Déploiement"   = @{
        Description   = "Tâches de déploiement et de mise en production"
        SubCategories = @{
            "Configuration" = "Configuration des environnements"
            "Installation"  = "Installation et déploiement"
            "Migration"     = "Migration des données"
            "Monitoring"    = "Mise en place du monitoring"
        }
    }
    "Maintenance"   = @{
        Description   = "Tâches de maintenance et de support"
        SubCategories = @{
            "Correction"   = "Correction de bugs"
            "Optimisation" = "Optimisation des performances"
            "Mise à jour"  = "Mise à jour des dépendances"
            "Support"      = "Support utilisateur"
        }
    }
    "Recherche"     = @{
        Description   = "Tâches de recherche et d'exploration"
        SubCategories = @{
            "Veille"     = "Veille technologique"
            "Prototype"  = "Prototypage et preuve de concept"
            "Évaluation" = "Évaluation des technologies"
            "Benchmark"  = "Benchmark et comparaison"
        }
    }
}

# Définir les règles de classification
$classificationRules = @{
    "Planning"      = @{
        Patterns = @("Plan", "Analyse", "Conception", "Estimation", "Coordination", "Définir", "Spécifier")
        Keywords = @("planifier", "analyser", "concevoir", "estimer", "coordonner", "définir", "spécifier", "organiser", "préparer", "évaluer")
    }
    "Développement" = @{
        Patterns = @("Développer", "Implémenter", "Coder", "Programmer", "Intégrer", "Créer", "Construire")
        Keywords = @("développer", "implémenter", "coder", "programmer", "intégrer", "créer", "construire", "réaliser", "produire", "générer")
    }
    "Test"          = @{
        Patterns = @("Test", "Valider", "Vérifier", "QA", "Qualité", "Contrôle")
        Keywords = @("tester", "valider", "vérifier", "contrôler", "assurer", "qualifier", "certifier", "éprouver", "examiner", "inspecter")
    }
    "Documentation" = @{
        Patterns = @("Document", "Rédiger", "Écrire", "Guide", "Manuel", "Référence")
        Keywords = @("documenter", "rédiger", "écrire", "décrire", "expliquer", "détailler", "clarifier", "illustrer", "présenter", "exposer")
    }
    "Déploiement"   = @{
        Patterns = @("Déployer", "Installer", "Configurer", "Mettre en production", "Livrer", "Publier")
        Keywords = @("déployer", "installer", "configurer", "livrer", "publier", "distribuer", "délivrer", "mettre en ligne", "activer", "lancer")
    }
    "Maintenance"   = @{
        Patterns = @("Maintenir", "Corriger", "Optimiser", "Mettre à jour", "Supporter", "Améliorer")
        Keywords = @("maintenir", "corriger", "optimiser", "mettre à jour", "supporter", "améliorer", "réparer", "ajuster", "entretenir", "réviser")
    }
    "Recherche"     = @{
        Patterns = @("Rechercher", "Explorer", "Étudier", "Investiguer", "Expérimenter", "Prototyper")
        Keywords = @("rechercher", "explorer", "étudier", "investiguer", "expérimenter", "prototyper", "découvrir", "innover", "tester", "évaluer")
    }
}

# Fonction pour déterminer la classification d'une tâche
function Get-TaskClassification {
    <#
    .SYNOPSIS
        Détermine la classification d'une tâche en fonction de son contenu.

    .DESCRIPTION
        Cette fonction détermine la classification d'une tâche en fonction de son contenu,
        en utilisant des règles de classification prédéfinies.

    .PARAMETER Task
        La tâche à classifier.

    .PARAMETER Rules
        Les règles de classification à utiliser.

    .PARAMETER Taxonomy
        La taxonomie des tâches à utiliser.

    .PARAMETER TitleField
        Le nom du champ contenant le titre de la tâche.
        Par défaut: "Title".

    .PARAMETER DescriptionField
        Le nom du champ contenant la description de la tâche.
        Par défaut: "Description".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .EXAMPLE
        Get-TaskClassification -Task $task
        Détermine la classification de la tâche spécifiée.

    .OUTPUTS
        System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Task,

        [Parameter(Mandatory = $false)]
        [hashtable]$Rules = $classificationRules,

        [Parameter(Mandatory = $false)]
        [hashtable]$Taxonomy = $taskTaxonomy,

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "Title",

        [Parameter(Mandatory = $false)]
        [string]$DescriptionField = "Description",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id"
    )

    # Extraire le titre et la description de la tâche
    $title = if ($Task.PSObject.Properties.Name.Contains($TitleField) -and $Task.$TitleField) {
        $Task.$TitleField
    } else {
        ""
    }

    $description = if ($Task.PSObject.Properties.Name.Contains($DescriptionField) -and $Task.$DescriptionField) {
        $Task.$DescriptionField
    } else {
        ""
    }

    # Combiner le titre et la description pour l'analyse
    $content = "$title $description".ToLower()

    # Initialiser les scores pour chaque catégorie
    $scores = @{}
    foreach ($category in $Rules.Keys) {
        $scores[$category] = 0
    }

    # Calculer les scores pour chaque catégorie
    foreach ($category in $Rules.Keys) {
        # Vérifier les patterns dans le titre
        foreach ($pattern in $Rules[$category].Patterns) {
            if ($title -match $pattern) {
                $scores[$category] += 10
            }
        }

        # Vérifier les keywords dans le contenu
        foreach ($keyword in $Rules[$category].Keywords) {
            if ($content -match $keyword) {
                $scores[$category] += 5
            }
        }
    }

    # Trouver la catégorie avec le score le plus élevé
    $bestCategory = $scores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

    if ($bestCategory.Value -eq 0) {
        # Si aucune catégorie n'a de score, utiliser une heuristique basée sur l'ID
        if ($Task.PSObject.Properties.Name.Contains($IdField) -and $Task.$IdField) {
            $id = $Task.$IdField
            $parts = $id -split '\.'
            if ($parts.Count -gt 0) {
                $firstPart = [int]($parts[0] -replace '[^0-9]', '')

                # Attribuer une catégorie en fonction du premier chiffre de l'ID
                $category = switch ($firstPart) {
                    { $_ -le 2 } { "Planning" }
                    { $_ -le 4 } { "Développement" }
                    { $_ -le 6 } { "Test" }
                    { $_ -le 8 } { "Documentation" }
                    default { "Maintenance" }
                }

                return @{
                    Category    = $category
                    SubCategory = "Autre"
                    Confidence  = 30  # Confiance faible car basée sur l'ID
                }
            }
        }

        return @{
            Category    = "Non classifié"
            SubCategory = "Autre"
            Confidence  = 0
        }
    }

    # Trouver la sous-catégorie la plus appropriée
    $subCategory = "Autre"
    $subCategoryScore = 0

    if ($Taxonomy[$bestCategory.Name].SubCategories) {
        foreach ($subCat in $Taxonomy[$bestCategory.Name].SubCategories.Keys) {
            $subScore = 0

            if ($title -match $subCat) {
                $subScore += 10
            }

            if ($content -match $subCat) {
                $subScore += 5
            }

            if ($subScore -gt $subCategoryScore) {
                $subCategory = $subCat
                $subCategoryScore = $subScore
            }
        }
    }

    # Calculer la confiance (0-100%)
    $confidence = [Math]::Min(100, ($bestCategory.Value / 20) * 100)

    return @{
        Category    = $bestCategory.Name
        SubCategory = $subCategory
        Confidence  = $confidence
    }
}

# Fonction pour attribuer des classifications à une hiérarchie de tâches
function New-TaskClassificationAssignment {
    <#
    .SYNOPSIS
        Attribue des classifications à une hiérarchie de tâches.

    .DESCRIPTION
        Cette fonction attribue des classifications à une hiérarchie de tâches,
        en tenant compte de la structure hiérarchique et des dépendances.

    .PARAMETER Tasks
        Les tâches auxquelles attribuer des classifications.

    .PARAMETER Rules
        Les règles de classification à utiliser.

    .PARAMETER Taxonomy
        La taxonomie des tâches à utiliser.

    .PARAMETER ClassificationField
        Le nom du champ dans lequel stocker la classification dans les tâches.
        Par défaut: "Classification".

    .PARAMETER TitleField
        Le nom du champ contenant le titre de la tâche.
        Par défaut: "Title".

    .PARAMETER DescriptionField
        Le nom du champ contenant la description de la tâche.
        Par défaut: "Description".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ParentIdField
        Le nom du champ contenant l'ID du parent dans les tâches.
        Par défaut: "ParentId".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .EXAMPLE
        New-TaskClassificationAssignment -Tasks $tasks
        Attribue des classifications aux tâches spécifiées.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [hashtable]$Rules = $classificationRules,

        [Parameter(Mandatory = $false)]
        [hashtable]$Taxonomy = $taskTaxonomy,

        [Parameter(Mandatory = $false)]
        [string]$ClassificationField = "Classification",

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "Title",

        [Parameter(Mandatory = $false)]
        [string]$DescriptionField = "Description",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies"
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Classifier chaque tâche individuellement
    foreach ($task in $Tasks) {
        $classification = Get-TaskClassification -Task $task -Rules $Rules -Taxonomy $Taxonomy -TitleField $TitleField -DescriptionField $DescriptionField -IdField $IdField

        # Ajouter la classification à la tâche
        if (-not $task.PSObject.Properties.Name.Contains($ClassificationField)) {
            Add-Member -InputObject $task -MemberType NoteProperty -Name $ClassificationField -Value $classification
        } else {
            $task.$ClassificationField = $classification
        }
    }

    # Mettre à jour les classifications pour maintenir la cohérence hiérarchique
    $updatedTasks = Update-TaskClassificationHierarchy -Tasks $Tasks -ClassificationField $ClassificationField -IdField $IdField -ParentIdField $ParentIdField -ChildrenField $ChildrenField -DependenciesField $DependenciesField

    return $updatedTasks
}

# Fonction pour mettre à jour les classifications pour maintenir la cohérence hiérarchique
function Update-TaskClassificationHierarchy {
    <#
    .SYNOPSIS
        Met à jour les classifications pour maintenir la cohérence hiérarchique.

    .DESCRIPTION
        Cette fonction met à jour les classifications des tâches pour maintenir la cohérence hiérarchique,
        en tenant compte de la structure hiérarchique et des dépendances.

    .PARAMETER Tasks
        Les tâches à mettre à jour.

    .PARAMETER ClassificationField
        Le nom du champ contenant la classification dans les tâches.
        Par défaut: "Classification".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ParentIdField
        Le nom du champ contenant l'ID du parent dans les tâches.
        Par défaut: "ParentId".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .EXAMPLE
        Update-TaskClassificationHierarchy -Tasks $tasks
        Met à jour les classifications des tâches pour maintenir la cohérence hiérarchique.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$ClassificationField = "Classification",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies"
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Fonction récursive pour propager les classifications des parents aux enfants
    function Send-ClassificationDown {
        param (
            [PSObject]$Task,
            [hashtable]$TasksById,
            [string]$ClassificationField,
            [string]$ChildrenField
        )

        # Vérifier si la tâche a des enfants
        if ($Task.PSObject.Properties.Name.Contains($ChildrenField) -and $Task.$ChildrenField) {
            $childrenIds = $Task.$ChildrenField

            foreach ($childId in $childrenIds) {
                if ($TasksById.ContainsKey($childId)) {
                    $child = $TasksById[$childId]

                    # Si la confiance de la classification de l'enfant est faible, utiliser celle du parent
                    if ($child.$ClassificationField.Confidence -lt 50) {
                        $child.$ClassificationField = @{
                            Category            = $Task.$ClassificationField.Category
                            SubCategory         = $Task.$ClassificationField.SubCategory
                            Confidence          = [Math]::Max(30, $child.$ClassificationField.Confidence)  # Confiance minimale de 30%
                            InheritedFromParent = $true
                        }
                    }

                    # Propager récursivement aux enfants
                    Send-ClassificationDown -Task $child -TasksById $TasksById -ClassificationField $ClassificationField -ChildrenField $ChildrenField
                }
            }
        }
    }

    # Fonction pour propager les classifications entre tâches dépendantes
    function Sync-ClassificationDependencies {
        param (
            [PSObject[]]$Tasks,
            [hashtable]$TasksById,
            [string]$ClassificationField,
            [string]$DependenciesField
        )

        # Créer un dictionnaire des dépendances inverses (quelles tâches dépendent de cette tâche)
        $dependentTasks = @{}
        foreach ($task in $Tasks) {
            if ($task.PSObject.Properties.Name.Contains($DependenciesField) -and $task.$DependenciesField) {
                foreach ($depId in $task.$DependenciesField) {
                    if (-not $dependentTasks.ContainsKey($depId)) {
                        $dependentTasks[$depId] = @()
                    }
                    $dependentTasks[$depId] += $task.$IdField
                }
            }
        }

        # Propager les classifications des dépendances aux tâches dépendantes
        foreach ($task in $Tasks) {
            $id = $task.$IdField

            # Vérifier si d'autres tâches dépendent de celle-ci
            if ($dependentTasks.ContainsKey($id)) {
                foreach ($dependentId in $dependentTasks[$id]) {
                    if ($TasksById.ContainsKey($dependentId)) {
                        $dependentTask = $TasksById[$dependentId]

                        # Si la tâche dépendante a une confiance faible et que la dépendance a une confiance élevée
                        if ($dependentTask.$ClassificationField.Confidence -lt 40 -and $task.$ClassificationField.Confidence -gt 70) {
                            # Influencer la classification de la tâche dépendante
                            $dependentTask.$ClassificationField = @{
                                Category                = $task.$ClassificationField.Category
                                SubCategory             = $dependentTask.$ClassificationField.SubCategory  # Conserver la sous-catégorie
                                Confidence              = [Math]::Max(40, $dependentTask.$ClassificationField.Confidence)  # Confiance minimale de 40%
                                InheritedFromDependency = $true
                            }
                        }
                    }
                }
            }
        }
    }

    # Trouver les tâches racines (sans parent)
    $rootTasks = $Tasks | Where-Object { -not $_.$ParentIdField }

    # Propager les classifications des parents aux enfants
    foreach ($rootTask in $rootTasks) {
        Send-ClassificationDown -Task $rootTask -TasksById $tasksById -ClassificationField $ClassificationField -ChildrenField $ChildrenField
    }

    # Propager les classifications entre tâches dépendantes
    Sync-ClassificationDependencies -Tasks $Tasks -TasksById $tasksById -ClassificationField $ClassificationField -DependenciesField $DependenciesField

    # Harmoniser les classifications au sein des groupes de tâches
    $taskGroups = @{}
    foreach ($task in $Tasks) {
        $parentId = $task.$ParentIdField
        if ($parentId) {
            if (-not $taskGroups.ContainsKey($parentId)) {
                $taskGroups[$parentId] = @()
            }
            $taskGroups[$parentId] += $task
        }
    }

    foreach ($parentId in $taskGroups.Keys) {
        $group = $taskGroups[$parentId]

        # Compter les occurrences de chaque catégorie dans le groupe
        $categoryCounts = @{}
        foreach ($task in $group) {
            $category = $task.$ClassificationField.Category
            if (-not $categoryCounts.ContainsKey($category)) {
                $categoryCounts[$category] = 0
            }
            $categoryCounts[$category]++
        }

        # Trouver la catégorie la plus fréquente
        $mostFrequentCategory = $categoryCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

        # Si plus de 70% des tâches ont la même catégorie, harmoniser les autres
        if ($mostFrequentCategory.Value -gt ($group.Count * 0.7)) {
            foreach ($task in $group) {
                if ($task.$ClassificationField.Category -ne $mostFrequentCategory.Name -and $task.$ClassificationField.Confidence -lt 60) {
                    $task.$ClassificationField = @{
                        Category            = $mostFrequentCategory.Name
                        SubCategory         = $task.$ClassificationField.SubCategory  # Conserver la sous-catégorie
                        Confidence          = [Math]::Max(50, $task.$ClassificationField.Confidence)  # Confiance minimale de 50%
                        HarmonizedWithGroup = $true
                    }
                }
            }
        }
    }

    return $Tasks
}

# Fonction principale pour classifier automatiquement les tâches
function Invoke-TaskAutomaticClassification {
    <#
    .SYNOPSIS
        Classifie automatiquement les tâches en fonction de leur contenu.

    .DESCRIPTION
        Cette fonction classifie automatiquement les tâches en fonction de leur contenu,
        de leur position hiérarchique et de leurs dépendances.

    .PARAMETER Tasks
        Les tâches à classifier.

    .PARAMETER Rules
        Les règles de classification à utiliser.

    .PARAMETER Taxonomy
        La taxonomie des tâches à utiliser.

    .PARAMETER ClassificationField
        Le nom du champ dans lequel stocker la classification dans les tâches.
        Par défaut: "Classification".

    .PARAMETER TitleField
        Le nom du champ contenant le titre de la tâche.
        Par défaut: "Title".

    .PARAMETER DescriptionField
        Le nom du champ contenant la description de la tâche.
        Par défaut: "Description".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ParentIdField
        Le nom du champ contenant l'ID du parent dans les tâches.
        Par défaut: "ParentId".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .PARAMETER OutputFormat
        Le format de sortie des résultats.
        Valeurs possibles: "Objects", "JSON", "CSV".
        Par défaut: "Objects".

    .PARAMETER OutputPath
        Le chemin du fichier de sortie. Si non spécifié, les résultats sont retournés.

    .EXAMPLE
        Invoke-TaskAutomaticClassification -Tasks $tasks
        Classifie automatiquement les tâches spécifiées.

    .OUTPUTS
        System.Management.Automation.PSObject[] ou System.String
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [hashtable]$Rules = $classificationRules,

        [Parameter(Mandatory = $false)]
        [hashtable]$Taxonomy = $taskTaxonomy,

        [Parameter(Mandatory = $false)]
        [string]$ClassificationField = "Classification",

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "Title",

        [Parameter(Mandatory = $false)]
        [string]$DescriptionField = "Description",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Objects", "JSON", "CSV")]
        [string]$OutputFormat = "Objects",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Classifier les tâches
    $classifiedTasks = New-TaskClassificationAssignment -Tasks $Tasks -Rules $Rules -Taxonomy $Taxonomy -ClassificationField $ClassificationField -TitleField $TitleField -DescriptionField $DescriptionField -IdField $IdField -ParentIdField $ParentIdField -ChildrenField $ChildrenField -DependenciesField $DependenciesField

    # Préparer la sortie selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            $output = ConvertTo-Json -InputObject $classifiedTasks -Depth 10
        }
        "CSV" {
            $csv = "Id,Title,Category,SubCategory,Confidence`n"
            foreach ($task in $classifiedTasks) {
                $id = $task.$IdField
                $title = $task.$TitleField -replace '"', '""'  # Échapper les guillemets
                $category = $task.$ClassificationField.Category
                $subCategory = $task.$ClassificationField.SubCategory
                $confidence = $task.$ClassificationField.Confidence

                $csv += "$id,`"$title`",$category,$subCategory,$confidence`n"
            }
            $output = $csv
        }
        default {
            $output = $classifiedTasks
        }
    }

    # Écrire la sortie dans un fichier si demandé
    if ($OutputPath) {
        if ($OutputFormat -eq "Objects") {
            $output | Export-Clixml -Path $OutputPath
        } else {
            $output | Out-File -FilePath $OutputPath -Encoding utf8
        }
    }

    return $output
}
