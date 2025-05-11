# Generate-TaskAssignees.ps1
# Script pour générer des noms d'assignés réalistes pour les tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des noms d'assignés réalistes pour les tâches.

.DESCRIPTION
    Ce script fournit des fonctions pour générer des noms d'assignés réalistes
    pour les tâches, avec différentes options de personnalisation.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour générer un nom d'assigné aléatoire
function Get-RandomAssignee {
    <#
    .SYNOPSIS
        Génère un nom d'assigné aléatoire.

    .DESCRIPTION
        Cette fonction génère un nom d'assigné aléatoire à partir d'une liste prédéfinie
        ou en combinant des prénoms et noms aléatoires.

    .PARAMETER UseFullName
        Indique si le nom complet (prénom + nom) doit être utilisé.
        Si $false, seul le prénom sera utilisé.

    .PARAMETER Culture
        La culture à utiliser pour les noms (fr-FR, en-US, etc.).
        Par défaut: fr-FR.

    .PARAMETER PredefinedList
        Une liste prédéfinie de noms à utiliser. Si spécifiée, les autres paramètres
        de génération de noms sont ignorés.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des noms identiques à chaque exécution avec la même graine.

    .EXAMPLE
        Get-RandomAssignee
        Génère un nom d'assigné aléatoire en français.

    .EXAMPLE
        Get-RandomAssignee -UseFullName $true -Culture "en-US"
        Génère un nom complet d'assigné aléatoire en anglais.

    .EXAMPLE
        Get-RandomAssignee -PredefinedList @("Jean Dupont", "Marie Martin", "Pierre Durand")
        Sélectionne un nom aléatoire dans la liste prédéfinie.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$UseFullName = $false,

        [Parameter(Mandatory = $false)]
        [string]$Culture = "fr-FR",

        [Parameter(Mandatory = $false)]
        [string[]]$PredefinedList = @(),

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

    # Si une liste prédéfinie est fournie, l'utiliser
    if ($PredefinedList.Count -gt 0) {
        $index = $random.Next(0, $PredefinedList.Count)
        return $PredefinedList[$index]
    }

    # Listes de prénoms et noms par culture
    $firstNames = @{
        "fr-FR" = @("Jean", "Marie", "Pierre", "Sophie", "Thomas", "Julie", "Nicolas", "Isabelle", "François", "Catherine", 
                    "Michel", "Anne", "Philippe", "Nathalie", "David", "Caroline", "Éric", "Céline", "Stéphane", "Valérie",
                    "Christophe", "Sandrine", "Patrick", "Sylvie", "Olivier", "Christine", "Daniel", "Véronique", "Laurent", "Aurélie")
        "en-US" = @("John", "Mary", "James", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Elizabeth",
                    "David", "Susan", "Richard", "Jessica", "Joseph", "Sarah", "Thomas", "Karen", "Charles", "Nancy",
                    "Christopher", "Lisa", "Daniel", "Margaret", "Matthew", "Betty", "Anthony", "Sandra", "Mark", "Ashley")
        "es-ES" = @("José", "María", "Antonio", "Carmen", "Manuel", "Ana", "Francisco", "Isabel", "Juan", "Dolores",
                    "Pedro", "Laura", "Jesús", "Cristina", "Miguel", "Marta", "Rafael", "Pilar", "Javier", "Lucía",
                    "David", "Elena", "Carlos", "Sara", "Alberto", "Paula", "Luis", "Raquel", "Alejandro", "Manuela")
        "de-DE" = @("Hans", "Anna", "Peter", "Maria", "Michael", "Ursula", "Thomas", "Elisabeth", "Andreas", "Monika",
                    "Wolfgang", "Petra", "Klaus", "Sabine", "Jürgen", "Renate", "Dieter", "Claudia", "Manfred", "Brigitte",
                    "Uwe", "Andrea", "Werner", "Karin", "Günter", "Susanne", "Helmut", "Angelika", "Frank", "Nicole")
        "it-IT" = @("Giuseppe", "Maria", "Antonio", "Anna", "Giovanni", "Giuseppina", "Mario", "Rosa", "Luigi", "Angela",
                    "Francesco", "Giovanna", "Angelo", "Teresa", "Vincenzo", "Lucia", "Pietro", "Carmela", "Salvatore", "Caterina",
                    "Carlo", "Francesca", "Franco", "Antonietta", "Domenico", "Carla", "Bruno", "Elena", "Paolo", "Rita")
    }

    $lastNames = @{
        "fr-FR" = @("Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau",
                    "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier",
                    "Morel", "Girard", "André", "Lefevre", "Mercier", "Dupont", "Lambert", "Bonnet", "Francois", "Martinez")
        "en-US" = @("Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor",
                    "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson",
                    "Clark", "Rodriguez", "Lewis", "Lee", "Walker", "Hall", "Allen", "Young", "Hernandez", "King")
        "es-ES" = @("García", "González", "Rodríguez", "Fernández", "López", "Martínez", "Sánchez", "Pérez", "Gómez", "Martín",
                    "Jiménez", "Ruiz", "Hernández", "Díaz", "Moreno", "Álvarez", "Muñoz", "Romero", "Alonso", "Gutiérrez",
                    "Navarro", "Torres", "Domínguez", "Vázquez", "Ramos", "Gil", "Ramírez", "Serrano", "Blanco", "Suárez")
        "de-DE" = @("Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker", "Schulz", "Hoffmann",
                    "Schäfer", "Koch", "Bauer", "Richter", "Klein", "Wolf", "Schröder", "Neumann", "Schwarz", "Zimmermann",
                    "Braun", "Krüger", "Hofmann", "Hartmann", "Lange", "Schmitt", "Werner", "Schmitz", "Krause", "Meier")
        "it-IT" = @("Rossi", "Russo", "Ferrari", "Esposito", "Bianchi", "Romano", "Colombo", "Ricci", "Marino", "Greco",
                    "Bruno", "Gallo", "Conti", "De Luca", "Costa", "Giordano", "Mancini", "Rizzo", "Lombardi", "Moretti",
                    "Barbieri", "Fontana", "Santoro", "Mariani", "Rinaldi", "Caruso", "Ferrara", "Galli", "Martini", "Leone")
    }

    # Utiliser la culture par défaut si la culture spécifiée n'est pas disponible
    if (-not $firstNames.ContainsKey($Culture)) {
        $Culture = "fr-FR"
    }

    # Générer le nom
    $firstName = $firstNames[$Culture][$random.Next(0, $firstNames[$Culture].Count)]
    
    if ($UseFullName) {
        $lastName = $lastNames[$Culture][$random.Next(0, $lastNames[$Culture].Count)]
        return "$firstName $lastName"
    }
    else {
        return $firstName
    }
}

