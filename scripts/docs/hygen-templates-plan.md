# Plan des templates Hygen pour scripts

Ce document présente le plan des templates Hygen à développer pour le dossier scripts.

## Types de templates

### 1. Scripts d'automatisation (script-automation)

**Description** : Templates pour générer des scripts d'automatisation.

**Fichiers générés** :
- `scripts/automation/<name>.ps1` : Script d'automatisation PowerShell

**Paramètres** :
- `name` : Nom du script d'automatisation (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "automation, scripts")

**Structure du script généré** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, Paramètres, Exemples, Notes
- Paramètres : `Path`, `Force`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`
- Fonctions d'affichage : `Write-Success`, `Write-Error`, `Write-Info`, `Write-Warning`
- Fonction principale : `Start-<Name>`
- Appel à la fonction principale

### 2. Scripts d'analyse (script-analysis)

**Description** : Templates pour générer des scripts d'analyse.

**Fichiers générés** :
- `scripts/analysis/<subFolder>/<name>.ps1` : Script d'analyse PowerShell

**Paramètres** :
- `name` : Nom du script d'analyse (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `subFolder` : Sous-dossier (optionnel, ex: plugins, tests)
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "analysis, scripts")

**Structure du script généré** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, Paramètres, Exemples, Notes
- Paramètres : `InputPath`, `OutputPath`, `Format`
- Fonction d'affichage : `Write-ColorMessage`
- Fonctions d'analyse : `Analyze-File`, `Analyze-Directory`
- Fonction d'exportation : `Export-Results`
- Fonction principale : `Start-<Name>`
- Appel à la fonction principale

### 3. Scripts de test (script-test)

**Description** : Templates pour générer des scripts de test.

**Fichiers générés** :
- `scripts/tests/<name>.Tests.ps1` : Script de test PowerShell

**Paramètres** :
- `name` : Nom du script de test (sans extension et sans .Tests)
- `description` : Description courte du script de test
- `additionalDescription` : Description additionnelle (optionnel)
- `scriptToTest` : Chemin relatif du script à tester (ex: automation/Example-Script.ps1)
- `functionName` : Nom de la fonction principale à tester (sans le préfixe 'Start-')
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "tests, pester, scripts")

**Structure du script généré** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, Notes
- Bloc `BeforeAll` : Importation du script à tester
- Bloc `Describe` : Tests principaux
- Blocs `Context` : Groupes de tests
- Blocs `It` : Tests individuels
- Fonction d'exécution des tests : `Invoke-<Name>Tests`
- Exécution conditionnelle des tests

### 4. Scripts d'intégration (script-integration)

**Description** : Templates pour générer des scripts d'intégration.

**Fichiers générés** :
- `scripts/integration/<name>.ps1` : Script d'intégration PowerShell

**Paramètres** :
- `name` : Nom du script d'intégration (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "integration, scripts")

**Structure du script généré** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, Paramètres, Exemples, Notes
- Paramètres : `TargetSystem`, `ConfigPath`, `Force`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`
- Fonction d'affichage : `Write-ColorMessage`
- Fonctions d'intégration : `Load-Configuration`, `Validate-Configuration`, `Connect-TargetSystem`, `Execute-Integration`, `Generate-Report`
- Fonction principale : `Start-<Name>`
- Appel à la fonction principale

## Implémentation

Les templates ont été implémentés dans les dossiers suivants :

- `scripts/_templates/script-automation/new/` : Templates pour les scripts d'automatisation
- `scripts/_templates/script-analysis/new/` : Templates pour les scripts d'analyse
- `scripts/_templates/script-test/new/` : Templates pour les scripts de test
- `scripts/_templates/script-integration/new/` : Templates pour les scripts d'intégration

Chaque dossier contient les fichiers suivants :

- `hello.ejs.t` : Template principal
- `prompt.js` : Script de prompt pour les paramètres

## Utilisation

Pour utiliser ces templates, deux options sont disponibles :

1. **Script PowerShell** : `scripts/utils/Generate-Script.ps1`
2. **Script de commande** : `scripts/cmd/utils/generate-script.cmd`

### Exemples d'utilisation

```powershell
# Générer un script d'automatisation
.\scripts\utils\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"

# Générer un script d'analyse
.\scripts\utils\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualité du code" -SubFolder "plugins" -Author "Jane Smith"

# Générer un script de test
.\scripts\utils\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"

# Générer un script d'intégration
.\scripts\utils\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intégration avec GitHub Issues" -Author "Integration Team"
```

## Prochaines étapes

1. **Tests** : Tester les templates avec différents paramètres
2. **Améliorations** : Ajouter des fonctionnalités supplémentaires aux templates
3. **Documentation** : Créer une documentation complète pour l'utilisation des templates
4. **Intégration** : Intégrer les templates dans le workflow de développement scripts
