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

- `script/new/` : Templates pour les scripts PowerShell
  - `index.js` : Configuration du template
  - `script.ejs` : Template EJS pour les scripts PowerShell

## Ajout de nouveaux templates

Pour ajouter un nouveau type de template, utilisez la commande suivante :

```bash
npx hygen generator new [nom-du-template]
```

Puis modifiez les fichiers générés selon vos besoins.
