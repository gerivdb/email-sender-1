# Analyse de la structure scripts pour Hygen

Ce document prÃ©sente l'analyse de la structure du dossier scripts pour l'implÃ©mentation de Hygen.

## Structure actuelle

La structure actuelle du dossier scripts est la suivante :

```
development/scripts/
  â”œâ”€â”€ agent-auto/        # Scripts d'agent automatisÃ©
  â”œâ”€â”€ analysis/          # Scripts d'analyse
  â”‚   â”œâ”€â”€ plugins/       # Plugins d'analyse
  â”‚   â””â”€â”€ development/testing/tests/         # Tests d'analyse
  â”œâ”€â”€ api/               # Scripts d'API
  â”œâ”€â”€ automation/        # Scripts d'automatisation
  â”œâ”€â”€ integration/       # Scripts d'intÃ©gration
  â”œâ”€â”€ development/testing/tests/             # Scripts de test
  â””â”€â”€ utils/             # Scripts utilitaires
```

## Types de fichiers identifiÃ©s

### Scripts d'automatisation

Les scripts d'automatisation sont des scripts PowerShell qui automatisent des tÃ¢ches. Ils sont stockÃ©s dans le dossier `development/scripts/automation/`.

CaractÃ©ristiques :
- Extension : `.ps1`
- Directive : `#Requires -Version 5.1`
- ParamÃ¨tres communs : `Path`, `Force`
- Fonctions communes : `Start-*`, `Write-Success`, `Write-Error`, `Write-Info`, `Write-Warning`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`

### Scripts d'analyse

Les scripts d'analyse sont des scripts PowerShell qui analysent des donnÃ©es. Ils sont stockÃ©s dans le dossier `development/scripts/analysis/`.

CaractÃ©ristiques :
- Extension : `.ps1`
- Directive : `#Requires -Version 5.1`
- ParamÃ¨tres communs : `InputPath`, `OutputPath`, `Format`
- Fonctions communes : `Analyze-*`, `Export-Results`, `Write-ColorMessage`
- Sous-dossiers : `plugins`, `tests`

### Scripts de test

Les scripts de test sont des scripts PowerShell qui testent d'autres scripts. Ils sont stockÃ©s dans le dossier `development/scripts/development/testing/tests/`.

CaractÃ©ristiques :
- Extension : `.ps1` (gÃ©nÃ©ralement avec le suffixe `.Tests.ps1`)
- Directive : `#Requires -Version 5.1`
- Utilisation de Pester : `Describe`, `Context`, `It`, `Should`
- Blocs communs : `BeforeAll`, `AfterAll`
- Fonctions communes : `Invoke-*Tests`

### Scripts d'intÃ©gration

Les scripts d'intÃ©gration sont des scripts PowerShell qui intÃ¨grent diffÃ©rents systÃ¨mes. Ils sont stockÃ©s dans le dossier `development/scripts/integration/`.

CaractÃ©ristiques :
- Extension : `.ps1`
- Directive : `#Requires -Version 5.1`
- ParamÃ¨tres communs : `TargetSystem`, `ConfigPath`, `Force`
- Fonctions communes : `Connect-*`, `Execute-*`, `Generate-Report`, `Write-ColorMessage`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`

## Templates Hygen

Sur la base de cette analyse, les templates Hygen suivants ont Ã©tÃ© crÃ©Ã©s :

1. **script-automation** : Pour gÃ©nÃ©rer des scripts d'automatisation
2. **script-analysis** : Pour gÃ©nÃ©rer des scripts d'analyse
3. **script-test** : Pour gÃ©nÃ©rer des scripts de test
4. **script-integration** : Pour gÃ©nÃ©rer des scripts d'intÃ©gration

## ParamÃ¨tres des templates

### script-automation

- `name` : Nom du script d'automatisation (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "automation, scripts")

### script-analysis

- `name` : Nom du script d'analyse (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `subFolder` : Sous-dossier (optionnel, ex: plugins, tests)
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "analysis, scripts")

### script-test

- `name` : Nom du script de test (sans extension et sans .Tests)
- `description` : Description courte du script de test
- `additionalDescription` : Description additionnelle (optionnel)
- `scriptToTest` : Chemin relatif du script Ã  tester (ex: automation/Example-Script.ps1)
- `functionName` : Nom de la fonction principale Ã  tester (sans le prÃ©fixe 'Start-')
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "tests, pester, scripts")

### script-integration

- `name` : Nom du script d'intÃ©gration (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par dÃ©faut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par dÃ©faut "integration, scripts")

## IntÃ©gration avec la structure existante

Les templates Hygen ont Ã©tÃ© conÃ§us pour s'intÃ©grer parfaitement avec la structure existante du dossier scripts. Les fichiers gÃ©nÃ©rÃ©s sont placÃ©s dans les dossiers appropriÃ©s selon leur type :

- Scripts d'automatisation : `development/scripts/automation/`
- Scripts d'analyse : `development/scripts/analysis/` ou `development/scripts/analysis/<subFolder>/`
- Scripts de test : `development/scripts/development/testing/tests/`
- Scripts d'intÃ©gration : `development/scripts/integration/`

## Utilisation

Pour utiliser les templates Hygen, deux options sont disponibles :

1. **Script PowerShell** : `development/scripts/utils/Generate-Script.ps1`
2. **Script de commande** : `development/scripts/cmd/utils/generate-script.cmd`

### Exemples d'utilisation

```powershell
# GÃ©nÃ©rer un script d'automatisation
.\development\scripts\utils\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"

# GÃ©nÃ©rer un script d'analyse
.\development\scripts\utils\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualitÃ© du code" -SubFolder "plugins" -Author "Jane Smith"

# GÃ©nÃ©rer un script de test
.\development\scripts\utils\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"

# GÃ©nÃ©rer un script d'intÃ©gration
.\development\scripts\utils\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intÃ©gration avec GitHub Issues" -Author "Integration Team"
```

## Conclusion

L'implÃ©mentation de Hygen pour le dossier scripts permet de gÃ©nÃ©rer rapidement et de maniÃ¨re cohÃ©rente des scripts. Les templates sont conÃ§us pour s'intÃ©grer parfaitement avec la structure existante et respecter les conventions de codage du projet.
