# Extension du module : Création de nouveaux types d'informations extraites

## 1. Structure des types d'informations extraites

### 1.1 Type de base ExtractedInfo et ses propriétés

Le module `ExtractedInfoModuleV2` est construit autour d'un système de types d'objets d'information extraite hiérarchique et extensible. Au cœur de ce système se trouve le type de base `ExtractedInfo`, qui définit les propriétés fondamentales communes à tous les types d'informations extraites.

#### 1.1.1 Propriétés du type de base

Le type de base `ExtractedInfo` est représenté par une hashtable PowerShell avec les propriétés suivantes :

| Propriété | Type | Description | Obligatoire |
|-----------|------|-------------|-------------|
| `_Type` | String | Identifie le type de l'objet (toujours "ExtractedInfo" pour le type de base) | Oui |
| `Id` | String | Identifiant unique (GUID) | Oui |
| `Source` | String | Source de l'information (ex: nom de fichier, URL) | Oui |
| `ExtractorName` | String | Nom de l'extracteur utilisé | Oui |
| `ExtractionDate` | DateTime | Date et heure de l'extraction initiale | Oui |
| `LastModifiedDate` | DateTime | Date et heure de la dernière modification | Oui |
| `ProcessingState` | String | État de traitement (Raw, Processed, Validated, Error) | Oui |
| `ConfidenceScore` | Int32 | Score de confiance (0-100) | Oui |
| `Metadata` | Hashtable | Métadonnées additionnelles | Oui |

#### 1.1.2 Valeurs par défaut

Lors de la création d'un objet `ExtractedInfo` avec la fonction `New-ExtractedInfo`, les valeurs par défaut suivantes sont utilisées :

```powershell
$info = @{
    _Type = "ExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    Source = $Source -or "Unknown"
    ExtractorName = $ExtractorName -or "GenericExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = $ProcessingState -or "Raw"
    ConfidenceScore = $ConfidenceScore -or 50
    Metadata = @{}
}
```

#### 1.1.3 Contraintes et validation

Le type de base `ExtractedInfo` est soumis à plusieurs contraintes de validation :

1. **Propriétés requises** : Toutes les propriétés listées ci-dessus doivent être présentes.
2. **Types de données** : Chaque propriété doit avoir le type de données approprié.
3. **Valeurs autorisées** :
   - `ProcessingState` doit être l'une des valeurs suivantes : "Raw", "Processed", "Validated", "Error".
   - `ConfidenceScore` doit être un entier entre 0 et 100.

#### 1.1.4 Exemple de création d'un objet ExtractedInfo

```powershell
# Création d'un objet ExtractedInfo avec les valeurs par défaut
$info = New-ExtractedInfo

# Création d'un objet ExtractedInfo avec des valeurs spécifiques
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor" -ProcessingState "Raw" -ConfidenceScore 75

# Vérification du type de l'objet
$info._Type # Retourne "ExtractedInfo"
```

#### 1.1.5 Importance du type de base

Le type de base `ExtractedInfo` est fondamental pour le module car :

1. Il définit la structure commune à tous les types d'informations extraites.
2. Il permet aux fonctions du module de traiter tous les types d'informations de manière uniforme.
3. Il sert de base pour l'extension du système avec de nouveaux types spécialisés.

Lorsque vous créez un nouveau type d'information extraite, vous devez vous assurer qu'il hérite correctement de ce type de base en incluant toutes ses propriétés requises.

### 1.2 Mécanisme d'héritage par hashtable

Le module `ExtractedInfoModuleV2` implémente un système d'héritage basé sur les hashtables PowerShell, qui permet de créer des types spécialisés tout en maintenant la compatibilité avec les fonctions existantes.

#### 1.2.1 Principe de l'héritage par hashtable

Contrairement à l'héritage de classes traditionnel en programmation orientée objet, l'héritage par hashtable fonctionne en :

1. **Copiant toutes les propriétés** du type parent (base) dans le type enfant (spécialisé).
2. **Modifiant la propriété `_Type`** pour refléter le type spécialisé.
3. **Ajoutant des propriétés spécifiques** au type spécialisé.

Ce mécanisme permet de créer une hiérarchie de types sans utiliser de classes PowerShell ou .NET, ce qui garantit une compatibilité maximale avec différentes versions de PowerShell.

#### 1.2.2 Implémentation de l'héritage

Voici comment l'héritage est généralement implémenté dans les fonctions de création de types spécialisés :

```powershell
function New-SpecializedExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SpecialProperty,

        # Paramètres communs hérités du type de base
        [string]$Source = "Unknown",
        [string]$ExtractorName = "SpecializedExtractor",
        [string]$ProcessingState = "Raw",
        [int]$ConfidenceScore = 50
    )

    # 1. Créer d'abord un objet du type de base
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName -ProcessingState $ProcessingState -ConfidenceScore $ConfidenceScore

    # 2. Modifier le type pour refléter le type spécialisé
    $info._Type = "SpecializedExtractedInfo"

    # 3. Ajouter les propriétés spécifiques au type spécialisé
    $info.SpecialProperty = $SpecialProperty

    return $info
}
```

#### 1.2.3 Avantages de l'héritage par hashtable

Ce mécanisme d'héritage présente plusieurs avantages :

1. **Simplicité** : Facile à comprendre et à implémenter.
2. **Compatibilité** : Fonctionne avec toutes les versions de PowerShell (y compris PowerShell 5.1).
3. **Flexibilité** : Permet d'ajouter facilement de nouvelles propriétés et de nouveaux types.
4. **Interopérabilité** : Les objets peuvent être facilement convertis en JSON et vice-versa.
5. **Uniformité** : Toutes les fonctions du module peuvent traiter les différents types de manière cohérente.

#### 1.2.4 Considérations importantes

Lors de l'implémentation de l'héritage par hashtable, il est important de :

1. **Préserver toutes les propriétés du type de base** pour maintenir la compatibilité avec les fonctions existantes.
2. **Utiliser des noms de propriétés uniques** pour éviter les conflits avec les propriétés du type de base ou d'autres types spécialisés.
3. **Mettre à jour correctement la propriété `_Type`** pour permettre l'identification du type spécialisé.
4. **Implémenter des règles de validation spécifiques** pour les nouvelles propriétés.
5. **Documenter clairement la structure** du nouveau type pour faciliter son utilisation.

#### 1.2.5 Exemple d'héritage à plusieurs niveaux

L'héritage par hashtable peut également être utilisé pour créer des hiérarchies à plusieurs niveaux :

```powershell
# Niveau 1 : Type de base
$baseInfo = New-ExtractedInfo -Source "base.txt"

# Niveau 2 : Type spécialisé
$specializedInfo = New-SpecializedExtractedInfo -Source "specialized.txt" -SpecialProperty "Value"

# Niveau 3 : Type encore plus spécialisé
function New-VerySpecializedExtractedInfo {
    param (
        [string]$SpecialProperty,
        [string]$VerySpecialProperty,
        [string]$Source = "Unknown"
    )

    # Hériter du type spécialisé
    $info = New-SpecializedExtractedInfo -SpecialProperty $SpecialProperty -Source $Source

    # Modifier le type
    $info._Type = "VerySpecializedExtractedInfo"

    # Ajouter les propriétés spécifiques
    $info.VerySpecialProperty = $VerySpecialProperty

    return $info
}

$verySpecializedInfo = New-VerySpecializedExtractedInfo -Source "very_specialized.txt" -SpecialProperty "Value" -VerySpecialProperty "SpecialValue"
```

Cette approche permet de créer des types de plus en plus spécialisés tout en maintenant la compatibilité avec les fonctions qui traitent les types parents.

### 1.3 Types spécialisés existants

Le module `ExtractedInfoModuleV2` inclut plusieurs types spécialisés prédéfinis qui étendent le type de base `ExtractedInfo`. Ces types servent à la fois d'exemples pour la création de nouveaux types et de solutions prêtes à l'emploi pour les cas d'utilisation courants.

#### 1.3.1 TextExtractedInfo

Le type `TextExtractedInfo` est conçu pour stocker et manipuler des informations textuelles extraites de diverses sources.

**Propriétés spécifiques :**

| Propriété | Type | Description | Obligatoire |
|-----------|------|-------------|-------------|
| `Text` | String | Contenu textuel extrait | Oui |
| `Language` | String | Code de langue du texte (ex: "en", "fr") | Non |

**Fonction de création :**
```powershell
function New-TextExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [string]$Language = "unknown",
        [string]$Source = "Unknown",
        [string]$ExtractorName = "TextExtractor",
        [string]$ProcessingState = "Raw",
        [int]$ConfidenceScore = 50
    )

    # Créer un objet du type de base
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName -ProcessingState $ProcessingState -ConfidenceScore $ConfidenceScore

    # Modifier le type
    $info._Type = "TextExtractedInfo"

    # Ajouter les propriétés spécifiques
    $info.Text = $Text
    $info.Language = $Language

    return $info
}
```

**Exemple d'utilisation :**
```powershell
$textInfo = New-TextExtractedInfo -Source "document.txt" -Text "Ceci est un exemple de texte extrait." -Language "fr"
```

#### 1.3.2 StructuredDataExtractedInfo

Le type `StructuredDataExtractedInfo` est conçu pour stocker et manipuler des données structurées extraites, comme des objets JSON, XML, ou des structures de données hiérarchiques.

**Propriétés spécifiques :**

| Propriété | Type | Description | Obligatoire |
|-----------|------|-------------|-------------|
| `Data` | Object | Données structurées extraites (hashtable, array, etc.) | Oui |
| `DataFormat` | String | Format des données (ex: "JSON", "XML", "CSV") | Non |

**Fonction de création :**
```powershell
function New-StructuredDataExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Data,

        [string]$DataFormat = "JSON",
        [string]$Source = "Unknown",
        [string]$ExtractorName = "StructuredDataExtractor",
        [string]$ProcessingState = "Raw",
        [int]$ConfidenceScore = 50
    )

    # Créer un objet du type de base
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName -ProcessingState $ProcessingState -ConfidenceScore $ConfidenceScore

    # Modifier le type
    $info._Type = "StructuredDataExtractedInfo"

    # Ajouter les propriétés spécifiques
    $info.Data = $Data
    $info.DataFormat = $DataFormat

    return $info
}
```

**Exemple d'utilisation :**
```powershell
$data = @{
    Person = @{
        FirstName = "John"
        LastName = "Doe"
        Age = 30
    }
    Addresses = @(
        @{ Type = "Home"; City = "New York" },
        @{ Type = "Work"; City = "Boston" }
    )
}

$structuredInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data $data -DataFormat "JSON"
```

