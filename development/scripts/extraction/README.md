# Module ExtractedInfoModuleV2

## 1. Objectif et portée du module

### 1.1 Problème résolu par le module

Le module `ExtractedInfoModuleV2` a été conçu pour résoudre plusieurs problèmes fondamentaux liés à l'extraction, la gestion et la manipulation d'informations provenant de diverses sources :

1. **Fragmentation des données** : Les informations extraites de différentes sources (web, API, fichiers, bases de données) sont souvent stockées dans des formats disparates et incompatibles, rendant difficile leur traitement unifié.

2. **Manque de structure** : Les données extraites manquent généralement d'une structure cohérente, ce qui complique leur validation, leur transformation et leur analyse.

3. **Traçabilité limitée** : L'origine des informations et leur parcours de traitement sont rarement documentés de manière systématique, ce qui rend difficile la vérification de leur fiabilité et de leur pertinence.

4. **Difficultés de persistance** : La sauvegarde et la récupération des informations extraites nécessitent souvent des solutions ad hoc qui ne garantissent pas l'intégrité des données.

5. **Validation incohérente** : Les mécanismes de validation des données extraites sont généralement implémentés de manière inconsistante, ce qui peut conduire à des erreurs et des incohérences dans les traitements ultérieurs.

6. **Complexité d'organisation** : L'organisation des informations extraites en ensembles cohérents et interrogeables est souvent négligée ou implémentée de manière inefficace.

Le module `ExtractedInfoModuleV2` offre une solution unifiée à ces problèmes en fournissant un cadre structuré pour la représentation, la validation, l'organisation et la persistance des informations extraites, indépendamment de leur source ou de leur nature.

### 1.2 Cas d'utilisation principaux

Le module `ExtractedInfoModuleV2` est conçu pour répondre à plusieurs cas d'utilisation clés :

1. **Extraction et structuration de données web** : Capture et organisation d'informations provenant de sites web, avec traçabilité de la source et validation automatique des données extraites.

2. **Agrégation de données multi-sources** : Collecte et unification d'informations provenant de différentes sources (API, bases de données, fichiers) dans une structure cohérente et interrogeable.

3. **Traitement par étapes (pipeline)** : Mise en place de chaînes de traitement où les informations extraites passent par différentes étapes (extraction, nettoyage, enrichissement, validation) avec suivi de l'état de traitement.

4. **Persistance et partage d'informations** : Sauvegarde et chargement d'informations extraites dans des formats standardisés (JSON) pour faciliter leur partage et leur réutilisation.

5. **Analyse et reporting** : Organisation des informations extraites en collections pour faciliter leur analyse, leur filtrage et la génération de statistiques.

6. **Intégration avec d'autres systèmes** : Structuration des informations extraites de manière à faciliter leur intégration avec d'autres systèmes et modules PowerShell.

7. **Validation et contrôle qualité** : Application de règles de validation personnalisées pour garantir la qualité et la cohérence des informations extraites.

8. **Archivage et documentation** : Conservation des informations extraites avec leurs métadonnées pour référence future et documentation.

### 1.3 Avantages du module

L'utilisation du module `ExtractedInfoModuleV2` offre de nombreux avantages par rapport aux approches ad hoc ou non structurées :

1. **Uniformité et cohérence** : Toutes les informations extraites sont représentées selon un modèle cohérent, ce qui facilite leur traitement et leur analyse.

2. **Traçabilité complète** : Chaque information extraite conserve des métadonnées sur sa source, son extracteur, sa date d'extraction et son historique de modifications.

3. **Validation intégrée** : Le module inclut des mécanismes de validation robustes et extensibles qui garantissent l'intégrité et la qualité des données.

4. **Flexibilité et extensibilité** : Le système de types d'informations extraites peut être étendu pour répondre à des besoins spécifiques tout en conservant la compatibilité avec les fonctionnalités de base.

5. **Organisation optimisée** : Les collections d'informations extraites offrent des capacités d'indexation et de recherche performantes pour un accès rapide aux données.

6. **Sérialisation standardisée** : Les fonctionnalités de conversion JSON et de persistance fichier garantissent l'interopérabilité et la durabilité des données.

7. **Gestion des métadonnées** : Le système de métadonnées permet d'enrichir les informations extraites avec des données contextuelles sans altérer leur structure principale.

8. **Performances optimisées** : Les opérations sur les collections sont optimisées pour gérer efficacement de grands volumes d'informations extraites.

9. **Intégration PowerShell native** : Le module suit les conventions PowerShell pour une intégration transparente dans les scripts et les pipelines existants.

10. **Documentation complète** : Chaque fonction et structure de données est documentée de manière exhaustive pour faciliter l'apprentissage et l'utilisation.

### 1.4 Limites et contraintes du module

Le module `ExtractedInfoModuleV2` a été conçu avec certaines limites et contraintes qu'il est important de comprendre :

1. **Limites de performance** :
   - Le module n'est pas optimisé pour des collections extrêmement volumineuses (> 100 000 éléments) sans indexation appropriée.
   - Les opérations de sérialisation/désérialisation peuvent devenir coûteuses pour de très grandes collections.
   - L'utilisation intensive de hashtables peut entraîner une consommation mémoire significative.

2. **Contraintes techniques** :
   - Compatible avec PowerShell 5.1 et versions ultérieures.
   - Utilise exclusivement des structures de données natives à PowerShell (pas de classes .NET personnalisées).
   - Encodage en UTF-8 sans BOM pour garantir la compatibilité maximale.
   - Pas de dépendances externes pour maximiser la portabilité.

3. **Limites fonctionnelles** :
   - Pas de support natif pour les opérations asynchrones.
   - Pas de mécanisme intégré de persistance autre que JSON (pas de support direct pour les bases de données).
   - Pas de gestion native des versions pour les informations extraites.
   - Pas de mécanisme de chiffrement intégré pour les données sensibles.

4. **Contraintes de conception** :
   - Architecture basée sur des fonctions plutôt que des classes pour maximiser la compatibilité.
   - Utilisation de hashtables pour représenter les objets, ce qui limite certaines fonctionnalités orientées objet.
   - Validation manuelle des types et propriétés en l'absence d'un système de typage fort.
   - Pas de support natif pour l'héritage ou le polymorphisme complexe.

5. **Considérations d'utilisation** :
   - Le module est conçu comme une bibliothèque utilitaire, pas comme une application complète.
   - Il est recommandé d'implémenter des mécanismes de journalisation externes pour les opérations critiques.
   - Pour les cas d'utilisation à haute performance, des optimisations spécifiques peuvent être nécessaires.
   - L'intégration avec des sources de données externes nécessite des adaptateurs personnalisés.

## 2. Architecture du module

### 2.1 Structure des objets d'information extraite

Le module `ExtractedInfoModuleV2` est construit autour d'un système de types d'objets d'information extraite hiérarchique et extensible. Cette architecture permet de représenter différents types d'informations tout en maintenant une structure commune pour les opérations de base.

#### 2.1.1 Type de base : ExtractedInfo

Tous les objets d'information extraite héritent d'un type de base commun, `ExtractedInfo`, qui définit les propriétés fondamentales :

```
ExtractedInfo
├── _Type : string                 # Type de l'information extraite (ex: "ExtractedInfo")
├── Id : string                    # Identifiant unique (GUID)
├── Source : string                # Source de l'information (ex: "Web", "API", "File")
├── ExtractorName : string         # Nom de l'extracteur utilisé
├── ExtractionDate : datetime      # Date et heure de l'extraction initiale
├── LastModifiedDate : datetime    # Date et heure de la dernière modification
├── ProcessingState : string       # État de traitement (Raw, Processed, Validated, Error)
├── ConfidenceScore : int          # Score de confiance (0-100)
└── Metadata : hashtable           # Métadonnées additionnelles
```