# Fonction pour générer une liste d'assignés
function New-AssigneeList {
    <#
    .SYNOPSIS
        Génère une liste d'assignés pour les tâches.

    .DESCRIPTION
        Cette fonction génère une liste d'assignés pour les tâches, avec différentes
        options de personnalisation.

    .PARAMETER Count
        Le nombre d'assignés à générer.

    .PARAMETER UseFullName
        Indique si les noms complets (prénom + nom) doivent être utilisés.
        Si $false, seuls les prénoms seront utilisés.

    .PARAMETER Culture
        La culture à utiliser pour les noms (fr-FR, en-US, etc.).
        Par défaut: fr-FR.

    .PARAMETER PredefinedList
        Une liste prédéfinie de noms à utiliser. Si spécifiée, les autres paramètres
        de génération de noms sont ignorés.

    .PARAMETER AllowDuplicates
        Indique si les doublons sont autorisés dans la liste générée.
        Par défaut: $false.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des listes identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-AssigneeList -Count 5
        Génère une liste de 5 assignés avec des prénoms en français.

    .EXAMPLE
        New-AssigneeList -Count 10 -UseFullName $true -Culture "en-US"
        Génère une liste de 10 assignés avec des noms complets en anglais.

    .OUTPUTS
        System.String[]
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Count,

        [Parameter(Mandatory = $false)]
        [bool]$UseFullName = $false,

        [Parameter(Mandatory = $false)]
        [string]$Culture = "fr-FR",

        [Parameter(Mandatory = $false)]
        [string[]]$PredefinedList = @(),

        [Parameter(Mandatory = $false)]
        [bool]$AllowDuplicates = $false,

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

    # Si une liste prédéfinie est fournie, l'utiliser
    if ($PredefinedList.Count -gt 0) {
        if ($AllowDuplicates -or $PredefinedList.Count -ge $Count) {
            $result = @()
            for ($i = 0; $i -lt $Count; $i++) {
                $index = $random.Next(0, $PredefinedList.Count)
                $result += $PredefinedList[$index]
            }
            return $result
        }
        else {
            # Si les doublons ne sont pas autorisés et que la liste prédéfinie est trop petite,
            # utiliser tous les éléments de la liste prédéfinie et compléter avec des noms générés
            $result = $PredefinedList.Clone()
            $remainingCount = $Count - $PredefinedList.Count
            
            for ($i = 0; $i -lt $remainingCount; $i++) {
                $result += Get-RandomAssignee -UseFullName $UseFullName -Culture $Culture -RandomSeed ($RandomSeed + $i)
            }
            
            return $result
        }
    }

    # Générer la liste d'assignés
    $result = @()
    $usedNames = @{}

    for ($i = 0; $i -lt $Count; $i++) {
        $attempts = 0
        $maxAttempts = 100  # Éviter les boucles infinies

        do {
            $name = Get-RandomAssignee -UseFullName $UseFullName -Culture $Culture -RandomSeed ($RandomSeed + $i + $attempts)
            $attempts++
        } while (-not $AllowDuplicates -and $usedNames.ContainsKey($name) -and $attempts -lt $maxAttempts)

        # Si on a atteint le nombre maximum de tentatives, ajouter un suffixe numérique
        if (-not $AllowDuplicates -and $usedNames.ContainsKey($name)) {
            $name = "$name $($usedNames.Count + 1)"
        }

        $result += $name
        $usedNames[$name] = $true
    }

    return $result
}