#### 1.3.3 MediaExtractedInfo

Le type `MediaExtractedInfo` est conçu pour stocker et manipuler des références à des fichiers média comme des images, des vidéos, des fichiers audio ou des documents.

**Propriétés spécifiques :**

| Propriété | Type | Description | Obligatoire |
|-----------|------|-------------|-------------|
| `MediaPath` | String | Chemin vers le fichier média | Oui |
| `MediaType` | String | Type de média (Image, Video, Audio, Document) | Oui |
| `MediaSize` | Int64 | Taille du fichier en octets | Non |

**Fonction de création :**
```powershell
function New-MediaExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$MediaPath,

        [string]$MediaType = "Image",
        [int64]$MediaSize = 0,
        [string]$Source = "Unknown",
        [string]$ExtractorName = "MediaExtractor",
        [string]$ProcessingState = "Raw",
        [int]$ConfidenceScore = 50
    )

    # Créer un objet du type de base
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName -ProcessingState $ProcessingState -ConfidenceScore $ConfidenceScore

    # Modifier le type
    $info._Type = "MediaExtractedInfo"

    # Ajouter les propriétés spécifiques
    $info.MediaPath = $MediaPath
    $info.MediaType = $MediaType
    $info.MediaSize = $MediaSize

    return $info
}
```

**Exemple d'utilisation :**
```powershell
$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\photo.jpg" -MediaType "Image" -MediaSize 1048576
```

#### 1.3.4 Règles de validation spécifiques

Chaque type spécialisé possède ses propres règles de validation qui s'ajoutent aux règles du type de base :

**TextExtractedInfo :**
- La propriété `Text` doit être présente et être une chaîne de caractères.
- La propriété `Language` doit être une chaîne de caractères.

**StructuredDataExtractedInfo :**
- La propriété `Data` doit être présente.
- La propriété `DataFormat` doit être une chaîne de caractères.

**MediaExtractedInfo :**
- La propriété `MediaPath` doit être présente et être une chaîne de caractères.
- La propriété `MediaType` doit être l'une des valeurs suivantes : "Image", "Video", "Audio", "Document".
- La propriété `MediaSize` doit être un entier positif ou nul.

#### 1.3.5 Intégration avec les fonctions du module

Les types spécialisés existants sont pleinement intégrés avec toutes les fonctions du module :

- **Fonctions de collection** : Les collections peuvent contenir des objets de différents types spécialisés.
- **Fonctions de sérialisation** : Les types spécialisés sont correctement sérialisés et désérialisés.
- **Fonctions de validation** : Les règles de validation spécifiques sont appliquées automatiquement.
- **Fonctions de métadonnées** : Les métadonnées peuvent être ajoutées à tous les types spécialisés.

Cette intégration complète sert de modèle pour l'ajout de nouveaux types spécialisés, qui doivent également fonctionner de manière transparente avec toutes les fonctions du module.

### 1.4 Conventions de nommage et de structure

Pour assurer la cohérence et la maintenabilité du module, il est important de suivre certaines conventions lors de la création de nouveaux types d'informations extraites.

#### 1.4.1 Conventions de nommage des types

Les types d'informations extraites doivent suivre ces conventions de nommage :

1. **Suffixe "ExtractedInfo"** : Tous les types doivent se terminer par "ExtractedInfo" pour indiquer clairement qu'ils font partie du système de types du module.
   - Exemple : `TextExtractedInfo`, `MediaExtractedInfo`, `EmailExtractedInfo`

2. **Préfixe descriptif** : Le préfixe doit décrire clairement le type d'information contenu.
   - Exemple : `Text` pour du texte, `StructuredData` pour des données structurées, `Media` pour des fichiers média

3. **PascalCase** : Utiliser le format PascalCase (première lettre de chaque mot en majuscule, sans séparateur).
   - Exemple : `SocialMediaPostExtractedInfo`, `WebPageExtractedInfo`

4. **Éviter les abréviations** : Utiliser des noms complets plutôt que des abréviations pour améliorer la lisibilité.
   - Préférer `EmailExtractedInfo` à `EmailExInfo`

#### 1.4.2 Conventions de nommage des propriétés

Les propriétés des types d'informations extraites doivent suivre ces conventions :

1. **PascalCase** : Utiliser le format PascalCase pour les noms de propriétés.
   - Exemple : `MediaPath`, `ConfidenceScore`, `ExtractionDate`

2. **Noms descriptifs** : Les noms doivent décrire clairement le contenu ou l'objectif de la propriété.
   - Exemple : `AuthorName` plutôt que `Author` ou `Name`

3. **Préfixes et suffixes cohérents** :
   - Utiliser le suffixe `Date` pour les dates : `ExtractionDate`, `PublicationDate`
   - Utiliser le suffixe `Path` pour les chemins de fichiers : `MediaPath`, `OutputPath`
   - Utiliser le préfixe `Is` pour les booléens : `IsValid`, `IsProcessed`

4. **Éviter les conflits** : Ne pas utiliser des noms qui entrent en conflit avec les propriétés du type de base.
   - Éviter de redéfinir `Source`, `Id`, `ProcessingState`, etc.

#### 1.4.3 Structure des fonctions de création

Les fonctions de création de nouveaux types doivent suivre cette structure :

1. **Nom de fonction** : Utiliser le format `New-TypeNameExtractedInfo`.
   - Exemple : `New-TextExtractedInfo`, `New-EmailExtractedInfo`

2. **Paramètres** :
   - Commencer par les paramètres spécifiques au type, avec les paramètres obligatoires en premier.
   - Inclure ensuite les paramètres communs hérités du type de base, avec des valeurs par défaut appropriées.
   - Utiliser l'attribut `[Parameter(Mandatory = $true)]` pour les paramètres obligatoires.

3. **Corps de fonction** :
   - Créer d'abord un objet du type de base avec `New-ExtractedInfo`.
   - Modifier la propriété `_Type` pour refléter le type spécialisé.
   - Ajouter les propriétés spécifiques au type.
   - Retourner l'objet modifié.

4. **Documentation** :
   - Inclure une description claire de la fonction.
   - Documenter tous les paramètres.
   - Fournir des exemples d'utilisation.

#### 1.4.4 Règles de validation

Les règles de validation pour les nouveaux types doivent :

1. **Vérifier les propriétés spécifiques** : S'assurer que toutes les propriétés spécifiques au type sont présentes et valides.
2. **Respecter les contraintes métier** : Implémenter des règles qui reflètent les contraintes métier spécifiques au type d'information.
3. **Être claires et précises** : Fournir des messages d'erreur clairs qui indiquent précisément le problème et comment le corriger.
4. **Être efficaces** : Éviter les validations inutilement complexes ou coûteuses en ressources.

#### 1.4.5 Exemple de structure conforme

Voici un exemple de structure conforme pour un nouveau type `EmailExtractedInfo` :

```powershell
function New-EmailExtractedInfo {
    <#
    .SYNOPSIS
    Crée un nouvel objet d'information extraite de type email.

    .DESCRIPTION
    La fonction New-EmailExtractedInfo crée un nouvel objet d'information extraite spécialisé pour les emails.

    .PARAMETER Subject
    Spécifie l'objet de l'email. Ce paramètre est obligatoire.

    .PARAMETER Sender
    Spécifie l'adresse email de l'expéditeur. Ce paramètre est obligatoire.

    .PARAMETER Recipients
    Spécifie un tableau d'adresses email des destinataires. Ce paramètre est obligatoire.

    .PARAMETER Body
    Spécifie le corps de l'email.

    .PARAMETER Source
    Spécifie la source de l'information extraite.

    .PARAMETER ExtractorName
    Spécifie le nom de l'extracteur utilisé.

    .PARAMETER ProcessingState
    Spécifie l'état de traitement de l'information extraite.

    .PARAMETER ConfidenceScore
    Spécifie le score de confiance associé à l'information extraite.

    .EXAMPLE
    $email = New-EmailExtractedInfo -Subject "Réunion hebdomadaire" -Sender "john.doe@example.com" -Recipients @("team@example.com")
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Sender,

        [Parameter(Mandatory = $true)]
        [string[]]$Recipients,

        [string]$Body = "",
        [string]$Source = "Unknown",
        [string]$ExtractorName = "EmailExtractor",
        [string]$ProcessingState = "Raw",
        [int]$ConfidenceScore = 50
    )

    # Créer un objet du type de base
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName -ProcessingState $ProcessingState -ConfidenceScore $ConfidenceScore

    # Modifier le type
    $info._Type = "EmailExtractedInfo"

    # Ajouter les propriétés spécifiques
    $info.Subject = $Subject
    $info.Sender = $Sender
    $info.Recipients = $Recipients
    $info.Body = $Body

    return $info
}
```

En suivant ces conventions, vous assurez que vos nouveaux types d'informations extraites s'intégreront harmonieusement avec le reste du module et seront faciles à comprendre et à utiliser pour les autres développeurs.

## 2. Exemple d'implémentation d'un nouveau type

Cette section présente un exemple complet d'implémentation d'un nouveau type d'information extraite, depuis la définition du cas d'utilisation jusqu'aux tests d'intégration avec les fonctions existantes.

### 2.1 Cas d'utilisation : GeoLocationExtractedInfo

#### 2.1.1 Définition du besoin

Nous allons créer un nouveau type d'information extraite appelé `GeoLocationExtractedInfo` pour stocker et manipuler des informations de géolocalisation extraites de diverses sources comme des métadonnées d'images, des API de cartographie, ou des textes contenant des références géographiques.

Ce type d'information sera utile pour :
- Stocker les coordonnées géographiques (latitude, longitude) extraites de diverses sources
- Conserver des informations contextuelles comme l'adresse, la ville, le pays
- Enregistrer des métadonnées spécifiques comme l'altitude, la précision, ou le fuseau horaire
- Permettre des recherches et des analyses basées sur la localisation

#### 2.1.2 Propriétés spécifiques

Le type `GeoLocationExtractedInfo` aura les propriétés spécifiques suivantes :

| Propriété | Type | Description | Obligatoire |
|-----------|------|-------------|-------------|
| `Latitude` | Double | Latitude en degrés décimaux | Oui |
| `Longitude` | Double | Longitude en degrés décimaux | Oui |
| `Altitude` | Double | Altitude en mètres | Non |
| `Accuracy` | Double | Précision en mètres | Non |
| `Address` | String | Adresse formatée | Non |
| `City` | String | Ville | Non |
| `Country` | String | Pays | Non |
| `LocationType` | String | Type de localisation (GPS, IP, Manual, etc.) | Non |

