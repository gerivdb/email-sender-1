# Système de gestion automatique de la roadmap

Ce dossier contient les outils nécessaires pour mettre à jour automatiquement la roadmap personnelle du projet, y compris les demandes spontanées et le formatage de texte en format roadmap.

## Fichiers inclus

### Gestion de la roadmap

- `Update-Markdown.ps1` : Script PowerShell principal pour la gestion de la roadmap
- `roadmap-update.bat` : Script batch pour faciliter l'utilisation du script PowerShell
- `Add-Task.ps1` : Script pour ajouter une nouvelle tâche à la roadmap
- `add-task.bat` : Script batch pour faciliter l'ajout de tâches
- `Capture-Request-Simple.ps1` : Script pour capturer les demandes spontanées
- `add-request.bat` : Script batch pour faciliter la capture des demandes
- `roadmap-data.json` : Fichier de données contenant l'état actuel des tâches
- `requests-log.txt` : Journal des demandes spontanées

### Formatage de texte pour la roadmap

- `Format-TextToRoadmap.ps1` : Script pour formater du texte en format roadmap
- `Add-FormattedTextToRoadmap.ps1` : Script pour ajouter du texte formaté à la roadmap
- `Roadmap-Text-Formatter.ps1` : Interface utilisateur pour le formatage de texte en format roadmap
- `Roadmap-Text-Formatter-Enhanced.ps1` : Interface utilisateur améliorée avec support pour les tâches prioritaires et les estimations de temps
- `format_roadmap_text.py` : Script Python pour formater du texte en format roadmap

- `README.md` : Ce fichier d'aide

## Utilisation

### Mise à jour des tâches existantes

```
roadmap-update [options]
```

Options :
- `-task <id>` : ID de la tâche à mettre à jour (ex: 1.1, 2.3, etc.)
- `-complete` : Marque la tâche comme terminée
- `-start` : Marque la tâche comme démarrée
- `-note "texte"` : Ajoute une note à la tâche

Exemples :
```
roadmap-update                         # Met à jour la roadmap
roadmap-update -task 1.1 -start        # Marque la tâche 1.1 comme démarrée
roadmap-update -task 1.1 -complete     # Marque la tâche 1.1 comme terminée
roadmap-update -task 1.1 -note "Note"  # Ajoute une note à la tâche 1.1
```

### Ajout de nouvelles tâches

```
add-task [options]
```

Options :
- `-category <id>` : ID de la catégorie (obligatoire, ex: 1, 2, etc.)
- `-description "texte"` : Description de la tâche (obligatoire)
- `-estimated "jours"` : Estimation en jours (optionnel, ex: "1-2", "3")
- `-start` : Marquer la tâche comme démarrée (optionnel)
- `-note "texte"` : Ajouter une note à la tâche (optionnel)

Exemples :
```
add-task -category 1 -description "Ma nouvelle tâche"
add-task -category 2 -description "Tâche complexe" -estimated "3-5" -start
add-task -category 3 -description "Tâche avec note" -note "Priorité haute"
```

### Capture des demandes spontanées

```
add-request [options]
```

Options :
- `-request "texte"` : Description de la demande (obligatoire)
- `-category <id>` : ID de la catégorie (optionnel, défaut: 7)
- `-estimated "jours"` : Estimation en jours (optionnel, défaut: "1-3")
- `-start` : Marquer la demande comme démarrée (optionnel)
- `-note "texte"` : Ajouter une note à la demande (optionnel)

Exemples :
```
add-request -request "Ajouter une fonctionnalité X"
add-request -request "Corriger le bug Y" -start -note "Urgent"
add-request -request "Améliorer la performance" -category 3 -estimated "2-4"
```

### Via PowerShell directement

