# Extension du module : Ajout de nouvelles fonctionnalités

## 1. Structure générale des fonctions du module

### 1.1 Structure générale des fonctions

Le module `ExtractedInfoModuleV2` est conçu pour être extensible, permettant l'ajout de nouvelles fonctionnalités tout en maintenant la cohérence avec les fonctionnalités existantes. Cette section présente la structure générale des fonctions du module et les principes à suivre lors de l'ajout de nouvelles fonctions.

#### 1.1.1 Organisation des fonctions par catégories

Les fonctions du module sont organisées en plusieurs catégories fonctionnelles :

| Catégorie | Préfixe courant | Description | Exemples |
|-----------|-----------------|-------------|----------|
| **Création** | `New-` | Fonctions qui créent de nouveaux objets d'information extraite | `New-ExtractedInfo`, `New-TextExtractedInfo` |
| **Manipulation** | `Copy-`, `Add-`, `Remove-` | Fonctions qui modifient des objets existants | `Copy-ExtractedInfo`, `Add-ExtractedInfoMetadata` |
| **Collection** | `New-`, `Add-`, `Get-` | Fonctions qui gèrent des collections d'objets | `New-ExtractedInfoCollection`, `Add-ExtractedInfoToCollection` |
| **Sérialisation** | `ConvertTo-`, `ConvertFrom-`, `Save-`, `Load-` | Fonctions qui convertissent ou persistent des objets | `ConvertTo-ExtractedInfoJson`, `Save-ExtractedInfoToFile` |
| **Validation** | `Test-`, `Get-`, `Add-`, `Remove-` | Fonctions qui valident des objets ou gèrent des règles de validation | `Test-ExtractedInfo`, `Add-ExtractedInfoValidationRule` |
| **Utilitaires** | Divers | Fonctions auxiliaires pour des tâches spécifiques | `Get-ExtractedInfoSummary`, `Format-ExtractedInfo` |

#### 1.1.2 Structure interne des fonctions

Les fonctions du module suivent une structure interne cohérente :

```powershell
function Verb-NounExtractedInfo {
    <#

    .SYNOPSIS
    Brève description de la fonction (1-2 lignes).

    .DESCRIPTION
    Description détaillée de la fonction, expliquant son objectif,
    son fonctionnement et ses cas d'utilisation.

    .PARAMETER ParameterName
    Description du paramètre.

    .EXAMPLE
    Exemple d'utilisation de la fonction.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]$MainParameter,

        [Parameter(Mandatory = $false)]
        [string]$OptionalParameter = "DefaultValue"
    )

    begin {
        # Code exécuté une fois au début, avant le traitement du pipeline

        Write-Verbose "Démarrage de Verb-NounExtractedInfo"
    }

    process {
        # Code exécuté pour chaque élément du pipeline

        # 1. Validation des paramètres

        if (-not $MainParameter.ContainsKey("RequiredProperty")) {
            throw "Le paramètre MainParameter doit contenir la propriété 'RequiredProperty'"
        }

        # 2. Traitement principal

        $result = $MainParameter.Clone() # Éviter de modifier l'objet original

        # 3. Modification de l'objet

        $result.NewProperty = "Value"

        # 4. Retour du résultat

        return $result
    }

    end {
        # Code exécuté une fois à la fin, après le traitement du pipeline

        Write-Verbose "Fin de Verb-NounExtractedInfo"
    }
}
```plaintext
#### 1.1.3 Principes de conception des fonctions

Les fonctions du module suivent plusieurs principes de conception importants :

1. **Immutabilité** : Les fonctions ne modifient pas les objets d'entrée, mais retournent de nouveaux objets modifiés. Cela permet d'éviter les effets de bord indésirables.

```powershell
# Exemple d'immutabilité

function Add-PropertyToInfo {
    param ([hashtable]$Info, [string]$Key, [object]$Value)

    $result = $Info.Clone() # Créer une copie pour ne pas modifier l'original

    $result[$Key] = $Value
    return $result
}
```plaintext
2. **Support du pipeline** : Les fonctions qui traitent des objets d'information extraite acceptent les entrées via le pipeline, ce qui permet de créer des chaînes de traitement.

```powershell
# Exemple de support du pipeline

function Process-ExtractedInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    process {
        # Traitement de chaque objet du pipeline

        return $Info
    }
}

# Utilisation avec le pipeline

$info | Process-ExtractedInfo | Another-Function
```plaintext
3. **Gestion des erreurs** : Les fonctions utilisent des mécanismes de gestion des erreurs cohérents, avec des messages d'erreur clairs et informatifs.

```powershell
# Exemple de gestion des erreurs

function Validate-RequiredProperties {
    param ([hashtable]$Info, [string[]]$RequiredProperties)

    foreach ($prop in $RequiredProperties) {
        if (-not $Info.ContainsKey($prop)) {
            throw "Propriété requise manquante : $prop"
        }
    }
}
```plaintext
4. **Verbosité configurable** : Les fonctions utilisent `Write-Verbose` pour fournir des informations détaillées sur leur exécution, qui peuvent être activées ou désactivées selon les besoins.

```powershell
# Exemple de verbosité configurable

function Process-WithVerbosity {
    [CmdletBinding()]
    param ([hashtable]$Info)

    Write-Verbose "Traitement de l'objet avec ID : $($Info.Id)"
    # Traitement...

    Write-Verbose "Traitement terminé"
}

# Activation de la verbosité

Process-WithVerbosity -Info $info -Verbose
```plaintext
5. **Validation des paramètres** : Les fonctions utilisent des attributs de validation pour garantir que les paramètres respectent certaines contraintes.

```powershell
# Exemple de validation des paramètres

function Set-ConfidenceScore {
    param (
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$Score
    )

    $result = $Info.Clone()
    $result.ConfidenceScore = $Score
    return $result
}
```plaintext
#### 1.1.4 Documentation des fonctions

Toutes les fonctions du module sont documentées de manière cohérente avec des commentaires d'aide PowerShell :

1. **Synopsis** : Une brève description de la fonction (1-2 lignes).
2. **Description** : Une description détaillée de la fonction, son objectif et son fonctionnement.
3. **Paramètres** : Description de chaque paramètre, y compris son type, s'il est obligatoire, et sa signification.
4. **Exemples** : Au moins un exemple d'utilisation de la fonction.
5. **Notes** : Informations supplémentaires, limitations, ou considérations particulières.
6. **Liens** : Références à d'autres fonctions connexes.

```powershell
<#

.SYNOPSIS
Ajoute une métadonnée à un objet d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoMetadata ajoute une métadonnée à un objet d'information extraite.
Elle crée une copie de l'objet original pour éviter de le modifier directement.

.PARAMETER Info
L'objet d'information extraite auquel ajouter la métadonnée.

.PARAMETER Key
La clé de la métadonnée à ajouter.

.PARAMETER Value
La valeur de la métadonnée à ajouter.

.EXAMPLE
$info = New-ExtractedInfo -Source "document.txt"
$infoWithMetadata = Add-ExtractedInfoMetadata -Info $info -Key "Author" -Value "John Doe"

.NOTES
Cette fonction ne modifie pas l'objet original, mais retourne une nouvelle copie.

.LINK
Get-ExtractedInfoMetadata
Remove-ExtractedInfoMetadata
#>

```plaintext
#### 1.1.5 Tests unitaires

Chaque fonction du module est accompagnée de tests unitaires qui vérifient son comportement dans différentes situations :

1. **Tests de cas normaux** : Vérifier que la fonction fonctionne correctement avec des entrées valides.
2. **Tests de cas limites** : Vérifier que la fonction gère correctement les cas limites (valeurs minimales, maximales, etc.).
3. **Tests d'erreurs** : Vérifier que la fonction génère les erreurs appropriées avec des entrées invalides.
4. **Tests de performance** : Vérifier que la fonction a des performances acceptables avec des entrées volumineuses.

```powershell
# Exemple de test unitaire avec Pester

Describe "Add-ExtractedInfoMetadata" {
    BeforeAll {
        $info = New-ExtractedInfo -Source "test.txt"
    }

    It "Ajoute une métadonnée simple" {
        $result = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
        $result.Metadata.TestKey | Should -Be "TestValue"
    }

    It "Ne modifie pas l'objet original" {
        $original = $info.Clone()
        $result = Add-ExtractedInfoMetadata -Info $info -Key "AnotherKey" -Value "AnotherValue"
        $info | Should -BeExactly $original
    }

    It "Remplace une métadonnée existante" {
        $infoWithMeta = Add-ExtractedInfoMetadata -Info $info -Key "ExistingKey" -Value "OriginalValue"
        $result = Add-ExtractedInfoMetadata -Info $infoWithMeta -Key "ExistingKey" -Value "NewValue"
        $result.Metadata.ExistingKey | Should -Be "NewValue"
    }

    It "Génère une erreur avec un objet null" {
        { Add-ExtractedInfoMetadata -Info $null -Key "Key" -Value "Value" } | Should -Throw
    }
}
```plaintext
#### 1.1.6 Intégration avec les autres fonctions

Les nouvelles fonctions doivent s'intégrer harmonieusement avec les fonctions existantes du module :

1. **Cohérence des interfaces** : Les nouvelles fonctions doivent avoir des interfaces cohérentes avec les fonctions existantes (noms de paramètres, types de retour, etc.).

2. **Réutilisation du code** : Les nouvelles fonctions doivent réutiliser les fonctions existantes lorsque c'est approprié, plutôt que de dupliquer du code.

3. **Chaînage via le pipeline** : Les nouvelles fonctions doivent pouvoir être chaînées avec les fonctions existantes via le pipeline PowerShell.

```powershell
# Exemple d'intégration avec les fonctions existantes

function Add-ExtractedInfoTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    process {
        # Réutilisation de Add-ExtractedInfoMetadata

        $result = Add-ExtractedInfoMetadata -Info $Info -Key "Tags" -Value @($Tag)

        # Si Tags existe déjà et est un tableau, ajouter le nouveau tag

        if ($Info.Metadata.ContainsKey("Tags") -and $Info.Metadata.Tags -is [array]) {
            $tags = $Info.Metadata.Tags + $Tag
            $result = Add-ExtractedInfoMetadata -Info $Info -Key "Tags" -Value $tags
        }

        return $result
    }
}

# Utilisation avec le pipeline et d'autres fonctions

$info | Add-ExtractedInfoTag -Tag "Important" | Save-ExtractedInfoToFile -FilePath "tagged_info.json"
```plaintext
En suivant ces principes et cette structure, vous pouvez créer de nouvelles fonctions qui s'intègrent parfaitement avec le module existant et qui maintiennent sa cohérence et sa qualité.

### 1.2 Conventions de paramètres et de retour

Pour maintenir la cohérence du module, il est important de suivre des conventions spécifiques pour les paramètres et les valeurs de retour des fonctions. Cette section détaille ces conventions et fournit des exemples de leur application.

#### 1.2.1 Conventions de paramètres

##### Paramètres communs

Certains paramètres sont utilisés de manière cohérente dans tout le module :

| Paramètre | Type | Description | Utilisation |
|-----------|------|-------------|-------------|
| `Info` | `[hashtable]` | Objet d'information extraite à traiter | Utilisé dans les fonctions qui manipulent un objet existant |
| `InfoList` | `[hashtable[]]` | Liste d'objets d'information extraite | Utilisé pour traiter plusieurs objets à la fois |
| `Collection` | `[hashtable]` | Collection d'objets d'information extraite | Utilisé dans les fonctions qui manipulent des collections |
| `Source` | `[string]` | Source de l'information extraite | Utilisé dans les fonctions de création |
| `ExtractorName` | `[string]` | Nom de l'extracteur utilisé | Utilisé dans les fonctions de création |
| `ProcessingState` | `[string]` | État de traitement de l'information | Utilisé dans les fonctions de création et de mise à jour |
| `ConfidenceScore` | `[int]` | Score de confiance (0-100) | Utilisé dans les fonctions de création et de mise à jour |
| `Metadata` | `[hashtable]` | Métadonnées associées à l'information | Utilisé dans les fonctions de métadonnées |

##### Attributs de paramètres

Les paramètres utilisent des attributs PowerShell pour définir leur comportement :

1. **Mandatory** : Indique si le paramètre est obligatoire.

```powershell
[Parameter(Mandatory = $true)]
[hashtable]$Info
```plaintext
2. **ValueFromPipeline** : Permet au paramètre de recevoir des valeurs via le pipeline.

```powershell
[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
[hashtable]$Info
```plaintext
3. **Position** : Définit la position du paramètre dans l'appel de fonction (rarement utilisé dans le module).

```powershell
[Parameter(Mandatory = $true, Position = 0)]
[string]$Source
```plaintext
4. **ParameterSetName** : Groupe les paramètres en ensembles mutuellement exclusifs.

```powershell
[Parameter(Mandatory = $true, ParameterSetName = "ByInfo")]
[hashtable]$Info,

[Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
[string]$FilePath
```plaintext
##### Validation des paramètres

Les paramètres utilisent des attributs de validation pour garantir leur validité :

1. **ValidateNotNull** / **ValidateNotNullOrEmpty** : Vérifie que le paramètre n'est pas null ou vide.

```powershell
[Parameter(Mandatory = $true)]
[ValidateNotNull()]
[hashtable]$Info
```plaintext
2. **ValidateRange** : Vérifie que la valeur est dans une plage spécifiée.

```powershell
[ValidateRange(0, 100)]
[int]$ConfidenceScore = 50
```plaintext
3. **ValidateSet** : Vérifie que la valeur est l'une des valeurs spécifiées.

```powershell
[ValidateSet("Raw", "Processed", "Validated", "Error")]
[string]$ProcessingState = "Raw"
```plaintext
4. **ValidateScript** : Utilise un script pour valider la valeur.

```powershell
[ValidateScript({ Test-Path $_ -PathType Leaf })]
[string]$FilePath
```plaintext
##### Valeurs par défaut

Les paramètres optionnels ont généralement des valeurs par défaut raisonnables :

```powershell
[string]$Source = "Unknown",
[string]$ExtractorName = "GenericExtractor",
[string]$ProcessingState = "Raw",
[int]$ConfidenceScore = 50,
[switch]$Force = $false
```plaintext
##### Paramètres communs PowerShell

Toutes les fonctions du module supportent les paramètres communs PowerShell grâce à l'attribut `[CmdletBinding()]` :

- `-Verbose` : Active les messages détaillés
- `-Debug` : Active les messages de débogage
- `-ErrorAction` : Définit le comportement en cas d'erreur
- `-ErrorVariable` : Stocke les erreurs dans une variable
- `-WarningAction` : Définit le comportement pour les avertissements
- `-WarningVariable` : Stocke les avertissements dans une variable
- `-InformationAction` : Définit le comportement pour les informations
- `-InformationVariable` : Stocke les informations dans une variable

```powershell
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [hashtable]$Info
)

# Utilisation

Process-Info -Info $info -Verbose -ErrorAction Stop
```plaintext
#### 1.2.2 Conventions de retour

##### Types de retour

Les fonctions du module retournent généralement l'un des types suivants :

| Type de fonction | Type de retour | Description | Exemple |
|------------------|----------------|-------------|---------|
| Création | `[hashtable]` | Nouvel objet d'information extraite | `New-ExtractedInfo` |
| Manipulation | `[hashtable]` | Objet d'information extraite modifié | `Add-ExtractedInfoMetadata` |
| Collection | `[hashtable]` | Collection modifiée ou objets extraits | `Add-ExtractedInfoToCollection` |
| Sérialisation | `[string]` ou `[bool]` | JSON ou indicateur de succès | `ConvertTo-ExtractedInfoJson` |
| Validation | `[bool]` ou `[string[]]` | Résultat de validation ou erreurs | `Test-ExtractedInfo` |
| Utilitaires | Divers | Dépend de la fonction | `Get-ExtractedInfoSummary` |

##### Immutabilité des objets

Les fonctions qui manipulent des objets d'information extraite ne modifient jamais les objets d'entrée, mais retournent de nouveaux objets modifiés :

```powershell
function Add-PropertyToExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [object]$PropertyValue
    )

    # Créer une copie de l'objet original

    $result = $Info.Clone()

    # Modifier la copie

    $result[$PropertyName] = $PropertyValue

    # Mettre à jour la date de dernière modification

    $result.LastModifiedDate = Get-Date

    # Retourner la copie modifiée

    return $result
}
```plaintext
##### Retour de collections

Les fonctions qui manipulent des collections retournent généralement la collection modifiée :

```powershell
function Add-ItemToCollection {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Collection,

        [Parameter(Mandatory = $true)]
        [hashtable]$Item
    )

    # Créer une copie de la collection

    $result = $Collection.Clone()

    # Ajouter l'élément à la copie

    $result.Items += $Item

    # Mettre à jour les index si nécessaire

    # ...

    # Retourner la collection modifiée

    return $result
}
```plaintext
##### Retour de résultats détaillés

Certaines fonctions peuvent retourner des résultats détaillés sous forme de hashtable :

```powershell
function Test-ExtractedInfoDetailed {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    $errors = @()

    # Effectuer des validations

    if (-not $Info.ContainsKey("Id")) {
        $errors += "Missing required property: Id"
    }

    # Retourner un résultat détaillé

    return @{
        IsValid = ($errors.Count -eq 0)
        ObjectType = $Info._Type
        Errors = $errors
    }
}
```plaintext
##### Gestion des erreurs dans les valeurs de retour

Les fonctions qui peuvent échouer utilisent généralement des exceptions plutôt que des codes de retour :

```powershell
function Process-CriticalOperation {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    if (-not (Test-ExtractedInfo -Info $Info)) {
        throw "L'objet d'information extraite n'est pas valide"
    }

    # Traitement...

    return $result
}
```plaintext
Cependant, certaines fonctions utilitaires peuvent retourner `$null` ou une valeur spéciale pour indiquer un échec :

```powershell
function Try-GetProperty {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    if ($Info.ContainsKey($PropertyName)) {
        return $Info[$PropertyName]
    }
    else {
        return $null
    }
}
```plaintext
#### 1.2.3 Exemples d'application des conventions

##### Exemple 1 : Fonction de création

```powershell
function New-CustomExtractedInfo {
    <#

    .SYNOPSIS
    Crée un nouvel objet d'information extraite personnalisé.

    .DESCRIPTION
    Cette fonction crée un nouvel objet d'information extraite personnalisé avec les propriétés spécifiées.

    .PARAMETER CustomProperty
    Propriété personnalisée spécifique à ce type d'information.

    .PARAMETER Source
    Source de l'information extraite.

    .PARAMETER ExtractorName
    Nom de l'extracteur utilisé.

    .PARAMETER ProcessingState
    État de traitement de l'information.

    .PARAMETER ConfidenceScore
    Score de confiance (0-100).

    .EXAMPLE
    $info = New-CustomExtractedInfo -CustomProperty "Value" -Source "document.txt"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CustomProperty,

        [string]$Source = "Unknown",

        [string]$ExtractorName = "CustomExtractor",

        [ValidateSet("Raw", "Processed", "Validated", "Error")]
        [string]$ProcessingState = "Raw",

        [ValidateRange(0, 100)]
        [int]$ConfidenceScore = 50
    )

    # Créer un objet de base

    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName -ProcessingState $ProcessingState -ConfidenceScore $ConfidenceScore

    # Modifier le type

    $info._Type = "CustomExtractedInfo"

    # Ajouter la propriété personnalisée

    $info.CustomProperty = $CustomProperty

    return $info
}
```plaintext
##### Exemple 2 : Fonction de manipulation

```powershell
function Set-ExtractedInfoProperty {
    <#

    .SYNOPSIS
    Définit une propriété dans un objet d'information extraite.

    .DESCRIPTION
    Cette fonction définit une propriété dans un objet d'information extraite et retourne une copie modifiée.

    .PARAMETER Info
    L'objet d'information extraite à modifier.

    .PARAMETER PropertyName
    Nom de la propriété à définir.

    .PARAMETER PropertyValue
    Valeur de la propriété à définir.

    .PARAMETER Force
    Indique si la propriété doit être remplacée si elle existe déjà.

    .EXAMPLE
    $modifiedInfo = Set-ExtractedInfoProperty -Info $info -PropertyName "Category" -PropertyValue "Document"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [object]$PropertyValue,

        [switch]$Force = $false
    )

    process {
        # Vérifier si la propriété existe déjà

        if ($Info.ContainsKey($PropertyName) -and -not $Force) {
            throw "La propriété '$PropertyName' existe déjà. Utilisez -Force pour la remplacer."
        }

        # Créer une copie de l'objet

        $result = $Info.Clone()

        # Définir la propriété

        $result[$PropertyName] = $PropertyValue

        # Mettre à jour la date de dernière modification

        $result.LastModifiedDate = Get-Date

        return $result
    }
}
```plaintext
##### Exemple 3 : Fonction de validation

```powershell
function Test-CustomExtractedInfo {
    <#

    .SYNOPSIS
    Vérifie si un objet est un objet CustomExtractedInfo valide.

    .DESCRIPTION
    Cette fonction vérifie si un objet est un objet CustomExtractedInfo valide en vérifiant
    la présence des propriétés requises et la validité des valeurs.

    .PARAMETER Info
    L'objet à vérifier.

    .PARAMETER Detailed
    Indique si le résultat doit inclure des informations détaillées sur les erreurs.

    .EXAMPLE
    $isValid = Test-CustomExtractedInfo -Info $info

    .EXAMPLE
    $validationResult = Test-CustomExtractedInfo -Info $info -Detailed
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]$Info,

        [switch]$Detailed = $false
    )

    process {
        $errors = @()

        # Vérifier le type

        if ($Info._Type -ne "CustomExtractedInfo") {
            $errors += "Type invalide : $($Info._Type) (attendu : CustomExtractedInfo)"
        }

        # Vérifier les propriétés de base (via la fonction existante)

        $baseValidation = Get-ExtractedInfoValidationErrors -Info $Info
        $errors += $baseValidation

        # Vérifier la propriété spécifique

        if (-not $Info.ContainsKey("CustomProperty")) {
            $errors += "Propriété requise manquante : CustomProperty"
        }
        elseif ([string]::IsNullOrEmpty($Info.CustomProperty)) {
            $errors += "La propriété CustomProperty ne peut pas être vide"
        }

        # Retourner le résultat

        if ($Detailed) {
            return @{
                IsValid = ($errors.Count -eq 0)
                ObjectType = $Info._Type
                Errors = $errors
            }
        }
        else {
            return ($errors.Count -eq 0)
        }
    }
}
```plaintext
En suivant ces conventions de paramètres et de retour, vous pouvez créer des fonctions qui s'intègrent parfaitement avec le module existant et qui offrent une expérience utilisateur cohérente.

### 1.3 Gestion des erreurs et validation

La gestion des erreurs et la validation des entrées sont des aspects cruciaux du développement de fonctions robustes pour le module `ExtractedInfoModuleV2`. Cette section détaille les approches recommandées pour implémenter ces mécanismes dans vos nouvelles fonctions.

#### 1.3.1 Principes de gestion des erreurs

La gestion des erreurs dans le module suit plusieurs principes fondamentaux :

1. **Validation précoce** : Valider les entrées le plus tôt possible dans la fonction pour éviter les erreurs en aval.
2. **Messages d'erreur clairs** : Fournir des messages d'erreur détaillés et informatifs qui aident à comprendre et à résoudre le problème.
3. **Exceptions plutôt que codes de retour** : Utiliser des exceptions pour signaler les erreurs plutôt que des codes de retour ou des valeurs spéciales.
4. **Préservation du contexte** : Inclure des informations contextuelles dans les messages d'erreur pour faciliter le débogage.
5. **Nettoyage approprié** : S'assurer que les ressources sont correctement libérées en cas d'erreur.

#### 1.3.2 Types d'erreurs

Les fonctions du module peuvent rencontrer différents types d'erreurs :

1. **Erreurs de validation des paramètres** : Les paramètres fournis ne respectent pas les contraintes définies.
2. **Erreurs de validation des objets** : Les objets d'information extraite ne sont pas valides selon les règles du module.
3. **Erreurs d'exécution** : Des erreurs surviennent pendant l'exécution de la fonction (fichier introuvable, opération non autorisée, etc.).
4. **Erreurs de logique métier** : Des erreurs liées à la logique métier spécifique de la fonction.