# Fonction pour assigner des responsables aux tâches
function Add-TaskAssignees {
    <#
    .SYNOPSIS
        Assigne des responsables aux tâches.

    .DESCRIPTION
        Cette fonction assigne des responsables aux tâches en fonction de différentes
        stratégies d'attribution.

    .PARAMETER Tasks
        Les tâches auxquelles assigner des responsables.

    .PARAMETER Assignees
        La liste des assignés disponibles.

    .PARAMETER Strategy
        La stratégie d'attribution à utiliser:
        - Random: Attribution aléatoire
        - RoundRobin: Attribution en alternance
        - Balanced: Attribution équilibrée en fonction de la charge
        - Specialized: Attribution en fonction des compétences (nécessite SkillsMapping)
        - Hierarchical: Attribution en fonction de la hiérarchie des tâches
        Par défaut: Random.

    .PARAMETER SkillsMapping
        Un mapping des compétences pour chaque assigné, utilisé avec la stratégie Specialized.
        Format: @{ "Assigné1" = @("Compétence1", "Compétence2"); "Assigné2" = @("Compétence3") }

    .PARAMETER TaskField
        Le nom du champ dans lequel stocker l'assigné dans les tâches.
        Par défaut: "Assignee".

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des attributions identiques à chaque exécution avec la même graine.

    .EXAMPLE
        Add-TaskAssignees -Tasks $tasks -Assignees @("Jean", "Marie", "Pierre") -Strategy "RoundRobin"
        Assigne des responsables aux tâches en alternance.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $true)]
        [string[]]$Assignees,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Random", "RoundRobin", "Balanced", "Specialized", "Hierarchical")]
        [string]$Strategy = "Random",

        [Parameter(Mandatory = $false)]
        [hashtable]$SkillsMapping = @{},

        [Parameter(Mandatory = $false)]
        [string]$TaskField = "Assignee",

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

    # Vérifier qu'il y a au moins un assigné
    if ($Assignees.Count -eq 0) {
        Write-Error "La liste des assignés ne peut pas être vide."
        return $Tasks
    }

    # Appliquer la stratégie d'attribution
    switch ($Strategy) {
        "Random" {
            # Attribution aléatoire
            foreach ($task in $Tasks) {
                $index = $random.Next(0, $Assignees.Count)
                $assignee = $Assignees[$index]
                
                # Ajouter l'assigné à la tâche
                if (-not $task.PSObject.Properties.Name.Contains($TaskField)) {
                    Add-Member -InputObject $task -MemberType NoteProperty -Name $TaskField -Value $assignee
                }
                else {
                    $task.$TaskField = $assignee
                }
            }
        }
        "RoundRobin" {
            # Attribution en alternance
            $index = 0
            foreach ($task in $Tasks) {
                $assignee = $Assignees[$index % $Assignees.Count]
                $index++
                
                # Ajouter l'assigné à la tâche
                if (-not $task.PSObject.Properties.Name.Contains($TaskField)) {
                    Add-Member -InputObject $task -MemberType NoteProperty -Name $TaskField -Value $assignee
                }
                else {
                    $task.$TaskField = $assignee
                }
            }
        }
        "Balanced" {
            # Attribution équilibrée en fonction de la charge
            $assigneeCount = @{}
            foreach ($assignee in $Assignees) {
                $assigneeCount[$assignee] = 0
            }
            
            foreach ($task in $Tasks) {
                # Trouver l'assigné avec la charge la plus faible
                $minCount = [int]::MaxValue
                $selectedAssignee = $null
                
                foreach ($assignee in $Assignees) {
                    if ($assigneeCount[$assignee] -lt $minCount) {
                        $minCount = $assigneeCount[$assignee]
                        $selectedAssignee = $assignee
                    }
                }
                
                # Ajouter l'assigné à la tâche
                if (-not $task.PSObject.Properties.Name.Contains($TaskField)) {
                    Add-Member -InputObject $task -MemberType NoteProperty -Name $TaskField -Value $selectedAssignee
                }
                else {
                    $task.$TaskField = $selectedAssignee
                }
                
                # Mettre à jour le compteur
                $assigneeCount[$selectedAssignee]++
            }
        }
        "Specialized" {
            # Attribution en fonction des compétences
            foreach ($task in $Tasks) {
                $matchingAssignees = @()
                
                # Vérifier si la tâche a des compétences requises
                if ($task.PSObject.Properties.Name.Contains("Skills") -and $task.Skills -is [array] -and $task.Skills.Count -gt 0) {
                    # Trouver les assignés qui ont toutes les compétences requises
                    foreach ($assignee in $Assignees) {
                        if ($SkillsMapping.ContainsKey($assignee)) {
                            $hasAllSkills = $true
                            foreach ($skill in $task.Skills) {
                                if (-not $SkillsMapping[$assignee].Contains($skill)) {
                                    $hasAllSkills = $false
                                    break
                                }
                            }
                            
                            if ($hasAllSkills) {
                                $matchingAssignees += $assignee
                            }
                        }
                    }
                }
                
                # Si aucun assigné ne correspond, utiliser tous les assignés
                if ($matchingAssignees.Count -eq 0) {
                    $matchingAssignees = $Assignees
                }
                
                # Sélectionner un assigné aléatoire parmi les correspondants
                $index = $random.Next(0, $matchingAssignees.Count)
                $assignee = $matchingAssignees[$index]
                
                # Ajouter l'assigné à la tâche
                if (-not $task.PSObject.Properties.Name.Contains($TaskField)) {
                    Add-Member -InputObject $task -MemberType NoteProperty -Name $TaskField -Value $assignee
                }
                else {
                    $task.$TaskField = $assignee
                }
            }
        }
        "Hierarchical" {
            # Attribution en fonction de la hiérarchie des tâches
            # Les tâches de niveau supérieur sont assignées aux premiers assignés de la liste
            
            # Trier les tâches par niveau hiérarchique (si disponible)
            $sortedTasks = $Tasks
            if ($Tasks.Count -gt 0 -and $Tasks[0].PSObject.Properties.Name.Contains("IndentLevel")) {
                $sortedTasks = $Tasks | Sort-Object -Property IndentLevel
            }
            
            # Calculer le nombre de niveaux
            $maxLevel = 0
            foreach ($task in $sortedTasks) {
                if ($task.PSObject.Properties.Name.Contains("IndentLevel") -and $task.IndentLevel -gt $maxLevel) {
                    $maxLevel = $task.IndentLevel
                }
            }
            
            # Répartir les assignés par niveau
            $assigneesByLevel = @{}
            $assigneesPerLevel = [Math]::Max(1, [Math]::Ceiling($Assignees.Count / ($maxLevel + 1)))
            
            for ($level = 0; $level -le $maxLevel; $level++) {
                $startIndex = $level * $assigneesPerLevel
                $endIndex = [Math]::Min(($level + 1) * $assigneesPerLevel - 1, $Assignees.Count - 1)
                
                if ($startIndex -le $endIndex) {
                    $assigneesByLevel[$level] = $Assignees[$startIndex..$endIndex]
                }
                else {
                    $assigneesByLevel[$level] = $Assignees
                }
            }
            
            # Assigner les tâches
            foreach ($task in $sortedTasks) {
                $level = 0
                if ($task.PSObject.Properties.Name.Contains("IndentLevel")) {
                    $level = $task.IndentLevel
                }
                
                $levelAssignees = $assigneesByLevel[$level]
                $index = $random.Next(0, $levelAssignees.Count)
                $assignee = $levelAssignees[$index]
                
                # Ajouter l'assigné à la tâche
                if (-not $task.PSObject.Properties.Name.Contains($TaskField)) {
                    Add-Member -InputObject $task -MemberType NoteProperty -Name $TaskField -Value $assignee
                }
                else {
                    $task.$TaskField = $assignee
                }
            }
        }
    }

    return $Tasks
}
