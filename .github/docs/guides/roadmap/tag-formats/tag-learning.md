# Apprentissage des nouveaux formats de tags

## Introduction

Le système d'apprentissage des nouveaux formats de tags permet de détecter automatiquement les formats de tags non reconnus dans les roadmaps et de les ajouter à la configuration. Cette fonctionnalité facilite l'évolution du système de tags sans nécessiter de modifications manuelles de la configuration.

## Fonctionnement

Le processus d'apprentissage des nouveaux formats de tags se déroule en plusieurs étapes :

1. **Chargement de la configuration** : Chargement des formats de tags existants
2. **Détection des tâches** : Analyse du contenu pour identifier les tâches
3. **Détection des potentiels nouveaux formats** : Recherche de patterns de tags non reconnus
4. **Création de patterns regex** : Génération d'expressions régulières pour les nouveaux formats
5. **Ajout à la configuration** : Intégration des nouveaux formats dans la configuration

## Utilisation du script Learn-NewTagFormats.ps1

Le script `Learn-NewTagFormats.ps1` permet d'apprendre et d'ajouter automatiquement de nouveaux formats de tags.

### Paramètres

- **FilePath** : Chemin du fichier à analyser
- **Content** : Contenu à analyser (alternative à FilePath)
- **ConfigPath** : Chemin du fichier de configuration des formats de tags
- **OutputPath** : Chemin du fichier de sortie pour le rapport d'apprentissage
- **Mode** : Mode d'apprentissage (Auto, Interactive, Silent)
- **ConfidenceThreshold** : Seuil de confiance pour l'ajout automatique (mode Auto)
- **Force** : Forcer l'opération

### Modes d'apprentissage

Le script propose trois modes d'apprentissage :

- **Auto** : Ajoute automatiquement les formats détectés avec un nombre d'occurrences supérieur au seuil
- **Interactive** : Demande confirmation à l'utilisateur pour chaque nouveau format détecté
- **Silent** : Ajoute tous les nouveaux formats détectés sans confirmation

### Exemples d'utilisation

#### Apprentissage interactif à partir d'un fichier

```powershell
.\Learn-NewTagFormats.ps1 -FilePath "path\to\roadmap.md" -ConfigPath "path\to\config.json" -Mode "Interactive"
```

#### Apprentissage automatique à partir d'un contenu

```powershell
$content = Get-Content -Path "path\to\roadmap.md" -Raw
.\Learn-NewTagFormats.ps1 -Content $content -ConfigPath "path\to\config.json" -Mode "Auto" -ConfidenceThreshold 0.7
```

#### Apprentissage silencieux avec rapport

```powershell
.\Learn-NewTagFormats.ps1 -FilePath "path\to\roadmap.md" -ConfigPath "path\to\config.json" -Mode "Silent" -OutputPath "path\to\report.md"
```

## Détection des potentiels nouveaux formats

Le système utilise plusieurs patterns génériques pour détecter les potentiels nouveaux formats de tags :

- **Format général** : `#tag:value` ou `#tag(value)`
- **Format de durée** : `#tag:Xunit` ou `#tag(Xunit)`
- **Format composite** : `#tag:Xunit1Yunit2`

Ces patterns permettent de détecter une grande variété de formats de tags, même s'ils n'ont pas été définis explicitement dans la configuration.

## Création de patterns regex

Pour chaque nouveau format détecté, le système génère une expression régulière adaptée en fonction du type de format :

- **Format général** : Expression régulière pour capturer la valeur
- **Format de durée** : Expression régulière pour capturer la valeur numérique et l'unité
- **Format composite** : Expression régulière pour capturer plusieurs valeurs et unités

Le système détermine également automatiquement les unités en fonction des suffixes utilisés (j/d pour jours, h pour heures, etc.).

## Ajout à la configuration

Les nouveaux formats sont ajoutés à la configuration avec les informations suivantes :

- **Nom** : Nom unique généré automatiquement
- **Pattern** : Expression régulière générée
- **Description** : Description générée en fonction du format
- **Exemple** : Exemple basé sur le format détecté
- **Groupe de valeur** : Numéro du groupe de capture pour la valeur
- **Unité** : Unité déterminée automatiquement