#### 1.3.3 Mécanismes de validation

##### Validation des paramètres

La validation des paramètres est effectuée à plusieurs niveaux :

1. **Attributs de validation PowerShell** : Utilisés pour les validations simples et standard.

```powershell
[Parameter(Mandatory = $true)]
[ValidateNotNull()]
[ValidateRange(0, 100)]
[int]$ConfidenceScore
```plaintext
2. **Validation manuelle dans le corps de la fonction** : Utilisée pour les validations plus complexes ou spécifiques.

```powershell
if ($PropertyName -match '[^a-zA-Z0-9_]') {
    throw "Le nom de propriété '$PropertyName' contient des caractères non autorisés. Utilisez uniquement des lettres, des chiffres et des underscores."
}
```plaintext
3. **Validation conditionnelle** : Utilisée lorsque la validation dépend de certaines conditions.

```powershell
if ($ProcessingState -eq "Validated" -and $ConfidenceScore -lt 80) {
    throw "Un objet avec l'état 'Validated' doit avoir un score de confiance d'au moins 80 (actuel : $ConfidenceScore)."
}
```plaintext
##### Validation des objets

La validation des objets d'information extraite est généralement effectuée à l'aide des fonctions de validation du module :

```powershell
# Validation simple

if (-not (Test-ExtractedInfo -Info $Info)) {
    throw "L'objet d'information extraite n'est pas valide."
}

# Validation détaillée

$validationResult = Get-ExtractedInfoValidationErrors -Info $Info
if ($validationResult.Count -gt 0) {
    $errorMessage = "L'objet d'information extraite n'est pas valide :`n"
    $errorMessage += $validationResult -join "`n"
    throw $errorMessage
}
```plaintext
Pour les types personnalisés, vous pouvez créer des fonctions de validation spécifiques :

```powershell
function Test-CustomExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Vérifier d'abord que c'est un objet d'information extraite valide

    if (-not (Test-ExtractedInfo -Info $Info)) {
        return $false
    }

    # Vérifier que c'est bien du type attendu

    if ($Info._Type -ne "CustomExtractedInfo") {
        return $false
    }

    # Vérifier les propriétés spécifiques

    if (-not $Info.ContainsKey("CustomProperty") -or [string]::IsNullOrEmpty($Info.CustomProperty)) {
        return $false
    }

    return $true
}
```plaintext
#### 1.3.4 Gestion des exceptions

##### Génération d'exceptions

Les fonctions du module utilisent l'instruction `throw` pour générer des exceptions :

```powershell
function Process-CriticalOperation {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    if (-not (Test-ExtractedInfo -Info $Info)) {
        throw "L'objet d'information extraite n'est pas valide."
    }

    if (-not (Test-Path $OutputPath)) {
        throw "Le chemin de sortie '$OutputPath' n'existe pas."
    }

    try {
        # Opération qui peut échouer

        $result = Invoke-RiskyOperation -Input $Info
    }
    catch {
        throw "Échec de l'opération critique : $_"
    }

    return $result
}
```plaintext
##### Capture et gestion des exceptions

Les fonctions qui appellent d'autres fonctions doivent gérer les exceptions de manière appropriée :

```powershell
function Safe-ProcessMultipleItems {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable[]]$Items
    )

    $results = @()
    $errors = @()

    foreach ($item in $Items) {
        try {
            $result = Process-CriticalOperation -Info $item
            $results += $result
        }
        catch {
            $errors += "Erreur lors du traitement de l'élément $($item.Id) : $_"
            Write-Warning "Échec du traitement de l'élément $($item.Id) : $_"
            # Continuer avec l'élément suivant

        }
    }

    # Journaliser les erreurs

    if ($errors.Count -gt 0) {
        $errorLog = Join-Path $env:TEMP "ProcessErrors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $errors | Out-File -FilePath $errorLog -Encoding utf8
        Write-Warning "Des erreurs se sont produites. Consultez le journal des erreurs : $errorLog"
    }

    return $results
}
```plaintext
##### Nettoyage des ressources

Utilisez des blocs `try`/`finally` pour garantir que les ressources sont correctement libérées, même en cas d'erreur :

```powershell
function Process-WithCleanup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $tempFile = Join-Path $env:TEMP "temp_$(Get-Date -Format 'yyyyMMdd_HHmmss').tmp"

    try {
        # Créer le fichier temporaire

        "Contenu temporaire" | Out-File -FilePath $tempFile -Encoding utf8

        # Opération qui peut échouer

        $result = Process-File -InputPath $tempFile -OutputPath $FilePath

        return $result
    }
    catch {
        Write-Error "Erreur lors du traitement du fichier : $_"
        throw
    }
    finally {
        # Nettoyer, même en cas d'erreur

        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force
            Write-Verbose "Fichier temporaire supprimé : $tempFile"
        }
    }
}
```plaintext
#### 1.3.5 Journalisation et débogage

##### Messages de journalisation

Utilisez les cmdlets de journalisation PowerShell pour fournir des informations utiles :

```powershell
function Process-WithLogging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    Write-Verbose "Début du traitement de l'objet $($Info.Id)"

    # Validation

    if (-not (Test-ExtractedInfo -Info $Info)) {
        Write-Error "L'objet $($Info.Id) n'est pas valide"
        return $null
    }

    # Traitement

    Write-Verbose "Étape 1 : Préparation des données"
    # ...

    Write-Verbose "Étape 2 : Transformation"
    # ...

    if ($WarningCondition) {
        Write-Warning "Condition inhabituelle détectée : $WarningCondition"
    }

    Write-Verbose "Traitement terminé avec succès"
    return $result
}
```plaintext
##### Débogage

Incluez des informations de débogage détaillées qui peuvent être activées avec le paramètre `-Debug` :

```powershell
function Process-WithDebug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    Write-Debug "Entrée : $($Info | ConvertTo-Json -Depth 2)"

    # Traitement

    $intermediateResult = Transform-Data -Input $Info.Data
    Write-Debug "Résultat intermédiaire : $($intermediateResult | ConvertTo-Json -Depth 2)"

    $finalResult = Format-Output -Input $intermediateResult
    Write-Debug "Résultat final : $($finalResult | ConvertTo-Json -Depth 2)"

    return $finalResult
}
```plaintext
#### 1.3.6 Exemples complets de gestion des erreurs

##### Exemple 1 : Fonction avec validation complète

```powershell
function Update-ExtractedInfoStatus {
    <#

    .SYNOPSIS
    Met à jour l'état de traitement d'un objet d'information extraite.

    .DESCRIPTION
    Cette fonction met à jour l'état de traitement d'un objet d'information extraite
    et effectue les validations nécessaires pour garantir la cohérence des données.

    .PARAMETER Info
    L'objet d'information extraite à mettre à jour.

    .PARAMETER ProcessingState
    Le nouvel état de traitement. Valeurs valides : "Raw", "Processed", "Validated", "Error".

    .PARAMETER ErrorReason
    La raison de l'erreur, obligatoire si ProcessingState est "Error".

    .PARAMETER ConfidenceScore
    Le nouveau score de confiance (0-100), obligatoire si ProcessingState est "Validated".

    .EXAMPLE
    $updatedInfo = Update-ExtractedInfoStatus -Info $info -ProcessingState "Processed" -ConfidenceScore 75
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Raw", "Processed", "Validated", "Error")]
        [string]$ProcessingState,

        [Parameter(Mandatory = $false)]
        [string]$ErrorReason,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$ConfidenceScore
    )

    begin {
        Write-Verbose "Début de Update-ExtractedInfoStatus"
    }

    process {
        try {
            # Validation de l'objet d'entrée

            if (-not (Test-ExtractedInfo -Info $Info)) {
                $errors = Get-ExtractedInfoValidationErrors -Info $Info
                $errorMessage = "L'objet d'information extraite n'est pas valide :`n"
                $errorMessage += $errors -join "`n"
                throw $errorMessage
            }

            Write-Debug "Objet d'entrée valide : $($Info.Id), état actuel : $($Info.ProcessingState)"

            # Validation des paramètres en fonction de l'état

            if ($ProcessingState -eq "Error" -and [string]::IsNullOrEmpty($ErrorReason)) {
                throw "Le paramètre ErrorReason est obligatoire lorsque ProcessingState est 'Error'."
            }

            if ($ProcessingState -eq "Validated") {
                if (-not $PSBoundParameters.ContainsKey('ConfidenceScore')) {
                    throw "Le paramètre ConfidenceScore est obligatoire lorsque ProcessingState est 'Validated'."
                }

                if ($ConfidenceScore -lt 80) {
                    throw "Le score de confiance doit être d'au moins 80 pour l'état 'Validated' (actuel : $ConfidenceScore)."
                }
            }

            # Créer une copie de l'objet

            $result = $Info.Clone()

            # Mettre à jour l'état

            $result.ProcessingState = $ProcessingState
            $result.LastModifiedDate = Get-Date

            # Mettre à jour le score de confiance si spécifié

            if ($PSBoundParameters.ContainsKey('ConfidenceScore')) {
                $result.ConfidenceScore = $ConfidenceScore
            }

            # Gérer les métadonnées spécifiques à l'état

            if ($ProcessingState -eq "Error") {
                $result = Add-ExtractedInfoMetadata -Info $result -Key "ErrorReason" -Value $ErrorReason
                $result = Add-ExtractedInfoMetadata -Info $result -Key "ErrorDate" -Value (Get-Date)
            }
            elseif ($ProcessingState -eq "Validated") {
                $result = Add-ExtractedInfoMetadata -Info $result -Key "ValidationDate" -Value (Get-Date)
                $result = Add-ExtractedInfoMetadata -Info $result -Key "ValidatedBy" -Value $env:USERNAME
            }

            Write-Verbose "État mis à jour avec succès : $ProcessingState"
            Write-Debug "Objet de sortie : $($result | ConvertTo-Json -Depth 3)"

            return $result
        }
        catch {
            Write-Error "Erreur dans Update-ExtractedInfoStatus : $_"
            throw
        }
    }

    end {
        Write-Verbose "Fin de Update-ExtractedInfoStatus"
    }
}
```plaintext
##### Exemple 2 : Fonction avec gestion d'erreurs avancée

```powershell
function Export-ExtractedInfoBatch {
    <#

    .SYNOPSIS
    Exporte un lot d'objets d'information extraite vers des fichiers.

    .DESCRIPTION
    Cette fonction exporte un lot d'objets d'information extraite vers des fichiers
    dans le répertoire spécifié, avec gestion des erreurs et journalisation.

    .PARAMETER InfoList
    Liste des objets d'information extraite à exporter.

    .PARAMETER OutputDirectory
    Répertoire de sortie pour les fichiers exportés.

    .PARAMETER Format
    Format d'exportation. Valeurs valides : "JSON", "CSV", "XML".

    .PARAMETER ContinueOnError
    Indique si l'exportation doit continuer en cas d'erreur sur un objet.

    .EXAMPLE
    Export-ExtractedInfoBatch -InfoList $infoList -OutputDirectory "C:\Exports" -Format "JSON"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]$InfoList,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "XML")]
        [string]$Format = "JSON",

        [Parameter(Mandatory = $false)]
        [switch]$ContinueOnError = $false
    )

    begin {
        Write-Verbose "Début de Export-ExtractedInfoBatch"

        # Initialiser les compteurs et les journaux

        $successCount = 0
        $errorCount = 0
        $errors = @()

        # Créer un journal d'exportation

        $logFile = Join-Path $OutputDirectory "Export_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        "Début de l'exportation : $(Get-Date)" | Out-File -FilePath $logFile -Encoding utf8
        "Format : $Format" | Out-File -FilePath $logFile -Encoding utf8 -Append

        # Vérifier que le répertoire de sortie est accessible en écriture

        try {
            $testFile = Join-Path $OutputDirectory "test.tmp"
            "Test" | Out-File -FilePath $testFile -Encoding utf8
            Remove-Item -Path $testFile -Force
            Write-Verbose "Répertoire de sortie accessible en écriture : $OutputDirectory"
        }
        catch {
            $errorMessage = "Le répertoire de sortie n'est pas accessible en écriture : $OutputDirectory. Erreur : $_"
            Write-Error $errorMessage
            throw $errorMessage
        }
    }

    process {
        foreach ($info in $InfoList) {
            try {
                # Valider l'objet

                if (-not (Test-ExtractedInfo -Info $info)) {
                    throw "L'objet n'est pas un objet d'information extraite valide."
                }

                # Générer le nom de fichier

                $fileName = "$($info.Id)_$($info._Type)"
                $filePath = Join-Path $OutputDirectory "$fileName.$($Format.ToLower())"

                Write-Verbose "Exportation de l'objet $($info.Id) vers $filePath"

                # Exporter selon le format

                switch ($Format) {
                    "JSON" {
                        $json = ConvertTo-ExtractedInfoJson -Info $info -Indent
                        $json | Out-File -FilePath $filePath -Encoding utf8
                    }
                    "CSV" {
                        # Convertir en format CSV (exemple simplifié)

                        $csvData = [PSCustomObject]@{
                            Id = $info.Id
                            Type = $info._Type
                            Source = $info.Source
                            ExtractionDate = $info.ExtractionDate
                            ProcessingState = $info.ProcessingState
                            ConfidenceScore = $info.ConfidenceScore
                        }
                        $csvData | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
                    }
                    "XML" {
                        # Convertir en format XML (exemple simplifié)

                        $xmlData = [PSCustomObject]@{
                            ExtractedInfo = $info
                        }
                        $xmlData | Export-Clixml -Path $filePath
                    }
                }

                # Journaliser le succès

                "Exporté : $($info.Id) -> $filePath" | Out-File -FilePath $logFile -Encoding utf8 -Append
                $successCount++
            }
            catch {
                $errorMessage = "Erreur lors de l'exportation de l'objet $($info.Id) : $_"
                Write-Warning $errorMessage
                $errors += $errorMessage
                "ERREUR : $($info.Id) - $errorMessage" | Out-File -FilePath $logFile -Encoding utf8 -Append
                $errorCount++

                if (-not $ContinueOnError) {
                    throw "Exportation interrompue en raison d'une erreur. Utilisez -ContinueOnError pour continuer malgré les erreurs."
                }
            }
        }
    }

    end {
        # Journaliser le résumé

        $summary = @"
Fin de l'exportation : $(Get-Date)
Objets traités : $($successCount + $errorCount)
Succès : $successCount
Erreurs : $errorCount
"@
        $summary | Out-File -FilePath $logFile -Encoding utf8 -Append

        # Créer un fichier d'erreurs si nécessaire

        if ($errorCount -gt 0) {
            $errorFile = Join-Path $OutputDirectory "Export_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            $errors | Out-File -FilePath $errorFile -Encoding utf8
            Write-Warning "Des erreurs se sont produites lors de l'exportation. Consultez le journal des erreurs : $errorFile"
        }

        Write-Verbose "Fin de Export-ExtractedInfoBatch. Succès : $successCount, Erreurs : $errorCount"

        # Retourner un résumé

        return [PSCustomObject]@{
            SuccessCount = $successCount
            ErrorCount = $errorCount
            LogFile = $logFile
            ErrorFile = if ($errorCount -gt 0) { $errorFile } else { $null }
        }
    }
}
```plaintext
#### 1.3.7 Bonnes pratiques pour la gestion des erreurs

1. **Validation précoce** : Validez les entrées dès le début de la fonction pour éviter les erreurs en aval.
2. **Messages d'erreur informatifs** : Incluez des informations utiles dans les messages d'erreur (valeurs actuelles, valeurs attendues, etc.).
3. **Journalisation appropriée** : Utilisez les niveaux de journalisation appropriés (Verbose, Debug, Warning, Error) selon la gravité.
4. **Gestion des ressources** : Utilisez des blocs `try`/`finally` pour garantir que les ressources sont libérées.
5. **Propagation contrôlée** : Propagez les erreurs de manière contrôlée, en ajoutant du contexte si nécessaire.
6. **Options de récupération** : Offrez des options pour continuer malgré les erreurs lorsque c'est approprié.
7. **Tests d'erreur** : Testez explicitement les cas d'erreur pour vous assurer que la gestion des erreurs fonctionne correctement.

En suivant ces principes et pratiques de gestion des erreurs et de validation, vous pouvez créer des fonctions robustes qui gèrent correctement les situations exceptionnelles et fournissent des informations utiles pour le débogage.

### 1.4 Intégration avec les types existants

Lors de l'ajout de nouvelles fonctions au module `ExtractedInfoModuleV2`, il est essentiel de comprendre comment ces fonctions doivent interagir avec les types d'informations extraites existants. Cette section explique les principes et les bonnes pratiques pour assurer une intégration harmonieuse.

#### 1.4.1 Interaction avec le type de base ExtractedInfo

Le type de base `ExtractedInfo` est le fondement du système de types du module. Toutes les fonctions qui manipulent des objets d'information extraite doivent être conçues pour fonctionner correctement avec ce type de base.

##### Propriétés fondamentales

Lorsque vous créez une fonction qui interagit avec des objets `ExtractedInfo`, vous devez tenir compte des propriétés fondamentales suivantes :

| Propriété | Type | Description | Considérations |
|-----------|------|-------------|----------------|
| `_Type` | String | Identifie le type de l'objet | Utilisé pour déterminer le comportement spécifique au type |
| `Id` | String | Identifiant unique (GUID) | Utilisé pour l'identification et le référencement |
| `Source` | String | Source de l'information | Peut contenir des informations sur l'origine des données |
| `ExtractorName` | String | Nom de l'extracteur utilisé | Peut être utilisé pour des traitements spécifiques à l'extracteur |
| `ExtractionDate` | DateTime | Date et heure de l'extraction | Utilisé pour le tri chronologique et le filtrage |
| `LastModifiedDate` | DateTime | Date et heure de la dernière modification | Doit être mis à jour lors de la modification de l'objet |
| `ProcessingState` | String | État de traitement | Utilisé pour le suivi du flux de travail |
| `ConfidenceScore` | Int32 | Score de confiance (0-100) | Peut influencer les décisions de traitement |
| `Metadata` | Hashtable | Métadonnées additionnelles | Peut contenir des informations supplémentaires importantes |

##### Vérification du type

Lorsque vous créez une fonction qui doit fonctionner avec des objets `ExtractedInfo`, vous devez vérifier que l'objet est bien du type attendu :

```powershell
function Process-ExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Vérifier que c'est bien un objet ExtractedInfo

    if (-not $Info.ContainsKey("_Type") -or $Info._Type -notlike "*ExtractedInfo") {
        throw "L'objet fourni n'est pas un objet d'information extraite valide."
    }

    # Traitement...

}
```plaintext
Pour une validation plus complète, utilisez la fonction `Test-ExtractedInfo` :

```powershell
function Process-ExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Validation complète

    if (-not (Test-ExtractedInfo -Info $Info)) {
        $errors = Get-ExtractedInfoValidationErrors -Info $Info
        throw "L'objet d'information extraite n'est pas valide : $($errors -join ', ')"
    }

    # Traitement...

}
```plaintext
##### Préservation de l'immutabilité

Les fonctions qui modifient des objets `ExtractedInfo` doivent préserver l'immutabilité en créant une copie de l'objet avant de le modifier :

```powershell
function Update-ExtractedInfoProperty {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [object]$PropertyValue
    )

    # Créer une copie de l'objet

    $result = $Info.Clone()

    # Modifier la copie

    $result[$PropertyName] = $PropertyValue

    # Mettre à jour la date de dernière modification

    $result.LastModifiedDate = Get-Date

    return $result
}
```plaintext
##### Mise à jour de la date de dernière modification

Toute fonction qui modifie un objet `ExtractedInfo` doit mettre à jour la propriété `LastModifiedDate` :

```powershell
function Set-ExtractedInfoConfidenceScore {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$ConfidenceScore
    )

    $result = $Info.Clone()
    $result.ConfidenceScore = $ConfidenceScore
    $result.LastModifiedDate = Get-Date

    return $result
}
```plaintext
##### Accès aux propriétés

Lorsque vous accédez aux propriétés d'un objet `ExtractedInfo`, utilisez la méthode `ContainsKey` pour vérifier l'existence de la propriété avant d'y accéder :

```powershell
function Get-ExtractedInfoSourceSummary {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    if (-not $Info.ContainsKey("Source")) {
        return "Source inconnue"
    }

    return "Source: $($Info.Source), Extracteur: $($Info.ExtractorName)"
}
```plaintext
##### Fonctions génériques vs. fonctions spécifiques

Vous pouvez créer des fonctions qui fonctionnent avec tous les types d'informations extraites ou des fonctions spécifiques à certains types :

**Fonction générique** :
```powershell
function Get-ExtractedInfoSummary {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Fonctionne avec tous les types d'informations extraites

    $summary = "ID: $($Info.Id)`n"
    $summary += "Type: $($Info._Type)`n"
    $summary += "Source: $($Info.Source)`n"
    $summary += "État: $($Info.ProcessingState)`n"
    $summary += "Score de confiance: $($Info.ConfidenceScore)`n"

    return $summary
}
```plaintext
**Fonction avec comportement spécifique au type** :
```powershell
function Get-ExtractedInfoDetailedSummary {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Base commune pour tous les types

    $summary = "ID: $($Info.Id)`n"
    $summary += "Type: $($Info._Type)`n"
    $summary += "Source: $($Info.Source)`n"

    # Comportement spécifique selon le type

    switch ($Info._Type) {
        "TextExtractedInfo" {
            $summary += "Texte: $($Info.Text.Substring(0, [Math]::Min(50, $Info.Text.Length)))...`n"
            $summary += "Langue: $($Info.Language)`n"
        }
        "StructuredDataExtractedInfo" {
            $summary += "Format: $($Info.DataFormat)`n"
            $summary += "Nombre de propriétés: $($Info.Data.Count)`n"
        }
        "MediaExtractedInfo" {
            $summary += "Chemin: $($Info.MediaPath)`n"
            $summary += "Type de média: $($Info.MediaType)`n"
        }
        default {
            $summary += "Aucun détail spécifique disponible pour ce type.`n"
        }
    }

    return $summary
}
```plaintext
##### Exemples d'intégration avec le type de base

**Exemple 1 : Fonction de filtrage générique**

```powershell
function Filter-ExtractedInfoByConfidence {
    <#

    .SYNOPSIS
    Filtre une liste d'objets d'information extraite selon leur score de confiance.

    .DESCRIPTION
    Cette fonction filtre une liste d'objets d'information extraite pour ne conserver
    que ceux dont le score de confiance est supérieur ou égal au seuil spécifié.

    .PARAMETER InfoList
    Liste des objets d'information extraite à filtrer.

    .PARAMETER MinimumConfidence
    Score de confiance minimum (0-100).

    .EXAMPLE
    $filteredList = Filter-ExtractedInfoByConfidence -InfoList $infoList -MinimumConfidence 75
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]$InfoList,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$MinimumConfidence
    )

    begin {
        $results = @()
    }

    process {
        foreach ($info in $InfoList) {
            # Vérifier que c'est un objet ExtractedInfo valide

            if (-not (Test-ExtractedInfo -Info $info)) {
                Write-Warning "Objet invalide ignoré : $($info.Id)"
                continue
            }

            # Filtrer selon le score de confiance

            if ($info.ConfidenceScore -ge $MinimumConfidence) {
                $results += $info
            }
        }
    }

    end {
        return $results
    }
}
```plaintext
**Exemple 2 : Fonction de transformation générique**

```powershell
function Convert-ExtractedInfoToSummaryObject {
    <#

    .SYNOPSIS
    Convertit un objet d'information extraite en objet résumé simplifié.

    .DESCRIPTION
    Cette fonction convertit un objet d'information extraite en un objet PSCustomObject
    contenant un résumé des propriétés principales, pour faciliter l'affichage et l'exportation.

    .PARAMETER Info
    L'objet d'information extraite à convertir.

    .EXAMPLE
    $summary = Convert-ExtractedInfoToSummaryObject -Info $info
    $summary | Format-Table
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    process {
        # Vérifier que c'est un objet ExtractedInfo valide

        if (-not (Test-ExtractedInfo -Info $Info)) {
            throw "L'objet fourni n'est pas un objet d'information extraite valide."
        }

        # Créer un objet résumé de base

        $summary = [PSCustomObject]@{
            Id = $Info.Id
            Type = $Info._Type
            Source = $Info.Source
            ExtractionDate = $Info.ExtractionDate
            ProcessingState = $Info.ProcessingState
            ConfidenceScore = $Info.ConfidenceScore
            MetadataCount = $Info.Metadata.Count
        }

        return $summary
    }
}
```plaintext
En suivant ces principes et bonnes pratiques pour l'interaction avec le type de base `ExtractedInfo`, vous pouvez créer des fonctions qui fonctionnent de manière cohérente et fiable avec tous les types d'informations extraites du module.

#### 1.4.2 Interaction avec les types spécialisés

Le module `ExtractedInfoModuleV2` inclut plusieurs types spécialisés qui étendent le type de base `ExtractedInfo`. Lorsque vous créez de nouvelles fonctions, vous devez tenir compte de ces types spécialisés et de leurs propriétés spécifiques.

##### Types spécialisés intégrés

Le module inclut les types spécialisés suivants :

| Type | Description | Propriétés spécifiques |
|------|-------------|------------------------|
| `TextExtractedInfo` | Informations textuelles | `Text`, `Language` |
| `StructuredDataExtractedInfo` | Données structurées | `Data`, `DataFormat` |
| `MediaExtractedInfo` | Références à des fichiers média | `MediaPath`, `MediaType`, `MediaSize` |

##### Détection du type spécialisé

Pour détecter le type spécialisé d'un objet d'information extraite, vérifiez la propriété `_Type` :

```powershell
function Process-SpecificType {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Vérifier que c'est un objet d'information extraite valide

    if (-not (Test-ExtractedInfo -Info $Info)) {
        throw "L'objet fourni n'est pas un objet d'information extraite valide."
    }

    # Traitement spécifique selon le type

    switch ($Info._Type) {
        "TextExtractedInfo" {
            # Traitement spécifique pour TextExtractedInfo

            return Process-TextInfo -Info $Info
        }
        "StructuredDataExtractedInfo" {
            # Traitement spécifique pour StructuredDataExtractedInfo

            return Process-StructuredDataInfo -Info $Info
        }
        "MediaExtractedInfo" {
            # Traitement spécifique pour MediaExtractedInfo

            return Process-MediaInfo -Info $Info
        }
        default {
            # Traitement par défaut pour les autres types

            Write-Warning "Type non pris en charge spécifiquement : $($Info._Type). Traitement générique appliqué."
            return Process-GenericInfo -Info $Info
        }
    }
}
```plaintext
##### Vérification des propriétés spécifiques

Lorsque vous travaillez avec des types spécialisés, vérifiez la présence des propriétés spécifiques à ce type :

```powershell
function Process-TextInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Vérifier que c'est bien un TextExtractedInfo

    if ($Info._Type -ne "TextExtractedInfo") {
        throw "L'objet fourni n'est pas un TextExtractedInfo."
    }

    # Vérifier les propriétés spécifiques

    if (-not $Info.ContainsKey("Text")) {
        throw "Propriété 'Text' manquante dans l'objet TextExtractedInfo."
    }

    # Traitement spécifique

    $textLength = $Info.Text.Length
    $wordCount = ($Info.Text -split '\s+').Count

    return [PSCustomObject]@{
        Id = $Info.Id
        TextLength = $textLength
        WordCount = $wordCount
        Language = if ($Info.ContainsKey("Language")) { $Info.Language } else { "unknown" }
    }
}
```plaintext
##### Fonctions spécifiques à un type

Vous pouvez créer des fonctions dédiées à un type spécifique :

```powershell
function Get-TextStatistics {
    <#

    .SYNOPSIS
    Obtient des statistiques sur un objet TextExtractedInfo.

    .DESCRIPTION
    Cette fonction analyse le texte contenu dans un objet TextExtractedInfo
    et retourne diverses statistiques comme le nombre de caractères, de mots, etc.

    .PARAMETER Info
    L'objet TextExtractedInfo à analyser.

    .EXAMPLE
    $stats = Get-TextStatistics -Info $textInfo
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    process {
        # Vérifier que c'est bien un TextExtractedInfo

        if ($Info._Type -ne "TextExtractedInfo") {
            throw "L'objet fourni n'est pas un TextExtractedInfo."
        }

        # Vérifier la présence du texte

        if (-not $Info.ContainsKey("Text") -or [string]::IsNullOrEmpty($Info.Text)) {
            throw "L'objet TextExtractedInfo ne contient pas de texte valide."
        }

        # Analyser le texte

        $text = $Info.Text
        $charCount = $text.Length
        $wordCount = ($text -split '\s+').Count
        $lineCount = ($text -split '\r?\n').Count
        $sentenceCount = ($text -split '[.!?]+\s').Count

        # Calculer des statistiques supplémentaires

        $avgWordLength = if ($wordCount -gt 0) { $charCount / $wordCount } else { 0 }
        $avgSentenceLength = if ($sentenceCount -gt 0) { $wordCount / $sentenceCount } else { 0 }

        # Retourner les statistiques

        return [PSCustomObject]@{
            CharacterCount = $charCount
            WordCount = $wordCount
            LineCount = $lineCount
            SentenceCount = $sentenceCount
            AverageWordLength = [Math]::Round($avgWordLength, 2)
            AverageSentenceLength = [Math]::Round($avgSentenceLength, 2)
            Language = if ($Info.ContainsKey("Language")) { $Info.Language } else { "unknown" }
        }
    }
}
```plaintext
##### Fonctions qui supportent plusieurs types spécifiques

Vous pouvez également créer des fonctions qui supportent plusieurs types spécifiques avec des comportements adaptés :

```powershell
function Export-ExtractedInfoContent {
    <#

    .SYNOPSIS
    Exporte le contenu principal d'un objet d'information extraite dans un fichier.

    .DESCRIPTION
    Cette fonction exporte le contenu principal d'un objet d'information extraite dans un fichier,
    avec un comportement adapté au type spécifique de l'objet.

    .PARAMETER Info
    L'objet d'information extraite à exporter.

    .PARAMETER OutputPath
    Le chemin du fichier de sortie.

    .PARAMETER Force
    Indique si le fichier doit être écrasé s'il existe déjà.

    .EXAMPLE
    Export-ExtractedInfoContent -Info $textInfo -OutputPath "C:\Exports\content.txt"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [switch]$Force = $false
    )

    process {
        # Vérifier que c'est un objet d'information extraite valide

        if (-not (Test-ExtractedInfo -Info $Info)) {
            throw "L'objet fourni n'est pas un objet d'information extraite valide."
        }

        # Vérifier si le fichier existe déjà

        if (Test-Path $OutputPath -PathType Leaf) {
            if (-not $Force) {
                throw "Le fichier '$OutputPath' existe déjà. Utilisez -Force pour l'écraser."
            }
        }

        # Créer le répertoire parent si nécessaire

        $parentDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $parentDir -PathType Container)) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }

        # Exporter selon le type

        switch ($Info._Type) {
            "TextExtractedInfo" {
                # Exporter le texte

                if (-not $Info.ContainsKey("Text")) {
                    throw "L'objet TextExtractedInfo ne contient pas de texte."
                }

                $Info.Text | Out-File -FilePath $OutputPath -Encoding utf8 -Force
                Write-Verbose "Texte exporté dans '$OutputPath'"
            }
            "StructuredDataExtractedInfo" {
                # Exporter les données structurées en JSON

                if (-not $Info.ContainsKey("Data")) {
                    throw "L'objet StructuredDataExtractedInfo ne contient pas de données."
                }

                $Info.Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
                Write-Verbose "Données structurées exportées en JSON dans '$OutputPath'"
            }
            "MediaExtractedInfo" {
                # Créer un lien symbolique ou copier le fichier média

                if (-not $Info.ContainsKey("MediaPath")) {
                    throw "L'objet MediaExtractedInfo ne contient pas de chemin média."
                }

                if (-not (Test-Path $Info.MediaPath -PathType Leaf)) {
                    throw "Le fichier média '$($Info.MediaPath)' n'existe pas."
                }

                Copy-Item -Path $Info.MediaPath -Destination $OutputPath -Force
                Write-Verbose "Fichier média copié vers '$OutputPath'"
            }
            default {
                # Exporter un résumé pour les autres types

                $summary = "ID: $($Info.Id)`n"
                $summary += "Type: $($Info._Type)`n"
                $summary += "Source: $($Info.Source)`n"
                $summary += "Extraction Date: $($Info.ExtractionDate)`n"
                $summary += "Processing State: $($Info.ProcessingState)`n"
                $summary += "Confidence Score: $($Info.ConfidenceScore)`n"

                $summary | Out-File -FilePath $OutputPath -Encoding utf8 -Force
                Write-Verbose "Résumé exporté dans '$OutputPath'"
            }
        }

        # Retourner le chemin du fichier exporté

        return $OutputPath
    }
}
```plaintext
##### Extension pour les types personnalisés

Lorsque vous créez des fonctions qui doivent prendre en charge des types personnalisés, utilisez une approche extensible :

```powershell
function Get-ExtractedInfoContentType {
    <#

    .SYNOPSIS
    Détermine le type de contenu d'un objet d'information extraite.

    .DESCRIPTION
    Cette fonction détermine le type de contenu MIME d'un objet d'information extraite
    en fonction de son type spécifique et de ses propriétés.

    .PARAMETER Info
    L'objet d'information extraite à analyser.

    .EXAMPLE
    $contentType = Get-ExtractedInfoContentType -Info $info
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    process {
        # Vérifier que c'est un objet d'information extraite valide

        if (-not (Test-ExtractedInfo -Info $Info)) {
            throw "L'objet fourni n'est pas un objet d'information extraite valide."
        }

        # Déterminer le type de contenu selon le type d'information

        switch -Regex ($Info._Type) {
            "TextExtractedInfo" {
                # Déterminer le type de contenu selon la langue

                if ($Info.ContainsKey("Language") -and $Info.Language -eq "html") {
                    return "text/html"
                }
                else {
                    return "text/plain"
                }
            }
            "StructuredDataExtractedInfo" {
                # Déterminer le type de contenu selon le format des données

                if ($Info.ContainsKey("DataFormat")) {
                    switch ($Info.DataFormat) {
                        "JSON" { return "application/json" }
                        "XML" { return "application/xml" }
                        "CSV" { return "text/csv" }
                        default { return "application/octet-stream" }
                    }
                }
                else {
                    return "application/json" # Par défaut pour les données structurées

                }
            }
            "MediaExtractedInfo" {
                # Déterminer le type de contenu selon le type de média

                if ($Info.ContainsKey("MediaType")) {
                    switch ($Info.MediaType) {
                        "Image" {
                            # Déterminer le type d'image selon l'extension du fichier

                            if ($Info.ContainsKey("MediaPath")) {
                                $extension = [System.IO.Path]::GetExtension($Info.MediaPath).ToLower()
                                switch ($extension) {
                                    ".jpg" { return "image/jpeg" }
                                    ".jpeg" { return "image/jpeg" }
                                    ".png" { return "image/png" }
                                    ".gif" { return "image/gif" }
                                    ".bmp" { return "image/bmp" }
                                    ".tiff" { return "image/tiff" }
                                    default { return "image/unknown" }
                                }
                            }
                            else {
                                return "image/unknown"
                            }
                        }
                        "Video" { return "video/mp4" } # Par défaut pour les vidéos

                        "Audio" { return "audio/mpeg" } # Par défaut pour les audios

                        "Document" { return "application/pdf" } # Par défaut pour les documents

                        default { return "application/octet-stream" }
                    }
                }
                else {
                    return "application/octet-stream"
                }
            }
            # Support pour les types personnalisés

            "GeoLocationExtractedInfo" {
                return "application/geo+json"
            }
            "EmailExtractedInfo" {
                return "message/rfc822"
            }
            default {
                # Type par défaut pour les autres types

                return "application/octet-stream"
            }
        }
    }
}
```plaintext
##### Exemples d'intégration avec les types spécialisés

**Exemple 1 : Fonction de traitement de texte**

```powershell
function Format-ExtractedText {
    <#

    .SYNOPSIS
    Formate le texte d'un objet TextExtractedInfo.

    .DESCRIPTION
    Cette fonction formate le texte contenu dans un objet TextExtractedInfo
    selon les options spécifiées (majuscules, minuscules, titre, etc.).

    .PARAMETER Info
    L'objet TextExtractedInfo à formater.

    .PARAMETER Format
    Le format à appliquer. Valeurs valides : "Upper", "Lower", "Title", "Sentence", "Trim".

    .EXAMPLE
    $formattedInfo = Format-ExtractedText -Info $textInfo -Format "Title"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Upper", "Lower", "Title", "Sentence", "Trim")]
        [string]$Format
    )

    process {
        # Vérifier que c'est bien un TextExtractedInfo

        if ($Info._Type -ne "TextExtractedInfo") {
            throw "L'objet fourni n'est pas un TextExtractedInfo."
        }

        # Vérifier la présence du texte

        if (-not $Info.ContainsKey("Text") -or $null -eq $Info.Text) {
            throw "L'objet TextExtractedInfo ne contient pas de texte."
        }

        # Créer une copie de l'objet

        $result = $Info.Clone()

        # Formater le texte selon l'option spécifiée

        switch ($Format) {
            "Upper" {
                $result.Text = $Info.Text.ToUpper()
            }
            "Lower" {
                $result.Text = $Info.Text.ToLower()
            }
            "Title" {
                $textInfo = (Get-Culture).TextInfo
                $result.Text = $textInfo.ToTitleCase($Info.Text.ToLower())
            }
            "Sentence" {
                # Mettre la première lettre en majuscule et le reste en minuscules

                if ($Info.Text.Length -gt 0) {
                    $firstChar = $Info.Text.Substring(0, 1).ToUpper()
                    $restOfText = if ($Info.Text.Length -gt 1) { $Info.Text.Substring(1).ToLower() } else { "" }
                    $result.Text = $firstChar + $restOfText
                }
            }
            "Trim" {
                $result.Text = $Info.Text.Trim()
            }
        }

        # Mettre à jour la date de dernière modification

        $result.LastModifiedDate = Get-Date

        return $result
    }
}
```plaintext
**Exemple 2 : Fonction de traitement de données structurées**

```powershell
function Get-StructuredDataProperty {
    <#

    .SYNOPSIS
    Récupère une propriété spécifique dans les données structurées d'un objet StructuredDataExtractedInfo.

    .DESCRIPTION
    Cette fonction récupère une propriété spécifique dans les données structurées d'un objet
    StructuredDataExtractedInfo en utilisant un chemin d'accès au format JSONPath simplifié.

    .PARAMETER Info
    L'objet StructuredDataExtractedInfo à interroger.

    .PARAMETER PropertyPath
    Le chemin d'accès à la propriété, au format "Property1.Property2[0].Property3".

    .PARAMETER DefaultValue
    La valeur par défaut à retourner si la propriété n'est pas trouvée.

    .EXAMPLE
    $value = Get-StructuredDataProperty -Info $dataInfo -PropertyPath "Person.Address.City" -DefaultValue "Unknown"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$PropertyPath,

        [Parameter(Mandatory = $false)]
        [object]$DefaultValue = $null
    )

    process {
        # Vérifier que c'est bien un StructuredDataExtractedInfo

        if ($Info._Type -ne "StructuredDataExtractedInfo") {
            throw "L'objet fourni n'est pas un StructuredDataExtractedInfo."
        }

        # Vérifier la présence des données

        if (-not $Info.ContainsKey("Data") -or $null -eq $Info.Data) {
            throw "L'objet StructuredDataExtractedInfo ne contient pas de données."
        }

        # Fonction récursive pour accéder à une propriété imbriquée

        function Get-NestedProperty {
            param (
                [object]$Object,
                [string]$Path
            )

            # Si l'objet est null, retourner la valeur par défaut

            if ($null -eq $Object) {
                return $DefaultValue
            }

            # Analyser le chemin

            if ($Path -match '^([^\.\[\]]+)(\..+|\[\d+\].+)?$') {
                $currentProp = $Matches[1]
                $remainingPath = $Matches[2]

                # Accéder à la propriété actuelle

                $currentValue = if ($Object -is [hashtable] -or $Object -is [System.Collections.Specialized.OrderedDictionary]) {
                    if ($Object.ContainsKey($currentProp)) { $Object[$currentProp] } else { $null }
                }
                elseif ($Object -is [PSCustomObject]) {
                    if (Get-Member -InputObject $Object -Name $currentProp -MemberType Properties) {
                        $Object.$currentProp
                    }
                    else {
                        $null
                    }
                }
                else {
                    $null
                }

                # Si c'est la fin du chemin, retourner la valeur

                if ([string]::IsNullOrEmpty($remainingPath)) {
                    return $currentValue ?? $DefaultValue
                }

                # Sinon, continuer avec le reste du chemin

                if ($remainingPath -match '^\[(\d+)\](.*)$') {
                    # Accès à un élément de tableau

                    $index = [int]$Matches[1]
                    $nextPath = $Matches[2]

                    if ($currentValue -is [array] -and $index -lt $currentValue.Count) {
                        return Get-NestedProperty -Object $currentValue[$index] -Path ($nextPath -replace '^\.')
                    }
                    else {
                        return $DefaultValue
                    }
                }
                elseif ($remainingPath -match '^\.(.+)$') {
                    # Accès à une propriété imbriquée

                    return Get-NestedProperty -Object $currentValue -Path $Matches[1]
                }
            }

            return $DefaultValue
        }

        # Récupérer la propriété

        return Get-NestedProperty -Object $Info.Data -Path $PropertyPath
    }
}
```plaintext
**Exemple 3 : Fonction de traitement de média**

```powershell
function Get-MediaMetadata {
    <#

    .SYNOPSIS
    Récupère les métadonnées d'un fichier média référencé par un objet MediaExtractedInfo.

    .DESCRIPTION
    Cette fonction récupère les métadonnées d'un fichier média (image, vidéo, audio)
    référencé par un objet MediaExtractedInfo.

    .PARAMETER Info
    L'objet MediaExtractedInfo à analyser.

    .EXAMPLE
    $metadata = Get-MediaMetadata -Info $mediaInfo
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    process {
        # Vérifier que c'est bien un MediaExtractedInfo

        if ($Info._Type -ne "MediaExtractedInfo") {
            throw "L'objet fourni n'est pas un MediaExtractedInfo."
        }

        # Vérifier la présence du chemin média

        if (-not $Info.ContainsKey("MediaPath") -or [string]::IsNullOrEmpty($Info.MediaPath)) {
            throw "L'objet MediaExtractedInfo ne contient pas de chemin média valide."
        }

        # Vérifier que le fichier existe

        if (-not (Test-Path $Info.MediaPath -PathType Leaf)) {
            throw "Le fichier média '$($Info.MediaPath)' n'existe pas."
        }

        # Récupérer les informations de base du fichier

        $fileInfo = Get-Item $Info.MediaPath

        # Créer un objet de métadonnées de base

        $metadata = [PSCustomObject]@{
            FileName = $fileInfo.Name
            FileExtension = $fileInfo.Extension
            FileSize = $fileInfo.Length
            CreationTime = $fileInfo.CreationTime
            LastWriteTime = $fileInfo.LastWriteTime
            MediaType = if ($Info.ContainsKey("MediaType")) { $Info.MediaType } else { "Unknown" }
        }

        # Récupérer des métadonnées spécifiques selon le type de média

        if ($Info.ContainsKey("MediaType")) {
            switch ($Info.MediaType) {
                "Image" {
                    # Pour les images, récupérer les dimensions et d'autres métadonnées

                    try {
                        Add-Type -AssemblyName System.Drawing
                        $image = [System.Drawing.Image]::FromFile($Info.MediaPath)

                        $metadata | Add-Member -MemberType NoteProperty -Name "Width" -Value $image.Width
                        $metadata | Add-Member -MemberType NoteProperty -Name "Height" -Value $image.Height
                        $metadata | Add-Member -MemberType NoteProperty -Name "PixelFormat" -Value $image.PixelFormat
                        $metadata | Add-Member -MemberType NoteProperty -Name "Resolution" -Value "$($image.HorizontalResolution)x$($image.VerticalResolution) dpi"

                        # Libérer les ressources

                        $image.Dispose()
                    }
                    catch {
                        Write-Warning "Impossible de récupérer les métadonnées de l'image : $_"
                    }
                }
                # Ajouter d'autres types de média si nécessaire

            }
        }

        return $metadata
    }
}
```plaintext
En suivant ces principes et exemples pour l'interaction avec les types spécialisés, vous pouvez créer des fonctions qui exploitent pleinement les capacités spécifiques de chaque type d'information extraite tout en maintenant une cohérence globale dans le module.

#### 1.4.3 Bonnes pratiques pour le traitement polymorphique

Le module `ExtractedInfoModuleV2` utilise un système de types basé sur des hashtables, ce qui permet un traitement polymorphique des objets d'information extraite. Cette section présente les bonnes pratiques pour créer des fonctions qui traitent différents types d'objets de manière cohérente et extensible.

##### Principes du traitement polymorphique

Le traitement polymorphique dans le module repose sur plusieurs principes :

1. **Identification par type** : Utilisation de la propriété `_Type` pour identifier le type spécifique d'un objet.
2. **Comportement adaptatif** : Adaptation du comportement d'une fonction en fonction du type de l'objet.
3. **Extensibilité** : Conception de fonctions qui peuvent être étendues pour prendre en charge de nouveaux types sans modification du code existant.
4. **Cohérence** : Maintien d'une interface cohérente pour toutes les fonctions, quel que soit le type d'objet traité.

##### Approches pour le traitement polymorphique

Plusieurs approches peuvent être utilisées pour implémenter un traitement polymorphique :

1. **Instruction switch** : Utilisation d'une instruction `switch` pour sélectionner le comportement en fonction du type.

```powershell
function Process-ExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Traitement commun à tous les types

    $result = $Info.Clone()

    # Traitement spécifique selon le type

    switch ($Info._Type) {
        "TextExtractedInfo" {
            # Traitement spécifique pour TextExtractedInfo

            $result.ProcessedText = $Info.Text.ToUpper()
        }
        "StructuredDataExtractedInfo" {
            # Traitement spécifique pour StructuredDataExtractedInfo

            $result.ProcessedData = ConvertTo-Json -InputObject $Info.Data -Depth 10
        }
        "MediaExtractedInfo" {
            # Traitement spécifique pour MediaExtractedInfo

            $result.ProcessedMedia = Get-FileHash -Path $Info.MediaPath -Algorithm SHA256
        }
        default {
            # Traitement par défaut pour les autres types

            $result.ProcessedGeneric = $true
        }
    }

    return $result
}
```plaintext
2. **Délégation à des fonctions spécifiques** : Délégation du traitement à des fonctions spécifiques à chaque type.

```powershell
function Process-ExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Traitement commun à tous les types

    $result = $Info.Clone()

    # Délégation à des fonctions spécifiques

    switch ($Info._Type) {
        "TextExtractedInfo" {
            $result = Process-TextExtractedInfo -Info $result
        }
        "StructuredDataExtractedInfo" {
            $result = Process-StructuredDataExtractedInfo -Info $result
        }
        "MediaExtractedInfo" {
            $result = Process-MediaExtractedInfo -Info $result
        }
        default {
            $result = Process-GenericExtractedInfo -Info $result
        }
    }

    return $result
}

