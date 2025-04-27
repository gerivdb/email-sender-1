# Plan des templates Hygen pour scripts

Ce document prÃ©sente le plan des templates Hygen Ã  dÃ©velopper pour le dossier scripts.

## Types de templates

### 1. Scripts d'automatisation (script-automation)

**Description** : Templates pour gÃ©nÃ©rer des scripts d'automatisation.

**Fichiers gÃ©nÃ©rÃ©s** :
- `scripts/automation/<name>.ps1` : Script d'automatisation PowerShell

**ParamÃ¨tres** :
- `name` : Nom du script d'automatisation (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "automation, scripts")

**Structure du script gÃ©nÃ©rÃ©** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, ParamÃ¨tres, Exemples, Notes
- ParamÃ¨tres : `Path`, `Force`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`
- Fonctions d'affichage : `Write-Success`, `Write-Error`, `Write-Info`, `Write-Warning`
- Fonction principale : `Start-<Name>`
- Appel Ã  la fonction principale

### 2. Scripts d'analyse (script-analysis)

**Description** : Templates pour gÃ©nÃ©rer des scripts d'analyse.

**Fichiers gÃ©nÃ©rÃ©s** :
- `scripts/analysis/<subFolder>/<name>.ps1` : Script d'analyse PowerShell

**ParamÃ¨tres** :
- `name` : Nom du script d'analyse (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `subFolder` : Sous-dossier (optionnel, ex: plugins, tests)
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "analysis, scripts")

**Structure du script gÃ©nÃ©rÃ©** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, ParamÃ¨tres, Exemples, Notes
- ParamÃ¨tres : `InputPath`, `OutputPath`, `Format`
- Fonction d'affichage : `Write-ColorMessage`
- Fonctions d'analyse : `Analyze-File`, `Analyze-Directory`
- Fonction d'exportation : `Export-Results`
- Fonction principale : `Start-<Name>`
- Appel Ã  la fonction principale

### 3. Scripts de test (script-test)

**Description** : Templates pour gÃ©nÃ©rer des scripts de test.

**Fichiers gÃ©nÃ©rÃ©s** :
- `scripts/tests/<name>.Tests.ps1` : Script de test PowerShell

**ParamÃ¨tres** :
- `name` : Nom du script de test (sans extension et sans .Tests)
- `description` : Description courte du script de test
- `additionalDescription` : Description additionnelle (optionnel)
- `scriptToTest` : Chemin relatif du script Ã  tester (ex: automation/Example-Script.ps1)
- `functionName` : Nom de la fonction principale Ã  tester (sans le prÃ©fixe 'Start-')
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "tests, pester, scripts")

**Structure du script gÃ©nÃ©rÃ©** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, Notes
- Bloc `BeforeAll` : Importation du script Ã  tester
- Bloc `Describe` : Tests principaux
- Blocs `Context` : Groupes de tests
- Blocs `It` : Tests individuels
- Fonction d'exÃ©cution des tests : `Invoke-<Name>Tests`
- ExÃ©cution conditionnelle des tests

### 4. Scripts d'intÃ©gration (script-integration)

**Description** : Templates pour gÃ©nÃ©rer des scripts d'intÃ©gration.

**Fichiers gÃ©nÃ©rÃ©s** :
- `scripts/integration/<name>.ps1` : Script d'intÃ©gration PowerShell

**ParamÃ¨tres** :
- `name` : Nom du script d'intÃ©gration (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "integration, scripts")

**Structure du script gÃ©nÃ©rÃ©** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, ParamÃ¨tres, Exemples, Notes
- ParamÃ¨tres : `TargetSystem`, `ConfigPath`, `Force`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`
- Fonction d'affichage : `Write-ColorMessage`
- Fonctions d'intÃ©gration : `Load-Configuration`, `Validate-Configuration`, `Connect-TargetSystem`, `Execute-Integration`, `Generate-Report`
- Fonction principale : `Start-<Name>`
- Appel Ã  la fonction principale

## ImplÃ©mentation

Les templates ont Ã©tÃ© implÃ©mentÃ©s dans les dossiers suivants :

- `scripts/_templates/script-automation/new/` : Templates pour les scripts d'automatisation
- `scripts/_templates/script-analysis/new/` : Templates pour les scripts d'analyse
- `scripts/_templates/script-test/new/` : Templates pour les scripts de test
- `scripts/_templates/script-integration/new/` : Templates pour les scripts d'intÃ©gration

Chaque dossier contient les fichiers suivants :

- `hello.ejs.t` : Template principal
- `prompt.js` : Script de prompt pour les paramÃ¨tres

## Utilisation

Pour utiliser ces templates, deux options sont disponibles :

1. **Script PowerShell** : `scripts/utils/Generate-Script.ps1`
2. **Script de commande** : `scripts/cmd/utils/generate-script.cmd`

### Exemples d'utilisation

```powershell
# GÃ©nÃ©rer un script d'automatisation
.\scripts\utils\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"

# GÃ©nÃ©rer un script d'analyse
.\scripts\utils\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualitÃ© du code" -SubFolder "plugins" -Author "Jane Smith"

# GÃ©nÃ©rer un script de test
.\scripts\utils\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"

# GÃ©nÃ©rer un script d'intÃ©gration
.\scripts\utils\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intÃ©gration avec GitHub Issues" -Author "Integration Team"
```

## Prochaines Ã©tapes

1. **Tests** : Tester les templates avec diffÃ©rents paramÃ¨tres
2. **AmÃ©liorations** : Ajouter des fonctionnalitÃ©s supplÃ©mentaires aux templates
3. **Documentation** : CrÃ©er une documentation complÃ¨te pour l'utilisation des templates
4. **IntÃ©gration** : IntÃ©grer les templates dans le workflow de dÃ©veloppement scripts