Chaque objet `ExtractedInfo` est représenté par une hashtable PowerShell avec ces propriétés, ce qui permet une manipulation flexible tout en maintenant une structure cohérente.

#### 2.1.2 Types spécialisés

Le module définit plusieurs types spécialisés qui étendent le type de base pour des cas d'utilisation spécifiques :

**TextExtractedInfo** : Pour les informations textuelles
```
TextExtractedInfo (hérite de ExtractedInfo)
├── [Toutes les propriétés de ExtractedInfo]
├── Text : string                  # Contenu textuel extrait
└── Language : string              # Code de langue du texte (ex: "en", "fr")
```

**StructuredDataExtractedInfo** : Pour les données structurées (JSON, XML, etc.)
```
StructuredDataExtractedInfo (hérite de ExtractedInfo)
├── [Toutes les propriétés de ExtractedInfo]
├── Data : hashtable/array         # Données structurées extraites
└── DataFormat : string            # Format des données (ex: "JSON", "XML")
```

**MediaExtractedInfo** : Pour les références à des fichiers média
```
MediaExtractedInfo (hérite de ExtractedInfo)
├── [Toutes les propriétés de ExtractedInfo]
├── MediaPath : string             # Chemin vers le fichier média
├── MediaType : string             # Type de média (Image, Video, Audio, Document)
└── MediaSize : long               # Taille du fichier en octets
```

#### 2.1.3 Extensibilité

Le système est conçu pour être extensible, permettant la création de nouveaux types spécialisés selon les besoins spécifiques. Pour créer un nouveau type, il suffit de :

1. Définir un nouveau type qui hérite de `ExtractedInfo`
2. Ajouter les propriétés spécifiques au nouveau type
3. Implémenter les fonctions de création et de validation correspondantes
4. Mettre à jour les fonctions de sérialisation/désérialisation si nécessaire

#### 2.1.4 Validation des objets

Chaque type d'information extraite est associé à des règles de validation spécifiques qui garantissent l'intégrité et la cohérence des données :

