# Gestion du dossier maintenance

Ce document explique la structure et la gestion du dossier `development/scripts/maintenance` dans le projet EMAIL_SENDER_1.

## Structure du dossier

Le dossier `maintenance` est organisé en sous-dossiers thématiques pour faciliter la recherche et la maintenance des scripts. Voici la structure actuelle :

- **api** : Scripts d'analyse et de traitement des données
- **augment** : Scripts liés à Augment Code
- **backups** : Fichiers de sauvegarde (.bak)
- **cleanup** : Scripts de nettoyage et de réparation
- **docs** : Scripts de documentation
- **duplication** : Scripts de gestion des duplications
- **encoding** : Scripts de gestion des encodages
- **environment-compatibility** : Scripts de compatibilité d'environnement
- **error-handling** : Scripts de gestion des erreurs
- **error-learning** : Scripts d'apprentissage des erreurs
- **error-prevention** : Scripts de prévention des erreurs
- **git** : Scripts liés à Git
- **logs** : Scripts de gestion des journaux
- **mcp** : Scripts liés à MCP
- **migrate** : Scripts de migration
- **modes** : Scripts liés aux modes opérationnels
- **monitoring** : Scripts de surveillance
- **organize** : Scripts d'organisation
- **parallel-processing** : Scripts de traitement parallèle
- **paths** : Scripts de gestion des chemins
- **performance** : Scripts de performance
- **phase6** : Scripts de la phase 6
- **ps7-migration** : Scripts de migration vers PowerShell 7
- **references** : Scripts de gestion des références
- **registry** : Scripts de gestion du registre
- **repo** : Scripts de gestion du dépôt
- **roadmap** : Scripts liés à la roadmap
- **services** : Scripts de gestion des services
- **standards** : Scripts de gestion des standards
- **test** : Scripts de test
- **utils** : Scripts utilitaires divers
- **vscode** : Scripts liés à VS Code

## Règles d'organisation

1. **Aucun script à la racine** : Tous les scripts PowerShell (.ps1, .psm1, .psd1) doivent être placés dans le sous-dossier approprié. Les seuls fichiers autorisés à la racine sont :
   - README.md
   - Initialize-MaintenanceEnvironment.ps1

2. **Nommage des scripts** : Les scripts doivent suivre les conventions de nommage PowerShell :
   - Utiliser des verbes approuvés (Get, Set, New, Remove, etc.)
   - Utiliser le format PascalCase (Verb-Noun.ps1)
   - Être descriptifs et clairs

3. **Documentation des scripts** : Chaque script doit inclure un en-tête de documentation avec :
   - Synopsis
   - Description
   - Paramètres
   - Exemples d'utilisation
   - Notes (version, auteur, date de création)

## Mécanismes d'organisation automatique

Plusieurs mécanismes ont été mis en place pour maintenir l'organisation du dossier maintenance :

### 1. Hook pre-commit Git

Un hook pre-commit Git a été installé pour vérifier et organiser automatiquement les scripts avant chaque commit. Ce hook :
- Détecte les scripts PowerShell ajoutés à la racine du dossier maintenance
- Exécute automatiquement le script d'organisation
- Ajoute les fichiers déplacés au commit en cours

Pour réinstaller le hook pre-commit :
```powershell
.\development\scripts\maintenance\git\Install-PreCommitHook.ps1 -Force
```plaintext
### 2. Scripts d'organisation

Deux scripts sont disponibles pour organiser les fichiers :

#### Organize-MaintenanceScripts.ps1

Ce script analyse les fichiers PowerShell à la racine du dossier maintenance et les déplace dans les sous-dossiers appropriés en fonction de leur contenu et de leur nom.

```powershell
.\development\scripts\maintenance\organize\Organize-MaintenanceScripts.ps1 -Force
```plaintext
#### Move-ExistingScripts.ps1

Ce script utilise une classification prédéfinie pour déplacer les scripts dans les bons sous-dossiers.

```powershell
.\development\scripts\maintenance\organize\Move-ExistingScripts.ps1 -Force
```plaintext
### 3. Script de vérification

Un script de vérification est disponible pour s'assurer que l'organisation est correcte :

```powershell
.\development\scripts\maintenance\monitoring\Check-ScriptsOrganization.ps1
```plaintext
Ce script vérifie s'il reste des scripts à la racine du dossier maintenance et génère un rapport sur l'organisation des scripts.

### 4. Génération de nouveaux scripts avec Hygen

Pour créer de nouveaux scripts avec une structure standardisée, utilisez Hygen :

```powershell
npx hygen script new
```plaintext
Suivez les instructions pour spécifier le nom, la description et la catégorie du script.

## Initialisation de l'environnement

Pour configurer l'environnement de maintenance, exécutez :

```powershell
.\development\scripts\maintenance\Initialize-MaintenanceEnvironment.ps1 -Force
```plaintext
Ce script effectue les actions suivantes :
1. Vérifie les prérequis (Node.js, Git)
2. Installe Hygen si nécessaire
3. Configure le hook pre-commit Git
4. Organise les scripts existants
5. Configure MCP Desktop Commander
6. Déplace les scripts existants dans les bons sous-dossiers
7. Vérifie l'organisation des scripts
8. Propose d'installer une tâche planifiée pour vérifier régulièrement l'organisation

## Tests

Des tests unitaires et d'intégration sont disponibles pour vérifier le bon fonctionnement des scripts d'organisation :

```powershell
.\development\scripts\maintenance\test\Run-TestSuite.ps1 -OutputPath ".\reports" -GenerateHTML
```plaintext
## Bonnes pratiques

1. **Créez toujours de nouveaux scripts avec Hygen** pour assurer une structure cohérente
2. **Utilisez le hook pre-commit** pour maintenir l'organisation des scripts
3. **Respectez la structure des dossiers** en plaçant les scripts dans les bons sous-dossiers
4. **Documentez vos scripts** avec des commentaires et des exemples d'utilisation
5. **Suivez les standards de codage** du projet
6. **Vérifiez régulièrement l'organisation** des scripts pour détecter les problèmes

## Résolution des problèmes

Si vous rencontrez des problèmes avec l'organisation des scripts :

1. Vérifiez que Hygen est correctement installé : `npx hygen --version`
2. Vérifiez que le hook pre-commit est installé : `cat .git\hooks\pre-commit`
3. Exécutez le script d'organisation manuellement : `.\development\scripts\maintenance\organize\Organize-MaintenanceScripts.ps1 -Force`
4. Consultez les journaux pour identifier les erreurs

## Conclusion

Cette organisation rigoureuse des scripts de maintenance facilite la recherche et la maintenance des scripts, tout en assurant une structure cohérente et une documentation claire. Les mécanismes d'organisation automatique garantissent que cette structure est maintenue au fil du temps.
