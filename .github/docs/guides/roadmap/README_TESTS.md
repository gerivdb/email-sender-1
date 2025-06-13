# Guide d'exécution des tests pour le système RAG de roadmaps

Ce guide explique comment exécuter les tests pour le système RAG de roadmaps et comment résoudre les problèmes courants liés aux dépendances Python.

## Prérequis

- PowerShell 5.1 ou supérieur
- Python 3.8 ou supérieur
- pip (gestionnaire de paquets Python)
- Qdrant en cours d'exécution sur http://localhost:6333

## Options d'exécution des tests

Vous avez trois options pour exécuter les tests :

1. **Exécution directe** : Exécuter les tests avec les dépendances Python installées globalement
2. **Exécution avec dépendances compatibles** : Installer temporairement des versions compatibles des dépendances
3. **Exécution dans un environnement virtuel** : Créer un environnement virtuel dédié avec des dépendances compatibles

## 1. Exécution directe

Si vous avez déjà les dépendances Python installées globalement, vous pouvez exécuter les tests directement :

```powershell
cd development\scripts\roadmap\rag\tests
.\Invoke-AllTests.ps1 -TestType All -GenerateReport
```plaintext
Options disponibles :
- `-TestType` : Type de tests à exécuter (`All`, `ChangeDetection`, `VectorUpdate`, `Versioning`)
- `-GenerateReport` : Générer un rapport HTML des résultats des tests

## 2. Exécution avec dépendances compatibles

Si vous rencontrez des problèmes avec les dépendances Python, vous pouvez utiliser le script `Run-TestsWithCompatibleDependencies.ps1` qui installera temporairement des versions compatibles des dépendances :

```powershell
cd development\scripts\roadmap\rag\tests
.\Run-TestsWithCompatibleDependencies.ps1 -TestType All -GenerateReport
```plaintext
Options disponibles :
- `-TestType` : Type de tests à exécuter (`All`, `ChangeDetection`, `VectorUpdate`, `Versioning`)
- `-GenerateReport` : Générer un rapport HTML des résultats des tests
- `-SkipDependencyCheck` : Ignorer la vérification et l'installation des dépendances
- `-Force` : Forcer l'exécution des tests même si les dépendances ne sont pas correctement installées

## 3. Exécution dans un environnement virtuel

Pour une solution plus propre et isolée, vous pouvez créer un environnement virtuel dédié avec des dépendances compatibles :

### 3.1. Configuration de l'environnement virtuel

```powershell
cd development\scripts\roadmap\rag
.\Setup-VirtualEnvironment.ps1
```plaintext
Options disponibles :
- `-VenvPath` : Chemin de l'environnement virtuel (par défaut : `venv`)
- `-Force` : Forcer la recréation de l'environnement virtuel s'il existe déjà
- `-NoPrompt` : Ne pas demander de confirmation

### 3.2. Activation de l'environnement virtuel

```powershell
cd development\scripts\roadmap\rag
.\Activate-RoadmapEnvironment.ps1
```plaintext
### 3.3. Exécution des tests dans l'environnement virtuel

```powershell
cd development\scripts\roadmap\rag
.\Run-TestsInVenv.ps1 -TestType All -GenerateReport
```plaintext
Options disponibles :
- `-TestType` : Type de tests à exécuter (`All`, `ChangeDetection`, `VectorUpdate`, `Versioning`)
- `-GenerateReport` : Générer un rapport HTML des résultats des tests

### 3.4. Désactivation de l'environnement virtuel

```powershell
deactivate
```plaintext
## Résolution des problèmes

Si vous rencontrez des problèmes lors de l'exécution des tests, consultez le guide de dépannage :

```powershell
notepad docs\guides\roadmap\TROUBLESHOOTING_DEPENDENCIES.md
```plaintext
### Problèmes courants

1. **Erreurs d'importation avec `sentence-transformers`** : Incompatibilité entre les versions de `sentence-transformers`, `huggingface-hub` et `transformers`.
2. **Erreurs avec `qdrant-client`** : Version incompatible ou obsolète de `qdrant-client`.
3. **Erreurs de connexion à Qdrant** : Qdrant n'est pas en cours d'exécution ou n'est pas accessible.

### Démarrage de Qdrant

Si Qdrant n'est pas en cours d'exécution, démarrez-le avec :

```powershell
cd development\scripts\roadmap
.\Start-QdrantContainer.ps1 -Action Start
```plaintext
## Versions compatibles recommandées

| Bibliothèque | Version |
|--------------|---------|
| huggingface-hub | 0.19.4 |
| transformers | 4.36.2 |
| torch | 2.1.2 |
| sentence-transformers | 2.2.2 |
| qdrant-client | 1.7.0 |

## Structure des tests

Les tests sont organisés en trois catégories :

1. **ChangeDetection** : Tests pour la détection des changements dans les roadmaps
   - Détection des ajouts
   - Détection des suppressions
   - Détection des modifications
   - Détection des changements de statut
   - Détection des déplacements
   - Détection des changements structurels

2. **VectorUpdate** : Tests pour la mise à jour sélective des vecteurs
   - Mise à jour avec ajouts
   - Mise à jour avec modifications
   - Mise à jour avec changements de statut

3. **Versioning** : Tests pour le système de versionnage des embeddings
   - Enregistrement d'une version d'embedding
   - Création d'un snapshot
   - Migration vers un nouveau modèle
   - Rollback vers une version précédente

## Rapport de test

Si vous utilisez l'option `-GenerateReport`, un rapport HTML sera généré dans le répertoire `projet\roadmaps\analysis\test\output`. Ce rapport contient un résumé des résultats des tests et des détails sur chaque test exécuté.

Pour ouvrir le rapport :

```powershell
Invoke-Item projet\roadmaps\analysis\test\output\test_report.html
```plaintext