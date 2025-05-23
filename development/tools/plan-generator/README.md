# GoPlanGen - Générateur de Plans de Développement Modulaire en Go

GoPlanGen est un outil en ligne de commande écrit en Go pour générer des plans de développement au format Markdown. Il a été conçu pour remplacer Hygen dans la génération de plans, offrant une solution plus rapide, sans dépendance externe, modulaire et flexible.

## Architecture modulaire

Le générateur est maintenant organisé en modules suivant les principes SOLID et KISS :

- **models** : Définit les structures de données (Plan, Phase, Task)
- **utils** : Fonctions utilitaires et helpers
- **generator** : Fonctions de génération des tâches et des phases
- **io** : Opérations d'entrée/sortie pour les fichiers
- **interactive** : Mode interactif pour la création de plans
- **cmd** : Point d'entrée de l'application

Cette architecture modulaire facilite la maintenance, le débogage et l'évolution future du générateur.

## Avantages par rapport à Hygen

- **Performance** : Génération de plans quasi-instantanée
- **Sans dépendance** : Ne nécessite que le binaire Go (ou le binaire compilé)
- **Non-interactif par défaut** : Parfait pour l'automatisation
- **Multiplateforme** : Fonctionne sur Windows, Linux et macOS
- **Maintenance simplifiée** : Une seule technologie (Go) au lieu de Node.js + plusieurs dépendances

## Installation

### Prérequis

- [Go](https://golang.org/dl/) (version 1.16 ou supérieure) pour compiler le code source

### Compilation

1. Clonez ou téléchargez ce répertoire
2. Exécutez la commande suivante pour compiler l'outil :

```bash
go build -o goplangen goplangen.go
```

Ou utilisez le script PowerShell fourni :

```powershell
./build-and-run.ps1
```

## Utilisation

### En ligne de commande

```
./goplangen -version v33b -title "MCP Manager Centralisé" -description "Ce plan vise à..." -phases 5 -taskDepth 4 -output "./output"
```

### Hiérarchie des tâches

L'option `-taskDepth` vous permet de contrôler la profondeur maximale des tâches dans le plan généré :

- **Niveau 1** : Tâches principales uniquement (très simple)
- **Niveau 2-3** : Structure à deux ou trois niveaux (recommandé pour la plupart des projets)
- **Niveau 4-5** : Structure détaillée pour les projets complexes
- **Niveau 6-7** : Structure très granulaire pour les projets nécessitant un découpage fin des tâches

Exemple avec une profondeur minimale (niveau 1) :
```
./goplangen -version v40 -title "Plan Simple" -taskDepth 1
```

Exemple avec une profondeur maximale (niveau 7) :
```
./goplangen -version v39 -title "Plan Détaillé" -taskDepth 7
```

### Options disponibles

| Option | Description | Défaut |
| ------ | ----------- | ------ |
| `-version` | Numéro de version du plan (ex: v33b) | v1 |
| `-title` | Titre du plan de développement | Plan par défaut |
| `-description` | Description du plan | Description du plan de développement |
| `-phases` | Nombre de phases (1-6) | 5 |
| `-taskDepth` | Profondeur maximale des tâches (1-7) | 4 |
| `-phaseDetails` | Détails des phases au format JSON | {} |
| `-output` | Répertoire de sortie | ./output |
| `-interactive` | Exécuter en mode interactif | false |
| `-import` | Importer un plan depuis un fichier JSON | "" |
| `-importMD` | Importer et mettre à jour un plan à partir d'un fichier Markdown | "" |
| `-exportJSON` | Exporter également le plan au format JSON | false |

### Exemples

Générer un plan simple :
```
./goplangen -version v33b -title "MCP Manager" -phases 3
```

Générer un plan complet :
```
./goplangen -version v33b -title "MCP Manager Centralisé" -description "Ce plan vise à concevoir, développer et intégrer un MCP Manager centralisé pour orchestrer les serveurs MCP, gérer leurs capacités, et faciliter la communication avec le MCP Gateway." -phases 5 -phaseDetails "{\"1\":{\"inputs\":\"API Gateway\"}}" -output "./plans"
```

Utiliser le mode interactif :
```
./goplangen -interactive
```

Importer et mettre à jour un plan existant depuis un fichier Markdown :
```
./goplangen -importMD "./plans/plan-dev-v33b-mcp-manager.md" -version v33c -exportJSON
```

Importer un plan depuis un fichier JSON :
```
./goplangen -import "./plans/plan-dev-v33b-mcp-manager.json" -progress 25
```

## Structure du plan généré

Le plan généré est au format Markdown avec la structure suivante :

```markdown
# Plan de développement v33b - MCP Manager Centralisé
*Version 1.0 - 2025-05-23 - Progression globale : 0%*

Description du plan...

## Table des matières
- [1] Phase 1
- [2] Phase 2
...

## 1. Phase 1 (Phase 1)
  - [ ] **1.1** Tâche principale 1 - Phase d'analyse et de conception.
  - Étape 1 : Définir les objectifs
  ...
```

## Personnalisation

Le code source est organisé pour permettre facilement la personnalisation des templates. Vous pouvez modifier les fonctions suivantes pour adapter la génération :

- `PhaseDescription` : Descriptions par défaut des phases
- `GenerateTasksForPhase` : Structure et contenu des tâches
- `GenerateMarkdown` : Template Markdown complet

## Fonctionnalités avancées

### Import/Export JSON
L'outil prend en charge l'import et l'export de plans au format JSON, permettant une interopérabilité avec d'autres systèmes et une édition facile.

```
# Exporter un plan en JSON en plus du Markdown
./goplangen -title "Mon Plan" -exportJSON

# Importer un plan existant depuis JSON
./goplangen -import "./plans/mon-plan.json" 
```

### Mode interactif
Le mode interactif permet de guider l'utilisateur dans la création du plan via une interface en ligne de commande conviviale.

```
./goplangen -interactive
```

### Mise à jour de plans existants
Vous pouvez importer un plan existant au format Markdown pour le mettre à jour avec de nouvelles informations.

```
./goplangen -importMD "./plans/plan-existant.md" -progress 25
```

## Évolutions futures

- Interface web pour la génération de plans
- Support pour plusieurs templates personnalisables
- Génération de graphiques et diagrammes
- Intégration avec des systèmes de gestion de projet

## Support

Pour toute question ou suggestion, veuillez ouvrir une issue sur le dépôt du projet.

## Licence

MIT