#### 2.1.3 Contraintes et règles de validation

Les contraintes spécifiques à ce type d'information sont :

1. **Latitude** : Doit être un nombre décimal entre -90 et 90.
2. **Longitude** : Doit être un nombre décimal entre -180 et 180.
3. **Altitude** : Si spécifiée, doit être un nombre décimal.
4. **Accuracy** : Si spécifiée, doit être un nombre décimal positif.
5. **LocationType** : Si spécifié, doit être l'une des valeurs suivantes : "GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown".

#### 2.1.4 Intégration avec les fonctions existantes

Le nouveau type `GeoLocationExtractedInfo` devra s'intégrer avec les fonctions existantes du module :

- **Fonctions de collection** : Les objets `GeoLocationExtractedInfo` pourront être ajoutés à des collections et récupérés avec des filtres spécifiques.
- **Fonctions de sérialisation** : Les objets `GeoLocationExtractedInfo` pourront être sérialisés en JSON et désérialisés.
- **Fonctions de validation** : Des règles de validation spécifiques seront appliquées pour garantir l'intégrité des données.
- **Fonctions de métadonnées** : Des métadonnées pourront être ajoutées pour enrichir les informations de géolocalisation.

#### 2.1.5 Cas d'utilisation typiques

Voici quelques exemples de cas d'utilisation pour ce nouveau type :

1. **Extraction de métadonnées d'images** : Récupérer les coordonnées GPS à partir des métadonnées EXIF d'images.
2. **Géocodage d'adresses** : Convertir des adresses textuelles en coordonnées géographiques.
3. **Extraction de localisations à partir de textes** : Identifier et extraire des références géographiques dans des textes.
4. **Enrichissement de données** : Ajouter des informations de localisation à d'autres types d'informations extraites.
5. **Analyse spatiale** : Permettre des analyses basées sur la proximité géographique entre différentes informations extraites.

### 2.2 Implémentation de la fonction de création

Maintenant que nous avons défini le cas d'utilisation et les propriétés du nouveau type, nous allons implémenter la fonction de création `New-GeoLocationExtractedInfo`.

#### 2.2.1 Définition de la fonction

```powershell
function New-GeoLocationExtractedInfo {
    <#
    .SYNOPSIS
    Crée un nouvel objet d'information extraite de type géolocalisation.

    .DESCRIPTION
    La fonction New-GeoLocationExtractedInfo crée un nouvel objet d'information extraite spécialisé pour les données de géolocalisation.
    Elle permet de stocker des coordonnées géographiques (latitude, longitude) ainsi que des informations contextuelles comme l'adresse,
    la ville, le pays, etc.

    .PARAMETER Latitude
    Spécifie la latitude en degrés décimaux. Doit être une valeur entre -90 et 90. Ce paramètre est obligatoire.

    .PARAMETER Longitude
    Spécifie la longitude en degrés décimaux. Doit être une valeur entre -180 et 180. Ce paramètre est obligatoire.

    .PARAMETER Altitude
    Spécifie l'altitude en mètres.

    .PARAMETER Accuracy
    Spécifie la précision de la localisation en mètres.

    .PARAMETER Address
    Spécifie l'adresse formatée correspondant aux coordonnées.

    .PARAMETER City
    Spécifie la ville correspondant aux coordonnées.

    .PARAMETER Country
    Spécifie le pays correspondant aux coordonnées.

    .PARAMETER LocationType
    Spécifie le type de localisation. Les valeurs valides sont : "GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown".

    .PARAMETER Source
    Spécifie la source de l'information extraite.

    .PARAMETER ExtractorName
    Spécifie le nom de l'extracteur utilisé.

    .PARAMETER ProcessingState
    Spécifie l'état de traitement de l'information extraite.

    .PARAMETER ConfidenceScore
    Spécifie le score de confiance associé à l'information extraite.

    .EXAMPLE
    $geoInfo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -LocationType "GPS"

    .EXAMPLE
    $geoInfo = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -Address "New York, NY 10004" -Accuracy 10 -Source "GoogleMaps" -ConfidenceScore 90
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(-90, 90)]
        [double]$Latitude,

        [Parameter(Mandatory = $true)]
        [ValidateRange(-180, 180)]
        [double]$Longitude,

        [double]$Altitude,

        [ValidateRange(0, [double]::MaxValue)]
        [double]$Accuracy,

        [string]$Address,

        [string]$City,

        [string]$Country,

        [ValidateSet("GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown")]
        [string]$LocationType = "Unknown",

        [string]$Source = "Unknown",

        [string]$ExtractorName = "GeoLocationExtractor",

        [ValidateSet("Raw", "Processed", "Validated", "Error")]
        [string]$ProcessingState = "Raw",

        [ValidateRange(0, 100)]
        [int]$ConfidenceScore = 50
    )

    # Créer un objet du type de base
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName -ProcessingState $ProcessingState -ConfidenceScore $ConfidenceScore

    # Modifier le type
    $info._Type = "GeoLocationExtractedInfo"

    # Ajouter les propriétés spécifiques
    $info.Latitude = $Latitude
    $info.Longitude = $Longitude

    # Ajouter les propriétés optionnelles si elles sont spécifiées
    if ($PSBoundParameters.ContainsKey('Altitude')) {
        $info.Altitude = $Altitude
    }

    if ($PSBoundParameters.ContainsKey('Accuracy')) {
        $info.Accuracy = $Accuracy
    }

    if ($PSBoundParameters.ContainsKey('Address')) {
        $info.Address = $Address
    }

    if ($PSBoundParameters.ContainsKey('City')) {
        $info.City = $City
    }

    if ($PSBoundParameters.ContainsKey('Country')) {
        $info.Country = $Country
    }

    $info.LocationType = $LocationType

    return $info
}
```

#### 2.2.2 Caractéristiques clés de l'implémentation

Cette implémentation présente plusieurs caractéristiques importantes :

1. **Documentation complète** : La fonction inclut une documentation détaillée avec synopsis, description, paramètres et exemples.

2. **Validation des paramètres** : Les paramètres sont validés directement dans la définition de la fonction :
   - `[ValidateRange(-90, 90)]` pour la latitude
   - `[ValidateRange(-180, 180)]` pour la longitude
   - `[ValidateRange(0, [double]::MaxValue)]` pour la précision
   - `[ValidateSet("GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown")]` pour le type de localisation

3. **Paramètres obligatoires et optionnels** :
   - Les paramètres obligatoires (Latitude, Longitude) sont marqués avec `[Parameter(Mandatory = $true)]`
   - Les paramètres optionnels ont des valeurs par défaut ou sont ajoutés conditionnellement

4. **Gestion des propriétés optionnelles** : Les propriétés optionnelles ne sont ajoutées que si les paramètres correspondants sont spécifiés, ce qui permet d'économiser de l'espace et d'éviter les valeurs nulles.

5. **Héritage du type de base** : La fonction crée d'abord un objet du type de base avec `New-ExtractedInfo`, puis modifie le type et ajoute les propriétés spécifiques.

#### 2.2.3 Bonnes pratiques appliquées

Cette implémentation suit plusieurs bonnes pratiques :

1. **Utilisation de CmdletBinding** : `[CmdletBinding()]` permet d'activer les fonctionnalités avancées des cmdlets PowerShell.

2. **Validation des paramètres** : Les attributs de validation garantissent que les valeurs fournies respectent les contraintes définies.

3. **Vérification des paramètres optionnels** : `$PSBoundParameters.ContainsKey()` est utilisé pour vérifier si un paramètre a été spécifié, même s'il a une valeur par défaut.

4. **Nommage cohérent** : Les noms de paramètres et de propriétés suivent les conventions de nommage du module.

5. **Documentation détaillée** : La documentation aide les utilisateurs à comprendre comment utiliser la fonction correctement.

#### 2.2.4 Exemples d'utilisation

Voici quelques exemples d'utilisation de la fonction `New-GeoLocationExtractedInfo` :

```powershell
# Exemple 1 : Création d'un objet avec les propriétés minimales
$geoInfo1 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522

# Exemple 2 : Création d'un objet avec des informations contextuelles
$geoInfo2 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -LocationType "GPS"

# Exemple 3 : Création d'un objet avec toutes les propriétés
$geoInfo3 = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -Altitude 10 -Accuracy 5 -Address "New York, NY 10004" -City "New York" -Country "USA" -LocationType "GPS" -Source "GoogleMaps" -ConfidenceScore 90

# Exemple 4 : Vérification du type et des propriétés
$geoInfo4 = New-GeoLocationExtractedInfo -Latitude 51.5074 -Longitude -0.1278
Write-Host "Type: $($geoInfo4._Type)"
Write-Host "Latitude: $($geoInfo4.Latitude)"
Write-Host "Longitude: $($geoInfo4.Longitude)"
Write-Host "LocationType: $($geoInfo4.LocationType)"
```

### 2.3 Ajout des règles de validation spécifiques

Pour garantir l'intégrité des données et la cohérence du nouveau type, nous devons ajouter des règles de validation spécifiques qui seront appliquées lors de l'utilisation des fonctions `Test-ExtractedInfo` et `Get-ExtractedInfoValidationErrors`.

#### 2.3.1 Définition de la règle de validation

