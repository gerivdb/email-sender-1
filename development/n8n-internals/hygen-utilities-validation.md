# Guide de validation des scripts d'utilitaires Hygen

Ce guide explique comment valider les scripts d'utilitaires Hygen dans le projet n8n.

## Prérequis

- Node.js et npm installés
- Projet n8n initialisé
- Hygen installé en tant que dépendance de développement
- Installation de Hygen finalisée (voir [Guide de finalisation de l'installation](hygen-installation-finalization.md))
- Templates Hygen validés (voir [Guide de validation des templates](hygen-templates-validation.md))

## Scripts d'utilitaires disponibles

Le projet n8n utilise les scripts d'utilitaires Hygen suivants :

1. **Generate-N8nComponent.ps1** : Script PowerShell principal pour générer des composants n8n
2. **generate-component.cmd** : Script CMD pour générer des composants n8n
3. **install-hygen.cmd** : Script CMD pour installer Hygen
4. **validate-templates.cmd** : Script CMD pour valider les templates Hygen
5. **finalize-hygen.cmd** : Script CMD pour finaliser l'installation de Hygen

## Validation des scripts d'utilitaires

### Utilisation du script de commande

La méthode la plus simple pour valider les scripts d'utilitaires est d'utiliser le script de commande :

```batch
.\n8n\cmd\utils\validate-utilities.cmd
```

Ce script vous présentera un menu avec les options suivantes :

1. Tester tous les scripts d'utilitaires
2. Tester tous les scripts d'utilitaires en mode interactif
3. Tester tous les scripts d'utilitaires avec tests de performance
4. Tester tous les scripts d'utilitaires en mode interactif avec tests de performance
5. Tester tous les scripts d'utilitaires et conserver les fichiers générés
Q. Quitter

### Utilisation du script PowerShell

Vous pouvez également utiliser directement le script PowerShell :

```powershell
# Tester tous les scripts d'utilitaires
.\n8n\scripts\setup\validate-hygen-utilities.ps1

# Tester en mode interactif
.\n8n\scripts\setup\validate-hygen-utilities.ps1 -Interactive

# Tester avec tests de performance
.\n8n\scripts\setup\validate-hygen-utilities.ps1 -PerformanceTest

# Spécifier le nombre d'itérations pour les tests de performance
.\n8n\scripts\setup\validate-hygen-utilities.ps1 -PerformanceTest -Iterations 10

# Conserver les fichiers générés
.\n8n\scripts\setup\validate-hygen-utilities.ps1 -KeepGeneratedFiles

# Spécifier un dossier de sortie personnalisé
.\n8n\scripts\setup\validate-hygen-utilities.ps1 -OutputFolder "C:\Temp\HygenTest"
```

### Tests individuels

Vous pouvez également exécuter les tests individuels pour chaque script d'utilitaire :

```powershell
# Tester le script Generate-N8nComponent.ps1
.\n8n\scripts\setup\test-generate-component.ps1

# Tester les scripts CMD
.\n8n\scripts\setup\test-cmd-scripts.ps1

# Tester les performances
.\n8n\scripts\setup\test-performance.ps1
```

## Critères de validation

### Script Generate-N8nComponent.ps1

Le script PowerShell principal est validé selon les critères suivants :

- Le script peut être exécuté sans erreurs
- Le script peut générer des composants de tous les types (script, workflow, doc, integration)
- Le script fonctionne en mode interactif et non interactif
- Le script gère correctement les erreurs

### Scripts CMD

Les scripts CMD sont validés selon les critères suivants :

- Les scripts peuvent être exécutés sans erreurs
- Les scripts appellent correctement les scripts PowerShell sous-jacents
- Les scripts contiennent des options et des vérifications d'erreurs
- Les scripts fonctionnent en mode interactif et non interactif

### Tests de performance

Les tests de performance vérifient les critères suivants :

- Le temps d'exécution des scripts est acceptable
- Les scripts sont stables et ne génèrent pas d'erreurs lors d'exécutions répétées
- Les performances sont cohérentes entre les différents types de composants

## Rapport de validation

Après l'exécution des tests, un rapport de validation est généré dans le fichier :

```
n8n\projet/documentation\hygen-utilities-validation-report.md
```

Ce rapport contient les résultats des tests pour chaque script d'utilitaire et le résultat global.

Si des tests de performance ont été exécutés, un rapport de performance est également généré dans le fichier :

```
n8n\projet/documentation\hygen-performance-report.md
```

Ce rapport contient les résultats des tests de performance pour chaque type de composant.

## Résolution des problèmes

### Erreurs lors de l'exécution des scripts

Si vous rencontrez des erreurs lors de l'exécution des scripts, vérifiez les points suivants :

- Assurez-vous que PowerShell est configuré pour exécuter des scripts
- Assurez-vous que Node.js et npm sont installés et accessibles
- Assurez-vous que Hygen est correctement installé
- Assurez-vous que les templates sont présents dans le dossier `n8n/development/templates`

### Erreurs lors des tests de performance

Si vous rencontrez des erreurs lors des tests de performance, vérifiez les points suivants :

- Assurez-vous que le système dispose de suffisamment de ressources
- Essayez de réduire le nombre d'itérations
- Vérifiez si d'autres processus consomment des ressources

## Prochaines étapes

Une fois les scripts d'utilitaires validés, vous pouvez passer aux étapes suivantes :

1. Finaliser les tests et la documentation
2. Valider les bénéfices et l'utilité

Pour plus d'informations, consultez le guide d'utilisation de Hygen :

```
n8n\projet/documentation\hygen-guide.md
```
