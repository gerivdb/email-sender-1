# Documentation du Système d'Exclusion AVG

Ce dossier contient la documentation complète du système d'exclusion AVG mis en place pour éviter les blocages des fichiers `.exe` par l'antivirus AVG.

## Documents disponibles

| Document | Description |
|----------|-------------|
| [Guide Rapide](quickguide.md) | Instructions simples pour vérifier que le système fonctionne |
| [Documentation Système](system.md) | Vue d'ensemble complète du système et son fonctionnement |
| [Documentation Technique](technical.md) | Détails techniques d'implémentation des scripts |

## Scripts associés

Les scripts se trouvent dans le dossier `scripts/` à la racine du projet :

- `auto-avg-exclusion.ps1` - Script principal d'exclusion
- `ensure-exe-exclusion.ps1` - Script spécifique pour les fichiers `.exe`
- `avg-exclusion-vscode-hook.ps1` - Script pour l'intégration VS Code
- `test-avg-exe-exclusion.ps1` - Script de test des exclusions

## Tests et validation

Le dernier test d'exclusion a été exécuté le 18 juin 2025 et a confirmé que les fichiers `.exe` ne sont plus bloqués par AVG.

---

📝 *Pour plus d'informations, consultez le fichier [AVG-EXCLUSION-README.md](../../../../AVG-EXCLUSION-README.md) à la racine du projet.*
