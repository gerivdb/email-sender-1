#Requires -Version 5.1
<#
.SYNOPSIS
    Générateurs de données de test pour les tests unitaires PowerShell.
.DESCRIPTION
    Ce module fournit des générateurs de données de test pour les tests unitaires PowerShell
    dans le projet EMAIL_SENDER_1. Il permet de générer des données aléatoires ou spécifiques
    pour différents types de tests.
.EXAMPLE
    Import-Module TestDataGenerator
    $users = New-RandomUsers -Count 10
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

#region Variables globales
$script:ModuleName = 'TestDataGenerator'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '1.0.0'
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config\$script:ModuleName.config.json"
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs\$script:ModuleName.log"
$script:DataPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
#endregion

#region Fonctions privées
# Importer toutes les fonctions privées
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction privée importée : $($Function.BaseName)"
    } catch {
        Write-Error "Échec de l'importation de la fonction privée $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions publiques
# Importer toutes les fonctions publiques
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction publique importée : $($Function.BaseName)"
    } catch {
        Write-Error "Échec de l'importation de la fonction publique $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions principales du module

function New-RandomString {
    <#
    .SYNOPSIS
        Génère une chaîne aléatoire.
    .DESCRIPTION
        Génère une chaîne aléatoire avec des caractères spécifiés.
    .PARAMETER Length
        Longueur de la chaîne à générer.
    .PARAMETER CharacterSet
        Ensemble de caractères à utiliser (Alphanumeric, Alphabetic, Numeric, SpecialChars, All).
    .PARAMETER Prefix
        Préfixe à ajouter à la chaîne générée.
    .PARAMETER Suffix
        Suffixe à ajouter à la chaîne générée.
    .PARAMETER CustomCharacters
        Caractères personnalisés à utiliser pour la génération.
    .EXAMPLE
        New-RandomString -Length 10
    .EXAMPLE
        New-RandomString -Length 8 -CharacterSet Numeric -Prefix "ID-"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Length = 10,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Alphanumeric", "Alphabetic", "Numeric", "SpecialChars", "All")]
        [string]$CharacterSet = "Alphanumeric",

        [Parameter(Mandatory = $false)]
        [string]$Prefix = "",

        [Parameter(Mandatory = $false)]
        [string]$Suffix = "",

        [Parameter(Mandatory = $false)]
        [string]$CustomCharacters
    )

    # Définir les ensembles de caractères
    $charSets = @{
        Alphabetic   = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        Numeric      = "0123456789"
        SpecialChars = "!@#$%^&*()-_=+[]{};:,.<>/?|"
        Alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        All          = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{};:,.<>/?|"
    }

    # Utiliser les caractères personnalisés s'ils sont spécifiés
    if ($CustomCharacters) {
        $chars = $CustomCharacters
    } else {
        $chars = $charSets[$CharacterSet]
    }

    # Générer la chaîne aléatoire
    $random = New-Object System.Random
    $result = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $result += $chars[$random.Next(0, $chars.Length)]
    }

    # Ajouter le préfixe et le suffixe
    return $Prefix + $result + $Suffix
}

function New-RandomDate {
    <#
    .SYNOPSIS
        Génère une date aléatoire.
    .DESCRIPTION
        Génère une date aléatoire dans une plage spécifiée.
    .PARAMETER MinDate
        Date minimale (par défaut : 1 an avant aujourd'hui).
    .PARAMETER MaxDate
        Date maximale (par défaut : aujourd'hui).
    .PARAMETER Format
        Format de la date (par défaut : yyyy-MM-dd).
    .PARAMETER AsString
        Indique si la date doit être retournée sous forme de chaîne.
    .EXAMPLE
        New-RandomDate
    .EXAMPLE
        New-RandomDate -MinDate (Get-Date).AddYears(-5) -MaxDate (Get-Date).AddYears(1) -Format "dd/MM/yyyy"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [datetime]$MinDate = (Get-Date).AddYears(-1),

        [Parameter(Mandatory = $false)]
        [datetime]$MaxDate = (Get-Date),

        [Parameter(Mandatory = $false)]
        [string]$Format = "yyyy-MM-dd",

        [Parameter(Mandatory = $false)]
        [switch]$AsString
    )

    # Calculer la différence en jours
    $minTicks = $MinDate.Ticks
    $maxTicks = $MaxDate.Ticks
    $ticksRange = $maxTicks - $minTicks

    # Générer une date aléatoire
    $random = New-Object System.Random
    $randomTicks = [long]($minTicks + $random.NextDouble() * $ticksRange)
    $randomDate = New-Object System.DateTime($randomTicks)

    # Retourner la date au format demandé
    if ($AsString) {
        return $randomDate.ToString($Format)
    } else {
        return $randomDate
    }
}

function New-RandomNumber {
    <#
    .SYNOPSIS
        Génère un nombre aléatoire.
    .DESCRIPTION
        Génère un nombre aléatoire dans une plage spécifiée.
    .PARAMETER Min
        Valeur minimale (par défaut : 0).
    .PARAMETER Max
        Valeur maximale (par défaut : 100).
    .PARAMETER Decimal
        Indique si le nombre doit être décimal.
    .PARAMETER DecimalPlaces
        Nombre de décimales (par défaut : 2).
    .EXAMPLE
        New-RandomNumber
    .EXAMPLE
        New-RandomNumber -Min 1000 -Max 9999
    .EXAMPLE
        New-RandomNumber -Min 0 -Max 1 -Decimal -DecimalPlaces 4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Min = 0,

        [Parameter(Mandatory = $false)]
        [int]$Max = 100,

        [Parameter(Mandatory = $false)]
        [switch]$Decimal,

        [Parameter(Mandatory = $false)]
        [int]$DecimalPlaces = 2
    )

    $random = New-Object System.Random

    if ($Decimal) {
        $randomValue = $Min + $random.NextDouble() * ($Max - $Min)
        return [math]::Round($randomValue, $DecimalPlaces)
    } else {
        return $random.Next($Min, $Max + 1)
    }
}