```powershell
function Add-GeoLocationValidationRule {
    <#
    .SYNOPSIS
    Ajoute une règle de validation pour les objets GeoLocationExtractedInfo.

    .DESCRIPTION
    Cette fonction ajoute une règle de validation spécifique pour les objets de type GeoLocationExtractedInfo.
    La règle vérifie que les propriétés obligatoires sont présentes et que les valeurs respectent les contraintes définies.

    .EXAMPLE
    Add-GeoLocationValidationRule
    #>

    # Définir la règle de validation
    $geoLocationValidationRule = {
        param($Info)

        $errors = @()

        # Vérifier que l'objet est bien du type GeoLocationExtractedInfo
        if ($Info._Type -ne "GeoLocationExtractedInfo") {
            return $errors # Ne pas appliquer cette règle aux autres types
        }

        # Vérifier les propriétés obligatoires
        if (-not $Info.ContainsKey('Latitude')) {
            $errors += "Missing required property: Latitude"
        }
        elseif ($Info.Latitude -lt -90 -or $Info.Latitude -gt 90) {
            $errors += "Latitude must be between -90 and 90 (current value: $($Info.Latitude))"
        }

        if (-not $Info.ContainsKey('Longitude')) {
            $errors += "Missing required property: Longitude"
        }
        elseif ($Info.Longitude -lt -180 -or $Info.Longitude -gt 180) {
            $errors += "Longitude must be between -180 and 180 (current value: $($Info.Longitude))"
        }

        # Vérifier les propriétés optionnelles si elles sont présentes
        if ($Info.ContainsKey('Altitude') -and $null -ne $Info.Altitude -and -not ($Info.Altitude -is [double] -or $Info.Altitude -is [int])) {
            $errors += "Altitude must be a number (current type: $($Info.Altitude.GetType().Name))"
        }

        if ($Info.ContainsKey('Accuracy')) {
            if ($null -ne $Info.Accuracy -and -not ($Info.Accuracy -is [double] -or $Info.Accuracy -is [int])) {
                $errors += "Accuracy must be a number (current type: $($Info.Accuracy.GetType().Name))"
            }
            elseif ($Info.Accuracy -lt 0) {
                $errors += "Accuracy must be a positive number (current value: $($Info.Accuracy))"
            }
        }

        if ($Info.ContainsKey('LocationType')) {
            $validLocationTypes = @("GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown")
            if (-not ($validLocationTypes -contains $Info.LocationType)) {
                $errors += "LocationType must be one of the following values: $($validLocationTypes -join ', ') (current value: $($Info.LocationType))"
            }
        }

        # Vérifier la cohérence des données
        if ($Info.ContainsKey('City') -and $Info.ContainsKey('Country') -and $Info.City -and -not $Info.Country) {
            $errors += "Country should be specified when City is provided"
        }

        return $errors
    }

    # Ajouter la règle au système de validation
    Add-ExtractedInfoValidationRule -Name "GeoLocationValidationRule" -Rule $geoLocationValidationRule -TargetType "GeoLocationExtractedInfo" -Description "Validation rules for GeoLocationExtractedInfo objects" -Force
}
```

#### 2.3.2 Caractéristiques de la règle de validation

La règle de validation pour le type `GeoLocationExtractedInfo` vérifie plusieurs aspects :

1. **Propriétés obligatoires** :
   - Vérifie que `Latitude` et `Longitude` sont présentes
   - Vérifie que `Latitude` est entre -90 et 90
   - Vérifie que `Longitude` est entre -180 et 180

2. **Propriétés optionnelles** :
   - Vérifie que `Altitude` est un nombre si elle est spécifiée
   - Vérifie que `Accuracy` est un nombre positif si elle est spécifiée
   - Vérifie que `LocationType` est l'une des valeurs autorisées si elle est spécifiée

3. **Cohérence des données** :
   - Vérifie que `Country` est spécifié lorsque `City` est fourni

#### 2.3.3 Enregistrement de la règle de validation

La règle de validation est enregistrée avec la fonction `Add-ExtractedInfoValidationRule` du module, ce qui permet de l'appliquer automatiquement lors de la validation des objets `GeoLocationExtractedInfo`.

```powershell
# Enregistrer la règle de validation
Add-GeoLocationValidationRule
```

#### 2.3.4 Exemples de validation

Voici quelques exemples d'utilisation de la validation avec le nouveau type :

```powershell
# Créer un objet valide
$validGeoInfo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"

# Valider l'objet
$isValid = Test-ExtractedInfo -Info $validGeoInfo
Write-Host "L'objet est valide : $isValid"

# Créer un objet invalide (latitude hors limites)
$invalidGeoInfo = New-GeoLocationExtractedInfo -Latitude 100 -Longitude 2.3522 -City "Paris" -Country "France"

# Obtenir les erreurs de validation
$errors = Get-ExtractedInfoValidationErrors -Info $invalidGeoInfo
Write-Host "Erreurs de validation :"
foreach ($error in $errors) {
    Write-Host "- $error"
}

# Créer un objet avec des données incohérentes (ville sans pays)
$inconsistentGeoInfo = @{
    _Type = "GeoLocationExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    Source = "Manual"
    ExtractorName = "GeoLocationExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "Raw"
    ConfidenceScore = 50
    Metadata = @{}
    Latitude = 48.8566
    Longitude = 2.3522
    City = "Paris"
    # Country manquant
    LocationType = "Manual"
}

# Obtenir les erreurs de validation
$errors = Get-ExtractedInfoValidationErrors -Info $inconsistentGeoInfo
Write-Host "Erreurs de validation pour l'objet incohérent :"
foreach ($error in $errors) {
    Write-Host "- $error"
}
```

#### 2.3.5 Intégration avec les règles de validation existantes

La règle de validation spécifique au type `GeoLocationExtractedInfo` s'intègre avec les règles de validation existantes du module :

1. **Règles de base** : Les règles de validation du type de base `ExtractedInfo` sont toujours appliquées (vérification des propriétés requises, types de données, etc.).

2. **Règles spécifiques** : La règle spécifique au type `GeoLocationExtractedInfo` est appliquée uniquement aux objets de ce type.

3. **Règles personnalisées** : Des règles de validation personnalisées supplémentaires peuvent être spécifiées lors de l'appel à `Test-ExtractedInfo` ou `Get-ExtractedInfoValidationErrors`.

Cette approche garantit que les objets `GeoLocationExtractedInfo` sont validés de manière cohérente et complète, tout en permettant une flexibilité pour des validations spécifiques à certains cas d'utilisation.

### 2.4 Tests d'intégration avec les fonctions existantes

Pour s'assurer que le nouveau type `GeoLocationExtractedInfo` s'intègre correctement avec les fonctions existantes du module, nous allons effectuer une série de tests d'intégration.

#### 2.4.1 Tests avec les fonctions de collection

```powershell
# Créer une collection
$collection = New-ExtractedInfoCollection -Name "GeoLocations" -Description "Collection of geographical locations" -CreateIndexes

# Créer plusieurs objets GeoLocationExtractedInfo
$paris = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -LocationType "GPS"
$newYork = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA" -LocationType "GPS"
$tokyo = New-GeoLocationExtractedInfo -Latitude 35.6762 -Longitude 139.6503 -City "Tokyo" -Country "Japan" -LocationType "GPS"

# Ajouter les objets à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($paris, $newYork, $tokyo)

# Vérifier que les objets ont été ajoutés correctement
$count = $collection.Items.Count
Write-Host "Nombre d'éléments dans la collection : $count"

# Récupérer un objet spécifique
$parisFromCollection = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_.City -eq "Paris" }
Write-Host "Objet récupéré : $($parisFromCollection.City), $($parisFromCollection.Country)"

# Récupérer tous les objets d'un certain type
$geoLocations = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_._Type -eq "GeoLocationExtractedInfo" }
Write-Host "Nombre d'objets GeoLocationExtractedInfo : $($geoLocations.Count)"

# Obtenir des statistiques sur la collection
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection
Write-Host "Statistiques de la collection :"
Write-Host "- Nombre total d'éléments : $($stats.TotalItems)"
Write-Host "- Types d'éléments : $($stats.TypeCounts | ForEach-Object { "$($_.Key): $($_.Value)" } | Join-String -Separator ', ')"
```

#### 2.4.2 Tests avec les fonctions de sérialisation

```powershell
# Créer un objet GeoLocationExtractedInfo
$london = New-GeoLocationExtractedInfo -Latitude 51.5074 -Longitude -0.1278 -City "London" -Country "UK" -LocationType "GPS" -Accuracy 5

# Convertir l'objet en JSON
$json = ConvertTo-ExtractedInfoJson -Info $london -Indent
Write-Host "Objet sérialisé en JSON :"
Write-Host $json

# Désérialiser le JSON en objet
$deserializedLondon = ConvertFrom-ExtractedInfoJson -Json $json
Write-Host "Objet désérialisé :"
Write-Host "- Type : $($deserializedLondon._Type)"
Write-Host "- Ville : $($deserializedLondon.City)"
Write-Host "- Latitude : $($deserializedLondon.Latitude)"
Write-Host "- Longitude : $($deserializedLondon.Longitude)"

# Sauvegarder l'objet dans un fichier
$filePath = Join-Path $env:TEMP "london_geo.json"
$result = Save-ExtractedInfoToFile -Info $london -FilePath $filePath -Indent -Force
Write-Host "Sauvegarde dans un fichier : $result"

# Charger l'objet depuis le fichier
$loadedLondon = Load-ExtractedInfoFromFile -FilePath $filePath
Write-Host "Objet chargé depuis le fichier :"
Write-Host "- Type : $($loadedLondon._Type)"
Write-Host "- Ville : $($loadedLondon.City)"
Write-Host "- Latitude : $($loadedLondon.Latitude)"
Write-Host "- Longitude : $($loadedLondon.Longitude)"
```

#### 2.4.3 Tests avec les fonctions de métadonnées

```powershell
# Créer un objet GeoLocationExtractedInfo
$berlin = New-GeoLocationExtractedInfo -Latitude 52.5200 -Longitude 13.4050 -City "Berlin" -Country "Germany" -LocationType "GPS"

# Ajouter des métadonnées
$berlin = Add-ExtractedInfoMetadata -Info $berlin -Metadata @{
    Population = 3645000
    TimeZone = "Europe/Berlin"
    Currency = "EUR"
    VisitDate = Get-Date -Year 2023 -Month 6 -Day 15
}

# Ajouter une métadonnée individuelle
$berlin = Add-ExtractedInfoMetadata -Info $berlin -Key "IsCapital" -Value $true

# Récupérer une métadonnée spécifique
$population = Get-ExtractedInfoMetadata -Info $berlin -Key "Population"
Write-Host "Population de Berlin : $population"

# Récupérer toutes les métadonnées
$metadata = Get-ExtractedInfoMetadata -Info $berlin
Write-Host "Métadonnées de Berlin :"
foreach ($key in $metadata.Keys) {
    Write-Host "- $key : $($metadata[$key])"
}

# Supprimer une métadonnée
$berlin = Remove-ExtractedInfoMetadata -Info $berlin -Key "Currency"
$hasMetadata = Get-ExtractedInfoMetadata -Info $berlin -Key "Currency" -ErrorAction SilentlyContinue
Write-Host "La métadonnée 'Currency' existe toujours : $($null -ne $hasMetadata)"

# Obtenir un résumé de l'objet
$summary = Get-ExtractedInfoSummary -Info $berlin
Write-Host "Résumé de l'objet :"
Write-Host $summary
```

#### 2.4.4 Tests de validation complets