function Process-TextExtractedInfo {
    param ([hashtable]$Info)

    $result = $Info.Clone()
    $result.ProcessedText = $Info.Text.ToUpper()
    return $result
}

function Process-StructuredDataExtractedInfo {
    param ([hashtable]$Info)

    $result = $Info.Clone()
    $result.ProcessedData = ConvertTo-Json -InputObject $Info.Data -Depth 10
    return $result
}

# Autres fonctions spécifiques...

```plaintext
3. **Utilisation d'expressions régulières** : Utilisation d'expressions régulières pour une correspondance plus flexible des types.

```powershell
function Process-ExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Traitement commun à tous les types

    $result = $Info.Clone()

    # Traitement spécifique selon le type avec expressions régulières

    switch -Regex ($Info._Type) {
        "^Text" {
            # Traitement pour tous les types commençant par "Text"

            $result.ProcessedText = $Info.Text.ToUpper()
        }
        "^StructuredData" {
            # Traitement pour tous les types commençant par "StructuredData"

            $result.ProcessedData = ConvertTo-Json -InputObject $Info.Data -Depth 10
        }
        "^Media" {
            # Traitement pour tous les types commençant par "Media"

            $result.ProcessedMedia = Get-FileHash -Path $Info.MediaPath -Algorithm SHA256
        }
        "^GeoLocation" {
            # Traitement pour tous les types commençant par "GeoLocation"

            $result.ProcessedLocation = "$($Info.Latitude),$($Info.Longitude)"
        }
        default {
            # Traitement par défaut pour les autres types

            $result.ProcessedGeneric = $true
        }
    }

    return $result
}
```plaintext
4. **Utilisation d'un registre de gestionnaires** : Utilisation d'un registre de fonctions de traitement pour chaque type.

```powershell
# Registre global des gestionnaires de types

