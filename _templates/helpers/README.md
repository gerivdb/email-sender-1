# Helpers pour les Templates Hygen

Ce répertoire contient des modules utilitaires qui facilitent le développement et la maintenance des templates Hygen en offrant des fonctionnalités communes et standardisées.

## Modules disponibles

### path-helper.js

Module pour gérer les chemins de fichiers de façon compatible cross-platform, particulièrement utile pour éviter les problèmes entre Windows, macOS et Linux.

#### Fonctionnalités

- `projectPath(...segments)` : Construit un chemin relatif à la racine du projet
- `planPath(filename)` : Construit un chemin vers le dossier des plans de développement
- `normalizeName(name)` : Normalise un nom pour qu'il soit utilisable comme nom de fichier
- `generatePlanDevPath(version, title)` : Génère le chemin complet pour un fichier de plan de développement
- `isAbsolutePath(filePath)` : Vérifie si un chemin est absolu
- `convertFromWindowsPath(windowsPath)` : Convertit un chemin Windows en chemin compatible avec le système actuel

#### Utilisation

```javascript
// Dans un fichier prompt.js
const pathHelper = require('../helpers/path-helper');

// Pour générer un chemin vers un plan de développement
const planPath = pathHelper.generatePlanDevPath('v2025-05', 'Mon nouveau plan');
// Résultat: <project_root>/roadmaps/plans/consolidated/plan-dev-v2025-05-mon-nouveau-plan.md
```plaintext
## Bonnes pratiques

1. **Ne pas hardcoder les chemins** : Toujours utiliser les helpers pour construire des chemins
2. **Éviter les séparateurs de chemin manuels** : Ne pas utiliser `\` ou `/` directement, préférer `path.join()`
3. **Être relatif à la racine du projet** : Utiliser `projectPath()` au lieu de chemins absolus