- Validation des propriétés requises
- Validation des types de données
- Validation des valeurs autorisées (ex: ProcessingState doit être l'une des valeurs prédéfinies)
- Validation des contraintes spécifiques au type (ex: ConfidenceScore doit être entre 0 et 100)

Le système de validation est extensible et permet d'ajouter des règles personnalisées pour des besoins spécifiques.

### 2.2 Fonctionnement des collections

Le module `ExtractedInfoModuleV2` introduit le concept de collections pour organiser et manipuler efficacement des ensembles d'informations extraites. Les collections offrent des fonctionnalités avancées de gestion, d'indexation et de recherche.

#### 2.2.1 Structure d'une collection

Une collection d'informations extraites est représentée par une structure de données avec les propriétés suivantes :

```
ExtractedInfoCollection
├── _Type : string                 # Type de la collection (toujours "ExtractedInfoCollection")
├── Name : string                  # Nom de la collection
├── Description : string           # Description de la collection
├── Items : array                  # Tableau d'objets ExtractedInfo
├── Indexes : hashtable            # Index pour accélérer les recherches (optionnel)
├── Metadata : hashtable           # Métadonnées de la collection
├── CreationDate : datetime        # Date et heure de création de la collection
└── LastModifiedDate : datetime    # Date et heure de la dernière modification
```

#### 2.2.2 Système d'indexation

Les collections peuvent être optimisées avec un système d'indexation qui accélère considérablement les opérations de recherche et de filtrage. Les index sont organisés par type de propriété :

```
Indexes
├── ID : hashtable                 # Index par ID (clé: ID, valeur: objet ExtractedInfo)
├── Type : hashtable               # Index par type (clé: type, valeur: tableau d'IDs)
├── Source : hashtable             # Index par source (clé: source, valeur: tableau d'IDs)
└── ProcessingState : hashtable    # Index par état (clé: état, valeur: tableau d'IDs)
```

L'indexation est automatiquement maintenue à jour lors des opérations d'ajout, de mise à jour ou de suppression d'éléments dans la collection.

#### 2.2.3 Opérations sur les collections

Les collections supportent plusieurs opérations fondamentales :

1. **Création** : Initialisation d'une nouvelle collection vide ou avec des éléments initiaux.
   ```powershell
   $collection = New-ExtractedInfoCollection -Name "MaCollection" -CreateIndexes
   ```

2. **Ajout d'éléments** : Ajout d'un ou plusieurs éléments à la collection.
   ```powershell
   $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
   $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infoArray
   ```

3. **Récupération d'éléments** : Recherche et filtrage des éléments selon différents critères.
   ```powershell
   $item = Get-ExtractedInfoFromCollection -Collection $collection -Id "guid"
   $items = Get-ExtractedInfoFromCollection -Collection $collection -Source "Web" -ProcessingState "Processed"
   ```

4. **Statistiques** : Génération de statistiques sur le contenu de la collection.
   ```powershell
   $stats = Get-ExtractedInfoCollectionStatistics -Collection $collection
   ```

5. **Copie** : Création d'une copie profonde de la collection.
   ```powershell
   $newCollection = Copy-ExtractedInfoCollection -Collection $collection -Name "NouvelleCopie"
   ```

6. **Sérialisation** : Conversion de la collection en JSON pour persistance.
   ```powershell
   $json = ConvertTo-ExtractedInfoJson -Collection $collection
   Save-ExtractedInfoToFile -Collection $collection -FilePath "collection.json"
   ```

#### 2.2.4 Optimisation des performances

Les collections sont optimisées pour différents scénarios d'utilisation :

1. **Collections non indexées** : Pour les petites collections ou les cas où la mémoire est limitée.
   - Avantages : Consommation mémoire réduite, opérations d'ajout plus rapides.
   - Inconvénients : Recherches et filtrage plus lents (complexité O(n)).

2. **Collections indexées** : Pour les collections volumineuses ou les cas nécessitant des recherches fréquentes.
   - Avantages : Recherches et filtrage très rapides (complexité O(1) ou O(log n)).
   - Inconvénients : Consommation mémoire plus élevée, opérations d'ajout légèrement plus lentes.

Le choix entre ces deux modes dépend des besoins spécifiques de l'application et peut être fait lors de la création de la collection avec le paramètre `-CreateIndexes`.

### 2.3 Système de validation

Le module `ExtractedInfoModuleV2` intègre un système de validation robuste et extensible qui garantit l'intégrité et la cohérence des données à chaque étape du traitement.

#### 2.3.1 Architecture du système de validation

Le système de validation est organisé en plusieurs couches :

1. **Validation de base** : Vérification des propriétés communes à tous les types d'informations extraites.
2. **Validation spécifique au type** : Vérification des propriétés spécifiques à chaque type spécialisé.
3. **Validation personnalisée** : Règles de validation définies par l'utilisateur pour des besoins spécifiques.

Chaque couche de validation génère des erreurs qui sont collectées et peuvent être consultées pour diagnostiquer les problèmes.

#### 2.3.2 Règles de validation intégrées

Les règles de validation intégrées couvrent plusieurs aspects :

1. **Présence des propriétés requises** :
   ```powershell
   # Exemple de validation de propriétés requises
   if (-not $Info.ContainsKey("Source")) {
       $errors += "Missing required property: Source"
   }
   ```

2. **Types de données** :
   ```powershell
   # Exemple de validation de type de données
   if ($Info.ContainsKey("ConfidenceScore") -and $Info.ConfidenceScore -isnot [int]) {
       $errors += "Invalid property type: ConfidenceScore should be Integer"
   }
   ```

3. **Valeurs autorisées** :
   ```powershell
   # Exemple de validation de valeurs autorisées
   $validStates = @("Raw", "Processed", "Validated", "Error")
   if ($Info.ContainsKey("ProcessingState") -and -not $validStates.Contains($Info.ProcessingState)) {
       $errors += "Invalid ProcessingState value: $($Info.ProcessingState)"
   }
   ```

4. **Contraintes de valeur** :
   ```powershell
   # Exemple de validation de contraintes de valeur
   if ($Info.ContainsKey("ConfidenceScore") -and ($Info.ConfidenceScore -lt 0 -or $Info.ConfidenceScore -gt 100)) {
       $errors += "ConfidenceScore must be between 0 and 100"
   }
   ```

#### 2.3.3 Validation personnalisée

Le système permet d'ajouter des règles de validation personnalisées pour répondre à des besoins spécifiques :

```powershell
# Définition d'une règle de validation personnalisée
$customRule = {
    param($Info)

    $errors = @()

    # Exemple : Vérifier que le texte a une longueur minimale
    if ($Info._Type -eq "TextExtractedInfo" -and $Info.Text.Length -lt 10) {
        $errors += "Text must be at least 10 characters long"
    }

    return $errors
}

# Ajout de la règle au système de validation
Add-ExtractedInfoValidationRule -Name "MinTextLength" -Rule $customRule -TargetType "TextExtractedInfo"
```

Les règles personnalisées peuvent être :
- Globales (appliquées à tous les types)
- Spécifiques à un type particulier
- Temporaires (utilisées pour une validation ponctuelle)
- Permanentes (enregistrées dans le système pour toutes les validations futures)

#### 2.3.4 Fonctions de validation

Le module offre plusieurs fonctions pour effectuer la validation :

1. **Test-ExtractedInfo** : Vérifie si un objet d'information extraite est valide.
   ```powershell
   $isValid = Test-ExtractedInfo -Info $info
   ```

2. **Get-ExtractedInfoValidationErrors** : Récupère les erreurs de validation d'un objet.
   ```powershell
   $errors = Get-ExtractedInfoValidationErrors -Info $info
   ```

3. **Test-ExtractedInfoCollection** : Vérifie si une collection est valide.
   ```powershell
   $isValid = Test-ExtractedInfoCollection -Collection $collection -IncludeItemErrors
   ```

4. **Get-ExtractedInfoCollectionValidationErrors** : Récupère les erreurs de validation d'une collection.
   ```powershell
   $errors = Get-ExtractedInfoCollectionValidationErrors -Collection $collection -IncludeItemErrors
   ```

#### 2.3.5 Validation détaillée

Pour les cas nécessitant une analyse approfondie, le système peut fournir des résultats de validation détaillés :

```powershell
$validationResult = Test-ExtractedInfo -Info $info -Detailed
if (-not $validationResult.IsValid) {
    Write-Host "Validation failed for object of type $($validationResult.ObjectType)"
    foreach ($error in $validationResult.Errors) {
        Write-Host "- $error"
    }
}
```

Cette approche détaillée est particulièrement utile pour le débogage et l'analyse des problèmes de validation complexes.

### 2.4 Mécanisme de sérialisation

Le module `ExtractedInfoModuleV2` intègre un système complet de sérialisation qui permet de convertir les objets d'information extraite et les collections en format JSON pour la persistance et l'échange de données.

#### 2.4.1 Architecture du système de sérialisation

Le système de sérialisation est conçu pour être :

1. **Robuste** : Gestion correcte des types de données complexes et des caractères spéciaux.
2. **Complet** : Préservation de toutes les propriétés et relations entre les objets.
3. **Extensible** : Facilement adaptable pour prendre en charge de nouveaux types d'informations.
4. **Configurable** : Options pour contrôler le format et le contenu de la sortie.

#### 2.4.2 Conversion en JSON

La conversion des objets en JSON est réalisée par la fonction `ConvertTo-ExtractedInfoJson` qui prend en charge à la fois les objets individuels et les collections :

```powershell
# Conversion d'un objet individuel
$json = ConvertTo-ExtractedInfoJson -Info $info -Indent

# Conversion d'une collection
$json = ConvertTo-ExtractedInfoJson -Collection $collection -Indent -ExcludeIndexes
```

Options de configuration disponibles :

- **Indent** : Formatage indenté pour une meilleure lisibilité.
- **Depth** : Contrôle de la profondeur de sérialisation pour les structures imbriquées.
- **ExcludeMetadata** : Exclusion des métadonnées pour réduire la taille.
- **ExcludeIndexes** : Exclusion des index pour les collections (utile pour réduire la taille).

#### 2.4.3 Conversion depuis JSON

La conversion depuis JSON vers des objets est réalisée par la fonction `ConvertFrom-ExtractedInfoJson` :

```powershell
# Conversion d'un JSON en objet
$info = ConvertFrom-ExtractedInfoJson -Json $json

# Conversion avec options
$collection = ConvertFrom-ExtractedInfoJson -Json $json -AsHashtable
```

Options disponibles :

- **AsHashtable** : Conversion en hashtables plutôt qu'en objets PSCustomObject.
- **ValidateOnly** : Vérification de la validité du JSON sans effectuer la conversion complète.

#### 2.4.4 Persistance fichier

Pour faciliter la sauvegarde et le chargement des données, le module offre des fonctions dédiées :

```powershell
# Sauvegarde dans un fichier
Save-ExtractedInfoToFile -Info $info -FilePath "info.json" -Indent
Save-ExtractedInfoToFile -Collection $collection -FilePath "collection.json" -CreateDirectories

# Chargement depuis un fichier
$info = Load-ExtractedInfoFromFile -FilePath "info.json"
$collection = Load-ExtractedInfoFromFile -FilePath "collection.json"
```

Options disponibles :

- **CreateDirectories** : Création automatique des répertoires parents si nécessaire.
- **Force** : Écrasement des fichiers existants.
- **AsHashtable** : Chargement sous forme de hashtables.
- **ValidateOnly** : Vérification de la validité du fichier sans effectuer le chargement complet.

#### 2.4.5 Gestion des types spéciaux

Le système de sérialisation gère correctement plusieurs types de données spéciaux :

1. **Dates et heures** : Conversion des objets DateTime en chaînes ISO 8601 et vice-versa.
   ```json
   "ExtractionDate": "2023-05-15T10:30:00.0000000+02:00"
   ```

2. **Structures imbriquées** : Préservation des structures de données complexes.
   ```json
   "Data": {
     "Property1": "Value1",
     "NestedObject": {
       "SubProperty": "SubValue"
     },
     "Array": [1, 2, 3]
   }
   ```

3. **Caractères spéciaux** : Échappement correct des caractères spéciaux dans les chaînes.
   ```json
   "Text": "Texte avec des caractères spéciaux : \u00e9\u00e0\u00f9"
   ```

#### 2.4.6 Optimisation des performances

Pour les collections volumineuses, le système de sérialisation offre plusieurs optimisations :

1. **Sérialisation sélective** : Possibilité d'exclure certaines parties des objets (métadonnées, index).
2. **Contrôle de la profondeur** : Limitation de la profondeur de sérialisation pour les structures complexes.
3. **Format compact** : Option pour générer du JSON compact (sans indentation) pour réduire la taille.

Ces optimisations permettent de trouver un équilibre entre la richesse des données sérialisées et les performances de traitement.

## 3. Exemples d'utilisation

### 3.1 Extraction et stockage d'informations

Voici un exemple complet illustrant l'extraction d'informations à partir d'une page web, leur structuration et leur stockage :

```powershell
# Importer le module
Import-Module .\ExtractedInfoModuleV2.psm1

# Fonction d'extraction simple
function Extract-WebPageInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$ExtractorName = "WebExtractor"
    )

    try {
        # Télécharger le contenu de la page web
        $webClient = New-Object System.Net.WebClient
        $webClient.Encoding = [System.Text.Encoding]::UTF8
        $content = $webClient.DownloadString($Url)

        # Extraire le titre (exemple simple)
        $titleMatch = [regex]::Match($content, '<title>(.*?)</title>')
        $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Untitled" }

        # Extraire le texte principal (exemple simplifié)
        $bodyMatch = [regex]::Match($content, '<body.*?>(.*?)</body>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $bodyText = if ($bodyMatch.Success) {
            # Supprimer les balises HTML (simplification)
            $text = $bodyMatch.Groups[1].Value
            $text = [regex]::Replace($text, '<script.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            $text = [regex]::Replace($text, '<style.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            $text = [regex]::Replace($text, '<.*?>', ' ')
            $text = [regex]::Replace($text, '\s+', ' ')
            $text.Trim()
        } else {
            "No content found"
        }

        # Créer un objet TextExtractedInfo
        $extractedInfo = New-TextExtractedInfo -Source $Url -ExtractorName $ExtractorName -Text $bodyText

        # Ajouter des métadonnées
        $extractedInfo = Add-ExtractedInfoMetadata -Info $extractedInfo -Metadata @{
            Title = $title
            ExtractionDate = Get-Date
            ContentLength = $content.Length
            Url = $Url
        }

        return $extractedInfo
    }
    catch {
        Write-Error "Error extracting information from $Url : $_"
        return $null
    }
}

# Extraire des informations de plusieurs pages
$urls = @(
    "https://example.com",
    "https://example.org",
    "https://example.net"
)

$extractedInfos = @()
foreach ($url in $urls) {
    Write-Host "Extracting information from $url..."
    $info = Extract-WebPageInfo -Url $url
    if ($info) {
        $extractedInfos += $info
    }
}

# Créer une collection pour stocker les informations extraites
$collection = New-ExtractedInfoCollection -Name "WebPages" -Description "Collection of extracted web pages" -CreateIndexes

# Ajouter les informations extraites à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $extractedInfos

# Afficher des statistiques sur la collection
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection
Write-Host "Collection statistics:"
Write-Host "- Total items: $($stats.TotalCount)"
Write-Host "- Sources: $($stats.SourceDistribution.Keys -join ', ')"
Write-Host "- Average confidence score: $($stats.ConfidenceScoreStatistics.Average)"

# Sauvegarder la collection dans un fichier JSON
$outputPath = Join-Path $env:TEMP "WebPagesCollection.json"
Save-ExtractedInfoToFile -Collection $collection -FilePath $outputPath -Indent -CreateDirectories
Write-Host "Collection saved to $outputPath"

# Exemple de recherche dans la collection
$processedItems = Get-ExtractedInfoFromCollection -Collection $collection -ProcessingState "Raw" -MinConfidenceScore 50
Write-Host "Found $($processedItems.Count) items with raw processing state and confidence score >= 50"

# Mettre à jour l'état de traitement d'un élément
if ($processedItems.Count -gt 0) {
    $itemToUpdate = $processedItems[0]
    $updatedItem = Copy-ExtractedInfo -Info $itemToUpdate -ProcessingState "Processed" -ConfidenceScore 80
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $updatedItem
    Write-Host "Updated processing state of item $($updatedItem.Id) to Processed"
}

# Sauvegarder la collection mise à jour
Save-ExtractedInfoToFile -Collection $collection -FilePath $outputPath -Force
Write-Host "Updated collection saved to $outputPath"
```

Cet exemple illustre plusieurs aspects clés du module :

1. **Extraction d'informations** : Utilisation d'une fonction personnalisée pour extraire des informations de pages web.
2. **Création d'objets structurés** : Utilisation de `New-TextExtractedInfo` pour créer des objets d'information extraite.
3. **Ajout de métadonnées** : Enrichissement des informations avec des métadonnées contextuelles.
4. **Gestion de collections** : Création d'une collection et ajout d'informations.
5. **Statistiques** : Génération de statistiques sur la collection.
6. **Persistance** : Sauvegarde de la collection dans un fichier JSON.
7. **Recherche** : Filtrage des informations selon différents critères.
8. **Mise à jour** : Modification de l'état de traitement d'un élément.

### 3.2 Gestion de collections

Cet exemple illustre les opérations avancées sur les collections, notamment la création, la manipulation, le filtrage et l'analyse de collections d'informations extraites :

```powershell
# Importer le module
Import-Module .\ExtractedInfoModuleV2.psm1

# Créer une collection vide avec indexation
$collection = New-ExtractedInfoCollection -Name "DataCollection" -Description "Collection of various extracted data" -CreateIndexes

# Créer différents types d'informations extraites
$textInfo1 = New-TextExtractedInfo -Source "Document1.txt" -ExtractorName "TextExtractor" -Text "Ceci est un exemple de texte extrait." -Language "fr" -ProcessingState "Raw"
$textInfo2 = New-TextExtractedInfo -Source "Document2.txt" -ExtractorName "TextExtractor" -Text "This is an example of extracted text." -Language "en" -ProcessingState "Processed" -ConfidenceScore 85

$structuredInfo1 = New-StructuredDataExtractedInfo -Source "Data1.json" -ExtractorName "JsonExtractor" -Data @{
    Name = "John Doe"
    Age = 30
    Email = "john.doe@example.com"
    Address = @{
        Street = "123 Main St"
        City = "Anytown"
        Country = "USA"
    }
} -DataFormat "JSON" -ProcessingState "Validated" -ConfidenceScore 95

$mediaInfo1 = New-MediaExtractedInfo -Source "Image1.jpg" -ExtractorName "ImageExtractor" -MediaPath "C:\Images\image1.jpg" -MediaType "Image" -ProcessingState "Raw" -ConfidenceScore 70
$mediaInfo2 = New-MediaExtractedInfo -Source "Video1.mp4" -ExtractorName "VideoExtractor" -MediaPath "C:\Videos\video1.mp4" -MediaType "Video" -ProcessingState "Error" -ConfidenceScore 40

# Ajouter des métadonnées aux informations
$textInfo1 = Add-ExtractedInfoMetadata -Info $textInfo1 -Metadata @{
    Category = "Documentation"
    Tags = @("example", "text", "french")
    Priority = "Low"
}

$mediaInfo1 = Add-ExtractedInfoMetadata -Info $mediaInfo1 -Metadata @{
    Resolution = "1920x1080"
    FileSize = "2.5MB"
    Tags = @("example", "image", "high-res")
}

# Ajouter les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($textInfo1, $textInfo2, $structuredInfo1, $mediaInfo1, $mediaInfo2)

# Afficher des statistiques sur la collection
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection
Write-Host "Collection Statistics:"
Write-Host "- Total items: $($stats.TotalCount)"
Write-Host "- Types distribution: $($stats.TypeDistribution | ConvertTo-Json -Compress)"
Write-Host "- Processing states: $($stats.ProcessingStateDistribution | ConvertTo-Json -Compress)"
Write-Host "- Confidence score range: $($stats.ConfidenceScoreStatistics.Min) - $($stats.ConfidenceScoreStatistics.Max)"

# Filtrer la collection de différentes manières
Write-Host "`nFiltering examples:"

# 1. Filtrer par type
$textItems = Get-ExtractedInfoFromCollection -Collection $collection -Type "TextExtractedInfo"
Write-Host "Text items: $($textItems.Count)"

# 2. Filtrer par état de traitement
$rawItems = Get-ExtractedInfoFromCollection -Collection $collection -ProcessingState "Raw"
Write-Host "Raw items: $($rawItems.Count)"

# 3. Filtrer par score de confiance
$highConfidenceItems = Get-ExtractedInfoFromCollection -Collection $collection -MinConfidenceScore 80
Write-Host "High confidence items (>= 80): $($highConfidenceItems.Count)"

# 4. Filtrer par source
$documentItems = Get-ExtractedInfoFromCollection -Collection $collection -Source "Document1.txt"
Write-Host "Items from Document1.txt: $($documentItems.Count)"

# 5. Combinaison de filtres
$processedTextItems = Get-ExtractedInfoFromCollection -Collection $collection -Type "TextExtractedInfo" -ProcessingState "Processed"
Write-Host "Processed text items: $($processedTextItems.Count)"

# Manipuler la collection

# 1. Créer une sous-collection
$highQualityCollection = New-ExtractedInfoCollection -Name "HighQualityData" -Description "High quality extracted data" -CreateIndexes
$highQualityCollection = Add-ExtractedInfoToCollection -Collection $highQualityCollection -InfoList $highConfidenceItems
Write-Host "`nCreated high quality collection with $($highQualityCollection.Items.Count) items"

# 2. Mettre à jour un élément
$itemToUpdate = $rawItems[0]
$updatedItem = Copy-ExtractedInfo -Info $itemToUpdate -ProcessingState "Processed" -ConfidenceScore ($itemToUpdate.ConfidenceScore + 10)
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $updatedItem
Write-Host "Updated item $($updatedItem.Id) from Raw to Processed state"

# 3. Statistiques après mise à jour
$updatedStats = Get-ExtractedInfoCollectionStatistics -Collection $collection
Write-Host "Updated processing states: $($updatedStats.ProcessingStateDistribution | ConvertTo-Json -Compress)"

# 4. Copier la collection
$collectionCopy = Copy-ExtractedInfoCollection -Collection $collection -Name "DataCollectionCopy"
Write-Host "Created a copy of the collection with $($collectionCopy.Items.Count) items"

# 5. Ajouter des métadonnées à la collection
$collection.Metadata["CreatedBy"] = "Admin"
$collection.Metadata["Purpose"] = "Example"
$collection.Metadata["Tags"] = @("demo", "collection", "example")
$collection.LastModifiedDate = Get-Date
Write-Host "Added metadata to the collection"

# Sauvegarder les collections
$mainPath = Join-Path $env:TEMP "DataCollection.json"
$highQualityPath = Join-Path $env:TEMP "HighQualityCollection.json"

Save-ExtractedInfoToFile -Collection $collection -FilePath $mainPath -Indent -CreateDirectories
Save-ExtractedInfoToFile -Collection $highQualityCollection -FilePath $highQualityPath -Indent -CreateDirectories

Write-Host "`nCollections saved to:"
Write-Host "- Main collection: $mainPath"
Write-Host "- High quality collection: $highQualityPath"

# Charger une collection depuis un fichier
$loadedCollection = Load-ExtractedInfoFromFile -FilePath $mainPath
Write-Host "`nLoaded collection from file with $($loadedCollection.Items.Count) items"

# Analyser les métadonnées
$metadataTags = @{}
foreach ($item in $collection.Items) {
    if ($item.Metadata.ContainsKey("Tags")) {
        foreach ($tag in $item.Metadata.Tags) {
            if (-not $metadataTags.ContainsKey($tag)) {
                $metadataTags[$tag] = 0
            }
            $metadataTags[$tag]++
        }
    }
}

Write-Host "`nMetadata tags analysis:"
foreach ($tag in $metadataTags.Keys | Sort-Object) {
    Write-Host "- $tag : $($metadataTags[$tag]) items"
}
```

Cet exemple illustre plusieurs aspects avancés de la gestion des collections :

1. **Création de collections** : Création de collections avec indexation pour optimiser les performances.
2. **Ajout d'éléments variés** : Ajout de différents types d'informations extraites à une collection.
3. **Statistiques** : Génération et analyse de statistiques sur le contenu des collections.
4. **Filtrage avancé** : Utilisation de différents critères de filtrage, seuls ou combinés.
5. **Sous-collections** : Création de sous-collections basées sur des critères spécifiques.
6. **Mise à jour d'éléments** : Modification des propriétés d'éléments existants.
7. **Copie de collections** : Création de copies profondes de collections.
8. **Métadonnées** : Utilisation des métadonnées pour enrichir les informations et les collections.
9. **Persistance** : Sauvegarde et chargement de collections depuis des fichiers.
10. **Analyse avancée** : Extraction et analyse d'informations spécifiques à partir des collections.

### 3.3 Validation et correction

Cet exemple illustre l'utilisation du système de validation pour vérifier l'intégrité des informations extraites et corriger les problèmes détectés :

```powershell
# Importer le module
Import-Module .\ExtractedInfoModuleV2.psm1

# Fonction pour créer des informations extraites potentiellement invalides
function New-TestInfo {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Valid", "MissingSource", "InvalidConfidence", "InvalidState", "MissingText", "InvalidMediaType")]
        [string]$Type
    )

    switch ($Type) {
        "Valid" {
            # Créer une information valide
            return New-TextExtractedInfo -Source "ValidSource" -ExtractorName "TestExtractor" -Text "This is a valid text" -Language "en"
        }
        "MissingSource" {
            # Créer une information sans source (propriété requise)
            $info = New-TextExtractedInfo -Source "TempSource" -ExtractorName "TestExtractor" -Text "Text with missing source"
            $info.Remove("Source")
            return $info
        }
        "InvalidConfidence" {
            # Créer une information avec un score de confiance invalide
            return New-TextExtractedInfo -Source "InvalidConfidenceSource" -ExtractorName "TestExtractor" -Text "Text with invalid confidence" -ConfidenceScore 150
        }
        "InvalidState" {
            # Créer une information avec un état de traitement invalide
            $info = New-TextExtractedInfo -Source "InvalidStateSource" -ExtractorName "TestExtractor" -Text "Text with invalid state"
            $info.ProcessingState = "InvalidState"
            return $info
        }
        "MissingText" {
            # Créer une information de type texte sans texte (propriété requise pour ce type)
            $info = New-TextExtractedInfo -Source "MissingTextSource" -ExtractorName "TestExtractor" -Text "TempText"
            $info.Remove("Text")
            return $info
        }
        "InvalidMediaType" {
            # Créer une information média avec un type de média invalide
            $info = New-MediaExtractedInfo -Source "InvalidMediaTypeSource" -ExtractorName "MediaExtractor" -MediaPath "C:\path\to\media.xyz" -MediaType "InvalidType"
            return $info
        }
    }
}

