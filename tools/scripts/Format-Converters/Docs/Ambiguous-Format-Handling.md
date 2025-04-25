# Guide de gestion des cas ambigus

## Introduction

La détection automatique de format peut parfois être ambiguë, c'est-à-dire que plusieurs formats peuvent correspondre à un même fichier avec des scores de confiance similaires. Le module Format-Converters inclut un système avancé pour gérer ces cas ambigus.

## Qu'est-ce qu'un cas ambigu ?

Un cas ambigu se produit lorsque la différence de score de confiance entre les deux meilleurs formats détectés est inférieure à un certain seuil (par défaut 20 points). Par exemple, si un fichier est détecté comme JSON avec un score de 75% et comme JavaScript avec un score de 65%, il s'agit d'un cas ambigu.

## Options de résolution

Le module Format-Converters offre plusieurs options pour résoudre les cas ambigus :

### 1. Résolution automatique

Avec l'option `-AutoResolve`, le module choisit automatiquement le format avec la priorité la plus élevée parmi les formats ambigus. Chaque format a une priorité prédéfinie dans le fichier de critères de détection.

```powershell
Detect-FileFormat -FilePath "data.txt" -AutoResolve
```

### 2. Confirmation utilisateur

Sans l'option `-AutoResolve`, le module demande à l'utilisateur de choisir le format correct parmi les options possibles. L'utilisateur voit les formats possibles avec leurs scores de confiance et peut faire un choix éclairé.

```powershell
Detect-FileFormat -FilePath "data.txt"
```

Exemple d'interface de confirmation :

```
Plusieurs formats possibles ont été détectés.
Veuillez sélectionner le format correct :
  1. JSON (Score: 75%, Priorité: 10)
  2. JAVASCRIPT (Score: 65%, Priorité: 9)

Entrez le numéro du format (1-2) ou 'q' pour quitter:
```

### 3. Mémorisation des choix

Avec l'option `-RememberChoices`, le module mémorise les choix de l'utilisateur pour les cas similaires. Cela permet d'éviter de redemander à l'utilisateur pour des cas similaires à l'avenir.

```powershell
Detect-FileFormat -FilePath "data.txt" -RememberChoices
```

Les choix sont stockés dans un fichier JSON (`UserFormatChoices.json`) qui associe une clé unique représentant le cas ambigu au format choisi par l'utilisateur.

## Affichage des détails

L'option `-ShowDetails` permet d'afficher des informations détaillées sur la détection, y compris tous les formats détectés avec leurs scores de confiance et les critères correspondants.

```powershell
Detect-FileFormat -FilePath "data.txt" -ShowDetails
```

Exemple de sortie détaillée :

```
Résultats de détection de format pour 'data.txt'
Taille du fichier : 1024 octets
Type de fichier : Texte
Format détecté: JSON
Score de confiance: 75%
Critères correspondants: Extension (.txt), Contenu ("\"\\w+\"\\s*:"), Structure ("\\{.*\\}")

Tous les formats détectés:
  - JSON (Score: 75%, Priorité: 10)
    Critères: Extension (.txt), Contenu ("\"\\w+\"\\s*:"), Structure ("\\{.*\\}")
  - JAVASCRIPT (Score: 65%, Priorité: 9)
    Critères: Contenu ("var\\s+\\w+\\s*="), Structure ("\\{.*\\}")
```

## Personnalisation du seuil d'ambiguïté

Le seuil d'ambiguïté (la différence de score en dessous de laquelle deux formats sont considérés comme ambigus) peut être personnalisé en modifiant le paramètre `AmbiguityThreshold` dans le script `Handle-AmbiguousFormats.ps1`.

```powershell
Handle-AmbiguousFormats -FilePath "data.txt" -AmbiguityThreshold 15
```

Un seuil plus bas rendra le système plus strict (plus de cas seront considérés comme ambigus), tandis qu'un seuil plus élevé le rendra plus permissif (moins de cas seront considérés comme ambigus).

## Exportation des résultats

Les résultats de détection peuvent être exportés dans différents formats (JSON, CSV, HTML) pour une analyse ultérieure ou pour la documentation.

```powershell
Detect-FileFormat -FilePath "data.txt" -ShowDetails -ExportResults -ExportFormat "HTML"
```

L'exportation HTML inclut une visualisation conviviale des formats détectés avec leurs scores de confiance et les critères correspondants.

## Bonnes pratiques

1. **Utilisez `-AutoResolve` pour les scripts automatisés** : Cela évite les interruptions pour demander une confirmation utilisateur.
2. **Utilisez `-ShowDetails` pour le débogage** : Cela permet de voir pourquoi un fichier est considéré comme ambigu.
3. **Utilisez `-RememberChoices` pour les utilisateurs réguliers** : Cela améliore l'expérience utilisateur en évitant de redemander pour des cas similaires.
4. **Personnalisez les critères de détection** : Si vous rencontrez souvent des cas ambigus pour certains formats, ajustez les critères de détection dans le fichier `FormatDetectionCriteria.json`.

## Exemples de cas ambigus courants

1. **JSON vs JavaScript** : Les fichiers JSON peuvent être confondus avec des fichiers JavaScript, car ils partagent une syntaxe similaire.
2. **XML vs HTML** : Les fichiers XML peuvent être confondus avec des fichiers HTML, car HTML est un sous-ensemble de XML.
3. **CSV vs Texte** : Les fichiers CSV peuvent être confondus avec des fichiers texte, surtout s'ils ont peu de colonnes.
4. **YAML vs Texte** : Les fichiers YAML peuvent être confondus avec des fichiers texte, car ils utilisent une syntaxe lisible par l'homme.

## Conclusion

La gestion des cas ambigus est une fonctionnalité puissante du module Format-Converters qui permet de détecter avec précision le format d'un fichier, même dans les cas difficiles. En utilisant les options de résolution automatique, de confirmation utilisateur et de mémorisation des choix, vous pouvez adapter le comportement du module à vos besoins spécifiques.