$script:TypeHandlers = @{}

# Fonction pour enregistrer un gestionnaire de type

function Register-ExtractedInfoTypeHandler {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TypeName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Handler
    )

    $script:TypeHandlers[$TypeName] = $Handler
}

# Fonction pour traiter un objet avec le gestionnaire approprié

function Process-ExtractedInfoWithHandlers {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Vérifier que c'est un objet d'information extraite valide

    if (-not (Test-ExtractedInfo -Info $Info)) {
        throw "L'objet fourni n'est pas un objet d'information extraite valide."
    }

    # Traitement commun à tous les types

    $result = $Info.Clone()

    # Rechercher un gestionnaire pour ce type

    if ($script:TypeHandlers.ContainsKey($Info._Type)) {
        # Appeler le gestionnaire enregistré

        $handler = $script:TypeHandlers[$Info._Type]
        $result = & $handler $result
    }
    else {
        # Gestionnaire par défaut

        Write-Verbose "Aucun gestionnaire spécifique trouvé pour le type '$($Info._Type)'. Utilisation du gestionnaire par défaut."
        $result.ProcessedGeneric = $true
    }

    return $result
}

# Enregistrer des gestionnaires pour différents types

Register-ExtractedInfoTypeHandler -TypeName "TextExtractedInfo" -Handler {
    param ($Info)

    $result = $Info.Clone()
    $result.ProcessedText = $Info.Text.ToUpper()
    return $result
}

Register-ExtractedInfoTypeHandler -TypeName "StructuredDataExtractedInfo" -Handler {
    param ($Info)

    $result = $Info.Clone()
    $result.ProcessedData = ConvertTo-Json -InputObject $Info.Data -Depth 10
    return $result
}

# Utilisation

$processedInfo = Process-ExtractedInfoWithHandlers -Info $info
```plaintext
##### Bonnes pratiques pour le traitement polymorphique

Pour créer des fonctions qui traitent efficacement différents types d'objets d'information extraite, suivez ces bonnes pratiques :

1. **Validation préalable** : Validez toujours que l'objet est un objet d'information extraite valide avant de le traiter.

```powershell
if (-not (Test-ExtractedInfo -Info $Info)) {
    throw "L'objet fourni n'est pas un objet d'information extraite valide."
}
```plaintext
2. **Traitement commun d'abord** : Effectuez d'abord le traitement commun à tous les types, puis le traitement spécifique.

```powershell
# Traitement commun

$result = $Info.Clone()
$result.LastModifiedDate = Get-Date
$result.ProcessingState = "Processed"

# Traitement spécifique selon le type

switch ($Info._Type) {
    # ...

}
```plaintext
3. **Gestion des types inconnus** : Prévoyez toujours un cas par défaut pour les types inconnus ou non pris en charge.

```powershell
switch ($Info._Type) {
    "TextExtractedInfo" { /* ... */ }
    "StructuredDataExtractedInfo" { /* ... */ }
    "MediaExtractedInfo" { /* ... */ }
    default {
        Write-Warning "Type non pris en charge spécifiquement : $($Info._Type). Traitement générique appliqué."
        # Traitement générique

    }
}
```plaintext
4. **Extensibilité** : Concevez vos fonctions pour qu'elles puissent être facilement étendues pour prendre en charge de nouveaux types.

```powershell
# Approche extensible avec un registre de gestionnaires

$script:TypeHandlers = @{}

function Register-TypeHandler {
    param (
        [string]$TypeName,
        [scriptblock]$Handler
    )

    $script:TypeHandlers[$TypeName] = $Handler
}

function Process-WithHandlers {
    param ([hashtable]$Info)

    if ($script:TypeHandlers.ContainsKey($Info._Type)) {
        return & $script:TypeHandlers[$Info._Type] $Info
    }
    else {
        # Traitement par défaut

    }
}
```plaintext
5. **Cohérence des interfaces** : Maintenez une interface cohérente pour toutes les fonctions de traitement spécifiques.

```powershell
# Interface cohérente pour toutes les fonctions de traitement

function Process-TextExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{}
    )

    # Validation

    # Traitement

    # Retour

}

function Process-StructuredDataExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{}
    )

    # Même structure que Process-TextExtractedInfo

}
```plaintext
6. **Documentation claire** : Documentez clairement les types pris en charge et le comportement spécifique pour chaque type.

```powershell
<#

.SYNOPSIS
Traite un objet d'information extraite.

.DESCRIPTION
Cette fonction traite un objet d'information extraite avec un comportement adapté à son type spécifique.

Types pris en charge :
- TextExtractedInfo : Traitement du texte (mise en majuscules)
- StructuredDataExtractedInfo : Conversion des données en JSON
- MediaExtractedInfo : Calcul du hachage du fichier média

.PARAMETER Info
L'objet d'information extraite à traiter.
#>

```plaintext
7. **Tests pour chaque type** : Testez votre fonction avec tous les types qu'elle prend en charge.

```powershell
# Tests pour différents types

Describe "Process-ExtractedInfo" {
    It "Traite correctement un TextExtractedInfo" {
        $textInfo = New-TextExtractedInfo -Source "test.txt" -Text "test"
        $result = Process-ExtractedInfo -Info $textInfo
        $result.ProcessedText | Should -Be "TEST"
    }

    It "Traite correctement un StructuredDataExtractedInfo" {
        $dataInfo = New-StructuredDataExtractedInfo -Source "test.json" -Data @{ Key = "Value" }
        $result = Process-ExtractedInfo -Info $dataInfo
        $result.ProcessedData | Should -Not -BeNullOrEmpty
    }

    # Tests pour d'autres types...

}
```plaintext
##### Exemple complet de traitement polymorphique

Voici un exemple complet d'une fonction qui implémente un traitement polymorphique avancé :

```powershell
function Convert-ExtractedInfoToHtml {
    <#

    .SYNOPSIS
    Convertit un objet d'information extraite en HTML pour l'affichage.

    .DESCRIPTION
    Cette fonction convertit un objet d'information extraite en HTML avec un format adapté
    au type spécifique de l'objet. Elle prend en charge tous les types d'informations extraites
    intégrés et peut être étendue pour prendre en charge des types personnalisés.

    Types pris en charge :
    - ExtractedInfo (type de base) : Affichage des propriétés de base
    - TextExtractedInfo : Affichage du texte avec mise en forme
    - StructuredDataExtractedInfo : Affichage des données sous forme de tableau
    - MediaExtractedInfo : Affichage d'un aperçu du média avec métadonnées
    - GeoLocationExtractedInfo : Affichage des coordonnées sur une carte

    .PARAMETER Info
    L'objet d'information extraite à convertir en HTML.

    .PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans le HTML.

    .PARAMETER Theme
    Le thème à utiliser pour le HTML. Valeurs valides : "Light", "Dark", "Auto".

    .EXAMPLE
    $html = Convert-ExtractedInfoToHtml -Info $textInfo -Theme "Light"
    $html | Out-File -FilePath "preview.html" -Encoding utf8
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Light", "Dark", "Auto")]
        [string]$Theme = "Auto"
    )

    begin {
        # Fonction pour générer le HTML de base

        function Get-BaseHtml {
            param (
                [hashtable]$Info,
                [string]$Content,
                [string]$Theme
            )

            $themeClass = switch ($Theme) {
                "Light" { "theme-light" }
                "Dark" { "theme-dark" }
                default { "theme-auto" }
            }

            $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($Info._Type) - $($Info.Id)</title>
    <style>
        /* Styles de base */
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
        }

        /* Thème clair */
        .theme-light {
            background-color: #ffffff;

            color: #333333;

        }

        /* Thème sombre */
        .theme-dark {
            background-color: #222222;

            color: #f0f0f0;

        }

        /* Thème auto (basé sur les préférences du système) */
        @media (prefers-color-scheme: dark) {
            .theme-auto {
                background-color: #222222;

                color: #f0f0f0;

            }
        }

        @media (prefers-color-scheme: light) {
            .theme-auto {
                background-color: #ffffff;

                color: #333333;

            }
        }

        /* Styles communs */
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #ccc;

        }

        .content {
            margin-bottom: 20px;
        }

        .metadata {
            margin-top: 20px;
            padding-top: 10px;
            border-top: 1px solid #ccc;

        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }

        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;

        }

        /* Styles spécifiques aux types */
        .text-content {
            white-space: pre-wrap;
            padding: 10px;
            border: 1px solid #ddd;

            border-radius: 4px;
        }

        .media-preview {
            max-width: 100%;
            max-height: 400px;
            display: block;
            margin: 0 auto;
        }

        .map-container {
            height: 400px;
            width: 100%;
            border: 1px solid #ddd;

            border-radius: 4px;
        }
    </style>
</head>
<body class="$themeClass">
    <div class="container">
        <div class="header">
            <h1>$($Info._Type)</h1>
            <p><strong>ID:</strong> $($Info.Id)</p>
            <p><strong>Source:</strong> $($Info.Source)</p>
            <p><strong>Extraction Date:</strong> $($Info.ExtractionDate)</p>
            <p><strong>Processing State:</strong> $($Info.ProcessingState)</p>
            <p><strong>Confidence Score:</strong> $($Info.ConfidenceScore)</p>
        </div>

        <div class="content">
            $Content
        </div>

"@

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $Info.Metadata.Count -gt 0) {
                $html += @"
        <div class="metadata">
            <h2>Metadata</h2>
            <table>
                <tr>
                    <th>Key</th>
                    <th>Value</th>
                </tr>
"@

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]
                    $html += @"
                <tr>
                    <td>$key</td>
                    <td>$value</td>
                </tr>
"@
                }

                $html += @"
            </table>
        </div>
"@
            }

            $html += @"
    </div>