function New-RandomBoolean {
    <#
    .SYNOPSIS
        Génère une valeur booléenne aléatoire.
    .DESCRIPTION
        Génère une valeur booléenne aléatoire (True ou False).
    .PARAMETER TrueProbability
        Probabilité d'obtenir True (entre 0 et 1, par défaut : 0.5).
    .EXAMPLE
        New-RandomBoolean
    .EXAMPLE
        New-RandomBoolean -TrueProbability 0.8
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$TrueProbability = 0.5
    )

    $random = New-Object System.Random
    return $random.NextDouble() -lt $TrueProbability
}

function New-RandomArray {
    <#
    .SYNOPSIS
        Génère un tableau aléatoire.
    .DESCRIPTION
        Génère un tableau aléatoire avec des éléments spécifiés ou générés.
    .PARAMETER Count
        Nombre d'éléments dans le tableau.
    .PARAMETER Generator
        Fonction de génération pour chaque élément.
    .PARAMETER Items
        Éléments à utiliser pour la génération aléatoire.
    .PARAMETER AllowDuplicates
        Indique si les doublons sont autorisés.
    .EXAMPLE
        New-RandomArray -Count 5 -Generator { New-RandomString -Length 8 }
    .EXAMPLE
        New-RandomArray -Count 3 -Items @("Rouge", "Vert", "Bleu", "Jaune", "Noir") -AllowDuplicates:$false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Count,

        [Parameter(Mandatory = $false, ParameterSetName = "Generator")]
        [scriptblock]$Generator,

        [Parameter(Mandatory = $false, ParameterSetName = "Items")]
        [array]$Items,

        [Parameter(Mandatory = $false, ParameterSetName = "Items")]
        [switch]$AllowDuplicates
    )

    $result = @()
    $random = New-Object System.Random

    if ($PSCmdlet.ParameterSetName -eq "Generator") {
        for ($i = 0; $i -lt $Count; $i++) {
            $result += & $Generator
        }
    } else {
        if (-not $AllowDuplicates -and $Count -gt $Items.Count) {
            throw "Le nombre d'éléments demandé ($Count) est supérieur au nombre d'éléments disponibles ($($Items.Count)) et les doublons ne sont pas autorisés."
        }

        $availableItems = $Items.Clone()
        for ($i = 0; $i -lt $Count; $i++) {
            if ($AllowDuplicates) {
                $index = $random.Next(0, $Items.Count)
                $result += $Items[$index]
            } else {
                $index = $random.Next(0, $availableItems.Count)
                $result += $availableItems[$index]
                $availableItems = $availableItems | Where-Object { $_ -ne $availableItems[$index] }
            }
        }
    }

    return $result
}