```powershell
# Créer plusieurs objets pour tester la validation
$validObject = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
$invalidLatitude = New-GeoLocationExtractedInfo -Latitude 100 -Longitude 2.3522 -City "Paris" -Country "France"
$invalidLongitude = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 200 -City "Paris" -Country "France"
$negativeAccuracy = @{
    _Type = "GeoLocationExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    Source = "Manual"
    ExtractorName = "GeoLocationExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "Raw"
    ConfidenceScore = 50
    Metadata = @{}
    Latitude = 48.8566
    Longitude = 2.3522
    Accuracy = -10
}
$invalidLocationType = @{
    _Type = "GeoLocationExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    Source = "Manual"
    ExtractorName = "GeoLocationExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "Raw"
    ConfidenceScore = 50
    Metadata = @{}
    Latitude = 48.8566
    Longitude = 2.3522
    LocationType = "InvalidType"
}

# Fonction pour tester et afficher les résultats de validation
function Test-AndReport {
    param (
        $Info,
        $Description
    )

    $result = Test-ExtractedInfo -Info $Info -Detailed

    Write-Host "Test de $Description :"
    Write-Host "- Valide : $($result.IsValid)"

    if (-not $result.IsValid) {
        Write-Host "- Erreurs :"
        foreach ($error in $result.Errors) {
            Write-Host "  * $error"
        }
    }

    Write-Host ""
}

# Exécuter les tests
Test-AndReport -Info $validObject -Description "l'objet valide"
Test-AndReport -Info $invalidLatitude -Description "l'objet avec latitude invalide"
Test-AndReport -Info $invalidLongitude -Description "l'objet avec longitude invalide"
Test-AndReport -Info $negativeAccuracy -Description "l'objet avec précision négative"
Test-AndReport -Info $invalidLocationType -Description "l'objet avec type de localisation invalide"
```

#### 2.4.5 Résultats des tests

Les tests d'intégration montrent que le nouveau type `GeoLocationExtractedInfo` s'intègre correctement avec les fonctions existantes du module :

1. **Fonctions de collection** :
   - Les objets `GeoLocationExtractedInfo` peuvent être ajoutés à des collections.
   - Les objets peuvent être récupérés avec des filtres spécifiques.
   - Les statistiques de collection incluent correctement les objets du nouveau type.

2. **Fonctions de sérialisation** :
   - Les objets `GeoLocationExtractedInfo` peuvent être sérialisés en JSON.
   - Les objets sérialisés peuvent être désérialisés correctement.
   - Les objets peuvent être sauvegardés dans des fichiers et chargés à partir de fichiers.

3. **Fonctions de métadonnées** :
   - Des métadonnées peuvent être ajoutées aux objets `GeoLocationExtractedInfo`.
   - Les métadonnées peuvent être récupérées et supprimées.
   - Les résumés d'objets incluent les informations spécifiques au type.

4. **Fonctions de validation** :
   - Les règles de validation spécifiques sont appliquées correctement.
   - Les erreurs de validation sont détectées et rapportées de manière appropriée.
   - Les objets valides passent la validation sans erreur.

Ces tests confirment que le nouveau type `GeoLocationExtractedInfo` est pleinement intégré au module et peut être utilisé de manière transparente avec toutes les fonctions existantes.

## 3. Intégration avec les fonctions existantes

Cette section explique en détail comment les nouveaux types d'informations extraites s'intègrent avec les fonctions existantes du module.

### 3.1 Intégration avec les fonctions de collection

Les fonctions de collection du module `ExtractedInfoModuleV2` sont conçues pour fonctionner avec tous les types d'informations extraites, y compris les nouveaux types personnalisés que vous créez.

#### 3.1.1 Principes d'intégration

L'intégration avec les fonctions de collection repose sur plusieurs principes :

1. **Typage dynamique** : Les collections peuvent contenir des objets de différents types d'informations extraites, tant qu'ils héritent correctement du type de base `ExtractedInfo`.

2. **Identification par type** : La propriété `_Type` est utilisée pour identifier le type spécifique de chaque objet dans une collection.

3. **Filtrage flexible** : Les fonctions de filtrage peuvent accéder à toutes les propriétés des objets, y compris les propriétés spécifiques aux types personnalisés.

4. **Indexation automatique** : Les index de collection peuvent être créés pour les propriétés spécifiques aux types personnalisés.

#### 3.1.2 Fonctions de collection compatibles

Toutes les fonctions de collection suivantes sont compatibles avec les nouveaux types d'informations extraites :

| Fonction | Description | Compatibilité |
|----------|-------------|---------------|
| `New-ExtractedInfoCollection` | Crée une nouvelle collection | Fonctionne avec tous les types |
| `Add-ExtractedInfoToCollection` | Ajoute des objets à une collection | Accepte tous les types d'objets |
| `Get-ExtractedInfoFromCollection` | Récupère des objets d'une collection | Peut filtrer sur les propriétés spécifiques aux types |
| `Get-ExtractedInfoCollectionStatistics` | Obtient des statistiques sur une collection | Inclut des statistiques par type |

#### 3.1.3 Exemples d'intégration avec les collections

##### Exemple 1 : Création d'une collection mixte

```powershell
# Créer une collection
$mixedCollection = New-ExtractedInfoCollection -Name "MixedCollection" -CreateIndexes

# Créer des objets de différents types
$textInfo = New-TextExtractedInfo -Source "document.txt" -Text "Exemple de texte"
$geoInfo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris"
$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\photo.jpg" -MediaType "Image"

# Ajouter tous les objets à la collection
$mixedCollection = Add-ExtractedInfoToCollection -Collection $mixedCollection -InfoList @($textInfo, $geoInfo, $mediaInfo)

# Vérifier le contenu de la collection
$stats = Get-ExtractedInfoCollectionStatistics -Collection $mixedCollection
Write-Host "Statistiques de la collection mixte :"
Write-Host "- Nombre total d'éléments : $($stats.TotalItems)"
Write-Host "- Types d'éléments : $($stats.TypeCounts | ForEach-Object { "$($_.Key): $($_.Value)" } | Join-String -Separator ', ')"
```

##### Exemple 2 : Filtrage sur des propriétés spécifiques

```powershell
# Créer une collection de localisations
$geoCollection = New-ExtractedInfoCollection -Name "GeoCollection" -CreateIndexes

# Ajouter plusieurs objets GeoLocationExtractedInfo
$locations = @(
    (New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"),
    (New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA"),
    (New-GeoLocationExtractedInfo -Latitude 51.5074 -Longitude -0.1278 -City "London" -Country "UK"),
    (New-GeoLocationExtractedInfo -Latitude 52.5200 -Longitude 13.4050 -City "Berlin" -Country "Germany")
)
$geoCollection = Add-ExtractedInfoToCollection -Collection $geoCollection -InfoList $locations

# Filtrer sur des propriétés spécifiques au type GeoLocationExtractedInfo
$europeanLocations = Get-ExtractedInfoFromCollection -Collection $geoCollection -Filter {
    $_._Type -eq "GeoLocationExtractedInfo" -and
    $_.Longitude -gt -20 -and $_.Longitude -lt 40 -and
    $_.Latitude -gt 35 -and $_.Latitude -lt 60
}

Write-Host "Localisations européennes :"
foreach ($location in $europeanLocations) {
    Write-Host "- $($location.City), $($location.Country) ($($location.Latitude), $($location.Longitude))"
}
```

##### Exemple 3 : Création d'index personnalisés

```powershell
# Créer une collection avec des index personnalisés
$indexedCollection = New-ExtractedInfoCollection -Name "IndexedGeoCollection"

# Ajouter des index pour les propriétés spécifiques au type GeoLocationExtractedInfo
$indexedCollection.Indexes = @{
    "City" = @{}
    "Country" = @{}
    "LocationType" = @{}
    "LatitudeRange" = @{} # Index personnalisé pour les plages de latitude
}

# Ajouter plusieurs objets GeoLocationExtractedInfo
$moreLocations = @(
    (New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -LocationType "GPS"),
    (New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA" -LocationType "GPS"),
    (New-GeoLocationExtractedInfo -Latitude 35.6762 -Longitude 139.6503 -City "Tokyo" -Country "Japan" -LocationType "Manual"),
    (New-GeoLocationExtractedInfo -Latitude 19.4326 -Longitude -99.1332 -City "Mexico City" -Country "Mexico" -LocationType "Estimated")
)
$indexedCollection = Add-ExtractedInfoToCollection -Collection $indexedCollection -InfoList $moreLocations

# Créer l'index personnalisé pour les plages de latitude
$indexedCollection.Indexes.LatitudeRange = @{}
foreach ($item in $indexedCollection.Items) {
    if ($item._Type -eq "GeoLocationExtractedInfo") {
        $latitudeRange = switch ($item.Latitude) {
            {$_ -ge 0 -and $_ -lt 30} { "0-30" }
            {$_ -ge 30 -and $_ -lt 60} { "30-60" }
            {$_ -ge 60 -and $_ -le 90} { "60-90" }
            {$_ -lt 0 -and $_ -ge -30} { "-30-0" }
            {$_ -lt -30 -and $_ -ge -60} { "-60--30" }
            {$_ -lt -60 -and $_ -ge -90} { "-90--60" }
        }

        if (-not $indexedCollection.Indexes.LatitudeRange.ContainsKey($latitudeRange)) {
            $indexedCollection.Indexes.LatitudeRange[$latitudeRange] = @()
        }

        $indexedCollection.Indexes.LatitudeRange[$latitudeRange] += $item.Id
    }
}

# Utiliser l'index personnalisé pour récupérer des objets
$northernLocations = Get-ExtractedInfoFromCollection -Collection $indexedCollection -IndexName "LatitudeRange" -IndexValue "30-60"
Write-Host "Localisations dans la plage de latitude 30-60 :"
foreach ($location in $northernLocations) {
    Write-Host "- $($location.City), $($location.Country) (Latitude: $($location.Latitude))"
}
```

#### 3.1.4 Bonnes pratiques pour l'intégration avec les collections

Pour assurer une intégration optimale de vos nouveaux types avec les fonctions de collection, suivez ces bonnes pratiques :

1. **Propriétés uniques** : Utilisez des noms de propriétés uniques et descriptifs pour faciliter le filtrage et l'indexation.

2. **Types de données cohérents** : Utilisez des types de données cohérents pour les propriétés similaires (par exemple, toujours utiliser `[double]` pour les coordonnées géographiques).

3. **Valeurs par défaut** : Fournissez des valeurs par défaut raisonnables pour les propriétés optionnelles afin d'éviter les erreurs lors du filtrage.

