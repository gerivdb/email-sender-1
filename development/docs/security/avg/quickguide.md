# Guide Rapide - Exclusion AVG pour les fichiers .exe

Ce guide explique comment utiliser et vérifier le système d'exclusion AVG mis en place pour éviter que l'antivirus ne bloque vos fichiers `.exe` pendant le développement.

## 🚀 Démarrage Rapide

Le système d'exclusion AVG démarre **automatiquement** à l'ouverture du projet dans VS Code. Vous n'avez rien à faire !

## ✅ Vérifier que ça fonctionne

Pour confirmer que les exclusions fonctionnent correctement :

1. Ouvrez VS Code dans ce projet
2. Appuyez sur `Ctrl+Shift+P` (ou `Cmd+Shift+P` sur Mac)
3. Tapez "Tasks: Run Task"
4. Sélectionnez `avg-exclusion.test-exe`
5. Observez les résultats du test dans le terminal

Si le test réussit, un message "✨ Les fichiers .exe ne sont plus bloqués par AVG" s'affichera et un rapport sera généré dans `logs/avg-exe-exclusion-success.txt`.

## 🔄 Commandes Disponibles

| Tâche VS Code | Description |
|---------------|-------------|
| `avg-exclusion.auto-start` | Démarrage automatique (exécuté à l'ouverture du projet) |
| `avg-exclusion.start` | Démarrage manuel des exclusions |
| `avg-exclusion.status` | Afficher l'état actuel des exclusions |
| `avg-exclusion.stop` | Arrêter le processus d'exclusion |
| `avg-exclusion.test-exe` | Tester si les exclusions fonctionnent |

## 🛑 Problèmes Courants

### AVG bloque toujours mes fichiers .exe

1. Exécutez la tâche `avg-exclusion.start` manuellement
2. Redémarrez VS Code en mode administrateur
3. Exécutez à nouveau la tâche `avg-exclusion.start`
4. Vérifiez avec la tâche `avg-exclusion.test-exe`

### Messages d'erreur concernant les permissions

Si vous voyez des erreurs liées aux permissions :

1. Fermez VS Code
2. Redémarrez VS Code en tant qu'administrateur (clic droit → "Exécuter en tant qu'administrateur")
3. Le système d'exclusion démarrera automatiquement avec des privilèges élevés

## 📂 Où trouver les logs et rapports

- Logs du système d'exclusion : `logs/avg-exclusion.log`
- Rapport du test d'exclusion : `logs/avg-exe-exclusion-success.txt`
- Indicateur de processus : `logs/avg-auto-exclusion.status`

## 🔧 Configuration Manuelle (si nécessaire)

Si vous devez configurer manuellement les exclusions AVG :

1. Exécutez le script `scripts/ensure-exe-exclusion.ps1`
2. Suivez les instructions qui s'affichent
3. Un script d'aide sera généré dans `scripts/manual-exe-exclusion.ps1`

---

Pour plus d'informations techniques, consultez la [documentation complète](system.md) ou la [documentation technique](technical.md).
