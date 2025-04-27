# Guide de gestion des cas ambigus

## Introduction

La dÃ©tection automatique de format peut parfois Ãªtre ambiguÃ«, c'est-Ã -dire que plusieurs formats peuvent correspondre Ã  un mÃªme fichier avec des scores de confiance similaires. Le module Format-Converters inclut un systÃ¨me avancÃ© pour gÃ©rer ces cas ambigus.

## Qu'est-ce qu'un cas ambigu ?

Un cas ambigu se produit lorsque la diffÃ©rence de score de confiance entre les deux meilleurs formats dÃ©tectÃ©s est infÃ©rieure Ã  un certain seuil (par dÃ©faut 20 points). Par exemple, si un fichier est dÃ©tectÃ© comme JSON avec un score de 75% et comme JavaScript avec un score de 65%, il s'agit d'un cas ambigu.

## Options de rÃ©solution

Le module Format-Converters offre plusieurs options pour rÃ©soudre les cas ambigus :

### 1. RÃ©solution automatique

Avec l'option `-AutoResolve`, le module choisit automatiquement le format avec la prioritÃ© la plus Ã©levÃ©e parmi les formats ambigus. Chaque format a une prioritÃ© prÃ©dÃ©finie dans le fichier de critÃ¨res de dÃ©tection.

```powershell
Detect-FileFormat -FilePath "data.txt" -AutoResolve
```

### 2. Confirmation utilisateur

Sans l'option `-AutoResolve`, le module demande Ã  l'utilisateur de choisir le format correct parmi les options possibles. L'utilisateur voit les formats possibles avec leurs scores de confiance et peut faire un choix Ã©clairÃ©.

```powershell
Detect-FileFormat -FilePath "data.txt"
```

Exemple d'interface de confirmation :

```
Plusieurs formats possibles ont Ã©tÃ© dÃ©tectÃ©s.
Veuillez sÃ©lectionner le format correct :
  1. JSON (Score: 75%, PrioritÃ©: 10)
  2. JAVASCRIPT (Score: 65%, PrioritÃ©: 9)

Entrez le numÃ©ro du format (1-2) ou 'q' pour quitter:
```

### 3. MÃ©morisation des choix

Avec l'option `-RememberChoices`, le module mÃ©morise les choix de l'utilisateur pour les cas similaires. Cela permet d'Ã©viter de redemander Ã  l'utilisateur pour des cas similaires Ã  l'avenir.

```powershell
Detect-FileFormat -FilePath "data.txt" -RememberChoices
```

Les choix sont stockÃ©s dans un fichier JSON (`UserFormatChoices.json`) qui associe une clÃ© unique reprÃ©sentant le cas ambigu au format choisi par l'utilisateur.

## Affichage des dÃ©tails

L'option `-ShowDetails` permet d'afficher des informations dÃ©taillÃ©es sur la dÃ©tection, y compris tous les formats dÃ©tectÃ©s avec leurs scores de confiance et les critÃ¨res correspondants.

```powershell
Detect-FileFormat -FilePath "data.txt" -ShowDetails
```

Exemple de sortie dÃ©taillÃ©e :

```
RÃ©sultats de dÃ©tection de format pour 'data.txt'
Taille du fichier : 1024 octets
Type de fichier : Texte
Format dÃ©tectÃ©: JSON
Score de confiance: 75%
CritÃ¨res correspondants: Extension (.txt), Contenu ("\"\\w+\"\\s*:"), Structure ("\\{.*\\}")

Tous les formats dÃ©tectÃ©s:
  - JSON (Score: 75%, PrioritÃ©: 10)
    CritÃ¨res: Extension (.txt), Contenu ("\"\\w+\"\\s*:"), Structure ("\\{.*\\}")
  - JAVASCRIPT (Score: 65%, PrioritÃ©: 9)
    CritÃ¨res: Contenu ("var\\s+\\w+\\s*="), Structure ("\\{.*\\}")
```

## Personnalisation du seuil d'ambiguÃ¯tÃ©

Le seuil d'ambiguÃ¯tÃ© (la diffÃ©rence de score en dessous de laquelle deux formats sont considÃ©rÃ©s comme ambigus) peut Ãªtre personnalisÃ© en modifiant le paramÃ¨tre `AmbiguityThreshold` dans le script `Handle-AmbiguousFormats.ps1`.

```powershell
Handle-AmbiguousFormats -FilePath "data.txt" -AmbiguityThreshold 15
```

Un seuil plus bas rendra le systÃ¨me plus strict (plus de cas seront considÃ©rÃ©s comme ambigus), tandis qu'un seuil plus Ã©levÃ© le rendra plus permissif (moins de cas seront considÃ©rÃ©s comme ambigus).

## Exportation des rÃ©sultats

Les rÃ©sultats de dÃ©tection peuvent Ãªtre exportÃ©s dans diffÃ©rents formats (JSON, CSV, HTML) pour une analyse ultÃ©rieure ou pour la documentation.

```powershell
Detect-FileFormat -FilePath "data.txt" -ShowDetails -ExportResults -ExportFormat "HTML"
```

L'exportation HTML inclut une visualisation conviviale des formats dÃ©tectÃ©s avec leurs scores de confiance et les critÃ¨res correspondants.

## Bonnes pratiques

1. **Utilisez `-AutoResolve` pour les scripts automatisÃ©s** : Cela Ã©vite les interruptions pour demander une confirmation utilisateur.
2. **Utilisez `-ShowDetails` pour le dÃ©bogage** : Cela permet de voir pourquoi un fichier est considÃ©rÃ© comme ambigu.
3. **Utilisez `-RememberChoices` pour les utilisateurs rÃ©guliers** : Cela amÃ©liore l'expÃ©rience utilisateur en Ã©vitant de redemander pour des cas similaires.
4. **Personnalisez les critÃ¨res de dÃ©tection** : Si vous rencontrez souvent des cas ambigus pour certains formats, ajustez les critÃ¨res de dÃ©tection dans le fichier `FormatDetectionCriteria.json`.

## Exemples de cas ambigus courants

1. **JSON vs JavaScript** : Les fichiers JSON peuvent Ãªtre confondus avec des fichiers JavaScript, car ils partagent une syntaxe similaire.
2. **XML vs HTML** : Les fichiers XML peuvent Ãªtre confondus avec des fichiers HTML, car HTML est un sous-ensemble de XML.
3. **CSV vs Texte** : Les fichiers CSV peuvent Ãªtre confondus avec des fichiers texte, surtout s'ils ont peu de colonnes.
4. **YAML vs Texte** : Les fichiers YAML peuvent Ãªtre confondus avec des fichiers texte, car ils utilisent une syntaxe lisible par l'homme.

## Conclusion

La gestion des cas ambigus est une fonctionnalitÃ© puissante du module Format-Converters qui permet de dÃ©tecter avec prÃ©cision le format d'un fichier, mÃªme dans les cas difficiles. En utilisant les options de rÃ©solution automatique, de confirmation utilisateur et de mÃ©morisation des choix, vous pouvez adapter le comportement du module Ã  vos besoins spÃ©cifiques.