```powershell
.\Update-Markdown.ps1 [-TaskId <id>] [-Complete] [-Start] [-Note <note>]
.\Add-Task.ps1 -CategoryId <id> -Description <texte> [-EstimatedDays <jours>] [-Start] [-Note <note>]
.\Capture-Request-Simple.ps1 -Request <texte> [-Category <id>] [-EstimatedDays <jours>] [-Start] [-Note <note>]
```

## Fonctionnement

Le système fonctionne comme suit :

1. Les scripts lisent et modifient directement le fichier Markdown `roadmap_perso.md`
2. Les tâches sont organisées par catégories, avec des pourcentages de progression
3. Les demandes spontanées sont ajoutées automatiquement dans une catégorie dédiée (par défaut, catégorie 7)
4. Toutes les modifications sont horodatées et les pourcentages de progression sont recalculés automatiquement
5. Un journal des demandes spontanées est maintenu dans le fichier `requests-log.txt`

## Intégration avec Git

Pour une mise à jour automatique à chaque commit, vous pouvez ajouter un hook Git pre-commit :

1. Créez un fichier `.git/hooks/pre-commit` avec le contenu suivant :

```bash
#!/bin/sh
# Hook pre-commit pour mettre à jour automatiquement la roadmap

# Chemin relatif vers le script roadmap-update.bat
ROADMAP_SCRIPT="./tools/roadmap/roadmap-update.bat"

# Vérifier si le fichier roadmap_perso.md a été modifié
if git diff --cached --name-only | grep -q "roadmap_perso.md"; then
    echo "Mise à jour automatique de la roadmap..."
    $ROADMAP_SCRIPT
    git add roadmap_perso.md
fi

exit 0
```

2. Rendez le hook exécutable :

```bash
chmod +x .git/hooks/pre-commit
```

Cela mettra à jour automatiquement la roadmap chaque fois que vous modifiez manuellement le fichier `roadmap_perso.md` et que vous le committez.

## Personnalisation

Vous pouvez personnaliser le système en modifiant directement le fichier `roadmap_perso.md` ou en ajoutant de nouvelles fonctionnalités aux scripts PowerShell.

## Formatage de texte pour la roadmap

### Utilisation de Format-TextToRoadmap.ps1

```powershell
.\Format-TextToRoadmap.ps1 -Text "PHASE 1: Analyse des besoins
Identifier les exigences
Documenter les cas d'utilisation
Définir les critères de succès" -SectionTitle "Exemple de formatage" -Complexity "Élevée" -TimeEstimate "10-15 jours"
```

### Utilisation de Add-FormattedTextToRoadmap.ps1

```powershell
.\Add-FormattedTextToRoadmap.ps1 -Text "PHASE 1: Analyse des besoins
Identifier les exigences
Documenter les cas d'utilisation
Définir les critères de succès" -SectionTitle "Exemple de formatage" -Complexity "Élevée" -TimeEstimate "10-15 jours" -RoadmapFile "roadmap_perso.md"
```

### Utilisation de Roadmap-Text-Formatter.ps1

```powershell
.\Roadmap-Text-Formatter.ps1
```

Ce script affiche un menu interactif qui vous permet de :
1. Formater du texte en format roadmap
2. Ajouter une section à la roadmap
3. Insérer une section entre deux sections existantes

### Utilisation de Roadmap-Text-Formatter-Enhanced.ps1

```powershell
.\Roadmap-Text-Formatter-Enhanced.ps1
```

Version améliorée avec une interface utilisateur plus conviviale et des fonctionnalités supplémentaires :
1. Formater du texte en format roadmap
2. Ajouter une section à la roadmap
3. Insérer une section entre deux sections existantes
4. Aide et exemples
5. Support pour les tâches prioritaires (marquées avec "prioritaire", "!" ou "*")
6. Support pour les estimations de temps (format: (2h), (3 jours), etc.)
7. Copie dans le presse-papiers

### Exemples de texte à formater

#### Exemple 1 : Liste simple

```
Analyse des besoins
Conception
Développement
Tests
Déploiement
```

