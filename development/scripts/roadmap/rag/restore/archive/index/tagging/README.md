# Gestionnaire d'Etiquettes (Tags)

Ce module PowerShell fournit des fonctionnalites pour gerer les etiquettes (tags) des documents indexes.

## Fonctionnalites

- Ajout d'etiquettes a un document
- Suppression d'etiquettes d'un document
- Filtrage de documents par etiquettes
- Extraction des etiquettes uniques d'une collection de documents
- Suggestion d'etiquettes basees sur le contenu d'un document

## Installation

1. Copiez le fichier `TagManager.ps1` dans votre projet.
2. Importez le module avec la commande suivante :

```powershell
. "chemin/vers/TagManager.ps1"
```plaintext
## Utilisation

### Ajout d'etiquettes a un document

```powershell
$document = [PSCustomObject]@{
    id = "doc1"
    title = "Document de test"
    content = "Contenu du document de test"
    author = "Jean Dupont"
}

# Ajouter des etiquettes

$document = Add-DocumentTags -Document $document -Tags @("important", "documentation", "test")

# Ajouter des etiquettes avec Force (permet les doublons)

$document = Add-DocumentTags -Document $document -Tags @("urgent", "important") -Force
```plaintext
### Suppression d'etiquettes d'un document

```powershell
# Supprimer des etiquettes specifiques

$document = Remove-DocumentTags -Document $document -Tags @("documentation", "test")

# Supprimer toutes les etiquettes

$document = Remove-DocumentTags -Document $document -RemoveAll
```plaintext
### Filtrage de documents par etiquettes

```powershell
# Collection de documents

$documents = @(
    (New-TestDocument -Title "Document 1" -Tags @("important", "urgent", "client")),
    (New-TestDocument -Title "Document 2" -Tags @("documentation", "interne")),
    (New-TestDocument -Title "Document 3" -Tags @("important", "documentation")),
    (New-TestDocument -Title "Document 4" -Tags @("client", "contrat")),
    (New-TestDocument -Title "Document 5")
)

# Filtrer les documents qui ont au moins une des etiquettes specifiees

$filteredDocuments = Get-DocumentsByTags -Documents $documents -Tags @("important", "client") -MatchMode "Any"

# Filtrer les documents qui ont toutes les etiquettes specifiees

$filteredDocuments = Get-DocumentsByTags -Documents $documents -Tags @("important", "documentation") -MatchMode "All"

# Filtrer les documents qui n'ont aucune des etiquettes specifiees

$filteredDocuments = Get-DocumentsByTags -Documents $documents -Tags @("important", "client") -MatchMode "None"
```plaintext
### Extraction des etiquettes uniques

```powershell
# Extraire toutes les etiquettes uniques

$uniqueTags = Get-UniqueDocumentTags -Documents $documents

# Extraire toutes les etiquettes uniques avec leur nombre d'occurrences

$tagCounts = Get-UniqueDocumentTags -Documents $documents -IncludeCount
```plaintext
### Suggestion d'etiquettes

```powershell
# Suggerer des etiquettes basees sur le contenu d'un document

$document = [PSCustomObject]@{
    id = "doc1"
    title = "Rapport financier trimestriel"
    content = "Ce rapport présente les résultats financiers du trimestre. Les revenus ont augmenté de 15% par rapport au trimestre précédent. Les dépenses sont restées stables."
}

# Suggerer des etiquettes

$suggestedTags = Get-SuggestedTags -Document $document

# Suggerer des etiquettes en utilisant des documents similaires

$suggestedTags = Get-SuggestedTags -Document $document -SimilarDocuments $documents -MaxSuggestions 10
```plaintext
## Fonctions

### Add-DocumentTags

Ajoute des etiquettes a un document.

#### Parametres

- `Document` : Le document auquel on veut ajouter des etiquettes.
- `Tags` : Les etiquettes a ajouter.
- `Force` : Indique si les etiquettes dupliquees sont autorisees (par defaut : $false).

### Remove-DocumentTags

Supprime des etiquettes d'un document.

#### Parametres

- `Document` : Le document dont on veut supprimer des etiquettes.
- `Tags` : Les etiquettes a supprimer.
- `RemoveAll` : Indique si toutes les etiquettes doivent etre supprimees (par defaut : $false).

### Get-DocumentsByTags

Filtre des documents par etiquettes.

#### Parametres

- `Documents` : La collection de documents a filtrer.
- `Tags` : Les etiquettes a utiliser pour le filtrage.
- `MatchMode` : Le mode de correspondance (Any, All, None) (par defaut : Any).

### Get-UniqueDocumentTags

Extrait toutes les etiquettes uniques d'une collection de documents.

#### Parametres

- `Documents` : La collection de documents dont on veut extraire les etiquettes.
- `IncludeCount` : Indique si le nombre d'occurrences de chaque etiquette doit etre inclus (par defaut : $false).

### Get-SuggestedTags

Suggere des etiquettes basees sur le contenu d'un document.

#### Parametres

- `Document` : Le document pour lequel on veut suggerer des etiquettes.
- `SimilarDocuments` : Des documents similaires a utiliser pour la suggestion (par defaut : $null).
- `MaxSuggestions` : Le nombre maximum de suggestions a retourner (par defaut : 5).

## Exemple complet

Voir le fichier `RobustTagTest.ps1` pour un exemple complet d'utilisation du module.

## Algorithme de suggestion d'etiquettes

L'algorithme de suggestion d'etiquettes utilise plusieurs sources pour generer des suggestions pertinentes :

1. **Mots-cles du titre** : Les mots du titre du document sont extraits et recevront un score eleve (3 points).
2. **Mots-cles du contenu** : Les mots les plus frequents du contenu du document sont extraits et recevront un score base sur leur frequence (jusqu'a 2 points).
3. **Etiquettes des documents similaires** : Les etiquettes des documents similaires sont utilisees pour generer des suggestions, avec un score base sur leur frequence dans les documents similaires (jusqu'a 5 points).

Les etiquettes que le document possede deja sont exclues des suggestions. Les suggestions sont triees par score et les N meilleures sont retournees.

## Licence

Ce module est distribue sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
