# Roadmap Parser

Ce rÃ©pertoire contient des outils pour l'analyse, la manipulation et la gestion des fichiers de roadmap du projet.

## Structure du rÃ©pertoire

La structure est organisÃ©e de maniÃ¨re modulaire pour faciliter la maintenance et l'Ã©volution des outils :

```plaintext
development/roadmap/scripts-parser/
â”œâ”€â”€ core/                        # FonctionnalitÃ©s de base

â”‚   â”œâ”€â”€ parser/                  # Parseurs de roadmap

â”‚   â”œâ”€â”€ model/                   # ModÃ¨les de donnÃ©es

â”‚   â”œâ”€â”€ converter/               # Convertisseurs de format

â”‚   â””â”€â”€ structure/               # Gestion de structure

â”œâ”€â”€ modes/                       # Modes opÃ©rationnels

â”‚   â”œâ”€â”€ debug/                   # Mode de dÃ©bogage

â”‚   â”œâ”€â”€ test/                    # Mode de test

â”‚   â”œâ”€â”€ archi/                   # Mode d'architecture

â”‚   â”œâ”€â”€ check/                   # Mode de vÃ©rification

â”‚   â”œâ”€â”€ gran/                    # Mode de granularisation

â”‚   â”œâ”€â”€ dev-r/                   # Mode de dÃ©veloppement roadmap

â”‚   â”œâ”€â”€ review/                  # Mode de revue

â”‚   â””â”€â”€ opti/                    # Mode d'optimisation

â”œâ”€â”€ analysis/                    # Outils d'analyse

â”‚   â”œâ”€â”€ dependencies/            # Analyse de dÃ©pendances

â”‚   â”œâ”€â”€ performance/             # Analyse de performance

â”‚   â”œâ”€â”€ validation/              # Validation de roadmap

â”‚   â””â”€â”€ reporting/               # GÃ©nÃ©ration de rapports

â”œâ”€â”€ utils/                       # Utilitaires

â”‚   â”œâ”€â”€ encoding/                # Gestion d'encodage

â”‚   â”œâ”€â”€ export/                  # Export vers diffÃ©rents formats

â”‚   â”œâ”€â”€ import/                  # Import depuis diffÃ©rents formats

â”‚   â””â”€â”€ helpers/                 # Fonctions d'aide

â”œâ”€â”€ development/testing/tests/                       # Tests

â”‚   â”œâ”€â”€ unit/                    # Tests unitaires

â”‚   â”œâ”€â”€ integration/             # Tests d'intÃ©gration

â”‚   â”œâ”€â”€ performance/             # Tests de performance

â”‚   â””â”€â”€ validation/              # Tests de validation

â””â”€â”€ docs/                        # Documentation

    â”œâ”€â”€ examples/                # Exemples d'utilisation

    â”œâ”€â”€ guides/                  # Guides d'utilisation

    â””â”€â”€ api/                     # Documentation de l'API

```plaintext
## Utilisation de Hygen pour gÃ©nÃ©rer de nouveaux scripts

Ce projet utilise [Hygen](https://www.hygen.io/) pour gÃ©nÃ©rer de nouveaux scripts selon un modÃ¨le standardisÃ©.

### Installation de Hygen

Si Hygen n'est pas dÃ©jÃ  installÃ©, vous pouvez l'installer globalement avec npm :

```bash
npm install -g hygen
```plaintext
### GÃ©nÃ©ration d'un nouveau script

Pour gÃ©nÃ©rer un nouveau script, utilisez la commande suivante :

```bash
hygen roadmap-parser new script
```plaintext
Vous serez guidÃ© par une sÃ©rie de questions pour configurer votre script :
- Nom du script
- Description
- CatÃ©gorie
- Sous-catÃ©gorie
- Auteur

## Modes opÃ©rationnels

Le module roadmap-parser prend en charge plusieurs modes opÃ©rationnels, chacun avec un objectif spÃ©cifique :

- **DEBUG** : Mode de dÃ©bogage pour identifier et rÃ©soudre les problÃ¨mes
- **TEST** : Mode de test pour valider les fonctionnalitÃ©s
- **ARCHI** : Mode d'architecture pour analyser et amÃ©liorer la structure
- **CHECK** : Mode de vÃ©rification pour valider l'Ã©tat d'avancement
- **GRAN** : Mode de granularisation pour dÃ©composer les tÃ¢ches complexes
- **DEV-R** : Mode de dÃ©veloppement roadmap pour implÃ©menter les tÃ¢ches
- **REVIEW** : Mode de revue pour analyser la qualitÃ© du code
- **OPTI** : Mode d'optimisation pour amÃ©liorer les performances

Chaque mode est implÃ©mentÃ© dans un script dÃ©diÃ© dans le dossier `modes/`.

## Bonnes pratiques

- Utilisez toujours Hygen pour crÃ©er de nouveaux scripts afin de maintenir une structure cohÃ©rente
- Placez les scripts dans les dossiers appropriÃ©s selon leur fonction
- CrÃ©ez des tests unitaires pour chaque script
- Documentez vos scripts avec des commentaires d'aide PowerShell
- Suivez les conventions de nommage : verbe-nom.ps1 pour les scripts

## Contribution

Si vous souhaitez amÃ©liorer le module roadmap-parser, n'hÃ©sitez pas Ã  proposer des modifications. Voici quelques idÃ©es d'amÃ©lioration :

- Ajouter de nouveaux modes opÃ©rationnels
- AmÃ©liorer les performances des parseurs existants
- Ajouter de nouvelles fonctionnalitÃ©s d'analyse
- Ã‰tendre la couverture des tests
- AmÃ©liorer la documentation

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d'informations.