# Créer une collection d'informations à valider
$infoTypes = @("Valid", "MissingSource", "InvalidConfidence", "InvalidState", "MissingText", "InvalidMediaType")
$infosToValidate = @()

foreach ($type in $infoTypes) {
    $info = New-TestInfo -Type $type
    $infosToValidate += $info
    Write-Host "Created test info of type: $type with ID: $($info.Id)"
}

# Créer une collection
$collection = New-ExtractedInfoCollection -Name "ValidationTestCollection"
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infosToValidate

Write-Host "`nCollection created with $($collection.Items.Count) items"

# 1. Validation simple
Write-Host "`n1. Simple validation results:"
foreach ($info in $infosToValidate) {
    $isValid = Test-ExtractedInfo -Info $info -ErrorAction SilentlyContinue
    Write-Host "Item $($info._Type) (ID: $($info.Id)): $(if ($isValid) { 'Valid' } else { 'Invalid' })"
}

# 2. Validation avec erreurs détaillées
Write-Host "`n2. Detailed validation errors:"
foreach ($info in $infosToValidate) {
    $errors = Get-ExtractedInfoValidationErrors -Info $info
    if ($errors.Count -gt 0) {
        Write-Host "Item $($info._Type) (ID: $($info.Id)) has $($errors.Count) validation errors:"
        foreach ($error in $errors) {
            Write-Host "  - $error"
        }
    }
    else {
        Write-Host "Item $($info._Type) (ID: $($info.Id)) is valid"
    }
}

