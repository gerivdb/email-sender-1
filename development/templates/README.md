# Templates Hygen pour les modes opérationnels

Ce répertoire contient les templates Hygen utilisés pour générer les modes opérationnels et leurs composants associés.

## Structure des templates

```
_templates/
  mode/
    new/                      # Génération d'un nouveau mode
    add-command/              # Ajout d'une commande à un mode existant
    add-workflow/             # Création d'un nouveau workflow
  common/
    new/                      # Génération du module commun
  test/
    unit/                     # Génération de tests unitaires
    integration/              # Génération de tests d'intégration
  doc/
    user/                     # Documentation utilisateur
    dev/                      # Documentation développeur
```

## Utilisation

### Création d'un nouveau mode

```bash
hygen mode new --name MODE_NAME --description "Description du mode" --category "Catégorie"
```

Options disponibles :
- `--name` : Nom du mode (en majuscules, ex: DEBUG)
- `--description` : Description du mode
- `--category` : Catégorie du mode (analyse, développement, optimisation, spécialisé)
- `--commands` : Liste des commandes spécifiques (format: "CMD1,CMD2,CMD3")

### Ajout d'une commande à un mode existant

```bash
hygen mode add-command --mode MODE_NAME --name COMMAND_NAME --description "Description de la commande"
```

Options disponibles :
- `--mode` : Nom du mode existant
- `--name` : Nom de la commande (en majuscules)
- `--description` : Description de la commande
- `--params` : Paramètres de la commande (format: "param1:type1,param2:type2")

### Création d'un nouveau workflow

```bash
hygen mode add-workflow --name WORKFLOW_NAME --modes "MODE1,MODE2,MODE3" --description "Description du workflow"
```

Options disponibles :
- `--name` : Nom du workflow (en majuscules)
- `--modes` : Liste des modes impliqués (format: "MODE1,MODE2,MODE3")
- `--description` : Description du workflow
- `--category` : Catégorie du workflow (développement, correction, optimisation, release)

## Exemples

### Création du mode DEBUG

```bash
hygen mode new --name DEBUG --description "Résolution de bugs" --category "développement" --commands "TRACE,BREAK,STEP,VAR,FIX"
```

### Ajout d'une commande au mode DEBUG

```bash
hygen mode add-command --mode DEBUG --name MEMORY --description "Analyse de l'utilisation mémoire" --params "process:string,depth:int"
```

### Création d'un workflow de correction de bug

```bash
hygen mode add-workflow --name FIX_WORKFLOW --modes "DEBUG,TEST,REVIEW,GIT" --description "Cycle complet de correction de bug" --category "correction"
```

## Personnalisation

Les templates peuvent être personnalisés en modifiant les fichiers .ejs dans les répertoires correspondants. Consultez la documentation de Hygen pour plus d'informations sur la syntaxe des templates.
