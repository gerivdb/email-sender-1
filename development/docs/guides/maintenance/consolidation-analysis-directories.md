# Guide de consolidation des dossiers analysis et analytics

## Introduction

Ce guide explique comment consolider les dossiers `development/scripts/analysis` et `development/scripts/analytics` en une structure unifiée et organisée, en éliminant la redondance tout en préservant les fonctionnalités distinctes.

## Problématique

Les dossiers `development/scripts/analysis` et `development/scripts/analytics` ont des fonctions similaires mais avec des objectifs légèrement différents :

1. **development/scripts/analysis** : Contient des scripts pour l'analyse de code source, l'intégration avec des outils tiers d'analyse de code, et la mise à jour de la roadmap.

2. **development/scripts/analytics** : Contient des scripts pour l'analyse de données de performance, la détection d'anomalies, et le calcul de KPIs.

Cette duplication crée de la confusion et de la redondance dans la structure du projet.

## Solution

La solution consiste à consolider ces deux dossiers en une structure unifiée sous `development/scripts/analysis` avec des sous-dossiers clairs qui distinguent leurs fonctions tout en éliminant la redondance.

### Nouvelle structure

```plaintext
development/scripts/analysis/
├── code/                 # Analyse de code source

├── performance/          # Analyse de performance

├── data/                 # Analyse de données

├── reporting/            # Rapports

├── integration/          # Intégration avec des outils tiers

├── roadmap/              # Scripts liés à la roadmap

├── common/               # Modules et outils communs

│   ├── modules/
│   ├── tools/
│   └── plugins/
└── docs/                 # Documentation

```plaintext
## Implémentation

Un script PowerShell a été créé pour effectuer cette consolidation : `development/scripts/maintenance/Consolidate-AnalysisDirectories.ps1`.

### Utilisation du script

```powershell
# Exécuter en mode simulation (DryRun) pour voir les actions qui seraient effectuées

.\Consolidate-AnalysisDirectories.ps1 -DryRun

# Exécuter en mode réel avec confirmation pour chaque action

.\Consolidate-AnalysisDirectories.ps1

# Exécuter en mode réel sans confirmation

.\Consolidate-AnalysisDirectories.ps1 -Force

# Exécuter en mode réel avec un fichier de log personnalisé

.\Consolidate-AnalysisDirectories.ps1 -Force -LogFile "consolidation.log"
```plaintext
### Fonctionnement du script

1. Le script crée la nouvelle structure de dossiers sous `development/scripts/analysis`.
2. Il copie les fichiers des dossiers `analysis` et `analytics` vers les sous-dossiers appropriés.
3. Il crée des fichiers README.md pour chaque sous-dossier avec des informations sur les scripts disponibles.
4. Il crée un fichier de redirection dans le dossier `analytics` pour informer les utilisateurs de la nouvelle structure.

### Tests

Un script de test a été créé pour vérifier le bon fonctionnement du script de consolidation : `development/scripts/maintenance/Test-ConsolidateAnalysisDirectories.ps1`.

```powershell
# Exécuter les tests en mode simulation

.\Test-ConsolidateAnalysisDirectories.ps1 -DryRun

# Exécuter les tests en mode réel

.\Test-ConsolidateAnalysisDirectories.ps1
```plaintext
## Après la consolidation

Une fois la consolidation effectuée et vérifiée, vous pouvez supprimer le dossier `analytics` :

```powershell
Remove-Item -Path "development\scripts\analytics" -Recurse -Force
```plaintext
## Mise à jour des références

Après la consolidation, vous devrez mettre à jour les références aux scripts dans d'autres parties du code. Voici quelques exemples de modifications à effectuer :

- Remplacer `development\scripts\analysis\Start-CodeAnalysis.ps1` par `development\scripts\analysis\code\Start-CodeAnalysis.ps1`
- Remplacer `development\scripts\analytics\anomaly_detection.ps1` par `development\scripts\analysis\data\Detect-Anomalies.ps1`

## Conclusion

Cette consolidation permet de :

1. Éliminer la redondance entre les dossiers `analysis` et `analytics`
2. Clarifier la structure du projet
3. Organiser les scripts par fonction
4. Faciliter la maintenance et l'évolution du code

La nouvelle structure est plus cohérente et plus facile à comprendre pour les nouveaux développeurs qui rejoignent le projet.
