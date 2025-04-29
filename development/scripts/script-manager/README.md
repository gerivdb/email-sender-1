# Script Manager

Ce dossier contient le Script Manager du projet EMAIL_SENDER_1, un ensemble d'outils pour gérer, analyser et organiser les scripts du projet.

> **Documentation détaillée :**
> - [Guide du Script Manager](../../docs/guides/methodologies/script_manager.md)

## Structure du dossier

Le dossier est organisé en sous-dossiers thématiques :

- **analysis** : Scripts d'analyse des scripts
- **organization** : Scripts d'organisation des scripts
- **inventory** : Scripts de gestion de l'inventaire des scripts
- **documentation** : Scripts de génération de documentation
- **monitoring** : Scripts de surveillance des scripts
- **optimization** : Scripts d'optimisation des scripts
- **testing** : Scripts de test
- **configuration** : Scripts et fichiers de configuration
- **generation** : Scripts de génération de nouveaux scripts
- **integration** : Scripts d'intégration avec d'autres outils
- **ui** : Scripts d'interface utilisateur
- **core** : Scripts principaux du manager
- **config** : Configuration (ancien)
- **data** : Données générées (ancien)
- **modules** : Modules du gestionnaire (ancien)

## Fonctionnalités

- Indexation et catalogage des scripts du projet
- Analyse des scripts pour en extraire des informations structurelles
- Détection des dépendances entre les scripts
- Évaluation de la qualité du code
- Organisation des scripts dans une structure de dossiers cohérente
- Génération de nouveaux scripts avec une structure standardisée
- Documentation des scripts et des modules

## Utilisation

### Initialisation de l'environnement

Pour configurer l'environnement du script manager, exécutez :

```powershell
.\script-manager.ps1 -Force
```

### Création d'un nouveau script

Pour créer un nouveau script avec Hygen :

```powershell
npx hygen script new
```

Suivez les instructions pour spécifier le nom, la description et la catégorie du script.

### Création d'un nouveau module

Pour créer un nouveau module avec Hygen :

```powershell
npx hygen module new
```

Suivez les instructions pour spécifier le nom, la description et la catégorie du module.

### Organisation des scripts

Pour organiser les scripts existants :

```powershell
.\organization\Organize-ManagerScripts.ps1 -Force
```

### Surveillance des scripts

Pour surveiller les scripts et détecter les problèmes :

```powershell
.\monitoring\Monitor-ManagerScripts.ps1
```

### Utilisation de MCP Desktop Commander

Pour utiliser MCP Desktop Commander :

```powershell
npx -y @wonderwhy-er/desktop-commander
```

Sélectionnez la commande `manager` pour accéder aux commandes du script manager.

## Bonnes pratiques

1. **Créez toujours de nouveaux scripts avec Hygen** pour assurer une structure cohérente
2. **Utilisez le hook pre-commit** pour maintenir l'organisation des scripts
3. **Respectez la structure des dossiers** en plaçant les scripts dans les bons sous-dossiers
4. **Documentez vos scripts** avec des commentaires et des exemples d'utilisation
5. **Suivez les standards de codage** du projet
6. **Vérifiez régulièrement l'organisation** des scripts pour détecter les problèmes

## Tests

Des tests unitaires sont disponibles pour vérifier le bon fonctionnement des scripts :

```powershell
.\testing\Test-ManagerScripts.ps1
```

## Résolution des problèmes

Si vous rencontrez des problèmes avec le script manager :

1. Vérifiez que Hygen est correctement installé : `npx hygen --version`
2. Vérifiez que le hook pre-commit est installé : `cat .git\hooks\pre-commit`
3. Exécutez le script d'organisation manuellement : `.\organization\Organize-ManagerScripts.ps1 -Force`
4. Consultez les journaux pour identifier les erreurs

