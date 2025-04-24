# Modes de fonctionnement

Ce document décrit les différents modes de fonctionnement disponibles dans le système, leurs objectifs, déclencheurs et directives associées.

## ARCHI
- **Objectif** : Structurer, modéliser, anticiper les dépendances
- **Déclencheurs** : Analyse d'impact, modélisation, dette technique
- **Directives** : 
  - `diagram_layers()` : Générer des diagrammes de couches d'architecture
  - `define_contracts()` : Définir les contrats d'interface entre composants
  - `detect_critical_paths()` : Identifier les chemins critiques dans l'architecture
  - `suggest_refacto()` : Proposer des refactorisations pour améliorer l'architecture
  - `deliver_arch_synthesis()` : Fournir une synthèse de l'architecture

## DEBUG
- **Objectif** : Isoler, comprendre, corriger les anomalies
- **Déclencheurs** : Erreurs, logs, comportement inattendu
- **Directives** : 
  - `identify_fault_origin()` : Identifier l'origine des défauts
  - `test_edge_cases()` : Tester les cas limites
  - `simulate_context()` : Simuler le contexte d'exécution
  - `generate_fix_patch()` : Générer un correctif
  - `explain_bug()` : Expliquer la cause du bug

## TEST
- **Objectif** : Maximiser couverture et fiabilité
- **Déclencheurs** : Spécifications, mode TDD actif
- **Directives** : 
  - `test_suites(coverage=90%)` : Générer des suites de tests avec une couverture de 90%
  - `test_cases_by_pattern()` : Créer des cas de test basés sur des modèles
  - `test_results_analysis()` : Analyser les résultats des tests

## OPTI
- **Objectif** : Réduire complexité, taille ou temps d'exécution
- **Déclencheurs** : Complexité > 5, taille excessive
- **Directives** : 
  - `runtime_hotspots()` : Identifier les points chauds d'exécution
  - `reduce_LOC_nesting_calls()` : Réduire le nombre de lignes de code et les appels imbriqués
  - `optimized_version()` : Produire une version optimisée
- **Extensions** : 
  - `PARALLELIZER` : Optimiser les traitements lourds
  - `CACHE_MGR` : Accélérer les accès et prédictions

## REVIEW
- **Objectif** : Vérifier lisibilité, standards, documentation
- **Déclencheurs** : pre_commit, PR
- **Directives** : 
  - `check_SOLID_KISS_DRY()` : Vérifier le respect des principes SOLID, KISS et DRY
  - `doc_ratio()` : Vérifier le ratio de documentation
  - `cyclomatic_score()` : Calculer le score de complexité cyclomatique
  - `review_report()` : Générer un rapport de revue

## GRAN
- **Objectif** : Décomposer les blocs complexes DIRECTEMENT dans le document pour la sélection
- **Déclencheurs** : Taille > 5KB, complexité > 7, feedback utilisateur
- **Directives** : 
  - `split_by_responsibility()` : Diviser par responsabilité
  - `detect_concatenated_tasks()` : Détecter les tâches concaténées
  - `isolate_subtasks()` : Isoler les sous-tâches
  - `extract_functions()` : Extraire les fonctions
  - `granular_unit_set()` : Définir des unités granulaires
- **Extensions** : 
  - `SEGMENTOR` : Traiter des données structurées ou volumineuses

## DEV-R
- **Objectif** : Implémenter ce qui est dans la roadmap
- **Déclencheurs** : Nouvelle tâche roadmap confirmée
- **Directives** : 
  - Implémenter la sélection **sous-tâche par sous-tâche**
  - Générer les tests
  - Corriger tous les problèmes
  - Assurer 100% de couverture

## PREDIC
- **Objectif** : Anticiper performances, détecter anomalies, analyser tendances
- **Déclencheurs** : Besoin d'analyse de charge ou de comportement futur
- **Directives** : 
  - `predict_metrics()` : Prédire les métriques
  - `find_anomalies()` : Trouver les anomalies
  - `analyze_trends()` : Analyser les tendances
  - `export_prediction_report()` : Exporter un rapport de prédiction
  - `trigger_retraining_if_needed()` : Déclencher un réentraînement si nécessaire

## C-BREAK
- **Objectif** : Détecter et corriger les dépendances circulaires
- **Déclencheurs** : Logique récursive, erreurs d'import ou workflow bloqué
- **Directives** : 
  - `Detect-CyclicDependencies()` : Détecter les dépendances cycliques
  - `Validate-WorkflowCycles()` : Valider les cycles de workflow
  - `auto_fix_cycles()` : Corriger automatiquement les cycles
  - `suggest_refactor_path()` : Suggérer un chemin de refactorisation
