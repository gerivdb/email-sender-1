# Templates Hygen

Ce dossier contient les templates Hygen pour générer automatiquement différents types de fichiers dans le projet.

## Utilisation

### Générer un nouveau script PowerShell

```bash
npx hygen script new --name nom-du-script --category maintenance/sous-dossier --description "Description du script" --author "Votre Nom"
```

#### Paramètres

- `--name` : Nom du script (obligatoire)
- `--category` : Catégorie/dossier où placer le script (par défaut: 'maintenance')
- `--description` : Description du script (par défaut: 'Script PowerShell')
- `--author` : Auteur du script (par défaut: 'Augment Agent')

#### Exemples

```bash
# Créer un script de maintenance basique
npx hygen script new --name clean-temp-files

# Créer un script dans une sous-catégorie spécifique
npx hygen script new --name optimize-database --category database --description "Optimise la base de données" --author "John Doe"

# Créer un script dans un sous-dossier de maintenance
npx hygen script new --name update-config --category maintenance/config --description "Met à jour les fichiers de configuration"
```

## Structure des templates

Voici la liste des sous-dossiers et types de templates actuellement disponibles dans ce dossier :

- `plan-dev/` : Templates pour la création de plans de développement
- `doc-structure/` : Templates pour la documentation de structure et la migration
- `maintenance/` : Scripts et utilitaires de maintenance
- `mcp-server/` : Templates pour la configuration ou génération de serveurs MCP
- `mode/` : Génération de modes, commandes, et tests associés
- `powershell-module/` : Templates pour modules PowerShell
- `prd/` : Templates pour la documentation PRD
- `roadmap/` : Génération de roadmaps
- `roadmap-parser/` : Outils de parsing de roadmap
- `script/` : Génération de scripts PowerShell
- `script-analysis/` : Analyse de scripts
- `script-automation/` : Automatisation de scripts
- `script-integration/` : Intégration de scripts
- `script-test/` : Tests de scripts

## Ajout de nouveaux templates

Pour ajouter un nouveau type de template, utilisez la commande suivante :

```bash
npx hygen generator new [nom-du-template]
```

Puis modifiez les fichiers générés selon vos besoins.

---

Dernière mise à jour : 2025-05-21