function New-RandomObject {
    <#
    .SYNOPSIS
        Génère un objet aléatoire.
    .DESCRIPTION
        Génère un objet aléatoire avec des propriétés spécifiées.
    .PARAMETER Properties
        Hashtable des propriétés à générer.
    .PARAMETER Count
        Nombre d'objets à générer.
    .PARAMETER AsHashtable
        Indique si les objets doivent être retournés sous forme de hashtables.
    .EXAMPLE
        New-RandomObject -Properties @{
            Id = { New-RandomNumber -Min 1 -Max 1000 }
            Name = { New-RandomString -Length 8 }
            Created = { New-RandomDate }
            Active = { New-RandomBoolean }
        }
    .EXAMPLE
        New-RandomObject -Properties @{
            Id = { New-RandomNumber -Min 1 -Max 1000 }
            Name = { New-RandomString -Length 8 }
        } -Count 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties,

        [Parameter(Mandatory = $false)]
        [int]$Count = 1,

        [Parameter(Mandatory = $false)]
        [switch]$AsHashtable
    )

    $result = @()

    for ($i = 0; $i -lt $Count; $i++) {
        if ($AsHashtable) {
            $obj = @{}
        } else {
            $obj = [PSCustomObject]@{}
        }

        foreach ($key in $Properties.Keys) {
            $valueGenerator = $Properties[$key]
            $value = & $valueGenerator

            if ($AsHashtable) {
                $obj[$key] = $value
            } else {
                $obj | Add-Member -MemberType NoteProperty -Name $key -Value $value
            }
        }

        $result += $obj
    }

    if ($Count -eq 1) {
        return $result[0]
    } else {
        return $result
    }
}

function New-RandomUsers {
    <#
    .SYNOPSIS
        Génère des utilisateurs aléatoires.
    .DESCRIPTION
        Génère des utilisateurs aléatoires avec des propriétés réalistes.
    .PARAMETER Count
        Nombre d'utilisateurs à générer.
    .PARAMETER IncludeAddress
        Indique si les adresses doivent être incluses.
    .PARAMETER IncludePhone
        Indique si les numéros de téléphone doivent être inclus.
    .PARAMETER IncludeCompany
        Indique si les informations d'entreprise doivent être incluses.
    .PARAMETER Locale
        Locale à utiliser pour la génération (fr-FR, en-US, etc.).
    .EXAMPLE
        New-RandomUsers -Count 10
    .EXAMPLE
        New-RandomUsers -Count 5 -IncludeAddress -IncludePhone -IncludeCompany -Locale "fr-FR"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Count = 1,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAddress,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePhone,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCompany,

        [Parameter(Mandatory = $false)]
        [string]$Locale = "fr-FR"
    )

    # Charger les données de test
    $firstNames = @("Jean", "Pierre", "Marie", "Sophie", "Thomas", "Julie", "Nicolas", "Isabelle", "François", "Émilie")
    $lastNames = @("Dupont", "Martin", "Durand", "Lefebvre", "Moreau", "Simon", "Laurent", "Michel", "Leroy", "Roux")
    $domains = @("gmail.com", "yahoo.fr", "hotmail.com", "outlook.com", "orange.fr", "free.fr", "sfr.fr", "laposte.net")
    $streets = @("Rue de la Paix", "Avenue des Champs-Élysées", "Boulevard Saint-Michel", "Rue de Rivoli", "Avenue Montaigne")
    $cities = @("Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes", "Strasbourg", "Montpellier", "Bordeaux", "Lille")
    $companies = @("Acme Inc.", "Globex", "Initech", "Umbrella Corp.", "Stark Industries", "Wayne Enterprises", "Cyberdyne Systems", "Soylent Corp.")
    $jobTitles = @("Développeur", "Chef de projet", "Directeur", "Consultant", "Analyste", "Designer", "Ingénieur", "Technicien")

    # Adapter les données selon la locale
    if ($Locale -eq "en-US") {
        $firstNames = @("John", "Michael", "David", "James", "Robert", "Mary", "Jennifer", "Linda", "Patricia", "Elizabeth")
        $lastNames = @("Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor")
        $streets = @("Main Street", "Broadway", "Park Avenue", "5th Avenue", "Oak Street")
        $cities = @("New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose")
    }

    # Générer les utilisateurs
    $users = New-RandomObject -Properties @{
        Id        = { New-RandomNumber -Min 1 -Max 10000 }
        FirstName = { New-RandomArray -Count 1 -Items $firstNames }
        LastName  = { New-RandomArray -Count 1 -Items $lastNames }
        Email     = {
            $firstName = New-RandomArray -Count 1 -Items $firstNames
            $lastName = New-RandomArray -Count 1 -Items $lastNames
            $domain = New-RandomArray -Count 1 -Items $domains
            "$($firstName.ToLower()).$($lastName.ToLower())@$domain"
        }
        BirthDate = { New-RandomDate -MinDate (Get-Date).AddYears(-80) -MaxDate (Get-Date).AddYears(-18) }
        Active    = { New-RandomBoolean -TrueProbability 0.8 }
        CreatedAt = { New-RandomDate -MinDate (Get-Date).AddYears(-2) -MaxDate (Get-Date) }
    } -Count $Count

    # Ajouter les adresses si demandé
    if ($IncludeAddress) {
        foreach ($user in $users) {
            $address = New-RandomObject -Properties @{
                Street  = { New-RandomArray -Count 1 -Items $streets }
                Number  = { New-RandomNumber -Min 1 -Max 100 }
                City    = { New-RandomArray -Count 1 -Items $cities }
                ZipCode = {
                    if ($Locale -eq "fr-FR") {
                        New-RandomString -Length 5 -CharacterSet Numeric
                    } else {
                        New-RandomString -Length 5 -CharacterSet Numeric
                    }
                }
                Country = { if ($Locale -eq "fr-FR") { "France" } else { "USA" } }
            }
            $user | Add-Member -MemberType NoteProperty -Name "Address" -Value $address
        }
    }

    # Ajouter les numéros de téléphone si demandé
    if ($IncludePhone) {
        foreach ($user in $users) {
            $phone = New-RandomObject -Properties @{
                Mobile = {
                    if ($Locale -eq "fr-FR") {
                        "0" + (New-RandomNumber -Min 6 -Max 7).ToString() + (New-RandomString -Length 8 -CharacterSet Numeric)
                    } else {
                        New-RandomString -Length 3 -CharacterSet Numeric + "-" + New-RandomString -Length 3 -CharacterSet Numeric + "-" + New-RandomString -Length 4 -CharacterSet Numeric
                    }
                }
                Home   = {
                    if ($Locale -eq "fr-FR") {
                        "0" + (New-RandomNumber -Min 1 -Max 5).ToString() + (New-RandomString -Length 8 -CharacterSet Numeric)
                    } else {
                        New-RandomString -Length 3 -CharacterSet Numeric + "-" + New-RandomString -Length 3 -CharacterSet Numeric + "-" + New-RandomString -Length 4 -CharacterSet Numeric
                    }
                }
            }
            $user | Add-Member -MemberType NoteProperty -Name "Phone" -Value $phone
        }
    }

    # Ajouter les informations d'entreprise si demandé
    if ($IncludeCompany) {
        foreach ($user in $users) {
            $company = New-RandomObject -Properties @{
                Name       = { New-RandomArray -Count 1 -Items $companies }
                JobTitle   = { New-RandomArray -Count 1 -Items $jobTitles }
                Department = { New-RandomArray -Count 1 -Items @("IT", "RH", "Finance", "Marketing", "Ventes", "R&D", "Production", "Juridique") }
                HireDate   = { New-RandomDate -MinDate (Get-Date).AddYears(-10) -MaxDate (Get-Date) }
            }
            $user | Add-Member -MemberType NoteProperty -Name "Company" -Value $company
        }
    }

    return $users
}

