# Guide du mode DEV-R amélioré

## Introduction

Le mode DEV-R (Roadmap Delivery) amélioré est un mode opérationnel qui permet d'implémenter les tâches définies dans une roadmap de manière séquentielle et méthodique. Il a été amélioré pour prendre en charge le traitement de la sélection actuelle dans le document et peut traiter les tâches enfants avant les tâches parentes.

## Fonctionnalités

- **Traitement de la sélection** : Le mode DEV-R amélioré peut traiter la sélection actuelle dans le document, ce qui permet de se concentrer sur une partie spécifique de la roadmap.
- **Traitement des tâches enfants d'abord** : Le mode DEV-R amélioré peut traiter les tâches enfants avant les tâches parentes, ce qui permet de suivre une approche bottom-up.
- **Traitement pas à pas** : Le mode DEV-R amélioré peut traiter les tâches une par une avec une pause entre chaque tâche, ce qui permet de suivre l'avancement de manière plus précise.
- **Intégration avec Augment** : Le mode DEV-R amélioré est intégré à Augment, ce qui permet de l'utiliser directement depuis l'interface d'Augment.

## Utilisation

### Depuis PowerShell

```powershell
# Traiter une tâche spécifique

.\dev-r-mode-enhanced.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -ProjectPath "project" -TestsPath "tests"

# Traiter la sélection actuelle

.\dev-r-mode-enhanced.ps1 -FilePath "roadmap.md" -ProcessSelection -Selection "- [ ] 1.1 Tâche parent`n  - [ ] 1.1.1 Tâche enfant" -ChildrenFirst -StepByStep
```plaintext
### Depuis le script d'intégration

```powershell
# Traiter une tâche spécifique

.\Invoke-DevRMode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -ProjectPath "project" -TestsPath "tests"

# Traiter la sélection actuelle

.\Invoke-DevRMode.ps1 -FilePath "roadmap.md" -Selection "- [ ] 1.1 Tâche parent`n  - [ ] 1.1.1 Tâche enfant" -ChildrenFirst -StepByStep
```plaintext
### Depuis Augment

```powershell
# Traiter une tâche spécifique

.\Invoke-AugmentDevRMode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -ProjectPath "project" -TestsPath "tests"

# Traiter la sélection actuelle

.\Invoke-AugmentDevRMode.ps1 -FilePath "roadmap.md" -UseSelection -ChildrenFirst -StepByStep
```plaintext
### Depuis le module AugmentIntegration

```powershell
# Traiter une tâche spécifique

Invoke-AugmentMode -Mode DEV-R -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -ProjectPath "project" -TestsPath "tests"

# Traiter la sélection actuelle

Invoke-AugmentMode -Mode DEV-R -FilePath "roadmap.md" -UseSelection -ChildrenFirst -StepByStep
```plaintext
## Paramètres

### Paramètres communs

- **FilePath** : Chemin vers le fichier de roadmap à traiter.
- **TaskIdentifier** : Identifiant de la tâche à traiter (optionnel).
- **OutputPath** : Chemin où seront générés les fichiers de sortie.
- **ConfigFile** : Chemin vers un fichier de configuration personnalisé.
- **LogLevel** : Niveau de journalisation à utiliser.
- **ProjectPath** : Chemin vers le répertoire du projet.
- **TestsPath** : Chemin vers le répertoire des tests.
- **AutoCommit** : Indique si les changements doivent être automatiquement commités.
- **UpdateRoadmap** : Indique si la roadmap doit être mise à jour automatiquement.
- **GenerateTests** : Indique si des tests doivent être générés automatiquement.

### Paramètres spécifiques au mode DEV-R amélioré

- **ProcessSelection** / **UseSelection** : Indique si le script doit traiter la sélection actuelle dans le document.
- **Selection** : La sélection de texte à traiter si ProcessSelection est activé.
- **ChildrenFirst** : Indique si les tâches enfants doivent être traitées avant les tâches parentes.
- **StepByStep** : Indique si les tâches doivent être traitées une par une avec une pause entre chaque tâche.

## Exemples d'utilisation

### Traiter une tâche spécifique

```powershell
Invoke-AugmentMode -Mode DEV-R -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -ProjectPath "project" -TestsPath "tests"
```plaintext
Cette commande traite la tâche 1.2.3 du fichier roadmap.md, implémente la fonctionnalité dans le répertoire "project" et génère les tests dans le répertoire "tests".

### Traiter la sélection actuelle

```powershell
Invoke-AugmentMode -Mode DEV-R -FilePath "roadmap.md" -UseSelection -ChildrenFirst -StepByStep
```plaintext
Cette commande traite la sélection actuelle dans le document Augment en commençant par les tâches enfants, avec une pause entre chaque tâche.

### Traiter la sélection actuelle et mettre à jour les mémoires d'Augment

```powershell
Invoke-AugmentMode -Mode DEV-R -FilePath "roadmap.md" -UseSelection -ChildrenFirst -StepByStep -UpdateMemories
```plaintext
Cette commande traite la sélection actuelle dans le document Augment en commençant par les tâches enfants, avec une pause entre chaque tâche, et met à jour les mémoires d'Augment.

## Bonnes pratiques

- **Utiliser la sélection** : Utilisez la sélection pour vous concentrer sur une partie spécifique de la roadmap.
- **Traiter les tâches enfants d'abord** : Traitez les tâches enfants d'abord pour suivre une approche bottom-up.
- **Traiter les tâches pas à pas** : Traitez les tâches pas à pas pour suivre l'avancement de manière plus précise.
- **Mettre à jour les mémoires d'Augment** : Mettez à jour les mémoires d'Augment pour garder une trace de votre travail.

## Conclusion

Le mode DEV-R amélioré est un outil puissant pour implémenter les tâches définies dans une roadmap. Il offre une grande flexibilité et peut être adapté à différents workflows. Utilisez-le pour améliorer votre productivité et la qualité de votre code.
