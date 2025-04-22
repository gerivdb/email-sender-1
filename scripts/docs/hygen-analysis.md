# Analyse de la structure scripts pour Hygen

Ce document présente l'analyse de la structure du dossier scripts pour l'implémentation de Hygen.

## Structure actuelle

La structure actuelle du dossier scripts est la suivante :

```
scripts/
  ├── agent-auto/        # Scripts d'agent automatisé
  ├── analysis/          # Scripts d'analyse
  │   ├── plugins/       # Plugins d'analyse
  │   └── tests/         # Tests d'analyse
  ├── api/               # Scripts d'API
  ├── automation/        # Scripts d'automatisation
  ├── integration/       # Scripts d'intégration
  ├── tests/             # Scripts de test
  └── utils/             # Scripts utilitaires
```

## Types de fichiers identifiés

### Scripts d'automatisation

Les scripts d'automatisation sont des scripts PowerShell qui automatisent des tâches. Ils sont stockés dans le dossier `scripts/automation/`.

Caractéristiques :
- Extension : `.ps1`
- Directive : `#Requires -Version 5.1`
- Paramètres communs : `Path`, `Force`
- Fonctions communes : `Start-*`, `Write-Success`, `Write-Error`, `Write-Info`, `Write-Warning`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`

### Scripts d'analyse

Les scripts d'analyse sont des scripts PowerShell qui analysent des données. Ils sont stockés dans le dossier `scripts/analysis/`.

Caractéristiques :
- Extension : `.ps1`
- Directive : `#Requires -Version 5.1`
- Paramètres communs : `InputPath`, `OutputPath`, `Format`
- Fonctions communes : `Analyze-*`, `Export-Results`, `Write-ColorMessage`
- Sous-dossiers : `plugins`, `tests`

### Scripts de test

Les scripts de test sont des scripts PowerShell qui testent d'autres scripts. Ils sont stockés dans le dossier `scripts/tests/`.

Caractéristiques :
- Extension : `.ps1` (généralement avec le suffixe `.Tests.ps1`)
- Directive : `#Requires -Version 5.1`
- Utilisation de Pester : `Describe`, `Context`, `It`, `Should`
- Blocs communs : `BeforeAll`, `AfterAll`
- Fonctions communes : `Invoke-*Tests`

### Scripts d'intégration

Les scripts d'intégration sont des scripts PowerShell qui intègrent différents systèmes. Ils sont stockés dans le dossier `scripts/integration/`.

Caractéristiques :
- Extension : `.ps1`
- Directive : `#Requires -Version 5.1`
- Paramètres communs : `TargetSystem`, `ConfigPath`, `Force`
- Fonctions communes : `Connect-*`, `Execute-*`, `Generate-Report`, `Write-ColorMessage`
- Attribut : `[CmdletBinding(SupportsShouldProcess=$true)]`

## Templates Hygen

Sur la base de cette analyse, les templates Hygen suivants ont été créés :

1. **script-automation** : Pour générer des scripts d'automatisation
2. **script-analysis** : Pour générer des scripts d'analyse
3. **script-test** : Pour générer des scripts de test
4. **script-integration** : Pour générer des scripts d'intégration

## Paramètres des templates

### script-automation

- `name` : Nom du script d'automatisation (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "automation, scripts")

### script-analysis

- `name` : Nom du script d'analyse (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `subFolder` : Sous-dossier (optionnel, ex: plugins, tests)
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "analysis, scripts")

### script-test

- `name` : Nom du script de test (sans extension et sans .Tests)
- `description` : Description courte du script de test
- `additionalDescription` : Description additionnelle (optionnel)
- `scriptToTest` : Chemin relatif du script à tester (ex: automation/Example-Script.ps1)
- `functionName` : Nom de la fonction principale à tester (sans le préfixe 'Start-')
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "tests, pester, scripts")

### script-integration

- `name` : Nom du script d'intégration (sans extension)
- `description` : Description courte du script
- `additionalDescription` : Description additionnelle (optionnel)
- `author` : Auteur du script (optionnel, par défaut "EMAIL_SENDER_1")
- `tags` : Tags (optionnel, par défaut "integration, scripts")

## Intégration avec la structure existante

Les templates Hygen ont été conçus pour s'intégrer parfaitement avec la structure existante du dossier scripts. Les fichiers générés sont placés dans les dossiers appropriés selon leur type :

- Scripts d'automatisation : `scripts/automation/`
- Scripts d'analyse : `scripts/analysis/` ou `scripts/analysis/<subFolder>/`
- Scripts de test : `scripts/tests/`
- Scripts d'intégration : `scripts/integration/`

## Utilisation

Pour utiliser les templates Hygen, deux options sont disponibles :

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

## Conclusion

L'implémentation de Hygen pour le dossier scripts permet de générer rapidement et de manière cohérente des scripts. Les templates sont conçus pour s'intégrer parfaitement avec la structure existante et respecter les conventions de codage du projet.