Pour les formats composites, des informations supplémentaires sont ajoutées :
- **Composite** : Indique qu'il s'agit d'un format composite
- **Groupes de valeurs** : Liste des numéros des groupes de capture
- **Unités** : Liste des unités correspondantes

## Rapport d'apprentissage

Le script peut générer un rapport détaillé sur les formats appris, qui inclut :

- **Résumé** : Nombre de tâches analysées, formats détectés et ajoutés
- **Formats ajoutés** : Liste des formats ajoutés avec leurs détails

Exemple de rapport :

```markdown
# Rapport d'apprentissage des formats de tags

## Résumé

- Nombre de tâches analysées: 7
- Nombre de nouveaux formats détectés: 5
- Nombre de formats ajoutés: 3

## Formats ajoutés

### Type: temps, Format: temps_1

- Description: Format #temps:Xj (jours)
- Exemple: #temps:2j

### Type: duration, Format: duration_2

- Description: Format #duration:XdYh (jours et heures)
- Exemple: #duration:2d4h

### Type: priority, Format: priority_1

- Description: Format #priority:value
- Exemple: #priority:high
```

## Utilisation programmatique

Vous pouvez également utiliser les fonctions du script dans vos propres scripts PowerShell.

```powershell
# Charger les fonctions du script
. "path\to\Learn-NewTagFormats.ps1"

# Charger la configuration
$config = Get-TagFormatsConfig -ConfigPath "path\to\config.json"

# Détecter les tâches dans le contenu
$content = Get-Content -Path "path\to\roadmap.md" -Raw
$tasks = Get-TasksFromContent -Content $content

# Détecter les potentiels nouveaux formats
$detectedFormats = Detect-PotentialTagFormats -Tasks $tasks -TagFormats $config

# Créer des patterns regex
$newPatterns = Create-RegexPatterns -DetectedFormats $detectedFormats

# Ajouter les nouveaux formats à la configuration
$addedFormats = Add-NewFormatsToConfig -Config $config -NewPatterns $newPatterns -Mode "Silent"

# Sauvegarder la configuration mise à jour
Save-TagFormatsConfig -Config $config -ConfigPath "path\to\config.json"
```

## Bonnes pratiques

### Apprentissage initial

Pour initialiser votre système de tags, suivez ces étapes :

1. Créez une configuration de base avec les formats les plus courants
2. Exécutez le script en mode Interactive sur plusieurs roadmaps représentatives
3. Validez et ajustez les formats ajoutés si nécessaire
4. Sauvegardez la configuration enrichie

### Apprentissage continu

Pour maintenir votre système de tags à jour :

1. Exécutez régulièrement le script en mode Auto sur les nouvelles roadmaps
2. Vérifiez les rapports d'apprentissage pour identifier les tendances
3. Ajustez manuellement les formats si nécessaire
4. Partagez la configuration mise à jour avec l'équipe

### Personnalisation

Pour personnaliser le processus d'apprentissage :

1. Ajustez le seuil de confiance en fonction de vos besoins
2. Modifiez les patterns génériques pour détecter des formats spécifiques
3. Personnalisez la logique de détermination des unités
4. Adaptez la génération des noms de formats

## Dépannage

### Problèmes courants

- **Faux positifs** : Le système détecte des formats qui ne sont pas des tags
- **Formats non détectés** : Certains formats de tags ne sont pas reconnus
- **Unités incorrectes** : Le système attribue des unités incorrectes

### Solutions

- Ajustez les patterns génériques pour réduire les faux positifs
- Ajoutez manuellement les formats non détectés
- Corrigez manuellement les unités dans la configuration
- Utilisez le mode Interactive pour valider les formats détectés

## Conclusion

Le système d'apprentissage des nouveaux formats de tags offre une solution flexible et évolutive pour adapter votre système de tags aux besoins spécifiques de vos roadmaps. Il permet de détecter et d'intégrer automatiquement de nouveaux formats, facilitant ainsi l'adoption et l'utilisation des tags.

Pour plus d'informations sur la configuration des formats de tags et la détection des tags, consultez les guides correspondants :

- [Système de configuration des formats de tags](./README.md)
- [Détection des tags avec expressions régulières](./tag-detection.md)
