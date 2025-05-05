# Exemple d'ajout d'une nouvelle fonctionnalité au module ExtractedInfoModuleV2

Ce document présente un exemple concret d'ajout d'une nouvelle fonctionnalité au module ExtractedInfoModuleV2, en suivant les conventions et bonnes pratiques établies.

## Cas d'utilisation : Fusion d'objets d'information extraite

### Problème à résoudre

Dans certains scénarios, les utilisateurs du module peuvent avoir besoin de fusionner plusieurs objets d'information extraite qui proviennent de la même source mais contiennent des informations complémentaires. Par exemple :

1. Un document a été analysé par plusieurs outils d'extraction différents, chacun fournissant des informations partielles.
2. Un même contenu a été traité à différents moments, avec des niveaux de confiance variables.
3. Des informations extraites doivent être enrichies avec des données provenant d'autres sources.

Actuellement, le module ne fournit pas de mécanisme simple pour fusionner ces objets, ce qui oblige les utilisateurs à manipuler manuellement les structures de données.

### Solution proposée

Implémenter une fonction `Merge-ExtractedInfo` qui permettra de fusionner deux ou plusieurs objets d'information extraite en un seul objet consolidé, en respectant les règles suivantes :

1. Les objets à fusionner doivent être du même type (TextExtractedInfo, StructuredDataExtractedInfo, etc.).
2. En cas de conflit entre les propriétés, plusieurs stratégies de résolution seront disponibles :
   - Priorité au premier objet
   - Priorité au dernier objet
   - Priorité à l'objet avec le score de confiance le plus élevé
   - Fusion des valeurs lorsque possible (ex: concaténation de textes, fusion de hashtables)
3. Les métadonnées seront combinées, avec possibilité de spécifier une stratégie de résolution pour les conflits.
4. Un nouveau score de confiance sera calculé en fonction des scores des objets fusionnés.

### Bénéfices attendus

- Simplification du traitement des informations extraites provenant de sources multiples
- Réduction du code dupliqué dans les scripts utilisant le module
- Amélioration de la qualité des données par la consolidation d'informations complémentaires
- Standardisation du processus de fusion pour garantir la cohérence des résultats

### Fonctionnalités à implémenter

1. **Fonction principale** : `Merge-ExtractedInfo`
   - Fusion de deux ou plusieurs objets d'information extraite
   - Gestion des conflits selon différentes stratégies

2. **Fonctions auxiliaires** :
   - `Merge-ExtractedInfoMetadata` : Fusion des métadonnées
   - `Get-MergedConfidenceScore` : Calcul du score de confiance fusionné
   - `Test-ExtractedInfoCompatibility` : Vérification de la compatibilité des objets à fusionner

3. **Tests** :
   - Tests unitaires pour chaque fonction
   - Tests d'intégration pour vérifier le comportement global

### Exemples d'utilisation prévus

```powershell
# Exemple 1: Fusion simple de deux objets TextExtractedInfo
$text1 = New-TextExtractedInfo -Source "document.txt" -Text "Première partie du texte." -Language "fr"
$text2 = New-TextExtractedInfo -Source "document.txt" -Text "Seconde partie du texte." -Language "fr"
$mergedText = Merge-ExtractedInfo -PrimaryInfo $text1 -SecondaryInfo $text2 -MergeStrategy "Combine"

# Exemple 2: Fusion avec priorité basée sur le score de confiance
$data1 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "John"; Age = 30 } -DataFormat "Hashtable"
$data1.ConfidenceScore = 70
$data2 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "John Doe"; Email = "john@example.com" } -DataFormat "Hashtable"
$data2.ConfidenceScore = 90
$mergedData = Merge-ExtractedInfo -PrimaryInfo $data1 -SecondaryInfo $data2 -MergeStrategy "HighestConfidence"

# Exemple 3: Fusion de plusieurs objets
$infoArray = @($text1, $text2, $text3)
$mergedInfo = Merge-ExtractedInfo -InfoArray $infoArray -MergeStrategy "LastWins"
```
