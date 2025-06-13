# Roadmap Tools

Ce rÃ©pertoire contient des outils pour la gestion, l'analyse et la manipulation des fichiers de roadmap du projet.

## Structure du rÃ©pertoire

La structure est organisÃ©e de maniÃ¨re modulaire pour faciliter la maintenance et l'Ã©volution des outils :

```plaintext
development/roadmap/scripts/
â”œâ”€â”€ development/templates/                  # Templates Hygen pour la gÃ©nÃ©ration de scripts

â”œâ”€â”€ core/                        # FonctionnalitÃ©s de base

â”‚   â”œâ”€â”€ conversion/              # Scripts de conversion de format

â”‚   â”œâ”€â”€ structure/               # Scripts de gestion de structure

â”‚   â””â”€â”€ validation/              # Scripts de validation

â”œâ”€â”€ journal/                     # FonctionnalitÃ©s liÃ©es au journal

â”‚   â”œâ”€â”€ entries/                 # Gestion des entrÃ©es de journal

â”‚   â”œâ”€â”€ notifications/           # Notifications liÃ©es au journal

â”‚   â””â”€â”€ reports/                 # GÃ©nÃ©ration de rapports

â”œâ”€â”€ management/                  # Gestion des tÃ¢ches

â”‚   â”œâ”€â”€ archive/                 # Archivage des tÃ¢ches

â”‚   â”œâ”€â”€ creation/                # CrÃ©ation de tÃ¢ches

â”‚   â””â”€â”€ progress/                # Suivi de progression

â”œâ”€â”€ utils/                       # Utilitaires

â”‚   â”œâ”€â”€ encoding/                # Gestion d'encodage

â”‚   â”œâ”€â”€ export/                  # Export vers diffÃ©rents formats

â”‚   â””â”€â”€ import/                  # Import depuis diffÃ©rents formats

â”œâ”€â”€ development/testing/tests/                       # Tests unitaires et d'intÃ©gration

â”‚   â”œâ”€â”€ core/                    # Tests des fonctionnalitÃ©s de base

â”‚   â”œâ”€â”€ journal/                 # Tests des fonctionnalitÃ©s de journal

â”‚   â””â”€â”€ management/              # Tests de gestion des tÃ¢ches

â””â”€â”€ docs/                        # Documentation

    â”œâ”€â”€ examples/                # Exemples d'utilisation

    â””â”€â”€ guides/                  # Guides d'utilisation

```plaintext
## Fichiers principaux

- `RoadmapConverter.psm1` : Module PowerShell contenant les fonctions de conversion
- `Convert-Roadmap.ps1` : Script principal pour convertir une roadmap
- `Test-RoadmapConverter.ps1` : Script de test pour vÃ©rifier le fonctionnement du convertisseur
- `README.md` : Ce fichier

## Utilisation

### Conversion d'une roadmap

Pour convertir une roadmap existante vers le nouveau format de template, utilisez le script `Convert-Roadmap.ps1` :

```powershell
.\Convert-Roadmap.ps1 -SourcePath "Roadmap/roadmap_complete.md" -TemplatePath "Roadmap/roadmap_template.md" -OutputPath "Roadmap/roadmap_complete_new.md"
```plaintext
ParamÃ¨tres :
- `SourcePath` : Chemin vers la roadmap existante
- `TemplatePath` : Chemin vers le fichier de template
- `OutputPath` : Chemin oÃ¹ la nouvelle roadmap sera enregistrÃ©e

### Test du convertisseur

Pour tester le fonctionnement du convertisseur, utilisez le script `Test-RoadmapConverter.ps1` :

```powershell
.\Test-RoadmapConverter.ps1
```plaintext
Ce script exÃ©cute une sÃ©rie de tests pour vÃ©rifier que le convertisseur fonctionne correctement.

## Fonctionnement

Le convertisseur fonctionne en quatre Ã©tapes :

1. **Analyse** : Le script analyse la roadmap existante et extrait sa structure (sections, sous-sections, tÃ¢ches, etc.)
2. **Extraction** : Le script extrait la structure du template
3. **Transformation** : Le script transforme la structure de la roadmap selon le format du template
4. **GÃ©nÃ©ration** : Le script gÃ©nÃ¨re la nouvelle roadmap Ã  partir de la structure transformÃ©e

## Personnalisation

Si vous souhaitez personnaliser le comportement du convertisseur, vous pouvez modifier les fonctions dans le module `RoadmapConverter.psm1` :

- `Parse-ExistingRoadmap` : Analyse une roadmap existante et extrait sa structure
- `Get-TemplateStructure` : Extrait la structure du template
- `Transform-RoadmapStructure` : Transforme la structure de la roadmap selon le template
- `Generate-NewRoadmap` : GÃ©nÃ¨re une nouvelle roadmap Ã  partir du contenu transformÃ©

## Limitations

- Le convertisseur suppose que la roadmap existante suit une structure hiÃ©rarchique standard (titres de niveau 1 Ã  6)
- Certaines informations peuvent Ãªtre perdues ou simplifiÃ©es lors de la conversion
- Les sections complexes ou non standard peuvent ne pas Ãªtre correctement converties

## DÃ©pannage

Si vous rencontrez des problÃ¨mes lors de l'utilisation du convertisseur, vÃ©rifiez les points suivants :

1. Assurez-vous que les fichiers source et template existent et sont accessibles
2. VÃ©rifiez que la roadmap existante suit une structure hiÃ©rarchique standard
3. ExÃ©cutez le script de test pour identifier les problÃ¨mes potentiels
4. Consultez les messages d'erreur pour obtenir des informations sur la nature du problÃ¨me

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
hygen roadmap new script
```plaintext
Vous serez guidÃ© par une sÃ©rie de questions pour configurer votre script :
- Nom du script
- Description
- CatÃ©gorie
- Sous-catÃ©gorie
- Auteur

### GÃ©nÃ©ration d'un nouveau module

Pour gÃ©nÃ©rer un nouveau module PowerShell, utilisez :

```bash
hygen roadmap new module
```plaintext
### GÃ©nÃ©ration d'un test unitaire

Pour gÃ©nÃ©rer un test unitaire pour un script existant :

```bash
hygen roadmap new test
```plaintext
## Bonnes pratiques

- Utilisez toujours Hygen pour crÃ©er de nouveaux scripts afin de maintenir une structure cohÃ©rente
- Placez les scripts dans les dossiers appropriÃ©s selon leur fonction
- CrÃ©ez des tests unitaires pour chaque script
- Documentez vos scripts avec des commentaires d'aide PowerShell
- Suivez les conventions de nommage : verbe-nom.ps1 pour les scripts

## Contribution

Si vous souhaitez amÃ©liorer les outils de roadmap, n'hÃ©sitez pas Ã  proposer des modifications. Voici quelques idÃ©es d'amÃ©lioration :

- Ajouter une interface utilisateur graphique
- AmÃ©liorer la dÃ©tection des sections non standard
- Ajouter des options de personnalisation pour la conversion
- ImplÃ©menter une validation plus stricte de la roadmap gÃ©nÃ©rÃ©e
- DÃ©velopper de nouveaux outils d'analyse et de visualisation

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d'informations.