#endregion

#region Initialisation du module
function Initialize-TestDataGeneratorModule {
    <#
    .SYNOPSIS
        Initialise le module TestDataGenerator.
    .DESCRIPTION
        Crée les dossiers nécessaires et initialise les configurations du module.
    .EXAMPLE
        Initialize-TestDataGeneratorModule
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Créer les dossiers nécessaires s'ils n'existent pas
    $Folders = @(
        (Join-Path -Path $script:ModuleRoot -ChildPath "config"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "logs"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "data")
    )

    foreach ($Folder in $Folders) {
        if (-not (Test-Path -Path $Folder)) {
            if ($PSCmdlet.ShouldProcess($Folder, "Créer le dossier")) {
                New-Item -Path $Folder -ItemType Directory -Force | Out-Null
                Write-Verbose "Dossier créé : $Folder"
            }
        }
    }

    # Initialiser le fichier de configuration s'il n'existe pas
    if (-not (Test-Path -Path $script:ConfigPath)) {
        if ($PSCmdlet.ShouldProcess($script:ConfigPath, "Créer le fichier de configuration")) {
            $DefaultConfig = @{
                ModuleName = $script:ModuleName
                Version    = $script:ModuleVersion
                LogLevel   = "Info"
                LogPath    = $script:LogPath
                Enabled    = $true
                Settings   = @{
                    DataPath      = $script:DataPath
                    DefaultLocale = "fr-FR"
                }
            }

            $DefaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $script:ConfigPath -Encoding utf8
            Write-Verbose "Fichier de configuration créé : $script:ConfigPath"
        }
    }
}
#endregion

#region Exportation des fonctions
# Exporter uniquement les fonctions publiques
$FunctionsToExport = @(
    'New-RandomString'
    'New-RandomDate'
    'New-RandomNumber'
    'New-RandomBoolean'
    'New-RandomArray'
    'New-RandomObject'
    'New-RandomUsers'
)

# Ajouter les fonctions publiques si elles existent
if ($PublicFunctions -and $PublicFunctions.Count -gt 0) {
    $FunctionsToExport += $PublicFunctions.BaseName
}

Export-ModuleMember -Function $FunctionsToExport -Variable @()
#endregion

# Initialiser le module lors du chargement
Initialize-TestDataGeneratorModule