# 3. Validation de collection
Write-Host "`n3. Collection validation:"
$collectionValid = Test-ExtractedInfoCollection -Collection $collection -ErrorAction SilentlyContinue
Write-Host "Collection is $(if ($collectionValid) { 'valid' } else { 'invalid' })"

# 4. Validation de collection avec erreurs d'éléments
$collectionErrors = Get-ExtractedInfoCollectionValidationErrors -Collection $collection -IncludeItemErrors
Write-Host "`n4. Collection validation with item errors:"
if ($collectionErrors.Count -gt 0) {
    Write-Host "Collection has validation errors:"
    foreach ($error in $collectionErrors) {
        Write-Host "  - $error"
    }
}
else {
    Write-Host "Collection structure is valid (ignoring item errors)"
}

# 5. Validation détaillée de collection
$detailedResult = Test-ExtractedInfoCollection -Collection $collection -IncludeItemErrors -Detailed
Write-Host "`n5. Detailed collection validation:"
Write-Host "Collection structure is $(if ($detailedResult.IsValid) { 'valid' } else { 'invalid' })"
if ($detailedResult.ItemErrors -and $detailedResult.ItemErrors.Count -gt 0) {
    Write-Host "Collection contains $($detailedResult.ItemErrors.Count) items with errors:"
    foreach ($itemError in $detailedResult.ItemErrors) {
        Write-Host "  Item at index $($itemError.ItemIndex) (ID: $($collection.Items[$itemError.ItemIndex].Id)):"
        foreach ($error in $itemError.Errors) {
            Write-Host "    - $error"
        }
    }
}

