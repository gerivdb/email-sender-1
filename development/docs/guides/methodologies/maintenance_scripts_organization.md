# Guide d'organisation des scripts de maintenance

Ce guide explique la méthode hybride mise en place pour organiser les scripts de maintenance du projet EMAIL_SENDER_1.

## Objectifs

- Assurer une organisation rigoureuse des scripts de maintenance
- Faciliter la création de nouveaux scripts avec une structure standardisée
- Automatiser l'organisation des scripts pour éviter les erreurs humaines
- Maintenir une documentation claire sur l'organisation des scripts
- Surveiller régulièrement l'organisation pour détecter les problèmes

## Méthode hybride

La méthode hybride combine plusieurs approches complémentaires:

1. **Hygen**: Génération de nouveaux scripts avec une structure standardisée
2. **Hook pre-commit Git**: Vérification et organisation automatique des scripts avant chaque commit
3. **MCP Desktop Commander**: Interface conviviale pour exécuter les commandes de maintenance
4. **Script d'organisation automatique**: Analyse et déplacement des scripts dans les bons sous-dossiers
5. **Tâche planifiée**: Vérification régulière de l'organisation des scripts

## Structure des dossiers

Les scripts sont organisés dans des sous-dossiers thématiques:

- **api**: Scripts d'analyse et de traitement des données
- **augment**: Scripts liés à Augment Code
- **backups**: Scripts de sauvegarde
- **cleanup**: Scripts de nettoyage et de réparation
- **docs**: Scripts de documentation
- **duplication**: Scripts de gestion des duplications
- **encoding**: Scripts de gestion des encodages
- **environment-compatibility**: Scripts de compatibilité d'environnement
- **error-handling**: Scripts de gestion des erreurs
- **error-learning**: Scripts d'apprentissage des erreurs
- **error-prevention**: Scripts de prévention des erreurs
- **git**: Scripts liés à Git
- **logs**: Scripts de gestion des journaux
- **mcp**: Scripts liés à MCP
- **migrate**: Scripts de migration
- **modes**: Scripts liés aux modes opérationnels
- **monitoring**: Scripts de surveillance
- **organize**: Scripts d'organisation
- **parallel-processing**: Scripts de traitement parallèle
- **paths**: Scripts de gestion des chemins
- **performance**: Scripts de performance
- **phase6**: Scripts de la phase 6
- **ps7-migration**: Scripts de migration vers PowerShell 7
- **references**: Scripts de gestion des références
- **registry**: Scripts de gestion du registre
- **repo**: Scripts de gestion du dépôt
- **roadmap**: Scripts liés à la roadmap
- **services**: Scripts de gestion des services
- **standards**: Scripts de gestion des standards
- **test**: Scripts de test
- **utils**: Scripts utilitaires divers
- **vscode**: Scripts liés à VS Code

## Installation et configuration

### Initialisation de l'environnement

Pour configurer l'environnement de maintenance, exécutez:

```powershell
.\Initialize-MaintenanceEnvironment.ps1 -Force
```

Ce script effectue les actions suivantes:

1. Vérifie les prérequis (Node.js, Git)
2. Installe Hygen si nécessaire
3. Configure le hook pre-commit Git
4. Organise les scripts existants
5. Configure MCP Desktop Commander
6. Déplace les scripts existants dans les bons sous-dossiers
7. Vérifie l'organisation des scripts
8. Propose d'installer une tâche planifiée pour vérifier régulièrement l'organisation

### Installation manuelle des composants

Si vous préférez installer les composants manuellement:

1. **Hygen**:
   ```powershell
   npm install -g hygen
   ```

2. **Hook pre-commit Git**:
   ```powershell
   .\git\Install-PreCommitHook.ps1 -Force
   ```

3. **MCP Desktop Commander**:
   ```powershell
   Copy-Item -Path ".\mcp\mcp-config.json" -Destination "$repoRoot\mcp-config.json" -Force
   ```

4. **Tâche planifiée**:
   ```powershell
   .\monitoring\Install-OrganizationCheckTask.ps1 -TaskName "CheckScriptsOrganization" -Frequency Daily -Time "09:00" -Force
   ```

## Utilisation quotidienne

### Création d'un nouveau script

Pour créer un nouveau script avec Hygen:

```powershell
npx hygen script new
```

Suivez les instructions pour spécifier:
- Le nom du script (sans extension .ps1)
- La description du script
- La catégorie du script (sous-dossier de destination)

Le script sera créé avec une structure standardisée dans le sous-dossier approprié.

### Organisation des scripts existants

Pour organiser les scripts existants:

```powershell
.\organize\Organize-MaintenanceScripts.ps1 -Force
```

Ce script analyse les fichiers PowerShell à la racine du dossier maintenance et les déplace dans les sous-dossiers appropriés en fonction de leur contenu et de leur nom.

### Déplacement des scripts existants

Pour déplacer les scripts existants selon une classification prédéfinie:

```powershell
.\organize\Move-ExistingScripts.ps1 -Force
```

Ce script utilise une classification prédéfinie pour déplacer les scripts dans les bons sous-dossiers.

### Vérification de l'organisation

Pour vérifier l'organisation des scripts:

```powershell
.\monitoring\Check-ScriptsOrganization.ps1
```