4. **Documentation** : Documentez clairement les propriétés spécifiques à votre type pour faciliter leur utilisation dans les filtres et les index.

5. **Indexation** : Identifiez les propriétés qui seront fréquemment utilisées pour le filtrage et créez des index appropriés pour améliorer les performances.

En suivant ces principes et bonnes pratiques, vous pouvez créer des types d'informations extraites personnalisés qui s'intègrent parfaitement avec les fonctions de collection du module.

### 3.2 Intégration avec les fonctions de sérialisation

Les fonctions de sérialisation du module `ExtractedInfoModuleV2` permettent de convertir les objets d'information extraite en format JSON et vice-versa, ainsi que de les sauvegarder dans des fichiers et de les charger à partir de fichiers. Ces fonctions sont conçues pour fonctionner automatiquement avec tous les types d'informations extraites, y compris les nouveaux types personnalisés.

#### 3.2.1 Principes de sérialisation

L'intégration avec les fonctions de sérialisation repose sur plusieurs principes :

1. **Préservation du type** : La propriété `_Type` est préservée lors de la sérialisation et utilisée lors de la désérialisation pour recréer le bon type d'objet.

2. **Sérialisation récursive** : Toutes les propriétés de l'objet, y compris les propriétés spécifiques aux types personnalisés, sont sérialisées récursivement.

3. **Conversion des types complexes** : Les types de données complexes (comme les dates) sont automatiquement convertis en formats compatibles JSON lors de la sérialisation et reconvertis lors de la désérialisation.

4. **Gestion des métadonnées** : Les métadonnées sont correctement sérialisées et désérialisées, avec des options pour les inclure ou les exclure.

#### 3.2.2 Fonctions de sérialisation compatibles

Toutes les fonctions de sérialisation suivantes sont compatibles avec les nouveaux types d'informations extraites :

| Fonction | Description | Compatibilité |
|----------|-------------|---------------|
| `ConvertTo-ExtractedInfoJson` | Convertit un objet en JSON | Sérialise toutes les propriétés, y compris celles spécifiques aux types |
| `ConvertFrom-ExtractedInfoJson` | Convertit un JSON en objet | Reconstitue le type correct basé sur la propriété `_Type` |
| `Save-ExtractedInfoToFile` | Sauvegarde un objet dans un fichier | Fonctionne avec tous les types d'objets |
| `Load-ExtractedInfoFromFile` | Charge un objet depuis un fichier | Reconstitue le type correct basé sur la propriété `_Type` |

#### 3.2.3 Exemples d'intégration avec la sérialisation

##### Exemple 1 : Sérialisation et désérialisation d'un objet personnalisé

```powershell
# Créer un objet GeoLocationExtractedInfo
$sydney = New-GeoLocationExtractedInfo -Latitude -33.8688 -Longitude 151.2093 -City "Sydney" -Country "Australia" -LocationType "GPS" -Accuracy 10

# Ajouter des métadonnées
$sydney = Add-ExtractedInfoMetadata -Info $sydney -Metadata @{
    Population = 5312000
    TimeZone = "Australia/Sydney"
    IsCapital = $false
}

# Convertir en JSON avec indentation
$json = ConvertTo-ExtractedInfoJson -Info $sydney -Indent
Write-Host "JSON sérialisé :"
Write-Host $json

# Désérialiser le JSON
$deserializedSydney = ConvertFrom-ExtractedInfoJson -Json $json

# Vérifier que l'objet a été correctement reconstitué
Write-Host "Objet désérialisé :"
Write-Host "- Type : $($deserializedSydney._Type)"
Write-Host "- Ville : $($deserializedSydney.City)"
Write-Host "- Coordonnées : $($deserializedSydney.Latitude), $($deserializedSydney.Longitude)"
Write-Host "- Métadonnées :"
foreach ($key in $deserializedSydney.Metadata.Keys) {
    Write-Host "  * $key : $($deserializedSydney.Metadata[$key])"
}
```

##### Exemple 2 : Sérialisation avec exclusion de métadonnées

```powershell
# Créer un objet avec beaucoup de métadonnées
$rome = New-GeoLocationExtractedInfo -Latitude 41.9028 -Longitude 12.4964 -City "Rome" -Country "Italy"
$rome = Add-ExtractedInfoMetadata -Info $rome -Metadata @{
    Population = 2873000
    TimeZone = "Europe/Rome"
    IsCapital = $true
    FoundedYear = 753
    HistoricalNames = @("Roma", "Caput Mundi", "Eternal City")
    FamousLandmarks = @("Colosseum", "Vatican", "Trevi Fountain", "Pantheon", "Roman Forum")
    Climate = @{
        Type = "Mediterranean"
        AverageTemperature = 15.5
        RainyDays = 83
    }
}

# Sérialiser avec et sans métadonnées
$jsonWithMetadata = ConvertTo-ExtractedInfoJson -Info $rome -Indent
$jsonWithoutMetadata = ConvertTo-ExtractedInfoJson -Info $rome -Indent -ExcludeMetadata

# Comparer les tailles
$withSize = $jsonWithMetadata.Length
$withoutSize = $jsonWithoutMetadata.Length
$reduction = [Math]::Round(100 - ($withoutSize / $withSize * 100), 2)

Write-Host "Taille avec métadonnées : $withSize caractères"
Write-Host "Taille sans métadonnées : $withoutSize caractères"
Write-Host "Réduction : $reduction%"
```

##### Exemple 3 : Sauvegarde et chargement depuis un fichier

```powershell
# Créer plusieurs objets GeoLocationExtractedInfo
$capitals = @(
    (New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -LocationType "GPS"),
    (New-GeoLocationExtractedInfo -Latitude 51.5074 -Longitude -0.1278 -City "London" -Country "UK" -LocationType "GPS"),
    (New-GeoLocationExtractedInfo -Latitude 52.5200 -Longitude 13.4050 -City "Berlin" -Country "Germany" -LocationType "GPS"),
    (New-GeoLocationExtractedInfo -Latitude 40.4168 -Longitude -3.7038 -City "Madrid" -Country "Spain" -LocationType "GPS")
)

# Créer une collection
$capitalsCollection = New-ExtractedInfoCollection -Name "EuropeanCapitals" -CreateIndexes
$capitalsCollection = Add-ExtractedInfoToCollection -Collection $capitalsCollection -InfoList $capitals

# Sauvegarder la collection dans un fichier
$filePath = Join-Path $env:TEMP "european_capitals.json"
$result = Save-ExtractedInfoToFile -Collection $capitalsCollection -FilePath $filePath -Indent -Force
Write-Host "Sauvegarde de la collection : $result"

# Charger la collection depuis le fichier
$loadedCollection = Load-ExtractedInfoFromFile -FilePath $filePath

# Vérifier que la collection a été correctement chargée
Write-Host "Collection chargée :"
Write-Host "- Nom : $($loadedCollection.Name)"
Write-Host "- Nombre d'éléments : $($loadedCollection.Items.Count)"
Write-Host "- Villes :"
foreach ($item in $loadedCollection.Items) {
    Write-Host "  * $($item.City), $($item.Country)"
}
```

#### 3.2.4 Considérations spéciales pour les types personnalisés

Lors de la création de nouveaux types d'informations extraites, certaines considérations spéciales doivent être prises en compte pour assurer une sérialisation et une désérialisation correctes :

1. **Types de données compatibles JSON** : Utilisez des types de données qui peuvent être facilement sérialisés en JSON :
   - Types primitifs : `string`, `int`, `double`, `bool`
   - Tableaux et collections
   - Hashtables et objets imbriqués
   - Dates (automatiquement converties en chaînes ISO 8601)

2. **Éviter les références circulaires** : Les références circulaires ne peuvent pas être sérialisées en JSON. Assurez-vous que vos objets n'ont pas de références circulaires.