# 6. Correction automatique des problèmes
Write-Host "`n6. Automatic correction of validation issues:"

$correctedInfos = @()
foreach ($info in $infosToValidate) {
    $errors = Get-ExtractedInfoValidationErrors -Info $info

    if ($errors.Count -eq 0) {
        Write-Host "Item $($info._Type) (ID: $($info.Id)) is already valid, no correction needed"
        $correctedInfos += $info
        continue
    }

    # Créer une copie pour correction
    $correctedInfo = Copy-ExtractedInfo -Info $info
    $corrected = $false

    # Appliquer des corrections basées sur les erreurs
    foreach ($error in $errors) {
        if ($error -match "Missing required property: Source") {
            $correctedInfo.Source = "CorrectedSource"
            $corrected = $true
        }
        elseif ($error -match "ConfidenceScore must be between 0 and 100") {
            $correctedInfo.ConfidenceScore = 75
            $corrected = $true
        }
        elseif ($error -match "Invalid ProcessingState value") {
            $correctedInfo.ProcessingState = "Raw"
            $corrected = $true
        }
        elseif ($error -match "Missing required property: Text") {
            $correctedInfo.Text = "Corrected text content"
            $corrected = $true
        }
        elseif ($error -match "Invalid MediaType value") {
            $correctedInfo.MediaType = "Image"
            $corrected = $true
        }
    }

    if ($corrected) {
        Write-Host "Corrected item $($info._Type) (ID: $($correctedInfo.Id))"

        # Vérifier si la correction a résolu tous les problèmes
        $remainingErrors = Get-ExtractedInfoValidationErrors -Info $correctedInfo
        if ($remainingErrors.Count -eq 0) {
            Write-Host "  All validation issues resolved"
        }
        else {
            Write-Host "  Some validation issues remain: $($remainingErrors.Count) errors"
            foreach ($error in $remainingErrors) {
                Write-Host "    - $error"
            }
        }

        $correctedInfos += $correctedInfo
    }
    else {
        Write-Host "Could not correct item $($info._Type) (ID: $($info.Id))"
        $correctedInfos += $info
    }
}

# 7. Créer une collection corrigée
$correctedCollection = New-ExtractedInfoCollection -Name "CorrectedCollection"
$correctedCollection = Add-ExtractedInfoToCollection -Collection $correctedCollection -InfoList $correctedInfos

# 8. Valider la collection corrigée
$correctedValid = Test-ExtractedInfoCollection -Collection $correctedCollection -IncludeItemErrors
Write-Host "`n7. Validation of corrected collection:"
Write-Host "Corrected collection is $(if ($correctedValid) { 'valid' } else { 'still invalid' })"

if (-not $correctedValid) {
    $remainingErrors = Get-ExtractedInfoCollectionValidationErrors -Collection $correctedCollection -IncludeItemErrors
    Write-Host "Remaining errors in corrected collection:"
    foreach ($error in $remainingErrors) {
        Write-Host "  - $error"
    }
}

# 9. Ajouter une règle de validation personnalisée
Write-Host "`n8. Custom validation rules:"

# Définir une règle personnalisée
$customRule = {
    param($Info)

    $errors = @()

    # Règle : Les textes doivent avoir au moins 20 caractères
    if ($Info._Type -eq "TextExtractedInfo" -and $Info.ContainsKey("Text") -and $Info.Text.Length -lt 20) {
        $errors += "Text must be at least 20 characters long"
    }

    # Règle : Les sources doivent commencer par "Valid" ou "Corrected"
    if ($Info.ContainsKey("Source") -and -not ($Info.Source -match "^(Valid|Corrected)")) {
        $errors += "Source must start with 'Valid' or 'Corrected'"
    }

    return $errors
}

# Ajouter la règle au système de validation
Add-ExtractedInfoValidationRule -Name "TextLengthAndSourceRule" -Rule $customRule

# Valider avec la règle personnalisée
foreach ($info in $correctedInfos) {
    $customErrors = Get-ExtractedInfoValidationErrors -Info $info

    if ($customErrors.Count -gt 0) {
        Write-Host "Item $($info._Type) (ID: $($info.Id)) has custom validation errors:"
        foreach ($error in $customErrors) {
            Write-Host "  - $error"
        }
    }
    else {
        Write-Host "Item $($info._Type) (ID: $($info.Id)) passes custom validation"
    }
}

# 10. Supprimer la règle personnalisée
Remove-ExtractedInfoValidationRule -Name "TextLengthAndSourceRule"
Write-Host "`nCustom validation rule removed"

# Sauvegarder les collections pour référence
$originalPath = Join-Path $env:TEMP "OriginalCollection.json"
$correctedPath = Join-Path $env:TEMP "CorrectedCollection.json"

Save-ExtractedInfoToFile -Collection $collection -FilePath $originalPath -Indent -CreateDirectories
Save-ExtractedInfoToFile -Collection $correctedCollection -FilePath $correctedPath -Indent -CreateDirectories

