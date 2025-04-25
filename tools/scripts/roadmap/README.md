# Roadmap Tools

Ce répertoire contient des outils pour la gestion, l'analyse et la manipulation des fichiers de roadmap du projet.

## Structure du répertoire

La structure est organisée de manière modulaire pour faciliter la maintenance et l'évolution des outils :

```
scripts/roadmap/
├── _templates/                  # Templates Hygen pour la génération de scripts
├── core/                        # Fonctionnalités de base
│   ├── conversion/              # Scripts de conversion de format
│   ├── structure/               # Scripts de gestion de structure
│   └── validation/              # Scripts de validation
├── journal/                     # Fonctionnalités liées au journal
│   ├── entries/                 # Gestion des entrées de journal
│   ├── notifications/           # Notifications liées au journal
│   └── reports/                 # Génération de rapports
├── management/                  # Gestion des tâches
│   ├── archive/                 # Archivage des tâches
│   ├── creation/                # Création de tâches
│   └── progress/                # Suivi de progression
├── utils/                       # Utilitaires
│   ├── encoding/                # Gestion d'encodage
│   ├── export/                  # Export vers différents formats
│   └── import/                  # Import depuis différents formats
├── tests/                       # Tests unitaires et d'intégration
│   ├── core/                    # Tests des fonctionnalités de base
│   ├── journal/                 # Tests des fonctionnalités de journal
│   └── management/              # Tests de gestion des tâches
└── docs/                        # Documentation
    ├── examples/                # Exemples d'utilisation
    └── guides/                  # Guides d'utilisation
```

## Fichiers principaux

- `RoadmapConverter.psm1` : Module PowerShell contenant les fonctions de conversion
- `Convert-Roadmap.ps1` : Script principal pour convertir une roadmap
- `Test-RoadmapConverter.ps1` : Script de test pour vérifier le fonctionnement du convertisseur
- `README.md` : Ce fichier

## Utilisation

### Conversion d'une roadmap

Pour convertir une roadmap existante vers le nouveau format de template, utilisez le script `Convert-Roadmap.ps1` :

```powershell
.\Convert-Roadmap.ps1 -SourcePath "Roadmap/roadmap_complete.md" -TemplatePath "Roadmap/roadmap_template.md" -OutputPath "Roadmap/roadmap_complete_new.md"
```

Paramètres :
- `SourcePath` : Chemin vers la roadmap existante
- `TemplatePath` : Chemin vers le fichier de template
- `OutputPath` : Chemin où la nouvelle roadmap sera enregistrée

### Test du convertisseur

Pour tester le fonctionnement du convertisseur, utilisez le script `Test-RoadmapConverter.ps1` :

```powershell
.\Test-RoadmapConverter.ps1
```

Ce script exécute une série de tests pour vérifier que le convertisseur fonctionne correctement.

## Fonctionnement

Le convertisseur fonctionne en quatre étapes :

1. **Analyse** : Le script analyse la roadmap existante et extrait sa structure (sections, sous-sections, tâches, etc.)
2. **Extraction** : Le script extrait la structure du template
3. **Transformation** : Le script transforme la structure de la roadmap selon le format du template
4. **Génération** : Le script génère la nouvelle roadmap à partir de la structure transformée

## Personnalisation

Si vous souhaitez personnaliser le comportement du convertisseur, vous pouvez modifier les fonctions dans le module `RoadmapConverter.psm1` :

- `Parse-ExistingRoadmap` : Analyse une roadmap existante et extrait sa structure
- `Get-TemplateStructure` : Extrait la structure du template
- `Transform-RoadmapStructure` : Transforme la structure de la roadmap selon le template
- `Generate-NewRoadmap` : Génère une nouvelle roadmap à partir du contenu transformé

## Limitations

- Le convertisseur suppose que la roadmap existante suit une structure hiérarchique standard (titres de niveau 1 à 6)
- Certaines informations peuvent être perdues ou simplifiées lors de la conversion
- Les sections complexes ou non standard peuvent ne pas être correctement converties

## Dépannage

Si vous rencontrez des problèmes lors de l'utilisation du convertisseur, vérifiez les points suivants :

1. Assurez-vous que les fichiers source et template existent et sont accessibles
2. Vérifiez que la roadmap existante suit une structure hiérarchique standard
3. Exécutez le script de test pour identifier les problèmes potentiels
4. Consultez les messages d'erreur pour obtenir des informations sur la nature du problème

## Utilisation de Hygen pour générer de nouveaux scripts

Ce projet utilise [Hygen](https://www.hygen.io/) pour générer de nouveaux scripts selon un modèle standardisé.

### Installation de Hygen

Si Hygen n'est pas déjà installé, vous pouvez l'installer globalement avec npm :

```bash
npm install -g hygen
```

### Génération d'un nouveau script

Pour générer un nouveau script, utilisez la commande suivante :

```bash
hygen roadmap new script
```

Vous serez guidé par une série de questions pour configurer votre script :
- Nom du script
- Description
- Catégorie
- Sous-catégorie
- Auteur

### Génération d'un nouveau module

Pour générer un nouveau module PowerShell, utilisez :

```bash
hygen roadmap new module
```

### Génération d'un test unitaire

Pour générer un test unitaire pour un script existant :

```bash
hygen roadmap new test
```

## Bonnes pratiques

- Utilisez toujours Hygen pour créer de nouveaux scripts afin de maintenir une structure cohérente
- Placez les scripts dans les dossiers appropriés selon leur fonction
- Créez des tests unitaires pour chaque script
- Documentez vos scripts avec des commentaires d'aide PowerShell
- Suivez les conventions de nommage : verbe-nom.ps1 pour les scripts

## Contribution

Si vous souhaitez améliorer les outils de roadmap, n'hésitez pas à proposer des modifications. Voici quelques idées d'amélioration :

- Ajouter une interface utilisateur graphique
- Améliorer la détection des sections non standard
- Ajouter des options de personnalisation pour la conversion
- Implémenter une validation plus stricte de la roadmap générée
- Développer de nouveaux outils d'analyse et de visualisation

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