Ce script vérifie si des scripts PowerShell se trouvent à la racine du dossier maintenance et génère un rapport sur l'organisation des scripts.

### Utilisation de MCP Desktop Commander

Pour utiliser MCP Desktop Commander:

```powershell
npx -y @wonderwhy-er/desktop-commander
```

Sélectionnez la commande `maintenance` pour accéder aux commandes de maintenance:
- `organize`: Organiser les scripts de maintenance
- `create-script`: Créer un nouveau script avec Hygen
- `install-hooks`: Installer les hooks Git
- `list-categories`: Lister les catégories de scripts disponibles
- `list-scripts`: Lister tous les scripts par catégorie

## Bonnes pratiques

1. **Créez toujours de nouveaux scripts avec Hygen** pour assurer une structure cohérente
2. **Utilisez le hook pre-commit** pour maintenir l'organisation des scripts
3. **Respectez la structure des dossiers** en plaçant les scripts dans les bons sous-dossiers
4. **Documentez vos scripts** avec des commentaires et des exemples d'utilisation
5. **Suivez les standards de codage** du projet
6. **Vérifiez régulièrement l'organisation** des scripts pour détecter les problèmes
7. **Utilisez MCP Desktop Commander** pour exécuter les commandes de maintenance

## Résolution des problèmes

### Problèmes courants

1. **Scripts à la racine du dossier maintenance**:
   - Exécutez `.\organize\Organize-MaintenanceScripts.ps1 -Force` pour les déplacer automatiquement
   - Ou exécutez `.\organize\Move-ExistingScripts.ps1 -Force` pour utiliser la classification prédéfinie

2. **Erreurs lors de la création de scripts avec Hygen**:
   - Vérifiez que Hygen est correctement installé: `npx hygen --version`
   - Vérifiez que les templates Hygen existent: `Get-ChildItem -Path ".\maintenance\_templates"`

3. **Hook pre-commit non fonctionnel**:
   - Vérifiez que le hook est installé: `cat .git\hooks\pre-commit`
   - Réinstallez le hook: `.\git\Install-PreCommitHook.ps1 -Force`

4. **MCP Desktop Commander non fonctionnel**:
   - Vérifiez que le fichier de configuration existe: `Test-Path ".\mcp-config.json"`
   - Réinstallez la configuration: `Copy-Item -Path ".\mcp\mcp-config.json" -Destination "$repoRoot\mcp-config.json" -Force`

### Commandes de diagnostic

1. **Vérifier l'organisation des scripts**:
   ```powershell
   .\monitoring\Check-ScriptsOrganization.ps1
   ```

2. **Lister les catégories de scripts disponibles**:
   ```powershell
   Get-ChildItem -Path ".\maintenance" -Directory | Select-Object -ExpandProperty Name | Sort-Object
   ```

3. **Lister tous les scripts par catégorie**:
   ```powershell
   Get-ChildItem -Path ".\maintenance" -Directory | ForEach-Object { Write-Host "`n[$($_.Name)]" -ForegroundColor Cyan; Get-ChildItem -Path $_.FullName -File -Filter '*.ps1' | Select-Object -ExpandProperty Name | Sort-Object }
   ```

## Maintenance de l'organisation

L'organisation des scripts est maintenue par:

1. Le hook pre-commit qui vérifie et organise automatiquement les scripts avant chaque commit
2. Le script d'organisation automatique qui peut être exécuté manuellement
3. L'utilisation de Hygen pour créer de nouveaux scripts avec une structure standardisée
4. La tâche planifiée qui vérifie régulièrement l'organisation des scripts

## Personnalisation

### Ajouter une nouvelle catégorie

1. Créez un nouveau sous-dossier dans le dossier maintenance:
   ```powershell
   New-Item -Path ".\maintenance\nouvelle-categorie" -ItemType Directory
   ```

2. Mettez à jour le script d'organisation pour prendre en compte la nouvelle catégorie:
   ```powershell
   # Dans Organize-MaintenanceScripts.ps1, ajoutez une règle pour la nouvelle catégorie
   if ($lowerName -match 'nouveau-mot-cle') { return 'nouvelle-categorie' }
   ```

3. Mettez à jour le prompt Hygen pour inclure la nouvelle catégorie:
   ```javascript
   // Dans _templates/script/new/prompt.js, ajoutez la nouvelle catégorie à la liste des choix
   choices: [
     // ...
     'nouvelle-categorie',
     // ...
   ]
   ```

### Modifier les templates Hygen

Les templates Hygen se trouvent dans le dossier `_templates`:

- `_templates/.hygen.js`: Configuration générale de Hygen
- `_templates/script/new/prompt.js`: Questions posées lors de la création d'un script
- `_templates/script/new/script.ejs.t`: Template du script
- `_templates/script/new/index.ejs.t`: Configuration de la destination du script

Modifiez ces fichiers pour personnaliser les templates selon vos besoins.

## Conclusion

Cette méthode hybride d'organisation des scripts de maintenance combine plusieurs approches complémentaires pour assurer une organisation rigoureuse des scripts. Elle facilite la création de nouveaux scripts avec une structure standardisée, automatise l'organisation des scripts pour éviter les erreurs humaines, et maintient une documentation claire sur l'organisation des scripts.

En suivant ce guide, vous pourrez maintenir une organisation rigoureuse des scripts de maintenance du projet EMAIL_SENDER_1.
