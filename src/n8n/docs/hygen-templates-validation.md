# Guide de validation des templates Hygen

Ce guide explique comment valider les templates Hygen dans le projet n8n.

## Prérequis

- Node.js et npm installés
- Projet n8n initialisé
- Hygen installé en tant que dépendance de développement
- Installation de Hygen finalisée (voir [Guide de finalisation de l'installation](hygen-installation-finalization.md))

## Templates disponibles

Le projet n8n utilise les templates Hygen suivants :

1. **n8n-script** : Template pour les scripts PowerShell
2. **n8n-workflow** : Template pour les workflows n8n
3. **n8n-doc** : Template pour la documentation
4. **n8n-integration** : Template pour les intégrations

## Validation des templates

### Utilisation du script de commande

La méthode la plus simple pour valider les templates est d'utiliser le script de commande :

```batch
.\n8n\cmd\utils\validate-templates.cmd
```plaintext
Ce script vous présentera un menu avec les options suivantes :

1. Tester tous les templates
2. Tester le template PowerShell
3. Tester le template Workflow
4. Tester le template Documentation
5. Tester le template Integration
6. Tester tous les templates et conserver les fichiers générés
Q. Quitter

### Utilisation du script PowerShell

Vous pouvez également utiliser directement le script PowerShell :

```powershell
# Tester tous les templates

.\n8n\scripts\setup\validate-hygen-templates.ps1

# Tester un template spécifique

.\n8n\scripts\setup\validate-hygen-templates.ps1 -TestPowerShell
.\n8n\scripts\setup\validate-hygen-templates.ps1 -TestWorkflow
.\n8n\scripts\setup\validate-hygen-templates.ps1 -TestDocumentation
.\n8n\scripts\setup\validate-hygen-templates.ps1 -TestIntegration

# Conserver les fichiers générés

.\n8n\scripts\setup\validate-hygen-templates.ps1 -KeepGeneratedFiles

# Spécifier un dossier de sortie personnalisé

.\n8n\scripts\setup\validate-hygen-templates.ps1 -OutputFolder "C:\Temp\HygenTest"
```plaintext
### Tests individuels

Vous pouvez également exécuter les tests individuels pour chaque template :

```powershell
# Tester le template PowerShell

.\n8n\scripts\setup\test-powershell-template.ps1

# Tester le template Workflow

.\n8n\scripts\setup\test-workflow-template.ps1

# Tester le template Documentation

.\n8n\scripts\setup\test-documentation-template.ps1

# Tester le template Integration

.\n8n\scripts\setup\test-integration-template.ps1
```plaintext
## Critères de validation

### Template PowerShell

Le template pour les scripts PowerShell est validé selon les critères suivants :

- Le script est généré au bon emplacement
- Le script contient le nom et la description spécifiés
- Le script contient les sections standard (SYNOPSIS, DESCRIPTION, PARAMETER, etc.)
- Le script ne contient pas d'erreurs de syntaxe
- Le script peut être exécuté sans erreurs

### Template Workflow

Le template pour les workflows n8n est validé selon les critères suivants :

- Le workflow est généré au bon emplacement
- Le workflow contient le nom et les tags spécifiés
- Le workflow contient les propriétés standard (nodes, connections, active, etc.)
- Le workflow est un JSON valide

### Template Documentation

Le template pour la documentation est validé selon les critères suivants :

- Le document est généré au bon emplacement
- Le document contient le titre et la description spécifiés
- Le document contient les sections standard (Description, Installation, Utilisation, etc.)
- Le document contient des titres, des listes et des blocs de code valides

### Template Integration

Le template pour les intégrations est validé selon les critères suivants :

- Le script est généré au bon emplacement
- Le script contient le nom, le système et la description spécifiés
- Le script contient les sections standard (SYNOPSIS, DESCRIPTION, PARAMETER, etc.)
- Le script contient les fonctions d'intégration spécifiques
- Le script ne contient pas d'erreurs de syntaxe
- Le script peut être exécuté sans erreurs
- Pour les intégrations MCP, le script contient les fonctions d'intégration MCP spécifiques

## Rapport de validation

Après l'exécution des tests, un rapport de validation est généré dans le fichier :

```plaintext
n8n\docs\hygen-templates-validation-report.md
```plaintext
Ce rapport contient les résultats des tests pour chaque template et le résultat global.

## Résolution des problèmes

### Erreurs lors de la génération des templates

Si vous rencontrez des erreurs lors de la génération des templates, vérifiez les points suivants :

- Assurez-vous que Hygen est correctement installé
- Assurez-vous que les templates sont présents dans le dossier `n8n/_templates`
- Assurez-vous que les templates contiennent les fichiers nécessaires (hello.ejs.t et prompt.js)

### Erreurs lors de la validation des templates

Si vous rencontrez des erreurs lors de la validation des templates, vérifiez les points suivants :

- Assurez-vous que les templates génèrent des fichiers au bon emplacement
- Assurez-vous que les templates génèrent des fichiers avec le contenu attendu
- Assurez-vous que les fichiers générés sont valides (syntaxe, structure, etc.)

## Prochaines étapes

Une fois les templates validés, vous pouvez passer aux étapes suivantes :

1. Valider les scripts d'utilitaires
2. Finaliser les tests et la documentation
3. Valider les bénéfices et l'utilité

Pour plus d'informations, consultez le guide d'utilisation de Hygen :

```plaintext
n8n\docs\hygen-guide.md
```plaintext