Write-Host "`nCollections saved to:"
Write-Host "- Original collection: $originalPath"
Write-Host "- Corrected collection: $correctedPath"
```

Cet exemple illustre plusieurs aspects du système de validation :

1. **Validation de base** : Vérification de la validité des objets d'information extraite.
2. **Détection d'erreurs** : Identification précise des problèmes de validation.
3. **Validation de collections** : Vérification de la validité des collections et de leurs éléments.
4. **Correction automatique** : Mise en œuvre de stratégies de correction basées sur les erreurs détectées.
5. **Règles personnalisées** : Définition et application de règles de validation spécifiques.
6. **Gestion des règles** : Ajout et suppression de règles de validation.
7. **Validation détaillée** : Utilisation des résultats de validation détaillés pour l'analyse et le débogage.
8. **Persistance** : Sauvegarde des collections originales et corrigées pour référence.

### 3.4 Sérialisation et désérialisation

Cet exemple illustre les fonctionnalités de sérialisation et désérialisation du module, permettant de convertir les objets d'information extraite en JSON et de les reconstituer à partir de JSON :

```powershell
# Importer le module
Import-Module .\ExtractedInfoModuleV2.psm1

# Créer des objets d'information extraite de différents types
$textInfo = New-TextExtractedInfo -Source "Document.txt" -ExtractorName "TextExtractor" -Text "Ceci est un exemple de texte pour la sérialisation." -Language "fr" -ProcessingState "Processed" -ConfidenceScore 85
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Metadata @{
    Category = "Documentation"
    Tags = @("example", "serialization", "text")
    Author = "System"
}

$structuredInfo = New-StructuredDataExtractedInfo -Source "Data.json" -ExtractorName "JsonExtractor" -Data @{
    Person = @{
        FirstName = "John"
        LastName = "Doe"
        Age = 30
        Contact = @{
            Email = "john.doe@example.com"
            Phone = "+1234567890"
        }
    }
    Addresses = @(
        @{
            Type = "Home"
            Street = "123 Main St"
            City = "Anytown"
            Country = "USA"
        },
        @{
            Type = "Work"
            Street = "456 Business Ave"
            City = "Worktown"
            Country = "USA"
        }
    )
    Active = $true
    LastLogin = Get-Date
} -DataFormat "JSON" -ProcessingState "Validated" -ConfidenceScore 95

$mediaInfo = New-MediaExtractedInfo -Source "Image.jpg" -ExtractorName "ImageExtractor" -MediaPath "C:\Images\example.jpg" -MediaType "Image" -MediaSize 1024000 -ProcessingState "Raw" -ConfidenceScore 70

# Créer une collection
$collection = New-ExtractedInfoCollection -Name "SerializationExample" -Description "Collection for serialization demonstration" -CreateIndexes
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($textInfo, $structuredInfo, $mediaInfo)
$collection.Metadata["CreatedBy"] = "SerializationDemo"
$collection.Metadata["Purpose"] = "Demonstration"

# 1. Sérialisation d'objets individuels
Write-Host "1. Serializing individual objects to JSON:`n"

# Sérialiser un objet TextExtractedInfo
$textInfoJson = ConvertTo-ExtractedInfoJson -Info $textInfo -Indent
Write-Host "TextExtractedInfo JSON (first 500 chars):"
Write-Host ($textInfoJson.Substring(0, [Math]::Min(500, $textInfoJson.Length)) + "...")

# Sérialiser un objet StructuredDataExtractedInfo
$structuredInfoJson = ConvertTo-ExtractedInfoJson -Info $structuredInfo -Indent
Write-Host "`nStructuredDataExtractedInfo JSON (first 500 chars):"
Write-Host ($structuredInfoJson.Substring(0, [Math]::Min(500, $structuredInfoJson.Length)) + "...")

# Sérialiser un objet MediaExtractedInfo
$mediaInfoJson = ConvertTo-ExtractedInfoJson -Info $mediaInfo -Indent
Write-Host "`nMediaExtractedInfo JSON (first 500 chars):"
Write-Host ($mediaInfoJson.Substring(0, [Math]::Min(500, $mediaInfoJson.Length)) + "...")

# 2. Sérialisation d'une collection
Write-Host "`n2. Serializing a collection to JSON:`n"

# Sérialiser la collection complète
$collectionJson = ConvertTo-ExtractedInfoJson -Collection $collection -Indent
Write-Host "Collection JSON (first 500 chars):"
Write-Host ($collectionJson.Substring(0, [Math]::Min(500, $collectionJson.Length)) + "...")

# Sérialiser la collection sans les index
$collectionNoIndexesJson = ConvertTo-ExtractedInfoJson -Collection $collection -Indent -ExcludeIndexes
Write-Host "`nCollection JSON without indexes (size comparison):"
Write-Host "- With indexes: $($collectionJson.Length) chars"
Write-Host "- Without indexes: $($collectionNoIndexesJson.Length) chars"
Write-Host "- Size reduction: $(100 - [Math]::Round(($collectionNoIndexesJson.Length / $collectionJson.Length) * 100, 2))%"

# 3. Désérialisation d'objets individuels
Write-Host "`n3. Deserializing individual objects from JSON:`n"

# Désérialiser un objet TextExtractedInfo
$deserializedTextInfo = ConvertFrom-ExtractedInfoJson -Json $textInfoJson
Write-Host "Deserialized TextExtractedInfo:"
Write-Host "- Type: $($deserializedTextInfo._Type)"
Write-Host "- ID: $($deserializedTextInfo.Id)"
Write-Host "- Text (first 50 chars): $($deserializedTextInfo.Text.Substring(0, [Math]::Min(50, $deserializedTextInfo.Text.Length)))..."
Write-Host "- Metadata keys: $($deserializedTextInfo.Metadata.Keys -join ', ')"

# Désérialiser un objet StructuredDataExtractedInfo
$deserializedStructuredInfo = ConvertFrom-ExtractedInfoJson -Json $structuredInfoJson
Write-Host "`nDeserialized StructuredDataExtractedInfo:"
Write-Host "- Type: $($deserializedStructuredInfo._Type)"
Write-Host "- ID: $($deserializedStructuredInfo.Id)"
Write-Host "- Data format: $($deserializedStructuredInfo.DataFormat)"
Write-Host "- Person name: $($deserializedStructuredInfo.Data.Person.FirstName) $($deserializedStructuredInfo.Data.Person.LastName)"
Write-Host "- Number of addresses: $($deserializedStructuredInfo.Data.Addresses.Count)"

# 4. Désérialisation d'une collection
Write-Host "`n4. Deserializing a collection from JSON:`n"

# Désérialiser la collection
$deserializedCollection = ConvertFrom-ExtractedInfoJson -Json $collectionJson
Write-Host "Deserialized Collection:"
Write-Host "- Name: $($deserializedCollection.Name)"
Write-Host "- Description: $($deserializedCollection.Description)"
Write-Host "- Number of items: $($deserializedCollection.Items.Count)"
Write-Host "- Has indexes: $(if ($deserializedCollection.Indexes) { 'Yes' } else { 'No' })"
if ($deserializedCollection.Indexes) {
    Write-Host "- Index types: $($deserializedCollection.Indexes.Keys -join ', ')"
}
Write-Host "- Metadata: $($deserializedCollection.Metadata | ConvertTo-Json -Compress)"

# 5. Désérialisation avec options
Write-Host "`n5. Deserialization with options:`n"

# Désérialiser en hashtable
$deserializedAsHashtable = ConvertFrom-ExtractedInfoJson -Json $textInfoJson -AsHashtable
Write-Host "Deserialized as hashtable:"
Write-Host "- Object type: $($deserializedAsHashtable.GetType().Name)"
Write-Host "- Keys: $($deserializedAsHashtable.Keys -join ', ')"

# Validation uniquement
$isValidJson = ConvertFrom-ExtractedInfoJson -Json $structuredInfoJson -ValidateOnly
Write-Host "`nJSON validation result: $(if ($isValidJson) { 'Valid' } else { 'Invalid' })"

# 6. Persistance fichier
Write-Host "`n6. File persistence:`n"

