# Fonctions d'analyse statistique

Ce répertoire contient des fonctions pour l'analyse statistique des objets d'information extraite.

## Get-ExtractedInfoStatistics

La fonction `Get-ExtractedInfoStatistics` génère des statistiques détaillées sur des objets d'information extraite ou des collections d'objets d'information extraite.

### Syntaxe

```powershell
Get-ExtractedInfoStatistics -Info <hashtable> [-StatisticsType <string>] [-IncludeMetadata] [-OutputFormat <string>]
```

```powershell
Get-ExtractedInfoStatistics -Collection <hashtable> [-StatisticsType <string>] [-IncludeMetadata] [-OutputFormat <string>]
```

### Description

La fonction `Get-ExtractedInfoStatistics` analyse un objet d'information extraite ou une collection d'objets d'information extraite et génère des statistiques sur ces objets. Les statistiques peuvent inclure des informations sur le nombre d'éléments, les types, les sources, la distribution temporelle, les scores de confiance, la taille et la complexité du contenu, ainsi que les métadonnées.

### Paramètres

#### -Info

Un objet d'information extraite individuel à analyser. Ce paramètre est mutuellement exclusif avec le paramètre Collection.

```powershell
Type: Hashtable
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

#### -Collection

Une collection d'objets d'information extraite à analyser. Ce paramètre est mutuellement exclusif avec le paramètre Info.

```powershell
Type: Hashtable
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

#### -StatisticsType

Le type de statistiques à générer. Les valeurs possibles sont :

- **Basic** : Statistiques de base (nombre d'éléments, types, sources)
- **Temporal** : Statistiques temporelles (distribution par date d'extraction)
- **Confidence** : Statistiques de confiance (distribution des scores)
- **Content** : Statistiques de contenu (taille, complexité)
- **All** : Toutes les statistiques

La valeur par défaut est "Basic".

```powershell
Type: String
Position: Named
Default value: Basic
Accept pipeline input: False
Accept wildcard characters: False
```

#### -IncludeMetadata

Indique si les métadonnées doivent être incluses dans l'analyse statistique.

```powershell
Type: SwitchParameter
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

#### -OutputFormat

Le format de sortie des statistiques. Les valeurs possibles sont :

- **Text** : Format texte brut
- **HTML** : Format HTML
- **JSON** : Format JSON

La valeur par défaut est "Text".

```powershell
Type: String
Position: Named
Default value: Text
Accept pipeline input: False
Accept wildcard characters: False
```

### Types de statistiques

#### Statistiques de base (Basic)

- Distribution des types d'objets
- Distribution des sources
- Distribution des états de traitement
- Pourcentages pour chaque distribution
- Nombre de types, sources et états uniques

#### Statistiques temporelles (Temporal)

- Âge moyen des informations (en jours et en mois)
- Distribution par jour, mois, année, heure et jour de la semaine
- Périodes les plus actives (jour, mois, heure, jour de la semaine)

#### Statistiques de confiance (Confidence)

- Score de confiance moyen, médian, minimum et maximum
- Distribution des scores par plages
- Plage de confiance dominante

#### Statistiques de contenu (Content)

- Taille moyenne, médiane, minimum et maximum du contenu
- Taille totale de tous les contenus
- Distribution des tailles par plages
- Statistiques spécifiques aux types (par exemple, nombre de mots pour les textes)

#### Statistiques de métadonnées (avec IncludeMetadata)

- Nombre d'éléments avec métadonnées
- Nombre total d'éléments de métadonnées
- Moyenne de métadonnées par élément
- Clés de métadonnées les plus courantes
- Types de valeurs pour chaque clé de métadonnées

### Formats de sortie

#### Format texte (Text)

Génère un rapport textuel formaté avec des sections pour chaque type de statistiques.

#### Format HTML (HTML)

Génère un rapport HTML complet avec des tableaux et des sections stylisées pour chaque type de statistiques.

#### Format JSON (JSON)

Génère une représentation JSON des statistiques, utile pour l'intégration avec d'autres outils ou pour le traitement ultérieur.

### Exemples

#### Exemple 1 : Générer des statistiques de base sur un objet individuel

```powershell
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
Get-ExtractedInfoStatistics -Info $info -StatisticsType Basic
```

#### Exemple 2 : Générer toutes les statistiques sur une collection

```powershell
$collection = New-ExtractedInfoCollection -Name "Documents"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info2
Get-ExtractedInfoStatistics -Collection $collection -StatisticsType All -OutputFormat HTML
```

#### Exemple 3 : Générer des statistiques de confiance au format JSON

```powershell
$collection = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_.ProcessingState -eq "Processed" }
$stats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType Confidence -OutputFormat JSON
$stats | Out-File -FilePath "confidence_stats.json" -Encoding utf8
```

#### Exemple 4 : Générer des statistiques avec métadonnées

```powershell
$stats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType All -IncludeMetadata -OutputFormat Text
$stats | Out-File -FilePath "full_stats_report.txt" -Encoding utf8
```

### Remarques

- La fonction peut traiter tous les types d'objets d'information extraite (TextExtractedInfo, StructuredDataExtractedInfo, GeoLocationExtractedInfo, MediaExtractedInfo).
- Pour les collections volumineuses, l'analyse peut prendre un certain temps, surtout avec le type de statistiques "All".
- Le format HTML génère un rapport autonome qui peut être ouvert dans n'importe quel navigateur web.
- Les statistiques temporelles nécessitent que les objets aient une propriété ExtractedAt valide.
- Les statistiques de confiance nécessitent que les objets aient une propriété ConfidenceScore valide.

### Voir aussi

- [New-ExtractedInfoCollection](../Collection/New-ExtractedInfoCollection.md)
- [Add-ExtractedInfoToCollection](../Collection/Add-ExtractedInfoToCollection.md)
- [Get-ExtractedInfoFromCollection](../Collection/Get-ExtractedInfoFromCollection.md)
- [Add-ExtractedInfoMetadata](../Metadata/Add-ExtractedInfoMetadata.md)
