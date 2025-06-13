# Automation Scripts

Ce dossier contient des scripts d'automatisation pour diverses tâches liées au projet.

## Scripts disponibles

### `automate-chat-buttons.ps1`

- **Description** : Ce script simule des clics sur les boutons dans les boîtes de dialogue de GitHub Copilot dans Visual Studio Code.
- **Utilisation** :
  ```powershell
  pwsh.exe -File "automate-chat-buttons.ps1" -Action "Keep" -DelayBetweenActions 1
  ```
  - Action par défaut : `Keep`
  - Autres actions possibles : `Undo`, `Continue`
  - Paramètre optionnel `DelayBetweenActions` : Temps d'attente en secondes entre chaque action (défaut: 1)
- **Objectif** : Automatiser l'interaction avec les boîtes de dialogue de GitHub Copilot.
- **Fonctionnalités** :
  - ✅ **Conforme aux standards PowerShell** : Respect de toutes les règles PSScriptAnalyzer
  - 📝 **Journalisation détaillée** avec horodatage utilisant Write-Information
  - 🛡️ **Gestion robuste des erreurs** et mécanismes de récupération
  - 🎯 **Détection intelligente** de la fenêtre VS Code à activer
  - ⚡ **Navigation optimisée** par tabulation entre les boutons
  - ⏱️ **Délais adaptatifs** configurables pour assurer la compatibilité
  - 🔧 **Support ShouldProcess** pour les opérations de modification d'état

## Notes

- Assurez-vous que PowerShell est installé et configuré correctement.
- Le script nécessite les droits pour interagir avec la fenêtre VS Code.
- Si le script ne fonctionne pas correctement:
  - Augmentez les délais avec le paramètre `-DelayBetweenActions`
  - Vérifiez que VS Code est bien au premier plan avant l'exécution
  - Sur certains systèmes, vous devrez peut-être exécuter PowerShell en mode administrateur

## Dépannage

- **Le script ne semble pas cliquer sur le bon bouton**: VS Code pourrait avoir modifié son interface. Vérifiez l'ordre des boutons et ajustez le paramètre `TabCount` dans le script si nécessaire.
- **VS Code n'est pas amené au premier plan**: Essayez de cliquer manuellement sur la fenêtre VS Code avant d'exécuter le script.
- **Le script s'exécute mais ne fait rien**: Vérifiez que les boîtes de dialogue sont bien visibles avant de lancer le script.

## Qualité du code

Le script a été optimisé pour respecter toutes les bonnes pratiques PowerShell :
- ✅ **0 erreurs PSScriptAnalyzer** - Code conforme aux standards
- ✅ **Verbes approuvés** - Utilisation de `Invoke-` au lieu de `Perform-`
- ✅ **Gestion d'encodage** - Support UTF-8 avec BOM
- ✅ **Paramètres utilisés** - Tous les paramètres sont effectivement utilisés
- ✅ **Support ShouldProcess** - Pour les fonctions modifiant l'état du système
- ✅ **Types de sortie déclarés** - Documentation des types de retour