# Définir les chemins de fichier
$tempFolder = Join-Path $env:TEMP "ExtractedInfoDemo"
if (-not (Test-Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory | Out-Null
}

$textInfoPath = Join-Path $tempFolder "TextInfo.json"
$structuredInfoPath = Join-Path $tempFolder "StructuredInfo.json"
$collectionPath = Join-Path $tempFolder "Collection.json"
$compactCollectionPath = Join-Path $tempFolder "CompactCollection.json"

# Sauvegarder les objets dans des fichiers
Save-ExtractedInfoToFile -Info $textInfo -FilePath $textInfoPath -Indent -CreateDirectories
Save-ExtractedInfoToFile -Info $structuredInfo -FilePath $structuredInfoPath -Indent -CreateDirectories
Save-ExtractedInfoToFile -Collection $collection -FilePath $collectionPath -Indent -CreateDirectories
Save-ExtractedInfoToFile -Collection $collection -FilePath $compactCollectionPath -CreateDirectories -ExcludeIndexes

Write-Host "Files saved to:"
Write-Host "- Text info: $textInfoPath"
Write-Host "- Structured info: $structuredInfoPath"
Write-Host "- Collection (with indexes): $collectionPath"
Write-Host "- Collection (compact, no indexes): $compactCollectionPath"

# Afficher les tailles de fichier
$textInfoSize = (Get-Item $textInfoPath).Length
$structuredInfoSize = (Get-Item $structuredInfoPath).Length
$collectionSize = (Get-Item $collectionPath).Length
$compactCollectionSize = (Get-Item $compactCollectionPath).Length

Write-Host "`nFile sizes:"
Write-Host "- Text info: $([Math]::Round($textInfoSize / 1KB, 2)) KB"
Write-Host "- Structured info: $([Math]::Round($structuredInfoSize / 1KB, 2)) KB"
Write-Host "- Collection (with indexes): $([Math]::Round($collectionSize / 1KB, 2)) KB"
Write-Host "- Collection (compact, no indexes): $([Math]::Round($compactCollectionSize / 1KB, 2)) KB"
Write-Host "- Size reduction: $(100 - [Math]::Round(($compactCollectionSize / $collectionSize) * 100, 2))%"

# 7. Chargement depuis des fichiers
Write-Host "`n7. Loading from files:`n"

# Charger les objets depuis les fichiers
$loadedTextInfo = Load-ExtractedInfoFromFile -FilePath $textInfoPath
$loadedStructuredInfo = Load-ExtractedInfoFromFile -FilePath $structuredInfoPath
$loadedCollection = Load-ExtractedInfoFromFile -FilePath $collectionPath
$loadedCompactCollection = Load-ExtractedInfoFromFile -FilePath $compactCollectionPath

Write-Host "Loaded objects:"
Write-Host "- Text info: $($loadedTextInfo._Type) (ID: $($loadedTextInfo.Id))"
Write-Host "- Structured info: $($loadedStructuredInfo._Type) (ID: $($loadedStructuredInfo.Id))"
Write-Host "- Collection: $($loadedCollection.Name) with $($loadedCollection.Items.Count) items"
Write-Host "- Compact collection: $($loadedCompactCollection.Name) with $($loadedCompactCollection.Items.Count) items"

# Vérifier si les index ont été chargés
Write-Host "`nIndexes status:"
Write-Host "- Collection with indexes: $(if ($loadedCollection.Indexes) { 'Present' } else { 'Missing' })"
Write-Host "- Compact collection: $(if ($loadedCompactCollection.Indexes) { 'Present' } else { 'Missing' })"

# 8. Validation de fichier
Write-Host "`n8. File validation:`n"

# Valider les fichiers sans les charger
$textInfoValid = Load-ExtractedInfoFromFile -FilePath $textInfoPath -ValidateOnly
$structuredInfoValid = Load-ExtractedInfoFromFile -FilePath $structuredInfoPath -ValidateOnly
$collectionValid = Load-ExtractedInfoFromFile -FilePath $collectionPath -ValidateOnly

Write-Host "File validation results:"
Write-Host "- Text info: $(if ($textInfoValid) { 'Valid' } else { 'Invalid' })"
Write-Host "- Structured info: $(if ($structuredInfoValid) { 'Valid' } else { 'Invalid' })"
Write-Host "- Collection: $(if ($collectionValid) { 'Valid' } else { 'Invalid' })"

# 9. Gestion des caractères spéciaux
Write-Host "`n9. Special characters handling:`n"

# Créer un objet avec des caractères spéciaux
$specialCharsInfo = New-TextExtractedInfo -Source "SpecialChars.txt" -ExtractorName "TextExtractor" -Text "Texte avec caractères spéciaux: àéèêëìíîïòóôõöùúûüýÿ et symboles: !@#$%^&*()_+-=[]{}|;':\",./<>?"
$specialCharsJson = ConvertTo-ExtractedInfoJson -Info $specialCharsInfo -Indent

Write-Host "Special characters JSON (excerpt):"
Write-Host ($specialCharsJson.Substring(0, [Math]::Min(500, $specialCharsJson.Length)) + "...")

# Désérialiser et vérifier
$deserializedSpecialChars = ConvertFrom-ExtractedInfoJson -Json $specialCharsJson
Write-Host "`nDeserialized special characters text:"
Write-Host $deserializedSpecialChars.Text

# 10. Sérialisation/désérialisation en boucle
Write-Host "`n10. Round-trip serialization test:`n"

# Effectuer plusieurs cycles de sérialisation/désérialisation
$originalObject = $structuredInfo
$currentObject = $originalObject
$cycles = 5

for ($i = 1; $i -le $cycles; $i++) {
    # Sérialiser
    $json = ConvertTo-ExtractedInfoJson -Info $currentObject

    # Désérialiser
    $currentObject = ConvertFrom-ExtractedInfoJson -Json $json

    # Vérifier l'intégrité
    $isValid = Test-ExtractedInfo -Info $currentObject

    Write-Host "Cycle $i - Object valid: $isValid, ID preserved: $(if ($currentObject.Id -eq $originalObject.Id) { 'Yes' } else { 'No' })"
}

# Vérifier les données complexes après plusieurs cycles
$finalObject = $currentObject
Write-Host "`nData integrity after $cycles cycles:"
Write-Host "- Person name: $($finalObject.Data.Person.FirstName) $($finalObject.Data.Person.LastName)"
Write-Host "- Number of addresses: $($finalObject.Data.Addresses.Count)"
Write-Host "- First address: $($finalObject.Data.Addresses[0].Street), $($finalObject.Data.Addresses[0].City)"
```

Cet exemple illustre les fonctionnalités complètes de sérialisation et désérialisation du module :

1. **Sérialisation d'objets** : Conversion d'objets d'information extraite en JSON.
2. **Sérialisation de collections** : Conversion de collections complètes en JSON, avec ou sans index.
3. **Désérialisation d'objets** : Reconstitution d'objets à partir de JSON.
4. **Désérialisation de collections** : Reconstitution de collections complètes à partir de JSON.
5. **Options de sérialisation** : Utilisation des différentes options pour contrôler le format et le contenu.
6. **Persistance fichier** : Sauvegarde et chargement d'objets et collections depuis des fichiers.
7. **Validation** : Vérification de la validité des fichiers JSON sans chargement complet.
8. **Gestion des caractères spéciaux** : Traitement correct des caractères spéciaux et symboles.
9. **Intégrité des données** : Préservation de l'intégrité des données à travers plusieurs cycles de sérialisation/désérialisation.
10. **Optimisation de taille** : Comparaison des différentes options pour réduire la taille des données sérialisées.