#### Exemple 2 : Liste avec indentation

```
Analyse des besoins
  Identifier les exigences
  Documenter les cas d'utilisation
  Définir les critères de succès
Conception
  Créer les maquettes
  Définir l'architecture
  Choisir les technologies
Développement
  Mise en place de l'environnement
  Développement du backend
  Développement du frontend
```

#### Exemple 3 : Liste avec phases

```
PHASE 1: Analyse des besoins
Identifier les exigences
Documenter les cas d'utilisation
Définir les critères de succès

PHASE 2: Conception
Créer les maquettes
Définir l'architecture
Choisir les technologies
  Framework frontend
  Base de données
  Services backend

PHASE 3: Développement
Mise en place de l'environnement
Développement du backend
  API RESTful
  Authentification
  Gestion des données
Développement du frontend
  Interface utilisateur
  Intégration avec le backend
  Tests unitaires
```

#### Exemple 4 : Tâches prioritaires et estimations de temps

```
Analyse des besoins (3 jours)
Conception prioritaire (5 jours)
Développement ! (2 semaines)
Tests * (3 jours)
Déploiement (urgent) (1 jour)
```

Les tâches prioritaires peuvent être marquées de plusieurs façons :
- En ajoutant le mot "prioritaire", "urgent" ou "important"
- En ajoutant un point d'exclamation (!) ou un astérisque (*)

Les estimations de temps peuvent être spécifiées entre parenthèses :
- (Xh) pour les heures
- (X jours) pour les jours
- (X semaines) pour les semaines
- (X mois) pour les mois
- (X-Y jours) pour une plage de temps

### Format de sortie

Le texte formaté sera au format suivant :

```markdown
## Titre de la section
**Complexite**: Complexité
**Temps estime**: Temps estimé
**Progression**: 0%

- [ ] **Phase: Phase 1**
  - [ ] Tâche 1
  - [ ] Tâche 2 (3 jours)
    - [ ] Sous-tâche 1
    - [ ] Sous-tâche 2
- [ ] **Phase: Phase 2**
  - [ ] **Tâche 3** 🔴 (5 jours)
  - [ ] Tâche 4 (2 semaines)
```

Les tâches prioritaires sont mises en gras et marquées d'un point rouge 🔴.
Les estimations de temps sont affichées entre parenthèses après le nom de la tâche.

### Règles de formatage

- Les lignes qui commencent par "PHASE" ou qui sont en majuscules sont considérées comme des phases
- L'indentation est utilisée pour déterminer le niveau hiérarchique des tâches
- Les puces et les numéros sont supprimés des lignes
- Chaque ligne est formatée avec une case à cocher `[ ]`
- Les phases sont mises en gras avec `**Phase: ...**`
- Les tâches prioritaires (marquées avec "prioritaire", "urgent", "important", "!" ou "*") sont mises en gras et marquées d'un point rouge 🔴
- Les estimations de temps (format: (Xh), (X jours), etc.) sont affichées entre parenthèses après le nom de la tâche

## Remarques

- Le script utilise des caractères ASCII sans accents pour éviter les problèmes d'encodage
- Les pourcentages de progression sont calculés automatiquement en fonction du nombre de tâches terminées
- Les dates de démarrage et de fin sont ajoutées automatiquement aux tâches
- Les demandes spontanées sont automatiquement ajoutées à la roadmap et journalisées
- Vous pouvez utiliser la catégorie 7 pour les demandes spontanées ou spécifier une autre catégorie
- Les outils de formatage de texte vous permettent de convertir rapidement du texte brut en format roadmap structuré
- L'interface utilisateur améliorée (Roadmap-Text-Formatter-Enhanced.ps1) offre une expérience plus conviviale et des fonctionnalités supplémentaires
- Les tâches prioritaires sont automatiquement mises en évidence dans la roadmap
- Les estimations de temps pour les tâches individuelles permettent une meilleure planification