3. **Propriétés calculées** : Les propriétés calculées (qui ne sont pas stockées directement dans l'objet) ne seront pas sérialisées. Si nécessaire, précalculez ces valeurs et stockez-les dans l'objet avant la sérialisation.

4. **Objets complexes** : Pour les objets complexes qui ne peuvent pas être directement sérialisés en JSON, envisagez de les convertir en structures plus simples avant la sérialisation.

#### 3.2.5 Bonnes pratiques pour l'intégration avec la sérialisation

Pour assurer une intégration optimale de vos nouveaux types avec les fonctions de sérialisation, suivez ces bonnes pratiques :

1. **Testez la sérialisation et la désérialisation** : Vérifiez que vos objets peuvent être correctement sérialisés et désérialisés, en particulier s'ils contiennent des structures de données complexes.

2. **Documentez les propriétés sérialisables** : Indiquez clairement quelles propriétés sont sérialisées et comment elles sont représentées en JSON.

3. **Gérez les versions** : Si vous prévoyez de faire évoluer votre type au fil du temps, envisagez d'ajouter une propriété de version pour assurer la compatibilité ascendante lors de la désérialisation.

4. **Optimisez la taille du JSON** : Pour les objets volumineux, utilisez les options d'exclusion (comme `-ExcludeMetadata`) pour réduire la taille du JSON lorsque certaines propriétés ne sont pas nécessaires.

5. **Validez après désérialisation** : Après avoir désérialisé un objet, validez-le pour vous assurer qu'il est cohérent et complet.

En suivant ces principes et bonnes pratiques, vous pouvez créer des types d'informations extraites personnalisés qui fonctionnent parfaitement avec les fonctions de sérialisation du module.

### 3.3 Intégration avec les fonctions de validation

Les fonctions de validation du module `ExtractedInfoModuleV2` permettent de vérifier que les objets d'information extraite respectent certaines contraintes et règles métier. Le système de validation est conçu pour être extensible et prendre en charge les nouveaux types d'informations extraites.

#### 3.3.1 Principes de validation

L'intégration avec les fonctions de validation repose sur plusieurs principes :

1. **Validation hiérarchique** : Les règles de validation du type de base sont toujours appliquées, puis les règles spécifiques au type personnalisé sont appliquées.

2. **Règles de validation globales** : Des règles de validation globales peuvent être enregistrées pour être appliquées automatiquement à tous les objets d'un type spécifique.

3. **Règles de validation ponctuelles** : Des règles de validation supplémentaires peuvent être spécifiées lors de l'appel aux fonctions de validation.

4. **Messages d'erreur détaillés** : Les erreurs de validation fournissent des messages détaillés pour aider à identifier et corriger les problèmes.

#### 3.3.2 Fonctions de validation compatibles

Toutes les fonctions de validation suivantes sont compatibles avec les nouveaux types d'informations extraites :

| Fonction | Description | Compatibilité |
|----------|-------------|---------------|
| `Test-ExtractedInfo` | Vérifie si un objet est valide | Applique les règles spécifiques au type |
| `Get-ExtractedInfoValidationErrors` | Récupère les erreurs de validation | Détecte les erreurs spécifiques au type |
| `Add-ExtractedInfoValidationRule` | Ajoute une règle de validation globale | Peut cibler un type spécifique |
| `Remove-ExtractedInfoValidationRule` | Supprime une règle de validation globale | Fonctionne avec les règles pour tous les types |
| `Get-ExtractedInfoValidationRules` | Récupère les règles de validation enregistrées | Inclut les règles pour tous les types |

#### 3.3.3 Exemples d'intégration avec la validation

##### Exemple 1 : Validation d'un objet personnalisé

```powershell
# Créer un objet GeoLocationExtractedInfo valide
$validLocation = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"

# Valider l'objet
$isValid = Test-ExtractedInfo -Info $validLocation
Write-Host "L'objet est valide : $isValid"

# Créer un objet GeoLocationExtractedInfo invalide
$invalidLocation = @{
    _Type = "GeoLocationExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    Source = "Manual"
    ExtractorName = "GeoLocationExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "Raw"
    ConfidenceScore = 50
    Metadata = @{}
    Latitude = 100 # Invalide : doit être entre -90 et 90
    Longitude = 2.3522
}

# Obtenir les erreurs de validation
$errors = Get-ExtractedInfoValidationErrors -Info $invalidLocation
Write-Host "Erreurs de validation :"
foreach ($error in $errors) {
    Write-Host "- $error"
}
```

##### Exemple 2 : Ajout d'une règle de validation personnalisée

```powershell
# Définir une règle de validation personnalisée pour les objets GeoLocationExtractedInfo
$customRule = {
    param($Info)

    $errors = @()

    # Ne s'applique qu'aux objets GeoLocationExtractedInfo
    if ($Info._Type -ne "GeoLocationExtractedInfo") {
        return $errors
    }

    # Règle : Les coordonnées de l'Antarctique doivent avoir une précision élevée
    if ($Info.Latitude -lt -60) {
        if (-not $Info.ContainsKey('Accuracy') -or $Info.Accuracy -gt 10) {
            $errors += "Les coordonnées en Antarctique doivent avoir une précision d'au moins 10 mètres"
        }
    }

    # Règle : Les villes doivent avoir un pays spécifié
    if ($Info.ContainsKey('City') -and $Info.City -and (-not $Info.ContainsKey('Country') -or -not $Info.Country)) {
        $errors += "Le pays doit être spécifié pour la ville '$($Info.City)'"
    }

    return $errors
}

# Valider un objet avec la règle personnalisée
$antarctica = New-GeoLocationExtractedInfo -Latitude -75.2509 -Longitude -0.0713 -City "Research Station" -Accuracy 20
$validationResult = Test-ExtractedInfo -Info $antarctica -CustomValidationRule $customRule -Detailed

Write-Host "Validation avec règle personnalisée :"
Write-Host "- Valide : $($validationResult.IsValid)"
if (-not $validationResult.IsValid) {
    Write-Host "- Erreurs :"
    foreach ($error in $validationResult.Errors) {
        Write-Host "  * $error"
    }
}
```

##### Exemple 3 : Enregistrement d'une règle de validation globale

```powershell
# Définir une règle de validation globale pour les objets GeoLocationExtractedInfo
$globalRule = {
    param($Info)

    $errors = @()

    # Ne s'applique qu'aux objets GeoLocationExtractedInfo
    if ($Info._Type -ne "GeoLocationExtractedInfo") {
        return $errors
    }

    # Règle : Les coordonnées doivent avoir une précision cohérente avec le type de localisation
    if ($Info.ContainsKey('LocationType') -and $Info.ContainsKey('Accuracy')) {
        switch ($Info.LocationType) {
            "GPS" {
                if ($Info.Accuracy -gt 30) {
                    $errors += "La précision pour le type de localisation GPS ne devrait pas dépasser 30 mètres (actuelle : $($Info.Accuracy))"
                }
            }
            "Cell" {
                if ($Info.Accuracy -lt 100) {
                    $errors += "La précision pour le type de localisation Cell ne peut pas être inférieure à 100 mètres (actuelle : $($Info.Accuracy))"
                }
            }
            "WiFi" {
                if ($Info.Accuracy -lt 20 -or $Info.Accuracy -gt 100) {
                    $errors += "La précision pour le type de localisation WiFi doit être entre 20 et 100 mètres (actuelle : $($Info.Accuracy))"
                }
            }
        }
    }

    return $errors
}

# Enregistrer la règle globale
Add-ExtractedInfoValidationRule -Name "GeoLocationAccuracyRule" -Rule $globalRule -TargetType "GeoLocationExtractedInfo" -Description "Règles de précision pour les types de localisation"

# Tester la règle globale avec différents objets
$gpsLocation = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -LocationType "GPS" -Accuracy 50
$cellLocation = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -LocationType "Cell" -Accuracy 50
$wifiLocation = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -LocationType "WiFi" -Accuracy 50

# Valider les objets
$gpsValid = Test-ExtractedInfo -Info $gpsLocation -Detailed
$cellValid = Test-ExtractedInfo -Info $cellLocation -Detailed
$wifiValid = Test-ExtractedInfo -Info $wifiLocation -Detailed

# Afficher les résultats
Write-Host "Validation GPS : $($gpsValid.IsValid)"
if (-not $gpsValid.IsValid) {
    foreach ($error in $gpsValid.Errors) {
        Write-Host "- $error"
    }
}

Write-Host "Validation Cell : $($cellValid.IsValid)"
if (-not $cellValid.IsValid) {
    foreach ($error in $cellValid.Errors) {
        Write-Host "- $error"
    }
}

Write-Host "Validation WiFi : $($wifiValid.IsValid)"
if (-not $wifiValid.IsValid) {
    foreach ($error in $wifiValid.Errors) {
        Write-Host "- $error"
    }
}

# Supprimer la règle globale
Remove-ExtractedInfoValidationRule -Name "GeoLocationAccuracyRule"
```

#### 3.3.4 Création de règles de validation pour les types personnalisés

Lors de la création d'un nouveau type d'information extraite, il est recommandé de créer une fonction dédiée pour ajouter les règles de validation spécifiques à ce type. Cette fonction peut être appelée lors de l'initialisation du module ou lorsque le type est utilisé pour la première fois.

```powershell
function Add-GeoLocationValidationRules {
    <#
    .SYNOPSIS
    Ajoute les règles de validation pour les objets GeoLocationExtractedInfo.

    .DESCRIPTION
    Cette fonction ajoute les règles de validation spécifiques aux objets GeoLocationExtractedInfo.
    Ces règles vérifient que les propriétés obligatoires sont présentes et que les valeurs respectent les contraintes définies.

    .EXAMPLE
    Add-GeoLocationValidationRules
    #>

    # Règle de validation principale
    $geoLocationRule = {
        param($Info)

        $errors = @()

        # Ne s'applique qu'aux objets GeoLocationExtractedInfo
        if ($Info._Type -ne "GeoLocationExtractedInfo") {
            return $errors
        }

        # Vérifier les propriétés obligatoires
        if (-not $Info.ContainsKey('Latitude')) {
            $errors += "Missing required property: Latitude"
        }
        elseif ($Info.Latitude -lt -90 -or $Info.Latitude -gt 90) {
            $errors += "Latitude must be between -90 and 90 (current value: $($Info.Latitude))"
        }

        if (-not $Info.ContainsKey('Longitude')) {
            $errors += "Missing required property: Longitude"
        }
        elseif ($Info.Longitude -lt -180 -or $Info.Longitude -gt 180) {
            $errors += "Longitude must be between -180 and 180 (current value: $($Info.Longitude))"
        }

        # Vérifier les propriétés optionnelles
        if ($Info.ContainsKey('Altitude') -and $null -ne $Info.Altitude -and -not ($Info.Altitude -is [double] -or $Info.Altitude -is [int])) {
            $errors += "Altitude must be a number (current type: $($Info.Altitude.GetType().Name))"
        }

        if ($Info.ContainsKey('Accuracy')) {
            if ($null -ne $Info.Accuracy -and -not ($Info.Accuracy -is [double] -or $Info.Accuracy -is [int])) {
                $errors += "Accuracy must be a number (current type: $($Info.Accuracy.GetType().Name))"
            }
            elseif ($Info.Accuracy -lt 0) {
                $errors += "Accuracy must be a positive number (current value: $($Info.Accuracy))"
            }
        }

        if ($Info.ContainsKey('LocationType')) {
            $validLocationTypes = @("GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown")
            if (-not ($validLocationTypes -contains $Info.LocationType)) {
                $errors += "LocationType must be one of the following values: $($validLocationTypes -join ', ') (current value: $($Info.LocationType))"
            }
        }

        # Vérifier la cohérence des données
        if ($Info.ContainsKey('City') -and $Info.City -and $Info.ContainsKey('Country') -and -not $Info.Country) {
            $errors += "Country should be specified when City is provided"
        }

        return $errors
    }

    # Règle de validation pour les relations spatiales
    $spatialRelationRule = {
        param($Info)

        $errors = @()

        # Ne s'applique qu'aux objets GeoLocationExtractedInfo
        if ($Info._Type -ne "GeoLocationExtractedInfo") {
            return $errors
        }

        # Vérifier la cohérence entre les coordonnées et le pays (exemples simplifiés)
        if ($Info.ContainsKey('Country') -and $Info.Country -eq "France" -and $Info.ContainsKey('Latitude') -and $Info.ContainsKey('Longitude')) {
            # Vérification simplifiée pour la France métropolitaine
            if ($Info.Latitude -lt 41 -or $Info.Latitude -gt 52 -or $Info.Longitude -lt -5 -or $Info.Longitude -gt 10) {
                $errors += "Les coordonnées ($($Info.Latitude), $($Info.Longitude)) ne semblent pas correspondre à la France métropolitaine"
            }
        }

        return $errors
    }

    # Enregistrer les règles
    Add-ExtractedInfoValidationRule -Name "GeoLocationMainRule" -Rule $geoLocationRule -TargetType "GeoLocationExtractedInfo" -Description "Règles principales pour les objets GeoLocationExtractedInfo" -Force
    Add-ExtractedInfoValidationRule -Name "GeoLocationSpatialRule" -Rule $spatialRelationRule -TargetType "GeoLocationExtractedInfo" -Description "Règles de cohérence spatiale pour les objets GeoLocationExtractedInfo" -Force
}
```

#### 3.3.5 Bonnes pratiques pour l'intégration avec la validation

Pour assurer une intégration optimale de vos nouveaux types avec les fonctions de validation, suivez ces bonnes pratiques :

1. **Règles spécifiques au type** : Créez des règles de validation qui vérifient uniquement les objets de votre type personnalisé en utilisant la condition `if ($Info._Type -ne "VotreTypeExtractedInfo") { return @() }`.

2. **Messages d'erreur clairs** : Fournissez des messages d'erreur clairs et détaillés qui indiquent précisément le problème et comment le corriger.

3. **Validation hiérarchique** : Si votre type hérite d'un autre type personnalisé, assurez-vous que les règles de validation du type parent sont également appliquées.

4. **Validation contextuelle** : Créez des règles qui vérifient la cohérence entre différentes propriétés de l'objet.

5. **Documentation** : Documentez clairement les règles de validation pour que les utilisateurs comprennent les contraintes de votre type.

En suivant ces principes et bonnes pratiques, vous pouvez créer des types d'informations extraites personnalisés qui sont correctement validés et qui s'intègrent parfaitement avec le système de validation du module.

### 3.4 Considérations de compatibilité

Lors de la création de nouveaux types d'informations extraites, il est important de prendre en compte plusieurs considérations de compatibilité pour garantir que vos types fonctionnent correctement avec le module existant et qu'ils resteront compatibles avec les futures versions.

#### 3.4.1 Compatibilité avec les versions du module

Le module `ExtractedInfoModuleV2` est conçu pour évoluer tout en maintenant la compatibilité avec les types personnalisés existants. Cependant, certaines précautions doivent être prises pour assurer cette compatibilité :

1. **Propriétés du type de base** : Ne modifiez jamais les propriétés du type de base (`_Type`, `Id`, `Source`, etc.). Ces propriétés sont fondamentales pour le fonctionnement du module.

2. **Versionnement des types** : Si vous prévoyez de faire évoluer votre type au fil du temps, envisagez d'ajouter une propriété de version (par exemple, `SchemaVersion`) pour permettre la gestion des différentes versions.

3. **Compatibilité ascendante** : Assurez-vous que les nouvelles versions de vos types sont compatibles avec les anciennes versions. Par exemple, si vous ajoutez une nouvelle propriété obligatoire, fournissez une valeur par défaut raisonnable.

4. **Documentation des changements** : Documentez clairement les changements apportés à vos types pour faciliter la migration des utilisateurs.

#### 3.4.2 Compatibilité avec PowerShell

Le module est conçu pour fonctionner avec différentes versions de PowerShell. Pour garantir cette compatibilité :

1. **PowerShell 5.1 et 7.x** : Testez vos types avec PowerShell 5.1 et PowerShell 7.x pour vous assurer qu'ils fonctionnent correctement dans les deux environnements.

2. **Types de données compatibles** : Utilisez des types de données qui sont compatibles avec toutes les versions de PowerShell. Évitez les fonctionnalités spécifiques à PowerShell 7.x si vous devez maintenir la compatibilité avec PowerShell 5.1.

3. **Encodage des caractères** : Assurez-vous que vos types gèrent correctement les caractères spéciaux et les encodages (UTF-8, UTF-16, etc.).

4. **Gestion des erreurs** : Utilisez des mécanismes de gestion des erreurs compatibles avec toutes les versions de PowerShell.

#### 3.4.3 Compatibilité avec les autres types personnalisés

Si plusieurs types personnalisés sont utilisés ensemble, ils doivent être compatibles entre eux :

1. **Noms de propriétés uniques** : Évitez les conflits de noms de propriétés entre différents types personnalisés, surtout si ces types peuvent être utilisés ensemble.

2. **Conventions cohérentes** : Suivez les mêmes conventions de nommage et de structure pour tous vos types personnalisés.

3. **Règles de validation cohérentes** : Assurez-vous que les règles de validation de différents types ne se contredisent pas.

4. **Interopérabilité** : Si vos types doivent interagir entre eux, documentez clairement ces interactions et assurez-vous qu'elles fonctionnent correctement.

#### 3.4.4 Compatibilité avec les systèmes externes

Si vos types d'informations extraites doivent interagir avec des systèmes externes, tenez compte des considérations suivantes :

1. **Formats d'échange** : Assurez-vous que vos types peuvent être facilement convertis dans des formats d'échange standard (JSON, XML, CSV, etc.).

2. **Identifiants externes** : Si vos types font référence à des identifiants externes, documentez clairement ces références et assurez-vous qu'elles sont correctement gérées.

3. **Contraintes de taille** : Tenez compte des contraintes de taille des systèmes externes. Par exemple, certains systèmes peuvent avoir des limites sur la taille des chaînes de caractères ou le nombre d'éléments dans une collection.

4. **Sécurité** : Assurez-vous que vos types ne contiennent pas d'informations sensibles qui ne devraient pas être partagées avec des systèmes externes.

#### 3.4.5 Gestion des migrations et des mises à jour

Lorsque vous mettez à jour vos types personnalisés, vous devez prévoir des mécanismes pour migrer les données existantes :

1. **Fonctions de migration** : Créez des fonctions dédiées pour migrer les objets d'une version à une autre.

```powershell
function Update-GeoLocationExtractedInfoSchema {
    <#
    .SYNOPSIS
    Met à jour un objet GeoLocationExtractedInfo d'une version antérieure vers la version actuelle.

    .DESCRIPTION
    Cette fonction prend un objet GeoLocationExtractedInfo créé avec une version antérieure du schéma
    et le met à jour pour qu'il soit compatible avec la version actuelle.

    .PARAMETER Info
    L'objet GeoLocationExtractedInfo à mettre à jour.

    .EXAMPLE
    $updatedInfo = Update-GeoLocationExtractedInfoSchema -Info $oldInfo
    #>
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Vérifier que c'est bien un objet GeoLocationExtractedInfo
    if ($Info._Type -ne "GeoLocationExtractedInfo") {
        throw "L'objet fourni n'est pas un GeoLocationExtractedInfo"
    }

    # Créer une copie de l'objet pour ne pas modifier l'original
    $updatedInfo = $Info.Clone()

    # Ajouter la propriété SchemaVersion si elle n'existe pas
    if (-not $updatedInfo.ContainsKey('SchemaVersion')) {
        $updatedInfo.SchemaVersion = 1
    }

    # Mettre à jour de la version 1 à la version 2
    if ($updatedInfo.SchemaVersion -eq 1) {
        # Ajouter les nouvelles propriétés de la version 2
        if (-not $updatedInfo.ContainsKey('LocationType')) {
            $updatedInfo.LocationType = "Unknown"
        }

        # Mettre à jour la version
        $updatedInfo.SchemaVersion = 2
    }

    # Mettre à jour de la version 2 à la version 3
    if ($updatedInfo.SchemaVersion -eq 2) {
        # Renommer la propriété Accuracy en HorizontalAccuracy
        if ($updatedInfo.ContainsKey('Accuracy')) {
            $updatedInfo.HorizontalAccuracy = $updatedInfo.Accuracy
            $updatedInfo.Remove('Accuracy')
        }
        else {
            $updatedInfo.HorizontalAccuracy = 0
        }

        # Ajouter la nouvelle propriété VerticalAccuracy
        if (-not $updatedInfo.ContainsKey('VerticalAccuracy')) {
            $updatedInfo.VerticalAccuracy = 0
        }

        # Mettre à jour la version
        $updatedInfo.SchemaVersion = 3
    }

    return $updatedInfo
}
```

2. **Détection automatique de version** : Implémentez des mécanismes pour détecter automatiquement la version d'un objet et le mettre à jour si nécessaire.

```powershell
function Get-GeoLocationExtractedInfo {
    <#
    .SYNOPSIS
    Récupère un objet GeoLocationExtractedInfo et le met à jour si nécessaire.

    .DESCRIPTION
    Cette fonction récupère un objet GeoLocationExtractedInfo, détecte sa version,
    et le met à jour vers la version actuelle si nécessaire.

    .PARAMETER FilePath
    Le chemin du fichier contenant l'objet GeoLocationExtractedInfo.

    .EXAMPLE
    $info = Get-GeoLocationExtractedInfo -FilePath "location.json"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Charger l'objet depuis le fichier
    $info = Load-ExtractedInfoFromFile -FilePath $FilePath

    # Vérifier que c'est bien un objet GeoLocationExtractedInfo
    if ($info._Type -ne "GeoLocationExtractedInfo") {
        throw "Le fichier ne contient pas un objet GeoLocationExtractedInfo"
    }

    # Vérifier la version et mettre à jour si nécessaire
    $currentSchemaVersion = 3 # Version actuelle du schéma

    if (-not $info.ContainsKey('SchemaVersion') -or $info.SchemaVersion -lt $currentSchemaVersion) {
        Write-Verbose "Mise à jour de l'objet GeoLocationExtractedInfo de la version $($info.SchemaVersion) vers la version $currentSchemaVersion"
        $info = Update-GeoLocationExtractedInfoSchema -Info $info
    }

    return $info
}
```

3. **Documentation des migrations** : Documentez clairement les changements entre les versions et les étapes nécessaires pour migrer les données.

4. **Tests de migration** : Testez soigneusement les migrations pour vous assurer que les données sont correctement préservées.

#### 3.4.6 Bonnes pratiques pour la compatibilité

Pour assurer une compatibilité maximale de vos types personnalisés, suivez ces bonnes pratiques :

1. **Évolution incrémentale** : Faites évoluer vos types de manière incrémentale plutôt que de les refondre complètement.

2. **Tests de régression** : Testez régulièrement vos types avec les anciennes versions du module et avec différentes versions de PowerShell.

3. **Documentation claire** : Documentez clairement les exigences de compatibilité et les limitations connues de vos types.

4. **Gestion des erreurs robuste** : Implémentez une gestion des erreurs robuste pour détecter et gérer les problèmes de compatibilité.

5. **Rétrocompatibilité** : Privilégiez la rétrocompatibilité lors de l'ajout de nouvelles fonctionnalités ou propriétés.

En tenant compte de ces considérations de compatibilité, vous pouvez créer des types d'informations extraites qui fonctionneront de manière fiable dans différents environnements et qui pourront évoluer au fil du temps sans causer de problèmes aux utilisateurs existants.
