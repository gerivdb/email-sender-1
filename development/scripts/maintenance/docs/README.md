# Organisation des scripts de maintenance

Ce dossier contient les scripts de maintenance du projet EMAIL_SENDER_1. Une méthode hybride a été mise en place pour assurer une organisation rigoureuse des scripts.

> **Documentation détaillée :**
> - [Gestion du dossier maintenance](../../docs/guides/methodologies/maintenance_folder_management.md)
> - [Hook pre-commit pour l'organisation des scripts](../../docs/guides/git/pre-commit_hook_for_maintenance.md)

## Structure du dossier

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
- **vscode**: Scripts liés à VS Code

## Méthode hybride d'organisation

Une méthode hybride a été mise en place pour assurer l'organisation des scripts:

1. **Hygen**: Génération de nouveaux scripts avec une structure standardisée et placement automatique dans le bon sous-dossier
2. **Hook pre-commit Git**: Vérification et organisation automatique des scripts avant chaque commit
3. **MCP Desktop Commander**: Interface conviviale pour exécuter les commandes de maintenance
4. **Script d'organisation automatique**: Analyse et déplacement des scripts dans les bons sous-dossiers

## Utilisation

### Initialisation de l'environnement

Pour configurer l'environnement de maintenance, exécutez:

```powershell
.\Initialize-MaintenanceEnvironment.ps1 -Force
```plaintext
### Création d'un nouveau script

Pour créer un nouveau script avec Hygen:

```powershell
npx hygen script new
```plaintext
Suivez les instructions pour spécifier le nom, la description et la catégorie du script.

### Organisation des scripts existants

Pour organiser les scripts existants:

```powershell
.\organize\Organize-MaintenanceScripts.ps1 -Force
```plaintext
### Utilisation de MCP Desktop Commander

Pour utiliser MCP Desktop Commander:

```powershell
npx -y @wonderwhy-er/desktop-commander
```plaintext
Sélectionnez la commande `maintenance` pour accéder aux commandes de maintenance.

## Bonnes pratiques

1. **Créez toujours de nouveaux scripts avec Hygen** pour assurer une structure cohérente
2. **Utilisez le hook pre-commit** pour maintenir l'organisation des scripts
3. **Respectez la structure des dossiers** en plaçant les scripts dans les bons sous-dossiers
4. **Documentez vos scripts** avec des commentaires et des exemples d'utilisation
5. **Suivez les standards de codage** du projet

## Maintenance de l'organisation

L'organisation des scripts est maintenue par:

1. Le hook pre-commit qui vérifie et organise automatiquement les scripts avant chaque commit
2. Le script d'organisation automatique qui peut être exécuté manuellement
3. L'utilisation de Hygen pour créer de nouveaux scripts avec une structure standardisée

## Résolution des problèmes

Si vous rencontrez des problèmes avec l'organisation des scripts:

1. Vérifiez que Hygen est correctement installé: `npx hygen --version`
2. Vérifiez que le hook pre-commit est installé: `cat .git/hooks/pre-commit`
3. Exécutez le script d'organisation manuellement: `.\organize\Organize-MaintenanceScripts.ps1 -Force`
4. Consultez les journaux pour identifier les erreurs

## Tests

Des tests unitaires et d'intégration sont disponibles pour vérifier le bon fonctionnement des scripts d'organisation:

```powershell
.\test\Run-TestSuite.ps1 -OutputPath ".\reports" -GenerateHTML
```plaintext
Pour exécuter uniquement les tests unitaires:

```powershell
.\test\Run-AllTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
```plaintext
Pour vérifier l'organisation des scripts:

```powershell
.\monitoring\Check-ScriptsOrganization.ps1
```plaintext