</body>
</html>
"@

            return $html
        }

        # Registre des gestionnaires de types

        $typeHandlers = @{}

        # Gestionnaire pour le type de base ExtractedInfo

        $typeHandlers["ExtractedInfo"] = {
            param ($Info)

            $content = @"
<h2>Basic Information</h2>
<p>This is a basic ExtractedInfo object with no specialized content.</p>
"@

            return Get-BaseHtml -Info $Info -Content $content -Theme $Theme
        }

        # Gestionnaire pour TextExtractedInfo

        $typeHandlers["TextExtractedInfo"] = {
            param ($Info)

            $text = if ($Info.ContainsKey("Text")) { $Info.Text } else { "No text available" }
            $language = if ($Info.ContainsKey("Language")) { $Info.Language } else { "unknown" }

            $content = @"
<h2>Text Content</h2>
<p><strong>Language:</strong> $language</p>
<div class="text-content">$([System.Web.HttpUtility]::HtmlEncode($text))</div>
"@

            return Get-BaseHtml -Info $Info -Content $content -Theme $Theme
        }

        # Gestionnaire pour StructuredDataExtractedInfo

        $typeHandlers["StructuredDataExtractedInfo"] = {
            param ($Info)

            $dataFormat = if ($Info.ContainsKey("DataFormat")) { $Info.DataFormat } else { "Unknown" }

            $content = @"
<h2>Structured Data</h2>
<p><strong>Format:</strong> $dataFormat</p>
"@

            if ($Info.ContainsKey("Data") -and $null -ne $Info.Data) {
                $jsonData = ConvertTo-Json -InputObject $Info.Data -Depth 10 -Compress:$false
                $content += @"
<pre>$([System.Web.HttpUtility]::HtmlEncode($jsonData))</pre>
"@
            }
            else {
                $content += @"
<p>No data available</p>
"@
            }

            return Get-BaseHtml -Info $Info -Content $content -Theme $Theme
        }

        # Gestionnaire pour MediaExtractedInfo

        $typeHandlers["MediaExtractedInfo"] = {
            param ($Info)

            $mediaType = if ($Info.ContainsKey("MediaType")) { $Info.MediaType } else { "Unknown" }
            $mediaPath = if ($Info.ContainsKey("MediaPath")) { $Info.MediaPath } else { "" }
            $mediaSize = if ($Info.ContainsKey("MediaSize")) { $Info.MediaSize } else { 0 }

            $content = @"
<h2>Media Information</h2>
<p><strong>Media Type:</strong> $mediaType</p>
<p><strong>Media Path:</strong> $mediaPath</p>
<p><strong>Media Size:</strong> $([Math]::Round($mediaSize / 1KB, 2)) KB</p>
"@

            if ($mediaType -eq "Image" -and (Test-Path $mediaPath -PathType Leaf)) {
                # Convertir l'image en base64 pour l'inclure dans le HTML

                try {
                    $imageBytes = [System.IO.File]::ReadAllBytes($mediaPath)
                    $base64Image = [System.Convert]::ToBase64String($imageBytes)
                    $extension = [System.IO.Path]::GetExtension($mediaPath).TrimStart('.')
                    $mimeType = switch ($extension.ToLower()) {
                        "jpg" { "image/jpeg" }
                        "jpeg" { "image/jpeg" }
                        "png" { "image/png" }
                        "gif" { "image/gif" }
                        "bmp" { "image/bmp" }
                        default { "image/jpeg" }
                    }

                    $content += @"
<h3>Image Preview</h3>
<img src="data:$mimeType;base64,$base64Image" alt="Media Preview" class="media-preview">
"@
                }
                catch {
                    $content += @"
<p>Error loading image preview: $($_.Exception.Message)</p>
"@
                }
            }

            return Get-BaseHtml -Info $Info -Content $content -Theme $Theme
        }

        # Gestionnaire pour GeoLocationExtractedInfo

        $typeHandlers["GeoLocationExtractedInfo"] = {
            param ($Info)

            $latitude = if ($Info.ContainsKey("Latitude")) { $Info.Latitude } else { 0 }
            $longitude = if ($Info.ContainsKey("Longitude")) { $Info.Longitude } else { 0 }
            $altitude = if ($Info.ContainsKey("Altitude")) { $Info.Altitude } else { "N/A" }
            $accuracy = if ($Info.ContainsKey("Accuracy")) { $Info.Accuracy } else { "N/A" }
            $address = if ($Info.ContainsKey("Address")) { $Info.Address } else { "N/A" }
            $city = if ($Info.ContainsKey("City")) { $Info.City } else { "N/A" }
            $country = if ($Info.ContainsKey("Country")) { $Info.Country } else { "N/A" }

            $content = @"
<h2>Geolocation Information</h2>
<table>
    <tr>
        <th>Property</th>
        <th>Value</th>
    </tr>
    <tr>
        <td>Latitude</td>
        <td>$latitude</td>
    </tr>
    <tr>
        <td>Longitude</td>
        <td>$longitude</td>
    </tr>
    <tr>
        <td>Altitude</td>
        <td>$altitude</td>
    </tr>
    <tr>
        <td>Accuracy</td>
        <td>$accuracy</td>
    </tr>
    <tr>
        <td>Address</td>
        <td>$address</td>
    </tr>
    <tr>
        <td>City</td>
        <td>$city</td>
    </tr>
    <tr>
        <td>Country</td>
        <td>$country</td>
    </tr>
</table>

<h3>Map</h3>
<div class="map-container" id="map"></div>
<script>
    function initMap() {
        var location = {lat: $latitude, lng: $longitude};
        var map = new google.maps.Map(document.getElementById('map'), {
            zoom: 12,
            center: location
        });
        var marker = new google.maps.Marker({
            position: location,
            map: map
        });
    }
</script>
<script async defer src="https://maps.googleapis.com/maps/api/js?callback=initMap"></script>
"@

            return Get-BaseHtml -Info $Info -Content $content -Theme $Theme
        }
    }

    process {
        # Vérifier que c'est un objet d'information extraite valide

        if (-not (Test-ExtractedInfo -Info $Info)) {
            throw "L'objet fourni n'est pas un objet d'information extraite valide."
        }

        # Déterminer le gestionnaire à utiliser

        $handler = $null

        if ($typeHandlers.ContainsKey($Info._Type)) {
            $handler = $typeHandlers[$Info._Type]
        }
        else {
            # Utiliser le gestionnaire par défaut

            $handler = $typeHandlers["ExtractedInfo"]
            Write-Verbose "Aucun gestionnaire spécifique trouvé pour le type '$($Info._Type)'. Utilisation du gestionnaire par défaut."
        }

        # Appeler le gestionnaire

        $html = & $handler $Info

        return $html
    }
}
```plaintext
En suivant ces bonnes pratiques pour le traitement polymorphique, vous pouvez créer des fonctions qui traitent efficacement différents types d'objets d'information extraite tout en maintenant une architecture extensible et cohérente.

#### 1.4.4 Exemples d'intégration avec différents types

Cette section présente des exemples concrets de fonctions qui s'intègrent avec différents types d'informations extraites, illustrant les principes et les bonnes pratiques présentés précédemment.

##### 1.4.4.1 Exemple d'une fonction de recherche multi-types

L'exemple suivant montre une fonction de recherche qui peut trouver des informations dans différents types d'objets d'information extraite, en adaptant son comportement en fonction du type.

```powershell
function Find-ExtractedInfoContent {
    <#

    .SYNOPSIS
    Recherche un terme dans le contenu d'objets d'information extraite.

    .DESCRIPTION
    Cette fonction recherche un terme spécifié dans le contenu d'objets d'information extraite,
    en adaptant son comportement en fonction du type d'objet. Elle prend en charge tous les types
    d'informations extraites intégrés et peut être étendue pour prendre en charge des types personnalisés.

    Types pris en charge et comportement :
    - TextExtractedInfo : Recherche dans le texte
    - StructuredDataExtractedInfo : Recherche dans les valeurs des données structurées
    - MediaExtractedInfo : Recherche dans les métadonnées du média
    - GeoLocationExtractedInfo : Recherche dans l'adresse et les informations de localisation

    .PARAMETER InfoList
    Liste des objets d'information extraite dans lesquels effectuer la recherche.

    .PARAMETER SearchTerm
    Terme à rechercher. Peut être une chaîne simple ou une expression régulière.

    .PARAMETER CaseSensitive
    Indique si la recherche doit être sensible à la casse.

    .PARAMETER UseRegex
    Indique si le terme de recherche doit être interprété comme une expression régulière.

    .PARAMETER IncludeMetadata
    Indique si la recherche doit inclure les métadonnées des objets.

    .EXAMPLE
    $results = Find-ExtractedInfoContent -InfoList $infoCollection.Items -SearchTerm "important" -IncludeMetadata

    .EXAMPLE
    $results = Find-ExtractedInfoContent -InfoList $infoCollection.Items -SearchTerm "^\d{3}-\d{2}-\d{4}$" -UseRegex
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]$InfoList,

        [Parameter(Mandatory = $true)]
        [string]$SearchTerm,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive = $false,

        [Parameter(Mandatory = $false)]
        [switch]$UseRegex = $false,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false
    )

    begin {
        Write-Verbose "Début de Find-ExtractedInfoContent"

        # Résultats de la recherche

        $results = @()

        # Configurer les options de recherche

        $regexOptions = if ($CaseSensitive) { [System.Text.RegularExpressions.RegexOptions]::None } else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }

        # Compiler l'expression régulière si nécessaire

        $regex = if ($UseRegex) {
            try {
                [System.Text.RegularExpressions.Regex]::new($SearchTerm, $regexOptions)
            }
            catch {
                throw "Expression régulière invalide : $SearchTerm. Erreur : $_"
            }
        }
        else {
            # Échapper les caractères spéciaux pour une recherche de texte simple

            $escapedTerm = [System.Text.RegularExpressions.Regex]::Escape($SearchTerm)
            [System.Text.RegularExpressions.Regex]::new($escapedTerm, $regexOptions)
        }

        # Fonction pour rechercher dans une chaîne

        function Search-InString {
            param (
                [string]$Text,
                [System.Text.RegularExpressions.Regex]$Regex
            )

            if ([string]::IsNullOrEmpty($Text)) {
                return @()
            }

            $matches = $Regex.Matches($Text)

            if ($matches.Count -gt 0) {
                return @(
                    foreach ($match in $matches) {
                        [PSCustomObject]@{
                            Value = $match.Value
                            Index = $match.Index
                            Length = $match.Length
                            Context = Get-MatchContext -Text $Text -Match $match
                        }
                    }
                )
            }

            return @()
        }

        # Fonction pour obtenir le contexte autour d'une correspondance

        function Get-MatchContext {
            param (
                [string]$Text,
                [System.Text.RegularExpressions.Match]$Match
            )

            $contextLength = 30
            $startIndex = [Math]::Max(0, $Match.Index - $contextLength)
            $endIndex = [Math]::Min($Text.Length, $Match.Index + $Match.Length + $contextLength)
            $length = $endIndex - $startIndex

            $prefix = if ($startIndex -gt 0) { "..." } else { "" }
            $suffix = if ($endIndex -lt $Text.Length) { "..." } else { "" }

            return "$prefix$($Text.Substring($startIndex, $length))$suffix"
        }

        # Fonction pour rechercher dans un objet hashtable ou PSCustomObject

        function Search-InObject {
            param (
                [object]$Object,
                [System.Text.RegularExpressions.Regex]$Regex
            )

            $matches = @()

            if ($null -eq $Object) {
                return $matches
            }

            if ($Object -is [string]) {
                return Search-InString -Text $Object -Regex $Regex
            }
            elseif ($Object -is [hashtable] -or $Object -is [System.Collections.Specialized.OrderedDictionary]) {
                foreach ($key in $Object.Keys) {
                    $value = $Object[$key]

                    if ($value -is [string]) {
                        $stringMatches = Search-InString -Text $value -Regex $Regex

                        foreach ($match in $stringMatches) {
                            $matches += [PSCustomObject]@{
                                Path = $key
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                    elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
                        for ($i = 0; $i -lt $value.Count; $i++) {
                            $itemMatches = Search-InObject -Object $value[$i] -Regex $Regex

                            foreach ($match in $itemMatches) {
                                $matches += [PSCustomObject]@{
                                    Path = "$key[$i]$(if ($match.Path) { ".$($match.Path)" } else { "" })"
                                    Value = $match.Value
                                    Context = $match.Context
                                }
                            }
                        }
                    }
                    elseif ($value -is [hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary] -or $value -is [PSCustomObject]) {
                        $objectMatches = Search-InObject -Object $value -Regex $Regex

                        foreach ($match in $objectMatches) {
                            $matches += [PSCustomObject]@{
                                Path = "$key$(if ($match.Path) { ".$($match.Path)" } else { "" })"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                }
            }
            elseif ($Object -is [PSCustomObject]) {
                $properties = $Object | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name

                foreach ($property in $properties) {
                    $value = $Object.$property

                    if ($value -is [string]) {
                        $stringMatches = Search-InString -Text $value -Regex $Regex

                        foreach ($match in $stringMatches) {
                            $matches += [PSCustomObject]@{
                                Path = $property
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                    elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
                        for ($i = 0; $i -lt $value.Count; $i++) {
                            $itemMatches = Search-InObject -Object $value[$i] -Regex $Regex

                            foreach ($match in $itemMatches) {
                                $matches += [PSCustomObject]@{
                                    Path = "$property[$i]$(if ($match.Path) { ".$($match.Path)" } else { "" })"
                                    Value = $match.Value
                                    Context = $match.Context
                                }
                            }
                        }
                    }
                    elseif ($value -is [hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary] -or $value -is [PSCustomObject]) {
                        $objectMatches = Search-InObject -Object $value -Regex $Regex

                        foreach ($match in $objectMatches) {
                            $matches += [PSCustomObject]@{
                                Path = "$property$(if ($match.Path) { ".$($match.Path)" } else { "" })"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                }
            }
            elseif ($Object -is [array] -or $Object -is [System.Collections.IList]) {
                for ($i = 0; $i -lt $Object.Count; $i++) {
                    $itemMatches = Search-InObject -Object $Object[$i] -Regex $Regex

                    foreach ($match in $itemMatches) {
                        $matches += [PSCustomObject]@{
                            Path = "[$i]$(if ($match.Path) { ".$($match.Path)" } else { "" })"
                            Value = $match.Value
                            Context = $match.Context
                        }
                    }
                }
            }

            return $matches
        }
    }

    process {
        foreach ($info in $InfoList) {
            # Vérifier que c'est un objet d'information extraite valide

            if (-not (Test-ExtractedInfo -Info $info)) {
                Write-Warning "Objet invalide ignoré : $($info.Id)"
                continue
            }

            Write-Verbose "Recherche dans l'objet $($info.Id) de type $($info._Type)"

            # Initialiser les correspondances pour cet objet

            $infoMatches = @()

            # Recherche spécifique selon le type

            switch ($info._Type) {
                "TextExtractedInfo" {
                    # Rechercher dans le texte

                    if ($info.ContainsKey("Text") -and -not [string]::IsNullOrEmpty($info.Text)) {
                        $textMatches = Search-InString -Text $info.Text -Regex $regex

                        foreach ($match in $textMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "Text"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }

                    # Rechercher dans la langue

                    if ($info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($info.Language)) {
                        $languageMatches = Search-InString -Text $info.Language -Regex $regex

                        foreach ($match in $languageMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "Language"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                }
                "StructuredDataExtractedInfo" {
                    # Rechercher dans les données structurées

                    if ($info.ContainsKey("Data") -and $null -ne $info.Data) {
                        $dataMatches = Search-InObject -Object $info.Data -Regex $regex

                        foreach ($match in $dataMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "Data.$($match.Path)"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }

                    # Rechercher dans le format des données

                    if ($info.ContainsKey("DataFormat") -and -not [string]::IsNullOrEmpty($info.DataFormat)) {
                        $formatMatches = Search-InString -Text $info.DataFormat -Regex $regex

                        foreach ($match in $formatMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "DataFormat"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                }
                "MediaExtractedInfo" {
                    # Rechercher dans le chemin du média

                    if ($info.ContainsKey("MediaPath") -and -not [string]::IsNullOrEmpty($info.MediaPath)) {
                        $pathMatches = Search-InString -Text $info.MediaPath -Regex $regex

                        foreach ($match in $pathMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "MediaPath"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }

                    # Rechercher dans le type de média

                    if ($info.ContainsKey("MediaType") -and -not [string]::IsNullOrEmpty($info.MediaType)) {
                        $typeMatches = Search-InString -Text $info.MediaType -Regex $regex

                        foreach ($match in $typeMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "MediaType"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                }
                "GeoLocationExtractedInfo" {
                    # Rechercher dans l'adresse

                    if ($info.ContainsKey("Address") -and -not [string]::IsNullOrEmpty($info.Address)) {
                        $addressMatches = Search-InString -Text $info.Address -Regex $regex

                        foreach ($match in $addressMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "Address"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }

                    # Rechercher dans la ville

                    if ($info.ContainsKey("City") -and -not [string]::IsNullOrEmpty($info.City)) {
                        $cityMatches = Search-InString -Text $info.City -Regex $regex

                        foreach ($match in $cityMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "City"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }

                    # Rechercher dans le pays

                    if ($info.ContainsKey("Country") -and -not [string]::IsNullOrEmpty($info.Country)) {
                        $countryMatches = Search-InString -Text $info.Country -Regex $regex

                        foreach ($match in $countryMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "Country"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                }
                default {
                    # Pour les autres types, rechercher dans les propriétés de base

                    if ($info.ContainsKey("Source") -and -not [string]::IsNullOrEmpty($info.Source)) {
                        $sourceMatches = Search-InString -Text $info.Source -Regex $regex

                        foreach ($match in $sourceMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "Source"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }

                    if ($info.ContainsKey("ExtractorName") -and -not [string]::IsNullOrEmpty($info.ExtractorName)) {
                        $extractorMatches = Search-InString -Text $info.ExtractorName -Regex $regex

                        foreach ($match in $extractorMatches) {
                            $infoMatches += [PSCustomObject]@{
                                Property = "ExtractorName"
                                Value = $match.Value
                                Context = $match.Context
                            }
                        }
                    }
                }
            }

            # Rechercher dans les métadonnées si demandé

            if ($IncludeMetadata -and $info.ContainsKey("Metadata") -and $null -ne $info.Metadata) {
                $metadataMatches = Search-InObject -Object $info.Metadata -Regex $regex

                foreach ($match in $metadataMatches) {
                    $infoMatches += [PSCustomObject]@{
                        Property = "Metadata.$($match.Path)"
                        Value = $match.Value
                        Context = $match.Context
                    }
                }
            }

            # Si des correspondances ont été trouvées, ajouter l'objet aux résultats

            if ($infoMatches.Count -gt 0) {
                $results += [PSCustomObject]@{
                    Info = $info
                    Matches = $infoMatches
                }
            }
        }
    }

    end {
        Write-Verbose "Fin de Find-ExtractedInfoContent. $($results.Count) objets trouvés."
        return $results
    }
}
```plaintext
**Caractéristiques clés de cette fonction :**

1. **Traitement polymorphique** : La fonction adapte son comportement en fonction du type d'objet d'information extraite, en recherchant dans les propriétés spécifiques à chaque type.

2. **Extensibilité** : La fonction utilise une instruction `switch` pour gérer différents types, avec un cas `default` pour les types inconnus ou personnalisés.

3. **Recherche récursive** : La fonction `Search-InObject` permet de rechercher récursivement dans des structures de données complexes, comme celles qui peuvent être présentes dans les objets `StructuredDataExtractedInfo`.

4. **Options de recherche flexibles** : La fonction prend en charge la recherche sensible à la casse, les expressions régulières et l'inclusion des métadonnées.

5. **Résultats détaillés** : Les résultats incluent non seulement les correspondances trouvées, mais aussi leur contexte, ce qui facilite l'interprétation des résultats.

**Exemple d'utilisation :**

```powershell
# Créer une collection d'objets d'information extraite de différents types

$collection = New-ExtractedInfoCollection -Name "MixedCollection"

# Ajouter des objets de différents types

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @(
    (New-TextExtractedInfo -Source "document.txt" -Text "Ceci est un exemple de texte contenant des informations importantes." -Language "fr"),
    (New-StructuredDataExtractedInfo -Source "data.json" -Data @{
        Person = @{
            FirstName = "John"
            LastName = "Doe"
            Email = "john.doe@example.com"
            Phone = "123-45-6789"
        }
        Address = @{
            Street = "123 Main St"
            City = "New York"
            Country = "USA"
        }
    }),
    (New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -Address "Tour Eiffel, Champ de Mars, 5 Avenue Anatole France")
)

# Rechercher le terme "important" dans tous les objets

$results = Find-ExtractedInfoContent -InfoList $collection.Items -SearchTerm "important"

# Afficher les résultats

foreach ($result in $results) {
    Write-Host "Correspondances trouvées dans l'objet $($result.Info.Id) de type $($result.Info._Type) :"
    foreach ($match in $result.Matches) {
        Write-Host "- Propriété : $($match.Property)"
        Write-Host "  Valeur : $($match.Value)"
        Write-Host "  Contexte : $($match.Context)"
    }
    Write-Host ""
}

# Rechercher une adresse e-mail avec une expression régulière

$emailResults = Find-ExtractedInfoContent -InfoList $collection.Items -SearchTerm "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" -UseRegex

# Afficher les résultats

foreach ($result in $emailResults) {
    Write-Host "Adresse e-mail trouvée dans l'objet $($result.Info.Id) de type $($result.Info._Type) :"
    foreach ($match in $result.Matches) {
        Write-Host "- Propriété : $($match.Property)"
        Write-Host "  Adresse : $($match.Value)"
        Write-Host "  Contexte : $($match.Context)"
    }
    Write-Host ""
}
```plaintext
Cette fonction illustre comment créer une fonctionnalité qui s'intègre avec différents types d'informations extraites, en adaptant son comportement en fonction du type tout en maintenant une interface cohérente et une architecture extensible.

##### 1.4.4.2 Exemple d'une fonction de transformation adaptative

L'exemple suivant montre une fonction de transformation qui applique des transformations spécifiques à chaque type d'objet d'information extraite, tout en maintenant une interface cohérente.

```powershell
function Convert-ExtractedInfoToStandardFormat {
    <#

    .SYNOPSIS
    Convertit des objets d'information extraite en un format standard.

    .DESCRIPTION
    Cette fonction convertit des objets d'information extraite de différents types en un format standard
    pour faciliter l'intégration avec d'autres systèmes. Elle applique des transformations spécifiques
    à chaque type d'objet, tout en maintenant une structure de sortie cohérente.

    Types pris en charge et transformations :
    - TextExtractedInfo : Extraction du texte avec métadonnées linguistiques
    - StructuredDataExtractedInfo : Aplatissement des données structurées
    - MediaExtractedInfo : Extraction des métadonnées du média
    - GeoLocationExtractedInfo : Formatage des coordonnées et de l'adresse

    .PARAMETER Info
    L'objet d'information extraite à convertir.

    .PARAMETER OutputFormat
    Le format de sortie. Valeurs valides : "JSON", "CSV", "XML", "PSObject".

    .PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans la sortie.

    .PARAMETER DateFormat
    Le format à utiliser pour les dates. Par défaut : "yyyy-MM-dd HH:mm:ss".

    .EXAMPLE
    $standardInfo = Convert-ExtractedInfoToStandardFormat -Info $textInfo -OutputFormat "JSON"

    .EXAMPLE
    $collection.Items | Convert-ExtractedInfoToStandardFormat -OutputFormat "CSV" | Out-File -FilePath "export.csv"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "XML", "PSObject")]
        [string]$OutputFormat = "PSObject",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [string]$DateFormat = "yyyy-MM-dd HH:mm:ss"
    )

    begin {
        Write-Verbose "Début de Convert-ExtractedInfoToStandardFormat"

        # Fonction pour formater les dates

        function Format-Date {
            param ([datetime]$Date)

            return $Date.ToString($DateFormat)
        }

        # Fonction pour aplatir un objet imbriqué

        function Flatten-Object {
            param (
                [Parameter(Mandatory = $true)]
                [object]$Object,

                [Parameter(Mandatory = $false)]
                [string]$Prefix = ""
            )

            $result = @{}

            if ($null -eq $Object) {
                return $result
            }

            if ($Object -is [hashtable] -or $Object -is [System.Collections.Specialized.OrderedDictionary]) {
                foreach ($key in $Object.Keys) {
                    $propertyName = if ([string]::IsNullOrEmpty($Prefix)) { $key } else { "$Prefix.$key" }
                    $value = $Object[$key]

                    if ($value -is [hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary] -or $value -is [PSCustomObject]) {
                        $nestedProperties = Flatten-Object -Object $value -Prefix $propertyName
                        foreach ($nestedKey in $nestedProperties.Keys) {
                            $result[$nestedKey] = $nestedProperties[$nestedKey]
                        }
                    }
                    elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
                        if ($value.Count -gt 0) {
                            for ($i = 0; $i -lt $value.Count; $i++) {
                                $arrayPropertyName = "$propertyName[$i]"
                                $arrayValue = $value[$i]

                                if ($arrayValue -is [hashtable] -or $arrayValue -is [System.Collections.Specialized.OrderedDictionary] -or $arrayValue -is [PSCustomObject]) {
                                    $nestedProperties = Flatten-Object -Object $arrayValue -Prefix $arrayPropertyName
                                    foreach ($nestedKey in $nestedProperties.Keys) {
                                        $result[$nestedKey] = $nestedProperties[$nestedKey]
                                    }
                                }
                                else {
                                    $result[$arrayPropertyName] = $arrayValue
                                }
                            }
                        }
                        else {
                            $result[$propertyName] = "[]"
                        }
                    }
                    else {
                        $result[$propertyName] = $value
                    }
                }
            }
            elseif ($Object -is [PSCustomObject]) {
                $properties = $Object | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name

                foreach ($property in $properties) {
                    $propertyName = if ([string]::IsNullOrEmpty($Prefix)) { $property } else { "$Prefix.$property" }
                    $value = $Object.$property

                    if ($value -is [hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary] -or $value -is [PSCustomObject]) {
                        $nestedProperties = Flatten-Object -Object $value -Prefix $propertyName
                        foreach ($nestedKey in $nestedProperties.Keys) {
                            $result[$nestedKey] = $nestedProperties[$nestedKey]
                        }
                    }
                    elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
                        if ($value.Count -gt 0) {
                            for ($i = 0; $i -lt $value.Count; $i++) {
                                $arrayPropertyName = "$propertyName[$i]"
                                $arrayValue = $value[$i]

                                if ($arrayValue -is [hashtable] -or $arrayValue -is [System.Collections.Specialized.OrderedDictionary] -or $arrayValue -is [PSCustomObject]) {
                                    $nestedProperties = Flatten-Object -Object $arrayValue -Prefix $arrayPropertyName
                                    foreach ($nestedKey in $nestedProperties.Keys) {
                                        $result[$nestedKey] = $nestedProperties[$nestedKey]
                                    }
                                }
                                else {
                                    $result[$arrayPropertyName] = $arrayValue
                                }
                            }
                        }
                        else {
                            $result[$propertyName] = "[]"
                        }
                    }
                    else {
                        $result[$propertyName] = $value
                    }
                }
            }

            return $result
        }
    }

    process {
        # Vérifier que c'est un objet d'information extraite valide

        if (-not (Test-ExtractedInfo -Info $Info)) {
            throw "L'objet fourni n'est pas un objet d'information extraite valide."
        }

        Write-Verbose "Conversion de l'objet $($Info.Id) de type $($Info._Type)"

        # Créer un objet standard de base avec les propriétés communes

        $standardInfo = [ordered]@{
            Id = $Info.Id
            Type = $Info._Type
            Source = $Info.Source
            ExtractionDate = Format-Date -Date $Info.ExtractionDate
            LastModifiedDate = Format-Date -Date $Info.LastModifiedDate
            ProcessingState = $Info.ProcessingState
            ConfidenceScore = $Info.ConfidenceScore
        }

        # Ajouter les propriétés spécifiques selon le type

        switch ($Info._Type) {
            "TextExtractedInfo" {
                # Ajouter les propriétés spécifiques au texte

                if ($Info.ContainsKey("Text")) {
                    # Limiter la taille du texte pour éviter des sorties trop volumineuses

                    $maxTextLength = 1000
                    $text = $Info.Text

                    if ($text.Length -gt $maxTextLength) {
                        $text = $text.Substring(0, $maxTextLength) + "..."
                    }

                    $standardInfo["Content"] = $text
                    $standardInfo["ContentType"] = "text/plain"
                    $standardInfo["ContentLength"] = $Info.Text.Length

                    # Ajouter des statistiques sur le texte

                    $wordCount = ($Info.Text -split '\s+').Count
                    $lineCount = ($Info.Text -split '\r?\n').Count

                    $standardInfo["WordCount"] = $wordCount
                    $standardInfo["LineCount"] = $lineCount
                }

                if ($Info.ContainsKey("Language")) {
                    $standardInfo["Language"] = $Info.Language
                }
            }
            "StructuredDataExtractedInfo" {
                # Aplatir les données structurées

                if ($Info.ContainsKey("Data") -and $null -ne $Info.Data) {
                    $flattenedData = Flatten-Object -Object $Info.Data -Prefix "Data"

                    foreach ($key in $flattenedData.Keys) {
                        $standardInfo[$key] = $flattenedData[$key]
                    }

                    $standardInfo["ContentType"] = if ($Info.ContainsKey("DataFormat")) {
                        switch ($Info.DataFormat) {
                            "JSON" { "application/json" }
                            "XML" { "application/xml" }
                            "CSV" { "text/csv" }
                            default { "application/octet-stream" }
                        }
                    } else { "application/json" }
                }
            }
            "MediaExtractedInfo" {
                # Ajouter les propriétés spécifiques au média

                if ($Info.ContainsKey("MediaPath")) {
                    $standardInfo["ContentPath"] = $Info.MediaPath
                }

                if ($Info.ContainsKey("MediaType")) {
                    $standardInfo["ContentType"] = switch ($Info.MediaType) {
                        "Image" { "image/jpeg" } # Par défaut

                        "Video" { "video/mp4" }
                        "Audio" { "audio/mpeg" }
                        "Document" { "application/pdf" }
                        default { "application/octet-stream" }
                    }
                }

                if ($Info.ContainsKey("MediaSize")) {
                    $standardInfo["ContentSize"] = $Info.MediaSize
                    $standardInfo["ContentSizeFormatted"] = "{0:N2} KB" -f ($Info.MediaSize / 1KB)
                }
            }
            "GeoLocationExtractedInfo" {
                # Formater les coordonnées géographiques

                if ($Info.ContainsKey("Latitude") -and $Info.ContainsKey("Longitude")) {
                    $standardInfo["Coordinates"] = "$($Info.Latitude),$($Info.Longitude)"
                    $standardInfo["ContentType"] = "application/geo+json"

                    # Créer une URL Google Maps

                    $standardInfo["MapUrl"] = "https://www.google.com/maps?q=$($Info.Latitude),$($Info.Longitude)"
                }

                # Ajouter l'adresse formatée

                $addressParts = @()

                if ($Info.ContainsKey("Address") -and -not [string]::IsNullOrEmpty($Info.Address)) {
                    $addressParts += $Info.Address
                }
                elseif ($Info.ContainsKey("City") -or $Info.ContainsKey("Country")) {
                    if ($Info.ContainsKey("City") -and -not [string]::IsNullOrEmpty($Info.City)) {
                        $addressParts += $Info.City
                    }

                    if ($Info.ContainsKey("Country") -and -not [string]::IsNullOrEmpty($Info.Country)) {
                        $addressParts += $Info.Country
                    }
                }

                if ($addressParts.Count -gt 0) {
                    $standardInfo["FormattedAddress"] = $addressParts -join ", "
                }

                # Ajouter l'altitude si disponible

                if ($Info.ContainsKey("Altitude")) {
                    $standardInfo["Altitude"] = $Info.Altitude
                    $standardInfo["AltitudeFormatted"] = "{0:N2} m" -f $Info.Altitude
                }
            }
            default {
                # Pour les autres types, ajouter un message générique

                $standardInfo["ContentType"] = "application/octet-stream"
                $standardInfo["Note"] = "Type personnalisé ou non pris en charge spécifiquement : $($Info._Type)"
            }
        }

        # Ajouter les métadonnées si demandé

        if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
            $flattenedMetadata = Flatten-Object -Object $Info.Metadata -Prefix "Metadata"

            foreach ($key in $flattenedMetadata.Keys) {
                $standardInfo[$key] = $flattenedMetadata[$key]
            }
        }

        # Convertir au format de sortie demandé

        switch ($OutputFormat) {
            "JSON" {
                return ConvertTo-Json -InputObject $standardInfo -Depth 10
            }
            "CSV" {
                return [PSCustomObject]$standardInfo | ConvertTo-Csv -NoTypeInformation
            }
            "XML" {
                return [PSCustomObject]$standardInfo | ConvertTo-Xml -As String -NoTypeInformation
            }
            default {
                # PSObject est le format par défaut

                return [PSCustomObject]$standardInfo
            }
        }
    }

    end {
        Write-Verbose "Fin de Convert-ExtractedInfoToStandardFormat"
    }
}
```plaintext
**Caractéristiques clés de cette fonction :**

1. **Transformation adaptative** : La fonction applique des transformations spécifiques à chaque type d'objet d'information extraite, tout en produisant une structure de sortie cohérente.

2. **Format de sortie flexible** : La fonction prend en charge plusieurs formats de sortie (JSON, CSV, XML, PSObject), ce qui facilite l'intégration avec différents systèmes.

3. **Aplatissement des structures imbriquées** : La fonction `Flatten-Object` permet d'aplatir des structures de données complexes, ce qui est particulièrement utile pour les objets `StructuredDataExtractedInfo`.

4. **Traitement des propriétés spécifiques** : Chaque type d'objet est traité de manière spécifique pour extraire et formater les informations pertinentes.

5. **Gestion des métadonnées** : Les métadonnées peuvent être incluses ou exclues de la sortie selon les besoins.

**Exemple d'utilisation :**

```powershell
# Créer des objets d'information extraite de différents types

$textInfo = New-TextExtractedInfo -Source "document.txt" -Text "Ceci est un exemple de texte." -Language "fr"
$dataInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
    Person = @{
        FirstName = "John"
        LastName = "Doe"
        Age = 30
    }
    Contacts = @(
        @{ Type = "Email"; Value = "john.doe@example.com" },
        @{ Type = "Phone"; Value = "123-456-7890" }
    )
}
$geoInfo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"

# Convertir chaque objet en format standard

$standardTextInfo = Convert-ExtractedInfoToStandardFormat -Info $textInfo -OutputFormat "PSObject"
$standardDataInfo = Convert-ExtractedInfoToStandardFormat -Info $dataInfo -OutputFormat "JSON"
$standardGeoInfo = Convert-ExtractedInfoToStandardFormat -Info $geoInfo -OutputFormat "PSObject"

# Afficher les résultats

Write-Host "Informations textuelles standardisées :"
$standardTextInfo | Format-List

Write-Host "`nInformations de données structurées standardisées (JSON) :"
$standardDataInfo

Write-Host "`nInformations géographiques standardisées :"
$standardGeoInfo | Format-List

# Exporter tous les objets en CSV

$allObjects = @($textInfo, $dataInfo, $geoInfo)
$csvOutput = $allObjects | Convert-ExtractedInfoToStandardFormat -OutputFormat "CSV" -IncludeMetadata
$csvOutput | Out-File -FilePath "extracted_info_export.csv" -Encoding utf8
Write-Host "`nExportation CSV créée : extracted_info_export.csv"
```plaintext
Cette fonction illustre comment créer une fonctionnalité de transformation qui s'adapte à différents types d'objets d'information extraite, tout en produisant une sortie cohérente et structurée qui peut être facilement intégrée à d'autres systèmes.

##### 1.4.4.3 Exemple d'une fonction d'exportation universelle

L'exemple suivant montre une fonction d'exportation universelle qui peut exporter différents types d'objets d'information extraite vers divers formats de fichiers, en adaptant le processus d'exportation en fonction du type d'objet et du format cible.

###### 1.4.4.3.1 Structure de la fonction d'exportation

```powershell
function Export-ExtractedInfo {
    <#

    .SYNOPSIS
    Exporte des objets d'information extraite vers différents formats de fichiers.

    .DESCRIPTION
    Cette fonction exporte des objets d'information extraite vers différents formats de fichiers,
    en adaptant le processus d'exportation en fonction du type d'objet et du format cible.
    Elle prend en charge tous les types d'informations extraites intégrés et peut être étendue
    pour prendre en charge des types personnalisés et des formats d'exportation supplémentaires.

    Types pris en charge :
    - TextExtractedInfo : Exportation du texte
    - StructuredDataExtractedInfo : Exportation des données structurées
    - MediaExtractedInfo : Exportation des références aux fichiers média
    - GeoLocationExtractedInfo : Exportation des coordonnées géographiques

    Formats d'exportation pris en charge :
    - TXT : Texte brut
    - JSON : JavaScript Object Notation
    - XML : Extensible Markup Language
    - CSV : Comma-Separated Values
    - HTML : HyperText Markup Language
    - MARKDOWN : Format Markdown
    - KML : Keyhole Markup Language (pour les données géographiques)
    - GEOJSON : GeoJSON (pour les données géographiques)

    .PARAMETER InfoList
    Liste des objets d'information extraite à exporter.

    .PARAMETER OutputPath
    Chemin du dossier ou du fichier de sortie. Si un dossier est spécifié, des noms de fichiers
    seront générés automatiquement en fonction des IDs des objets.

    .PARAMETER Format
    Format d'exportation. Valeurs valides : "TXT", "JSON", "XML", "CSV", "HTML", "MARKDOWN", "KML", "GEOJSON".

    .PARAMETER Overwrite
    Indique si les fichiers existants doivent être écrasés.

    .PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans l'exportation.

    .PARAMETER ExportOptions
    Options supplémentaires pour l'exportation, spécifiques au format.

    .EXAMPLE
    Export-ExtractedInfo -InfoList $collection.Items -OutputPath "C:\Exports" -Format "JSON" -Overwrite

    .EXAMPLE
    $textInfo | Export-ExtractedInfo -OutputPath "C:\Exports\text_export.txt" -Format "TXT"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]$InfoList,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("TXT", "JSON", "XML", "CSV", "HTML", "MARKDOWN", "KML", "GEOJSON")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$Overwrite = $false,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    begin {
        Write-Verbose "Début de Export-ExtractedInfo"

        # Vérifier si le chemin de sortie existe

        $isDirectory = Test-Path -Path $OutputPath -PathType Container
        $isFile = Test-Path -Path $OutputPath -PathType Leaf

        if (-not $isDirectory -and -not $isFile) {
            # Le chemin n'existe pas, vérifier s'il s'agit d'un fichier ou d'un dossier

            $hasExtension = [System.IO.Path]::HasExtension($OutputPath)

            if ($hasExtension) {
                # C'est un fichier, créer le dossier parent

                $parentDir = [System.IO.Path]::GetDirectoryName($OutputPath)
                if (-not (Test-Path -Path $parentDir -PathType Container)) {
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }
            }
            else {
                # C'est un dossier, le créer

                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                $isDirectory = $true
            }
        }

        # Obtenir l'extension de fichier pour le format spécifié

        $extension = switch ($Format) {
            "TXT" { ".txt" }
            "JSON" { ".json" }
            "XML" { ".xml" }
            "CSV" { ".csv" }
            "HTML" { ".html" }
            "MARKDOWN" { ".md" }
            "KML" { ".kml" }
            "GEOJSON" { ".geojson" }
            default { ".txt" }
        }

        # Initialiser la liste des fichiers exportés

        $exportedFiles = @()

        # Fonction pour générer un nom de fichier unique

        function Get-UniqueFileName {
            param (
                [string]$BasePath,
                [string]$FileName,
                [string]$Extension
            )

            $fullPath = Join-Path -Path $BasePath -ChildPath "$FileName$Extension"
            $counter = 1

            while (Test-Path -Path $fullPath -PathType Leaf) {
                $fullPath = Join-Path -Path $BasePath -ChildPath "$FileName($counter)$Extension"
                $counter++
            }

            return $fullPath
        }
    }

    process {
        foreach ($info in $InfoList) {
            # Vérifier que c'est un objet d'information extraite valide

            if (-not (Test-ExtractedInfo -Info $info)) {
                Write-Warning "Objet invalide ignoré : $($info.Id)"
                continue
            }

            Write-Verbose "Exportation de l'objet $($info.Id) de type $($info._Type) au format $Format"

            # Déterminer le chemin de sortie pour cet objet

            $outputFilePath = if ($isDirectory) {
                # Générer un nom de fichier basé sur l'ID et le type

                $fileName = "$($info._Type)_$($info.Id)"
                Get-UniqueFileName -BasePath $OutputPath -FileName $fileName -Extension $extension
            }
            else {
                # Utiliser le chemin spécifié

                $OutputPath
            }

            # Vérifier si le fichier existe déjà

            if (Test-Path -Path $outputFilePath -PathType Leaf) {
                if (-not $Overwrite) {
                    Write-Warning "Le fichier '$outputFilePath' existe déjà et l'option Overwrite n'est pas spécifiée. Objet ignoré."
                    continue
                }
            }

            # Exporter l'objet selon son type et le format demandé

            try {
                $content = $null

                # Appeler la fonction d'exportation appropriée selon le type et le format

                switch ($info._Type) {
                    "TextExtractedInfo" {
                        $content = Export-TextExtractedInfo -Info $info -Format $Format -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
                    }
                    "StructuredDataExtractedInfo" {
                        $content = Export-StructuredDataExtractedInfo -Info $info -Format $Format -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
                    }
                    "MediaExtractedInfo" {
                        $content = Export-MediaExtractedInfo -Info $info -Format $Format -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
                    }
                    "GeoLocationExtractedInfo" {
                        $content = Export-GeoLocationExtractedInfo -Info $info -Format $Format -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
                    }
                    default {
                        # Pour les types non pris en charge spécifiquement, utiliser une exportation générique

                        $content = Export-GenericExtractedInfo -Info $info -Format $Format -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
                    }
                }

                # Écrire le contenu dans le fichier

                if ($null -ne $content) {
                    $encoding = if ($ExportOptions.ContainsKey("Encoding")) { $ExportOptions.Encoding } else { "utf8" }
                    $content | Out-File -FilePath $outputFilePath -Encoding $encoding -Force

                    $exportedFiles += $outputFilePath
                    Write-Verbose "Objet exporté avec succès vers '$outputFilePath'"
                }
                else {
                    Write-Warning "Aucun contenu généré pour l'objet $($info.Id) de type $($info._Type) au format $Format"
                }
            }
            catch {
                Write-Error "Erreur lors de l'exportation de l'objet $($info.Id) de type $($info._Type) : $_"
            }
        }
    }

    end {
        Write-Verbose "Fin de Export-ExtractedInfo. $($exportedFiles.Count) fichiers exportés."
        return $exportedFiles
    }
}
```plaintext
Cette structure de fonction d'exportation définit :

1. **Une interface cohérente** : La fonction principale `Export-ExtractedInfo` fournit une interface cohérente pour exporter tous les types d'objets d'information extraite.

2. **Un système de routage** : La fonction utilise une instruction `switch` pour router chaque objet vers la fonction d'exportation appropriée en fonction de son type.

3. **Une gestion flexible des chemins** : La fonction peut exporter vers un fichier spécifique ou générer automatiquement des noms de fichiers dans un dossier.

4. **Des options d'exportation extensibles** : Le paramètre `ExportOptions` permet de passer des options spécifiques à chaque format d'exportation.

5. **Une gestion des erreurs robuste** : La fonction inclut une gestion des erreurs pour chaque objet exporté, ce qui permet de continuer l'exportation même si certains objets échouent.

Dans les sections suivantes, nous allons implémenter les adaptateurs de format spécifiques aux types et ajouter la gestion des options d'exportation.

###### 1.4.4.3.2 Adaptateurs de format spécifiques aux types

Pour que la fonction d'exportation universelle fonctionne correctement, nous devons implémenter des adaptateurs spécifiques pour chaque type d'objet d'information extraite. Ces adaptateurs sont responsables de la conversion des objets en différents formats d'exportation.

####### 1.4.4.3.2.1 Adaptateur pour TextExtractedInfo

```powershell
function Export-TextExtractedInfo {
    <#

    .SYNOPSIS
    Exporte un objet TextExtractedInfo vers différents formats.

    .DESCRIPTION
    Cette fonction exporte un objet TextExtractedInfo vers différents formats de fichiers.

    .PARAMETER Info
    L'objet TextExtractedInfo à exporter.

    .PARAMETER Format
    Le format d'exportation.

    .PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans l'exportation.

    .PARAMETER ExportOptions
    Options supplémentaires pour l'exportation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    # Vérifier que c'est bien un TextExtractedInfo

    if ($Info._Type -ne "TextExtractedInfo") {
        throw "L'objet fourni n'est pas un TextExtractedInfo."
    }

    # Vérifier la présence du texte

    if (-not $Info.ContainsKey("Text") -or $null -eq $Info.Text) {
        throw "L'objet TextExtractedInfo ne contient pas de texte."
    }

    # Exporter selon le format demandé

    switch ($Format) {
        "TXT" {
            # Format texte brut

            $content = $Info.Text

            # Ajouter des informations de base si demandé

            if ($ExportOptions.ContainsKey("IncludeBasicInfo") -and $ExportOptions.IncludeBasicInfo) {
                $header = "ID: $($Info.Id)`n"
                $header += "Source: $($Info.Source)`n"
                $header += "Date d'extraction: $($Info.ExtractionDate)`n"
                if ($Info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($Info.Language)) {
                    $header += "Langue: $($Info.Language)`n"
                }
                $header += "---`n`n"

                $content = $header + $content
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $metadataText = "`n`n---`nMétadonnées:`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $metadataText += "$key: $($Info.Metadata[$key])`n"
                }

                $content += $metadataText
            }

            return $content
        }
        "JSON" {
            # Format JSON

            $jsonObject = @{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                Text = $Info.Text
            }

            # Ajouter la langue si disponible

            if ($Info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($Info.Language)) {
                $jsonObject["Language"] = $Info.Language
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $jsonObject["Metadata"] = $Info.Metadata
            }

            # Convertir en JSON avec la profondeur et l'indentation spécifiées

            $depth = if ($ExportOptions.ContainsKey("JsonDepth")) { $ExportOptions.JsonDepth } else { 10 }
            $indent = if ($ExportOptions.ContainsKey("JsonIndent")) { $ExportOptions.JsonIndent } else { $false }

            return ConvertTo-Json -InputObject $jsonObject -Depth $depth -Compress:(-not $indent)
        }
        "XML" {
            # Format XML

            $xmlObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                Text = $Info.Text
            }

            # Ajouter la langue si disponible

            if ($Info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($Info.Language)) {
                $xmlObject | Add-Member -MemberType NoteProperty -Name "Language" -Value $Info.Language
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $metadataObject = [PSCustomObject]@{}

                foreach ($key in $Info.Metadata.Keys) {
                    $metadataObject | Add-Member -MemberType NoteProperty -Name $key -Value $Info.Metadata[$key]
                }

                $xmlObject | Add-Member -MemberType NoteProperty -Name "Metadata" -Value $metadataObject
            }

            # Convertir en XML

            $xmlOptions = if ($ExportOptions.ContainsKey("XmlOptions")) { $ExportOptions.XmlOptions } else { @{} }
            $xmlOptions["NoTypeInformation"] = $true

            $xml = $xmlObject | ConvertTo-Xml -As String @xmlOptions

            # Ajouter une déclaration XML si elle n'est pas présente

            if (-not $xml.StartsWith("<?xml")) {
                $xml = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + $xml
            }

            return $xml
        }
        "CSV" {
            # Format CSV

            $csvObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
            }

            # Ajouter la langue si disponible

            if ($Info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($Info.Language)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "Language" -Value $Info.Language
            }

            # Pour le texte, limiter la taille pour éviter des problèmes avec CSV

            $maxTextLength = if ($ExportOptions.ContainsKey("MaxTextLength")) { $ExportOptions.MaxTextLength } else { 1000 }
            $text = $Info.Text

            if ($text.Length -gt $maxTextLength) {
                $text = $text.Substring(0, $maxTextLength) + "..."
            }

            $csvObject | Add-Member -MemberType NoteProperty -Name "Text" -Value $text

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                foreach ($key in $Info.Metadata.Keys) {
                    $metadataValue = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($metadataValue -is [hashtable] -or $metadataValue -is [array]) {
                        $metadataValue = ConvertTo-Json -InputObject $metadataValue -Compress
                    }

                    $csvObject | Add-Member -MemberType NoteProperty -Name "Metadata_$key" -Value $metadataValue
                }
            }

            # Convertir en CSV

            $csvOptions = if ($ExportOptions.ContainsKey("CsvOptions")) { $ExportOptions.CsvOptions } else { @{} }
            $csvOptions["NoTypeInformation"] = $true

            return $csvObject | ConvertTo-Csv @csvOptions
        }
        "HTML" {
            # Format HTML

            $title = if ($ExportOptions.ContainsKey("HtmlTitle")) {
                $ExportOptions.HtmlTitle
            } else {
                "TextExtractedInfo - $($Info.Id)"
            }

            $css = if ($ExportOptions.ContainsKey("HtmlCss")) {
                $ExportOptions.HtmlCss
            } else {
                @"
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    color: #333;

}
.container {
    max-width: 800px;
    margin: 0 auto;
}
.header {
    margin-bottom: 20px;
    padding-bottom: 10px;
    border-bottom: 1px solid #eee;

}
.content {
    margin-bottom: 20px;
    white-space: pre-wrap;
    padding: 15px;
    background-color: #f9f9f9;

    border: 1px solid #ddd;

    border-radius: 4px;
}
.metadata {
    margin-top: 20px;
    padding-top: 10px;
    border-top: 1px solid #eee;

}
table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}
th, td {
    padding: 8px;
    text-align: left;
    border-bottom: 1px solid #ddd;

}
th {
    background-color: #f2f2f2;

}
"@
            }

            $language = if ($Info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($Info.Language)) {
                $Info.Language
            } else {
                "non spécifiée"
            }

            $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
$css
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$title</h1>
            <table>
                <tr>
                    <th>ID</th>
                    <td>$($Info.Id)</td>
                </tr>
                <tr>
                    <th>Source</th>
                    <td>$($Info.Source)</td>
                </tr>
                <tr>
                    <th>Date d'extraction</th>
                    <td>$($Info.ExtractionDate)</td>
                </tr>
                <tr>
                    <th>Dernière modification</th>
                    <td>$($Info.LastModifiedDate)</td>
                </tr>
                <tr>
                    <th>État de traitement</th>
                    <td>$($Info.ProcessingState)</td>
                </tr>
                <tr>
                    <th>Score de confiance</th>
                    <td>$($Info.ConfidenceScore)</td>
                </tr>
                <tr>
                    <th>Langue</th>
                    <td>$language</td>
                </tr>
            </table>
        </div>

        <h2>Contenu</h2>
        <div class="content">$([System.Web.HttpUtility]::HtmlEncode($Info.Text))</div>
"@

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $html += @"

        <div class="metadata">
            <h2>Métadonnées</h2>
            <table>
                <tr>
                    <th>Clé</th>
                    <th>Valeur</th>
                </tr>
"@

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $html += @"
                <tr>
                    <td>$([System.Web.HttpUtility]::HtmlEncode($key))</td>
                    <td>$([System.Web.HttpUtility]::HtmlEncode($value))</td>
                </tr>
"@
                }

                $html += @"
            </table>
        </div>
"@
            }

            $html += @"
    </div>
</body>
</html>
"@

            return $html
        }
        "MARKDOWN" {
            # Format Markdown

            $markdown = "# TextExtractedInfo - $($Info.Id)`n`n"

            $markdown += "## Informations générales`n`n"

            $markdown += "| Propriété | Valeur |`n"
            $markdown += "| --- | --- |`n"
            $markdown += "| ID | $($Info.Id) |`n"
            $markdown += "| Source | $($Info.Source) |`n"
            $markdown += "| Date d'extraction | $($Info.ExtractionDate) |`n"
            $markdown += "| Dernière modification | $($Info.LastModifiedDate) |`n"
            $markdown += "| État de traitement | $($Info.ProcessingState) |`n"
            $markdown += "| Score de confiance | $($Info.ConfidenceScore) |`n"

            if ($Info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($Info.Language)) {
                $markdown += "| Langue | $($Info.Language) |`n"
            }

            $markdown += "`n## Contenu`n`n"

            # Déterminer si le contenu doit être mis en forme comme un bloc de code

            $formatAsCodeBlock = if ($ExportOptions.ContainsKey("FormatTextAsCodeBlock")) {
                $ExportOptions.FormatTextAsCodeBlock
            } else {
                $false
            }

            if ($formatAsCodeBlock) {
                $language = if ($Info.ContainsKey("Language") -and -not [string]::IsNullOrEmpty($Info.Language)) {
                    $Info.Language
                } else {
                    ""
                }

                $markdown += "```$language`n$($Info.Text)`n```"
            }
            else {
                $markdown += $Info.Text
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $markdown += "`n`n## Métadonnées`n`n"

                $markdown += "| Clé | Valeur |`n"
                $markdown += "| --- | --- |`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $markdown += "| $key | $value |`n"
                }
            }

            return $markdown
        }
        default {
            # Pour les formats non pris en charge spécifiquement, utiliser JSON

            Write-Warning "Format '$Format' non pris en charge spécifiquement pour TextExtractedInfo. Utilisation de JSON."
            return Export-TextExtractedInfo -Info $Info -Format "JSON" -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
        }
    }
}
```plaintext
Cet adaptateur pour `TextExtractedInfo` prend en charge plusieurs formats d'exportation :

1. **TXT** : Exporte le texte brut, avec des options pour inclure des informations de base et des métadonnées.
2. **JSON** : Convertit l'objet en format JSON, avec des options pour la profondeur et l'indentation.
3. **XML** : Convertit l'objet en format XML, avec des options pour la personnalisation.
4. **CSV** : Convertit l'objet en format CSV, avec une limitation de la taille du texte pour éviter des problèmes.
5. **HTML** : Génère une page HTML formatée avec le texte et les informations associées.
6. **MARKDOWN** : Génère un document Markdown avec le texte et les informations associées.

Pour chaque format, l'adaptateur prend en compte les spécificités du type `TextExtractedInfo`, comme la présence d'un texte et d'une langue, et adapte l'exportation en conséquence.

####### 1.4.4.3.2.2 Adaptateur pour StructuredDataExtractedInfo

```powershell
function Export-StructuredDataExtractedInfo {
    <#

    .SYNOPSIS
    Exporte un objet StructuredDataExtractedInfo vers différents formats.

    .DESCRIPTION
    Cette fonction exporte un objet StructuredDataExtractedInfo vers différents formats de fichiers.

    .PARAMETER Info
    L'objet StructuredDataExtractedInfo à exporter.

    .PARAMETER Format
    Le format d'exportation.

    .PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans l'exportation.

    .PARAMETER ExportOptions
    Options supplémentaires pour l'exportation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    # Vérifier que c'est bien un StructuredDataExtractedInfo

    if ($Info._Type -ne "StructuredDataExtractedInfo") {
        throw "L'objet fourni n'est pas un StructuredDataExtractedInfo."
    }

    # Vérifier la présence des données

    if (-not $Info.ContainsKey("Data") -or $null -eq $Info.Data) {
        throw "L'objet StructuredDataExtractedInfo ne contient pas de données."
    }

    # Exporter selon le format demandé

    switch ($Format) {
        "JSON" {
            # Format JSON

            $jsonObject = @{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                Data = $Info.Data
            }

            # Ajouter le format des données si disponible

            if ($Info.ContainsKey("DataFormat") -and -not [string]::IsNullOrEmpty($Info.DataFormat)) {
                $jsonObject["DataFormat"] = $Info.DataFormat
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $jsonObject["Metadata"] = $Info.Metadata
            }

            # Convertir en JSON avec la profondeur et l'indentation spécifiées

            $depth = if ($ExportOptions.ContainsKey("JsonDepth")) { $ExportOptions.JsonDepth } else { 10 }
            $indent = if ($ExportOptions.ContainsKey("JsonIndent")) { $ExportOptions.JsonIndent } else { $true }

            return ConvertTo-Json -InputObject $jsonObject -Depth $depth -Compress:(-not $indent)
        }
        "XML" {
            # Format XML

            $xmlObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
            }

            # Ajouter le format des données si disponible

            if ($Info.ContainsKey("DataFormat") -and -not [string]::IsNullOrEmpty($Info.DataFormat)) {
                $xmlObject | Add-Member -MemberType NoteProperty -Name "DataFormat" -Value $Info.DataFormat
            }

            # Convertir les données en PSCustomObject pour une meilleure sérialisation XML

            $dataObject = ConvertTo-PSCustomObject -InputObject $Info.Data
            $xmlObject | Add-Member -MemberType NoteProperty -Name "Data" -Value $dataObject

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $metadataObject = ConvertTo-PSCustomObject -InputObject $Info.Metadata
                $xmlObject | Add-Member -MemberType NoteProperty -Name "Metadata" -Value $metadataObject
            }

            # Convertir en XML

            $xmlOptions = if ($ExportOptions.ContainsKey("XmlOptions")) { $ExportOptions.XmlOptions } else { @{} }
            $xmlOptions["NoTypeInformation"] = $true

            $xml = $xmlObject | ConvertTo-Xml -As String @xmlOptions

            # Ajouter une déclaration XML si elle n'est pas présente

            if (-not $xml.StartsWith("<?xml")) {
                $xml = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + $xml
            }

            return $xml
        }
        "CSV" {
            # Format CSV - Aplatir les données structurées

            $flattenedData = Flatten-Object -Object $Info.Data -Prefix "Data"

            # Créer l'objet de base

            $csvObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
            }

            # Ajouter le format des données si disponible

            if ($Info.ContainsKey("DataFormat") -and -not [string]::IsNullOrEmpty($Info.DataFormat)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "DataFormat" -Value $Info.DataFormat
            }

            # Ajouter les données aplaties

            foreach ($key in $flattenedData.Keys) {
                $value = $flattenedData[$key]

                # Convertir les valeurs complexes en chaînes

                if ($value -is [hashtable] -or $value -is [array]) {
                    $value = ConvertTo-Json -InputObject $value -Compress
                }

                $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $value
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $flattenedMetadata = Flatten-Object -Object $Info.Metadata -Prefix "Metadata"

                foreach ($key in $flattenedMetadata.Keys) {
                    $value = $flattenedMetadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $value
                }
            }

            # Convertir en CSV

            $csvOptions = if ($ExportOptions.ContainsKey("CsvOptions")) { $ExportOptions.CsvOptions } else { @{} }
            $csvOptions["NoTypeInformation"] = $true

            return $csvObject | ConvertTo-Csv @csvOptions
        }
        "HTML" {
            # Format HTML

            $title = if ($ExportOptions.ContainsKey("HtmlTitle")) {
                $ExportOptions.HtmlTitle
            } else {
                "StructuredDataExtractedInfo - $($Info.Id)"
            }

            $css = if ($ExportOptions.ContainsKey("HtmlCss")) {
                $ExportOptions.HtmlCss
            } else {
                @"
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    color: #333;

}
.container {
    max-width: 800px;
    margin: 0 auto;
}
.header {
    margin-bottom: 20px;
    padding-bottom: 10px;
    border-bottom: 1px solid #eee;

}
.content {
    margin-bottom: 20px;
}
.data-container {
    background-color: #f9f9f9;

    border: 1px solid #ddd;

    border-radius: 4px;
    padding: 15px;
    overflow: auto;
}
pre {
    margin: 0;
    white-space: pre-wrap;
}
.metadata {
    margin-top: 20px;
    padding-top: 10px;
    border-top: 1px solid #eee;

}
table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}
th, td {
    padding: 8px;
    text-align: left;
    border-bottom: 1px solid #ddd;

}
th {
    background-color: #f2f2f2;

}
"@
            }

            $dataFormat = if ($Info.ContainsKey("DataFormat") -and -not [string]::IsNullOrEmpty($Info.DataFormat)) {
                $Info.DataFormat
            } else {
                "non spécifié"
            }

            # Convertir les données en JSON formaté pour l'affichage

            $jsonData = ConvertTo-Json -InputObject $Info.Data -Depth 10 -Compress:$false

            $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
$css
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$title</h1>
            <table>
                <tr>
                    <th>ID</th>
                    <td>$($Info.Id)</td>
                </tr>
                <tr>
                    <th>Source</th>
                    <td>$($Info.Source)</td>
                </tr>
                <tr>
                    <th>Date d'extraction</th>
                    <td>$($Info.ExtractionDate)</td>
                </tr>
                <tr>
                    <th>Dernière modification</th>
                    <td>$($Info.LastModifiedDate)</td>
                </tr>
                <tr>
                    <th>État de traitement</th>
                    <td>$($Info.ProcessingState)</td>
                </tr>
                <tr>
                    <th>Score de confiance</th>
                    <td>$($Info.ConfidenceScore)</td>
                </tr>
                <tr>
                    <th>Format des données</th>
                    <td>$dataFormat</td>
                </tr>
            </table>
        </div>

        <h2>Données structurées</h2>
        <div class="data-container">
            <pre>$([System.Web.HttpUtility]::HtmlEncode($jsonData))</pre>
        </div>
"@

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $html += @"

        <div class="metadata">
            <h2>Métadonnées</h2>
            <table>
                <tr>
                    <th>Clé</th>
                    <th>Valeur</th>
                </tr>
"@

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $html += @"
                <tr>
                    <td>$([System.Web.HttpUtility]::HtmlEncode($key))</td>
                    <td>$([System.Web.HttpUtility]::HtmlEncode($value))</td>
                </tr>
"@
                }

                $html += @"
            </table>
        </div>
"@
            }

            $html += @"
    </div>
</body>
</html>
"@

            return $html
        }
        "MARKDOWN" {
            # Format Markdown

            $markdown = "# StructuredDataExtractedInfo - $($Info.Id)`n`n"

            $markdown += "## Informations générales`n`n"

            $markdown += "| Propriété | Valeur |`n"
            $markdown += "| --- | --- |`n"
            $markdown += "| ID | $($Info.Id) |`n"
            $markdown += "| Source | $($Info.Source) |`n"
            $markdown += "| Date d'extraction | $($Info.ExtractionDate) |`n"
            $markdown += "| Dernière modification | $($Info.LastModifiedDate) |`n"
            $markdown += "| État de traitement | $($Info.ProcessingState) |`n"
            $markdown += "| Score de confiance | $($Info.ConfidenceScore) |`n"

            if ($Info.ContainsKey("DataFormat") -and -not [string]::IsNullOrEmpty($Info.DataFormat)) {
                $markdown += "| Format des données | $($Info.DataFormat) |`n"
            }

            $markdown += "`n## Données structurées`n`n"

            # Convertir les données en JSON formaté

            $jsonData = ConvertTo-Json -InputObject $Info.Data -Depth 10 -Compress:$false

            $markdown += "```json`n$jsonData`n```"

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $markdown += "`n`n## Métadonnées`n`n"

                $markdown += "| Clé | Valeur |`n"
                $markdown += "| --- | --- |`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $markdown += "| $key | $value |`n"
                }
            }

            return $markdown
        }
        "TXT" {
            # Format texte brut

            $content = "ID: $($Info.Id)`n"
            $content += "Type: $($Info._Type)`n"
            $content += "Source: $($Info.Source)`n"
            $content += "Date d'extraction: $($Info.ExtractionDate)`n"
            $content += "Dernière modification: $($Info.LastModifiedDate)`n"
            $content += "État de traitement: $($Info.ProcessingState)`n"
            $content += "Score de confiance: $($Info.ConfidenceScore)`n"

            if ($Info.ContainsKey("DataFormat") -and -not [string]::IsNullOrEmpty($Info.DataFormat)) {
                $content += "Format des données: $($Info.DataFormat)`n"
            }

            $content += "`n--- Données structurées ---`n`n"

            # Convertir les données en JSON formaté

            $jsonData = ConvertTo-Json -InputObject $Info.Data -Depth 10 -Compress:$false
            $content += $jsonData

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $content += "`n`n--- Métadonnées ---`n`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $content += "$key: $value`n"
                }
            }

            return $content
        }
        default {
            # Pour les formats non pris en charge spécifiquement, utiliser JSON

            Write-Warning "Format '$Format' non pris en charge spécifiquement pour StructuredDataExtractedInfo. Utilisation de JSON."
            return Export-StructuredDataExtractedInfo -Info $Info -Format "JSON" -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
        }
    }
}

# Fonction utilitaire pour convertir un objet en PSCustomObject

function ConvertTo-PSCustomObject {
    param (
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [string] -or $InputObject -is [int] -or $InputObject -is [double] -or $InputObject -is [bool] -or $InputObject -is [datetime]) {
        return $InputObject
    }

    if ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.Specialized.OrderedDictionary]) {
        $result = [PSCustomObject]@{}

        foreach ($key in $InputObject.Keys) {
            $value = ConvertTo-PSCustomObject -InputObject $InputObject[$key]
            $result | Add-Member -MemberType NoteProperty -Name $key -Value $value
        }

        return $result
    }

    if ($InputObject -is [array] -or $InputObject -is [System.Collections.IList]) {
        $result = @()

        foreach ($item in $InputObject) {
            $result += ConvertTo-PSCustomObject -InputObject $item
        }

        return $result
    }

    if ($InputObject -is [PSCustomObject]) {
        $result = [PSCustomObject]@{}

        $properties = $InputObject | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name

        foreach ($property in $properties) {
            $value = ConvertTo-PSCustomObject -InputObject $InputObject.$property
            $result | Add-Member -MemberType NoteProperty -Name $property -Value $value
        }

        return $result
    }

    # Pour les autres types, retourner tel quel

    return $InputObject
}

# Fonction utilitaire pour aplatir un objet imbriqué

function Flatten-Object {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Object,

        [Parameter(Mandatory = $false)]
        [string]$Prefix = ""
    )

    $result = @{}

    if ($null -eq $Object) {
        return $result
    }

    if ($Object -is [hashtable] -or $Object -is [System.Collections.Specialized.OrderedDictionary]) {
        foreach ($key in $Object.Keys) {
            $propertyName = if ([string]::IsNullOrEmpty($Prefix)) { $key } else { "$Prefix.$key" }
            $value = $Object[$key]

            if ($value -is [hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary] -or $value -is [PSCustomObject]) {
                $nestedProperties = Flatten-Object -Object $value -Prefix $propertyName
                foreach ($nestedKey in $nestedProperties.Keys) {
                    $result[$nestedKey] = $nestedProperties[$nestedKey]
                }
            }
            elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
                if ($value.Count -gt 0) {
                    for ($i = 0; $i -lt $value.Count; $i++) {
                        $arrayPropertyName = "$propertyName[$i]"
                        $arrayValue = $value[$i]

                        if ($arrayValue -is [hashtable] -or $arrayValue -is [System.Collections.Specialized.OrderedDictionary] -or $arrayValue -is [PSCustomObject]) {
                            $nestedProperties = Flatten-Object -Object $arrayValue -Prefix $arrayPropertyName
                            foreach ($nestedKey in $nestedProperties.Keys) {
                                $result[$nestedKey] = $nestedProperties[$nestedKey]
                            }
                        }
                        else {
                            $result[$arrayPropertyName] = $arrayValue
                        }
                    }
                }
                else {
                    $result[$propertyName] = "[]"
                }
            }
            else {
                $result[$propertyName] = $value
            }
        }
    }
    elseif ($Object -is [PSCustomObject]) {
        $properties = $Object | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name

        foreach ($property in $properties) {
            $propertyName = if ([string]::IsNullOrEmpty($Prefix)) { $property } else { "$Prefix.$property" }
            $value = $Object.$property

            if ($value -is [hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary] -or $value -is [PSCustomObject]) {
                $nestedProperties = Flatten-Object -Object $value -Prefix $propertyName
                foreach ($nestedKey in $nestedProperties.Keys) {
                    $result[$nestedKey] = $nestedProperties[$nestedKey]
                }
            }
            elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
                if ($value.Count -gt 0) {
                    for ($i = 0; $i -lt $value.Count; $i++) {
                        $arrayPropertyName = "$propertyName[$i]"
                        $arrayValue = $value[$i]

                        if ($arrayValue -is [hashtable] -or $arrayValue -is [System.Collections.Specialized.OrderedDictionary] -or $arrayValue -is [PSCustomObject]) {
                            $nestedProperties = Flatten-Object -Object $arrayValue -Prefix $arrayPropertyName
                            foreach ($nestedKey in $nestedProperties.Keys) {
                                $result[$nestedKey] = $nestedProperties[$nestedKey]
                            }
                        }
                        else {
                            $result[$arrayPropertyName] = $arrayValue
                        }
                    }
                }
                else {
                    $result[$propertyName] = "[]"
                }
            }
            else {
                $result[$propertyName] = $value
            }
        }
    }

    return $result
}
```plaintext
Cet adaptateur pour `StructuredDataExtractedInfo` prend en charge plusieurs formats d'exportation, avec une attention particulière aux spécificités des données structurées :

1. **JSON** : Format naturel pour les données structurées, avec des options pour la profondeur et l'indentation.
2. **XML** : Conversion des données structurées en format XML, avec une fonction utilitaire pour convertir les hashtables en PSCustomObjects.
3. **CSV** : Aplatissement des données structurées pour les adapter au format tabulaire CSV.
4. **HTML** : Génération d'une page HTML avec les données structurées affichées dans un bloc préformaté.
5. **MARKDOWN** : Génération d'un document Markdown avec les données structurées formatées en JSON.
6. **TXT** : Format texte brut avec les données structurées formatées en JSON.

L'adaptateur inclut également deux fonctions utilitaires importantes :

1. **ConvertTo-PSCustomObject** : Convertit récursivement les hashtables et autres structures de données en PSCustomObjects, ce qui est nécessaire pour une meilleure sérialisation XML.
2. **Flatten-Object** : Aplatit les structures de données imbriquées en une structure plate avec des noms de propriétés composés, ce qui est utile pour les formats tabulaires comme CSV.

####### 1.4.4.3.2.3 Adaptateur pour MediaExtractedInfo

```powershell
function Export-MediaExtractedInfo {
    <#

    .SYNOPSIS
    Exporte un objet MediaExtractedInfo vers différents formats.

    .DESCRIPTION
    Cette fonction exporte un objet MediaExtractedInfo vers différents formats de fichiers.

    .PARAMETER Info
    L'objet MediaExtractedInfo à exporter.

    .PARAMETER Format
    Le format d'exportation.

    .PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans l'exportation.

    .PARAMETER ExportOptions
    Options supplémentaires pour l'exportation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    # Vérifier que c'est bien un MediaExtractedInfo

    if ($Info._Type -ne "MediaExtractedInfo") {
        throw "L'objet fourni n'est pas un MediaExtractedInfo."
    }

    # Vérifier la présence du chemin média

    if (-not $Info.ContainsKey("MediaPath") -or [string]::IsNullOrEmpty($Info.MediaPath)) {
        throw "L'objet MediaExtractedInfo ne contient pas de chemin média valide."
    }

    # Obtenir les métadonnées du fichier média si possible

    $mediaMetadata = @{}

    if (Test-Path -Path $Info.MediaPath -PathType Leaf) {
        $fileInfo = Get-Item -Path $Info.MediaPath

        $mediaMetadata = @{
            FileName = $fileInfo.Name
            FileExtension = $fileInfo.Extension
            FileSize = $fileInfo.Length
            CreationTime = $fileInfo.CreationTime
            LastWriteTime = $fileInfo.LastWriteTime
            IsReadOnly = $fileInfo.IsReadOnly
        }

        # Essayer d'obtenir des métadonnées supplémentaires selon le type de média

        if ($Info.ContainsKey("MediaType")) {
            switch ($Info.MediaType) {
                "Image" {
                    try {
                        Add-Type -AssemblyName System.Drawing
                        $image = [System.Drawing.Image]::FromFile($Info.MediaPath)

                        $mediaMetadata["Width"] = $image.Width
                        $mediaMetadata["Height"] = $image.Height
                        $mediaMetadata["PixelFormat"] = $image.PixelFormat.ToString()
                        $mediaMetadata["Resolution"] = "$($image.HorizontalResolution)x$($image.VerticalResolution) dpi"

                        # Libérer les ressources

                        $image.Dispose()
                    }
                    catch {
                        Write-Warning "Impossible de récupérer les métadonnées de l'image : $_"
                    }
                }
                # Ajouter d'autres types de média si nécessaire

            }
        }
    }
    else {
        Write-Warning "Le fichier média '$($Info.MediaPath)' n'existe pas. Les métadonnées du fichier ne seront pas disponibles."
    }

    # Exporter selon le format demandé

    switch ($Format) {
        "JSON" {
            # Format JSON

            $jsonObject = @{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                MediaPath = $Info.MediaPath
            }

            # Ajouter le type de média si disponible

            if ($Info.ContainsKey("MediaType") -and -not [string]::IsNullOrEmpty($Info.MediaType)) {
                $jsonObject["MediaType"] = $Info.MediaType
            }

            # Ajouter la taille du média si disponible

            if ($Info.ContainsKey("MediaSize")) {
                $jsonObject["MediaSize"] = $Info.MediaSize
            }

            # Ajouter les métadonnées du fichier

            $jsonObject["FileMetadata"] = $mediaMetadata

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $jsonObject["Metadata"] = $Info.Metadata
            }

            # Convertir en JSON avec la profondeur et l'indentation spécifiées

            $depth = if ($ExportOptions.ContainsKey("JsonDepth")) { $ExportOptions.JsonDepth } else { 10 }
            $indent = if ($ExportOptions.ContainsKey("JsonIndent")) { $ExportOptions.JsonIndent } else { $true }

            return ConvertTo-Json -InputObject $jsonObject -Depth $depth -Compress:(-not $indent)
        }
        "XML" {
            # Format XML

            $xmlObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                MediaPath = $Info.MediaPath
            }

            # Ajouter le type de média si disponible

            if ($Info.ContainsKey("MediaType") -and -not [string]::IsNullOrEmpty($Info.MediaType)) {
                $xmlObject | Add-Member -MemberType NoteProperty -Name "MediaType" -Value $Info.MediaType
            }

            # Ajouter la taille du média si disponible

            if ($Info.ContainsKey("MediaSize")) {
                $xmlObject | Add-Member -MemberType NoteProperty -Name "MediaSize" -Value $Info.MediaSize
            }

            # Ajouter les métadonnées du fichier

            $fileMetadataObject = ConvertTo-PSCustomObject -InputObject $mediaMetadata
            $xmlObject | Add-Member -MemberType NoteProperty -Name "FileMetadata" -Value $fileMetadataObject

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $metadataObject = ConvertTo-PSCustomObject -InputObject $Info.Metadata
                $xmlObject | Add-Member -MemberType NoteProperty -Name "Metadata" -Value $metadataObject
            }

            # Convertir en XML

            $xmlOptions = if ($ExportOptions.ContainsKey("XmlOptions")) { $ExportOptions.XmlOptions } else { @{} }
            $xmlOptions["NoTypeInformation"] = $true

            $xml = $xmlObject | ConvertTo-Xml -As String @xmlOptions

            # Ajouter une déclaration XML si elle n'est pas présente

            if (-not $xml.StartsWith("<?xml")) {
                $xml = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + $xml
            }

            return $xml
        }
        "CSV" {
            # Format CSV

            $csvObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                MediaPath = $Info.MediaPath
            }

            # Ajouter le type de média si disponible

            if ($Info.ContainsKey("MediaType") -and -not [string]::IsNullOrEmpty($Info.MediaType)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "MediaType" -Value $Info.MediaType
            }

            # Ajouter la taille du média si disponible

            if ($Info.ContainsKey("MediaSize")) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "MediaSize" -Value $Info.MediaSize
            }

            # Ajouter les métadonnées du fichier

            $flattenedFileMetadata = Flatten-Object -Object $mediaMetadata -Prefix "FileMetadata"

            foreach ($key in $flattenedFileMetadata.Keys) {
                $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $flattenedFileMetadata[$key]
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $flattenedMetadata = Flatten-Object -Object $Info.Metadata -Prefix "Metadata"

                foreach ($key in $flattenedMetadata.Keys) {
                    $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $flattenedMetadata[$key]
                }
            }

            # Convertir en CSV

            $csvOptions = if ($ExportOptions.ContainsKey("CsvOptions")) { $ExportOptions.CsvOptions } else { @{} }
            $csvOptions["NoTypeInformation"] = $true

            return $csvObject | ConvertTo-Csv @csvOptions
        }
        "HTML" {
            # Format HTML

            $title = if ($ExportOptions.ContainsKey("HtmlTitle")) {
                $ExportOptions.HtmlTitle
            } else {
                "MediaExtractedInfo - $($Info.Id)"
            }

            $css = if ($ExportOptions.ContainsKey("HtmlCss")) {
                $ExportOptions.HtmlCss
            } else {
                @"
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    color: #333;

}
.container {
    max-width: 800px;
    margin: 0 auto;
}
.header {
    margin-bottom: 20px;
    padding-bottom: 10px;
    border-bottom: 1px solid #eee;

}
.content {
    margin-bottom: 20px;
}
.media-preview {
    max-width: 100%;
    max-height: 400px;
    display: block;
    margin: 0 auto;
    border: 1px solid #ddd;

    border-radius: 4px;
    padding: 5px;
}
.metadata {
    margin-top: 20px;
    padding-top: 10px;
    border-top: 1px solid #eee;

}
table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}
th, td {
    padding: 8px;
    text-align: left;
    border-bottom: 1px solid #ddd;

}
th {
    background-color: #f2f2f2;

}
"@
            }

            $mediaType = if ($Info.ContainsKey("MediaType") -and -not [string]::IsNullOrEmpty($Info.MediaType)) {
                $Info.MediaType
            } else {
                "non spécifié"
            }

            $mediaSize = if ($Info.ContainsKey("MediaSize")) {
                "{0:N2} KB" -f ($Info.MediaSize / 1KB)
            } else {
                "non spécifié"
            }

            $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
$css
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$title</h1>
            <table>
                <tr>
                    <th>ID</th>
                    <td>$($Info.Id)</td>
                </tr>
                <tr>
                    <th>Source</th>
                    <td>$($Info.Source)</td>
                </tr>
                <tr>
                    <th>Date d'extraction</th>
                    <td>$($Info.ExtractionDate)</td>
                </tr>
                <tr>
                    <th>Dernière modification</th>
                    <td>$($Info.LastModifiedDate)</td>
                </tr>
                <tr>
                    <th>État de traitement</th>
                    <td>$($Info.ProcessingState)</td>
                </tr>
                <tr>
                    <th>Score de confiance</th>
                    <td>$($Info.ConfidenceScore)</td>
                </tr>
                <tr>
                    <th>Type de média</th>
                    <td>$mediaType</td>
                </tr>
                <tr>
                    <th>Taille du média</th>
                    <td>$mediaSize</td>
                </tr>
                <tr>
                    <th>Chemin du média</th>
                    <td>$($Info.MediaPath)</td>
                </tr>
            </table>
        </div>
"@

            # Ajouter un aperçu du média si c'est une image et que le fichier existe

            if ($Info.ContainsKey("MediaType") -and $Info.MediaType -eq "Image" -and (Test-Path -Path $Info.MediaPath -PathType Leaf)) {
                # Déterminer si on doit inclure l'image directement ou juste un lien

                $includeImage = if ($ExportOptions.ContainsKey("IncludeImagePreview")) {
                    $ExportOptions.IncludeImagePreview
                } else {
                    $true
                }

                if ($includeImage) {
                    try {
                        # Convertir l'image en base64 pour l'inclure dans le HTML

                        $imageBytes = [System.IO.File]::ReadAllBytes($Info.MediaPath)
                        $base64Image = [System.Convert]::ToBase64String($imageBytes)
                        $extension = [System.IO.Path]::GetExtension($Info.MediaPath).TrimStart('.')
                        $mimeType = switch ($extension.ToLower()) {
                            "jpg" { "image/jpeg" }
                            "jpeg" { "image/jpeg" }
                            "png" { "image/png" }
                            "gif" { "image/gif" }
                            "bmp" { "image/bmp" }
                            default { "image/jpeg" }
                        }

                        $html += @"

        <h2>Aperçu du média</h2>
        <img src="data:$mimeType;base64,$base64Image" alt="Media Preview" class="media-preview">
"@
                    }
                    catch {
                        $html += @"

        <h2>Aperçu du média</h2>
        <p>Impossible de charger l'aperçu de l'image : $($_.Exception.Message)</p>
"@
                    }
                }
                else {
                    $html += @"

        <h2>Aperçu du média</h2>
        <p>Chemin de l'image : <a href="file://$($Info.MediaPath)">$($Info.MediaPath)</a></p>
"@
                }
            }

            # Ajouter les métadonnées du fichier

            if ($mediaMetadata.Count -gt 0) {
                $html += @"

        <h2>Métadonnées du fichier</h2>
        <table>
            <tr>
                <th>Propriété</th>
                <th>Valeur</th>
            </tr>
"@

                foreach ($key in $mediaMetadata.Keys) {
                    $value = $mediaMetadata[$key]

                    $html += @"
            <tr>
                <td>$([System.Web.HttpUtility]::HtmlEncode($key))</td>
                <td>$([System.Web.HttpUtility]::HtmlEncode($value))</td>
            </tr>
"@
                }

                $html += @"
        </table>
"@
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $html += @"

        <div class="metadata">
            <h2>Métadonnées</h2>
            <table>
                <tr>
                    <th>Clé</th>
                    <th>Valeur</th>
                </tr>
"@

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $html += @"
                <tr>
                    <td>$([System.Web.HttpUtility]::HtmlEncode($key))</td>
                    <td>$([System.Web.HttpUtility]::HtmlEncode($value))</td>
                </tr>
"@
                }

                $html += @"
            </table>
        </div>
"@
            }

            $html += @"
    </div>
</body>
</html>
"@

            return $html
        }
        "MARKDOWN" {
            # Format Markdown

            $markdown = "# MediaExtractedInfo - $($Info.Id)`n`n"

            $markdown += "## Informations générales`n`n"

            $markdown += "| Propriété | Valeur |`n"
            $markdown += "| --- | --- |`n"
            $markdown += "| ID | $($Info.Id) |`n"
            $markdown += "| Source | $($Info.Source) |`n"
            $markdown += "| Date d'extraction | $($Info.ExtractionDate) |`n"
            $markdown += "| Dernière modification | $($Info.LastModifiedDate) |`n"
            $markdown += "| État de traitement | $($Info.ProcessingState) |`n"
            $markdown += "| Score de confiance | $($Info.ConfidenceScore) |`n"

            if ($Info.ContainsKey("MediaType") -and -not [string]::IsNullOrEmpty($Info.MediaType)) {
                $markdown += "| Type de média | $($Info.MediaType) |`n"
            }

            if ($Info.ContainsKey("MediaSize")) {
                $markdown += "| Taille du média | {0:N2} KB |`n" -f ($Info.MediaSize / 1KB)
            }

            $markdown += "| Chemin du média | $($Info.MediaPath) |`n"

            # Ajouter un lien vers le fichier média

            $markdown += "`n## Fichier média`n`n"

            if (Test-Path -Path $Info.MediaPath -PathType Leaf) {
                $markdown += "Le fichier média est disponible à l'emplacement suivant : [$($Info.MediaPath)]($($Info.MediaPath))`n"
            }
            else {
                $markdown += "Le fichier média n'est pas accessible à l'emplacement spécifié : $($Info.MediaPath)`n"
            }

            # Ajouter les métadonnées du fichier

            if ($mediaMetadata.Count -gt 0) {
                $markdown += "`n## Métadonnées du fichier`n`n"

                $markdown += "| Propriété | Valeur |`n"
                $markdown += "| --- | --- |`n"

                foreach ($key in $mediaMetadata.Keys) {
                    $value = $mediaMetadata[$key]
                    $markdown += "| $key | $value |`n"
                }
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $markdown += "`n## Métadonnées`n`n"

                $markdown += "| Clé | Valeur |`n"
                $markdown += "| --- | --- |`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $markdown += "| $key | $value |`n"
                }
            }

            return $markdown
        }
        "TXT" {
            # Format texte brut

            $content = "ID: $($Info.Id)`n"
            $content += "Type: $($Info._Type)`n"
            $content += "Source: $($Info.Source)`n"
            $content += "Date d'extraction: $($Info.ExtractionDate)`n"
            $content += "Dernière modification: $($Info.LastModifiedDate)`n"
            $content += "État de traitement: $($Info.ProcessingState)`n"
            $content += "Score de confiance: $($Info.ConfidenceScore)`n"

            if ($Info.ContainsKey("MediaType") -and -not [string]::IsNullOrEmpty($Info.MediaType)) {
                $content += "Type de média: $($Info.MediaType)`n"
            }

            if ($Info.ContainsKey("MediaSize")) {
                $content += "Taille du média: {0:N2} KB`n" -f ($Info.MediaSize / 1KB)
            }

            $content += "Chemin du média: $($Info.MediaPath)`n"

            # Ajouter des informations sur le fichier média

            $content += "`n--- Informations sur le fichier média ---`n`n"

            if (Test-Path -Path $Info.MediaPath -PathType Leaf) {
                $content += "Le fichier média existe à l'emplacement spécifié.`n"
            }
            else {
                $content += "Le fichier média n'existe pas à l'emplacement spécifié.`n"
            }

            # Ajouter les métadonnées du fichier

            if ($mediaMetadata.Count -gt 0) {
                $content += "`n--- Métadonnées du fichier ---`n`n"

                foreach ($key in $mediaMetadata.Keys) {
                    $content += "$key: $($mediaMetadata[$key])`n"
                }
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $content += "`n--- Métadonnées ---`n`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $content += "$key: $value`n"
                }
            }

            return $content
        }
        default {
            # Pour les formats non pris en charge spécifiquement, utiliser JSON

            Write-Warning "Format '$Format' non pris en charge spécifiquement pour MediaExtractedInfo. Utilisation de JSON."
            return Export-MediaExtractedInfo -Info $Info -Format "JSON" -IncludeMetadata:$IncludeMetadata -ExportOptions $ExportOptions
        }
    }
}
```plaintext
Cet adaptateur pour `MediaExtractedInfo` prend en charge plusieurs formats d'exportation, avec une attention particulière aux spécificités des fichiers média :

1. **JSON** : Conversion de l'objet en format JSON, incluant les métadonnées du fichier média.
2. **XML** : Conversion de l'objet en format XML, avec les métadonnées du fichier média.
3. **CSV** : Aplatissement des métadonnées du fichier média pour les adapter au format tabulaire CSV.
4. **HTML** : Génération d'une page HTML avec un aperçu du média (pour les images) et les métadonnées associées.
5. **MARKDOWN** : Génération d'un document Markdown avec un lien vers le fichier média et les métadonnées associées.
6. **TXT** : Format texte brut avec les informations sur le fichier média et les métadonnées associées.

L'adaptateur inclut également des fonctionnalités spécifiques aux médias :

1. **Extraction de métadonnées de fichier** : Récupération des métadonnées de base du fichier (taille, dates, etc.).
2. **Extraction de métadonnées d'image** : Pour les images, récupération des dimensions, du format de pixel et de la résolution.
3. **Aperçu d'image en HTML** : Pour les images, inclusion d'un aperçu directement dans la page HTML en utilisant l'encodage base64.

####### 1.4.4.3.2.4 Adaptateur pour GeoLocationExtractedInfo

L'adaptateur pour `GeoLocationExtractedInfo` est conçu pour exporter des informations géographiques dans différents formats, y compris des formats spécifiques aux données géospatiales comme KML et GeoJSON.

###### 1.4.4.3.2.4.1 Structure de base de l'adaptateur

```powershell
function Export-GeoLocationExtractedInfo {
    <#

    .SYNOPSIS
    Exporte un objet GeoLocationExtractedInfo vers différents formats.

    .DESCRIPTION
    Cette fonction exporte un objet GeoLocationExtractedInfo vers différents formats de fichiers,
    y compris des formats spécifiques aux données géospatiales comme KML et GeoJSON.

    .PARAMETER Info
    L'objet GeoLocationExtractedInfo à exporter.

    .PARAMETER Format
    Le format d'exportation. Valeurs valides : "JSON", "XML", "CSV", "TXT", "HTML", "MARKDOWN", "KML", "GEOJSON".

    .PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans l'exportation.

    .PARAMETER ExportOptions
    Options supplémentaires pour l'exportation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "CSV", "TXT", "HTML", "MARKDOWN", "KML", "GEOJSON")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    # Vérifier que c'est bien un GeoLocationExtractedInfo

    if ($Info._Type -ne "GeoLocationExtractedInfo") {
        throw "L'objet fourni n'est pas un GeoLocationExtractedInfo."
    }

    # Vérifier la présence des coordonnées géographiques

    if (-not $Info.ContainsKey("Latitude") -or -not $Info.ContainsKey("Longitude")) {
        throw "L'objet GeoLocationExtractedInfo ne contient pas de coordonnées géographiques valides."
    }

    # Extraire les propriétés géographiques

    $latitude = $Info.Latitude
    $longitude = $Info.Longitude
    $altitude = if ($Info.ContainsKey("Altitude")) { $Info.Altitude } else { $null }
    $accuracy = if ($Info.ContainsKey("Accuracy")) { $Info.Accuracy } else { $null }

    # Extraire les propriétés d'adresse

    $address = if ($Info.ContainsKey("Address")) { $Info.Address } else { $null }
    $city = if ($Info.ContainsKey("City")) { $Info.City } else { $null }
    $region = if ($Info.ContainsKey("Region")) { $Info.Region } else { $null }
    $country = if ($Info.ContainsKey("Country")) { $Info.Country } else { $null }
    $postalCode = if ($Info.ContainsKey("PostalCode")) { $Info.PostalCode } else { $null }

    # Créer une adresse formatée si elle n'existe pas déjà

    $formattedAddress = if ($Info.ContainsKey("FormattedAddress")) {
        $Info.FormattedAddress
    } else {
        $addressParts = @()

        if (-not [string]::IsNullOrEmpty($address)) {
            $addressParts += $address
        }

        if (-not [string]::IsNullOrEmpty($city)) {
            $addressParts += $city
        }

        if (-not [string]::IsNullOrEmpty($region)) {
            $addressParts += $region
        }

        if (-not [string]::IsNullOrEmpty($postalCode)) {
            $addressParts += $postalCode
        }

        if (-not [string]::IsNullOrEmpty($country)) {
            $addressParts += $country
        }

        if ($addressParts.Count -gt 0) {
            $addressParts -join ", "
        } else {
            $null
        }
    }

    # Créer un nom pour le point géographique

    $locationName = if ($Info.ContainsKey("LocationName")) {
        $Info.LocationName
    } else {
        if (-not [string]::IsNullOrEmpty($formattedAddress)) {
            $formattedAddress
        } else {
            "Point ($latitude, $longitude)"
        }
    }

    # Exporter selon le format demandé

    switch ($Format) {
        "JSON" {
            # Format JSON

            $jsonObject = @{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                Coordinates = @{
                    Latitude = $latitude
                    Longitude = $longitude
                }
            }

            # Ajouter l'altitude si disponible

            if ($null -ne $altitude) {
                $jsonObject.Coordinates["Altitude"] = $altitude
            }

            # Ajouter la précision si disponible

            if ($null -ne $accuracy) {
                $jsonObject.Coordinates["Accuracy"] = $accuracy
            }

            # Ajouter les informations d'adresse si disponibles

            $addressInfo = @{}
            $hasAddress = $false

            if (-not [string]::IsNullOrEmpty($address)) {
                $addressInfo["Address"] = $address
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($city)) {
                $addressInfo["City"] = $city
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($region)) {
                $addressInfo["Region"] = $region
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($country)) {
                $addressInfo["Country"] = $country
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($postalCode)) {
                $addressInfo["PostalCode"] = $postalCode
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                $addressInfo["FormattedAddress"] = $formattedAddress
                $hasAddress = $true
            }

            if ($hasAddress) {
                $jsonObject["Address"] = $addressInfo
            }

            # Ajouter le nom du lieu si disponible

            if (-not [string]::IsNullOrEmpty($locationName)) {
                $jsonObject["LocationName"] = $locationName
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $jsonObject["Metadata"] = $Info.Metadata
            }

            # Convertir en JSON avec la profondeur et l'indentation spécifiées

            $depth = if ($ExportOptions.ContainsKey("JsonDepth")) { $ExportOptions.JsonDepth } else { 10 }
            $indent = if ($ExportOptions.ContainsKey("JsonIndent")) { $ExportOptions.JsonIndent } else { $true }

            return ConvertTo-Json -InputObject $jsonObject -Depth $depth -Compress:(-not $indent)
        }
        "XML" {
            # Format XML

            $xmlObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                Coordinates = [PSCustomObject]@{
                    Latitude = $latitude
                    Longitude = $longitude
                }
            }

            # Ajouter l'altitude si disponible

            if ($null -ne $altitude) {
                $xmlObject.Coordinates | Add-Member -MemberType NoteProperty -Name "Altitude" -Value $altitude
            }

            # Ajouter la précision si disponible

            if ($null -ne $accuracy) {
                $xmlObject.Coordinates | Add-Member -MemberType NoteProperty -Name "Accuracy" -Value $accuracy
            }

            # Ajouter les informations d'adresse si disponibles

            $addressInfo = [PSCustomObject]@{}
            $hasAddress = $false

            if (-not [string]::IsNullOrEmpty($address)) {
                $addressInfo | Add-Member -MemberType NoteProperty -Name "Address" -Value $address
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($city)) {
                $addressInfo | Add-Member -MemberType NoteProperty -Name "City" -Value $city
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($region)) {
                $addressInfo | Add-Member -MemberType NoteProperty -Name "Region" -Value $region
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($country)) {
                $addressInfo | Add-Member -MemberType NoteProperty -Name "Country" -Value $country
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($postalCode)) {
                $addressInfo | Add-Member -MemberType NoteProperty -Name "PostalCode" -Value $postalCode
                $hasAddress = $true
            }

            if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                $addressInfo | Add-Member -MemberType NoteProperty -Name "FormattedAddress" -Value $formattedAddress
                $hasAddress = $true
            }

            if ($hasAddress) {
                $xmlObject | Add-Member -MemberType NoteProperty -Name "Address" -Value $addressInfo
            }

            # Ajouter le nom du lieu si disponible

            if (-not [string]::IsNullOrEmpty($locationName)) {
                $xmlObject | Add-Member -MemberType NoteProperty -Name "LocationName" -Value $locationName
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $metadataObject = ConvertTo-PSCustomObject -InputObject $Info.Metadata
                $xmlObject | Add-Member -MemberType NoteProperty -Name "Metadata" -Value $metadataObject
            }

            # Convertir en XML

            $xmlOptions = if ($ExportOptions.ContainsKey("XmlOptions")) { $ExportOptions.XmlOptions } else { @{} }
            $xmlOptions["NoTypeInformation"] = $true

            $xml = $xmlObject | ConvertTo-Xml -As String @xmlOptions

            # Ajouter une déclaration XML si elle n'est pas présente

            if (-not $xml.StartsWith("<?xml")) {
                $xml = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + $xml
            }

            return $xml
        }
        "CSV" {
            # Format CSV

            $csvObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractionDate.ToString("o")
                LastModifiedDate = $Info.LastModifiedDate.ToString("o")
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
                Latitude = $latitude
                Longitude = $longitude
            }

            # Ajouter l'altitude si disponible

            if ($null -ne $altitude) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "Altitude" -Value $altitude
            }

            # Ajouter la précision si disponible

            if ($null -ne $accuracy) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "Accuracy" -Value $accuracy
            }

            # Ajouter les informations d'adresse si disponibles

            if (-not [string]::IsNullOrEmpty($address)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "Address" -Value $address
            }

            if (-not [string]::IsNullOrEmpty($city)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "City" -Value $city
            }

            if (-not [string]::IsNullOrEmpty($region)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "Region" -Value $region
            }

            if (-not [string]::IsNullOrEmpty($country)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "Country" -Value $country
            }

            if (-not [string]::IsNullOrEmpty($postalCode)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "PostalCode" -Value $postalCode
            }

            if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "FormattedAddress" -Value $formattedAddress
            }

            # Ajouter le nom du lieu si disponible

            if (-not [string]::IsNullOrEmpty($locationName)) {
                $csvObject | Add-Member -MemberType NoteProperty -Name "LocationName" -Value $locationName
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $flattenedMetadata = Flatten-Object -Object $Info.Metadata -Prefix "Metadata"

                foreach ($key in $flattenedMetadata.Keys) {
                    $value = $flattenedMetadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $value
                }
            }

            # Convertir en CSV

            $csvOptions = if ($ExportOptions.ContainsKey("CsvOptions")) { $ExportOptions.CsvOptions } else { @{} }
            $csvOptions["NoTypeInformation"] = $true

            return $csvObject | ConvertTo-Csv @csvOptions
        }
        "TXT" {
            # Format texte brut

            $content = "ID: $($Info.Id)`n"
            $content += "Type: $($Info._Type)`n"
            $content += "Source: $($Info.Source)`n"
            $content += "Date d'extraction: $($Info.ExtractionDate)`n"
            $content += "Dernière modification: $($Info.LastModifiedDate)`n"
            $content += "État de traitement: $($Info.ProcessingState)`n"
            $content += "Score de confiance: $($Info.ConfidenceScore)`n"

            $content += "`n--- Coordonnées géographiques ---`n`n"
            $content += "Latitude: $latitude`n"
            $content += "Longitude: $longitude`n"

            if ($null -ne $altitude) {
                $content += "Altitude: $altitude m`n"
            }

            if ($null -ne $accuracy) {
                $content += "Précision: $accuracy m`n"
            }

            # Ajouter les informations d'adresse si disponibles

            $hasAddress = $false

            if (-not [string]::IsNullOrEmpty($address) -or
                -not [string]::IsNullOrEmpty($city) -or
                -not [string]::IsNullOrEmpty($region) -or
                -not [string]::IsNullOrEmpty($country) -or
                -not [string]::IsNullOrEmpty($postalCode) -or
                -not [string]::IsNullOrEmpty($formattedAddress)) {

                $content += "`n--- Informations d'adresse ---`n`n"
                $hasAddress = $true

                if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                    $content += "Adresse formatée: $formattedAddress`n"
                }

                if (-not [string]::IsNullOrEmpty($address)) {
                    $content += "Adresse: $address`n"
                }

                if (-not [string]::IsNullOrEmpty($city)) {
                    $content += "Ville: $city`n"
                }

                if (-not [string]::IsNullOrEmpty($region)) {
                    $content += "Région: $region`n"
                }

                if (-not [string]::IsNullOrEmpty($postalCode)) {
                    $content += "Code postal: $postalCode`n"
                }

                if (-not [string]::IsNullOrEmpty($country)) {
                    $content += "Pays: $country`n"
                }
            }

            # Ajouter le nom du lieu si disponible

            if (-not [string]::IsNullOrEmpty($locationName) -and $locationName -ne $formattedAddress) {
                if (-not $hasAddress) {
                    $content += "`n--- Informations sur le lieu ---`n`n"
                }

                $content += "Nom du lieu: $locationName`n"
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $content += "`n--- Métadonnées ---`n`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes

                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }

                    $content += "$key: $value`n"
                }
            }

            # Ajouter un lien Google Maps

            $content += "`n--- Liens utiles ---`n`n"
            $content += "Google Maps: https://www.google.com/maps?q=$latitude,$longitude`n"

            return $content
        }
        "KML" {
            # Format KML (Keyhole Markup Language)

            $kml = @"
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$($Info.Id)</name>
    <description>$($Info.Source)</description>
    <Style id="defaultStyle">
      <IconStyle>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Placemark>
      <name>$([System.Security.SecurityElement]::Escape($locationName))</name>
      <styleUrl>#defaultStyle</styleUrl>

"@

            # Ajouter la description si des informations d'adresse sont disponibles

            if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                $kml += @"
      <description>$([System.Security.SecurityElement]::Escape($formattedAddress))</description>
"@
            }

            # Ajouter les coordonnées

            $kml += @"
      <Point>
"@

            # Ajouter l'altitude si disponible

            if ($null -ne $altitude) {
                $kml += @"
        <altitudeMode>absolute</altitudeMode>
        <coordinates>$longitude,$latitude,$altitude</coordinates>
"@
            }
            else {
                $kml += @"
        <altitudeMode>clampToGround</altitudeMode>
        <coordinates>$longitude,$latitude,0</coordinates>
"@
            }

            $kml += @"
      </Point>
"@

            # Ajouter des données étendues si demandé

            if ($IncludeMetadata -or $ExportOptions.ContainsKey("IncludeExtendedData") -and $ExportOptions.IncludeExtendedData) {
                $kml += @"
      <ExtendedData>
"@

                # Ajouter les propriétés de base

                $kml += @"
        <Data name="Id">
          <value>$($Info.Id)</value>
        </Data>
        <Data name="Source">
          <value>$([System.Security.SecurityElement]::Escape($Info.Source))</value>
        </Data>
        <Data name="ExtractionDate">
          <value>$($Info.ExtractionDate.ToString("o"))</value>
        </Data>
        <Data name="ProcessingState">
          <value>$($Info.ProcessingState)</value>
        </Data>
        <Data name="ConfidenceScore">
          <value>$($Info.ConfidenceScore)</value>
        </Data>
"@

                # Ajouter la précision si disponible

                if ($null -ne $accuracy) {
                    $kml += @"
        <Data name="Accuracy">
          <value>$accuracy</value>
        </Data>
"@
                }

                # Ajouter les informations d'adresse si disponibles

                if (-not [string]::IsNullOrEmpty($address)) {
                    $kml += @"
        <Data name="Address">
          <value>$([System.Security.SecurityElement]::Escape($address))</value>
        </Data>
"@
                }

                if (-not [string]::IsNullOrEmpty($city)) {
                    $kml += @"
        <Data name="City">
          <value>$([System.Security.SecurityElement]::Escape($city))</value>
        </Data>
"@
                }

                if (-not [string]::IsNullOrEmpty($region)) {
                    $kml += @"
        <Data name="Region">
          <value>$([System.Security.SecurityElement]::Escape($region))</value>
        </Data>
"@
                }

                if (-not [string]::IsNullOrEmpty($country)) {
                    $kml += @"
        <Data name="Country">
          <value>$([System.Security.SecurityElement]::Escape($country))</value>
        </Data>
"@
                }

                if (-not [string]::IsNullOrEmpty($postalCode)) {
                    $kml += @"
        <Data name="PostalCode">
          <value>$([System.Security.SecurityElement]::Escape($postalCode))</value>
        </Data>
"@
                }

                # Ajouter les métadonnées si demandé

                if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                    foreach ($key in $Info.Metadata.Keys) {
                        $value = $Info.Metadata[$key]

                        # Convertir les valeurs complexes en chaînes

                        if ($value -is [hashtable] -or $value -is [array]) {
                            $value = ConvertTo-Json -InputObject $value -Compress
                        }

                        $kml += @"
        <Data name="Metadata.$([System.Security.SecurityElement]::Escape($key))">
          <value>$([System.Security.SecurityElement]::Escape($value.ToString()))</value>
        </Data>
"@
                    }
                }

                $kml += @"
      </ExtendedData>
"@
            }

            $kml += @"
    </Placemark>
  </Document>
</kml>
"@

            return $kml
        }
        "GEOJSON" {
            # Format GeoJSON

            $geoJson = @{
                type = "FeatureCollection"
                features = @(
                    @{
                        type = "Feature"
                        id = $Info.Id
                        geometry = @{
                            type = "Point"
                            coordinates = if ($null -ne $altitude) {
                                @($longitude, $latitude, $altitude)
                            }
                            else {
                                @($longitude, $latitude)
                            }
                        }
                        properties = @{
                            name = $locationName
                            source = $Info.Source
                            extractionDate = $Info.ExtractionDate.ToString("o")
                            lastModifiedDate = $Info.LastModifiedDate.ToString("o")
                            processingState = $Info.ProcessingState
                            confidenceScore = $Info.ConfidenceScore
                        }
                    }
                )
            }

            # Ajouter la précision si disponible

            if ($null -ne $accuracy) {
                $geoJson.features[0].properties["accuracy"] = $accuracy
            }

            # Ajouter les informations d'adresse si disponibles

            if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                $geoJson.features[0].properties["formattedAddress"] = $formattedAddress
            }

            if (-not [string]::IsNullOrEmpty($address)) {
                $geoJson.features[0].properties["address"] = $address
            }

            if (-not [string]::IsNullOrEmpty($city)) {
                $geoJson.features[0].properties["city"] = $city
            }

            if (-not [string]::IsNullOrEmpty($region)) {
                $geoJson.features[0].properties["region"] = $region
            }

            if (-not [string]::IsNullOrEmpty($country)) {
                $geoJson.features[0].properties["country"] = $country
            }

            if (-not [string]::IsNullOrEmpty($postalCode)) {
                $geoJson.features[0].properties["postalCode"] = $postalCode
            }

            # Ajouter les métadonnées si demandé

            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $geoJson.features[0].properties["metadata"] = $Info.Metadata
            }

            # Convertir en JSON avec la profondeur et l'indentation spécifiées

            $depth = if ($ExportOptions.ContainsKey("JsonDepth")) { $ExportOptions.JsonDepth } else { 10 }
            $indent = if ($ExportOptions.ContainsKey("JsonIndent")) { $ExportOptions.JsonIndent } else { $true }

            return ConvertTo-Json -InputObject $geoJson -Depth $depth -Compress:(-not $indent)
        }
        # Les implémentations pour les autres formats seront ajoutées dans les sections suivantes

        default {
            throw "Format d'exportation '$Format' non implémenté pour GeoLocationExtractedInfo."
        }
    }
}
```plaintext
Cette structure de base définit :

1. **Paramètres d'entrée** : L'objet `GeoLocationExtractedInfo` à exporter, le format d'exportation, et des options supplémentaires.
2. **Validation** : Vérification que l'objet est bien un `GeoLocationExtractedInfo` et qu'il contient des coordonnées géographiques valides.
3. **Extraction des propriétés** : Récupération des propriétés géographiques (latitude, longitude, altitude, etc.) et des propriétés d'adresse.
4. **Formatage d'adresse** : Création d'une adresse formatée à partir des composants d'adresse si elle n'existe pas déjà.
5. **Nommage du point** : Création d'un nom pour le point géographique, utilisé dans certains formats comme KML.

###### 1.4.4.3.2.4.2 Exportation en formats standards (JSON, XML, CSV, TXT)

L'adaptateur pour `GeoLocationExtractedInfo` prend en charge plusieurs formats standards pour l'exportation des données géographiques :

1. **JSON** : Format structuré idéal pour l'échange de données, avec une organisation hiérarchique des coordonnées et des informations d'adresse.
2. **XML** : Format structuré avec balisage, adapté pour l'intégration avec des systèmes qui utilisent XML.
3. **CSV** : Format tabulaire simple, adapté pour l'importation dans des tableurs ou des bases de données.
4. **TXT** : Format texte brut, facile à lire pour les humains, avec des sections clairement délimitées.

Chaque format a ses spécificités :

**Format JSON** :
- Organisation hiérarchique des données avec un objet `Coordinates` contenant latitude, longitude, et éventuellement altitude et précision.
- Objet `Address` séparé pour les informations d'adresse.
- Support complet des métadonnées.

**Format XML** :
- Structure similaire au JSON, mais avec un balisage XML.
- Conversion des hashtables en objets PSCustomObject pour une meilleure sérialisation XML.
- Ajout d'une déclaration XML si nécessaire.

**Format CSV** :
- Structure plate avec toutes les propriétés au même niveau.
- Aplatissement des métadonnées avec des préfixes pour éviter les collisions de noms.
- Conversion des valeurs complexes en chaînes JSON.

**Format TXT** :
- Format lisible avec des sections clairement délimitées.
- Inclusion d'un lien Google Maps pour faciliter la visualisation.
- Organisation logique des informations par catégories.

Dans les sections suivantes, nous allons implémenter les formats spécifiques aux données géographiques (KML, GeoJSON) et les formats de présentation (HTML, Markdown).

###### 1.4.4.3.2.4.3 Exportation en formats géographiques (KML, GeoJSON)

L'adaptateur pour `GeoLocationExtractedInfo` prend également en charge des formats spécifiques aux données géographiques :

1. **KML (Keyhole Markup Language)** : Format basé sur XML utilisé par Google Earth et d'autres applications de cartographie.
2. **GeoJSON** : Format JSON standard pour représenter des données géospatiales.

Ces formats sont particulièrement adaptés pour la visualisation et l'analyse des données géographiques :

**Format KML** :
- Structure XML avec des éléments spécifiques pour les données géographiques.
- Support des points, lignes, polygones et autres formes géométriques.
- Possibilité d'inclure des styles et des descriptions.
- Prise en charge de l'altitude et des données étendues.
- Compatible avec Google Earth, Google Maps et d'autres applications de cartographie.

**Format GeoJSON** :
- Format JSON standard pour les données géospatiales.
- Structure simple et facile à comprendre.
- Support des points, lignes, polygones et collections.
- Prise en charge des propriétés personnalisées.
- Compatible avec de nombreuses bibliothèques de cartographie web comme Leaflet, Mapbox, etc.

L'implémentation de ces formats permet d'exporter les données géographiques dans des formats directement utilisables par des applications de cartographie, ce qui facilite la visualisation et l'analyse des données.
