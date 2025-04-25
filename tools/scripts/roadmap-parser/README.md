# Roadmap Parser

Ce répertoire contient des outils pour l'analyse, la manipulation et la gestion des fichiers de roadmap du projet.

## Structure du répertoire

La structure est organisée de manière modulaire pour faciliter la maintenance et l'évolution des outils :

```
scripts/roadmap-parser/
├── core/                        # Fonctionnalités de base
│   ├── parser/                  # Parseurs de roadmap
│   ├── model/                   # Modèles de données
│   ├── converter/               # Convertisseurs de format
│   └── structure/               # Gestion de structure
├── modes/                       # Modes opérationnels
│   ├── debug/                   # Mode de débogage
│   ├── test/                    # Mode de test
│   ├── archi/                   # Mode d'architecture
│   ├── check/                   # Mode de vérification
│   ├── gran/                    # Mode de granularisation
│   ├── dev-r/                   # Mode de développement roadmap
│   ├── review/                  # Mode de revue
│   └── opti/                    # Mode d'optimisation
├── analysis/                    # Outils d'analyse
│   ├── dependencies/            # Analyse de dépendances
│   ├── performance/             # Analyse de performance
│   ├── validation/              # Validation de roadmap
│   └── reporting/               # Génération de rapports
├── utils/                       # Utilitaires
│   ├── encoding/                # Gestion d'encodage
│   ├── export/                  # Export vers différents formats
│   ├── import/                  # Import depuis différents formats
│   └── helpers/                 # Fonctions d'aide
├── tests/                       # Tests
│   ├── unit/                    # Tests unitaires
│   ├── integration/             # Tests d'intégration
│   ├── performance/             # Tests de performance
│   └── validation/              # Tests de validation
└── docs/                        # Documentation
    ├── examples/                # Exemples d'utilisation
    ├── guides/                  # Guides d'utilisation
    └── api/                     # Documentation de l'API
```

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
hygen roadmap-parser new script
```

Vous serez guidé par une série de questions pour configurer votre script :
- Nom du script
- Description
- Catégorie
- Sous-catégorie
- Auteur

## Modes opérationnels

Le module roadmap-parser prend en charge plusieurs modes opérationnels, chacun avec un objectif spécifique :

- **DEBUG** : Mode de débogage pour identifier et résoudre les problèmes
- **TEST** : Mode de test pour valider les fonctionnalités
- **ARCHI** : Mode d'architecture pour analyser et améliorer la structure
- **CHECK** : Mode de vérification pour valider l'état d'avancement
- **GRAN** : Mode de granularisation pour décomposer les tâches complexes
- **DEV-R** : Mode de développement roadmap pour implémenter les tâches
- **REVIEW** : Mode de revue pour analyser la qualité du code
- **OPTI** : Mode d'optimisation pour améliorer les performances

Chaque mode est implémenté dans un script dédié dans le dossier `modes/`.

## Bonnes pratiques

- Utilisez toujours Hygen pour créer de nouveaux scripts afin de maintenir une structure cohérente
- Placez les scripts dans les dossiers appropriés selon leur fonction
- Créez des tests unitaires pour chaque script
- Documentez vos scripts avec des commentaires d'aide PowerShell
- Suivez les conventions de nommage : verbe-nom.ps1 pour les scripts

## Contribution

Si vous souhaitez améliorer le module roadmap-parser, n'hésitez pas à proposer des modifications. Voici quelques idées d'amélioration :

- Ajouter de nouveaux modes opérationnels
- Améliorer les performances des parseurs existants
- Ajouter de nouvelles fonctionnalités d'analyse
- Étendre la couverture des tests
- Améliorer la documentation

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
