# Méthodologies de travail

Ce document décrit les différentes méthodologies et approches à suivre lors du développement.

## MÉTHODO
- **ANALYZE** : 
  - `decompose(tasks)` : Décomposer les tâches en unités plus petites
  - `auto_complexity()` : Évaluer automatiquement la complexité

- **LEARN** : 
  - `extract_patterns(existing_code)` : Extraire les modèles du code existant

- **EXPLORE** : 
  - `ToT(3)` : Utiliser la technique Tree of Thoughts avec 3 branches
  - `select_best()` : Sélectionner la meilleure solution

- **REASON** : 
  - `ReAct(1)` = analyze→execute→adjust : Utiliser le cycle Réflexion-Action en 1 itération

- **CODE** : 
  - `implement(functional_unit ≤ 5KB)` : Implémenter des unités fonctionnelles de 5KB maximum

- **PROGRESS** : 
  - `sequential(no_confirmation)` : Progresser séquentiellement sans demander de confirmation

- **ADAPT** : 
  - `granularity(detected_complexity)` : Adapter la granularité en fonction de la complexité détectée

- **SEGMENT** : 
  - `divide_if(complex)` : Diviser si la tâche est complexe

## STANDARDS
- **SOLID** : 
  - `auto_check()` : Vérifier automatiquement le respect des principes SOLID

- **TDD** : 
  - `generate_tests(before_code)` : Générer les tests avant le code

- **MEASURE** : 
  - `metrics(cyclomatic, input_size)` : Mesurer la complexité cyclomatique et la taille des entrées

- **DOCUMENT** : 
  - `auto(doc_ratio=20%)` : Documenter automatiquement avec un ratio de 20%

- **VALIDATE** : 
  - `pre_check(code)` : Vérifier le code avant soumission

## AUTONOMIE
- **PROGRESSION** : 
  - `chain_tasks(no_break, follow_roadmap)` : Enchaîner les tâches sans interruption en suivant la roadmap

- **DECISION** : 
  - `resolve(heuristics_only)` : Résoudre les problèmes en utilisant uniquement des heuristiques

- **RESILIENCE** : 
  - `error_recovery(log=min)` : Récupérer des erreurs avec un minimum de journalisation

- **ESTIMATION** : 
  - `complexity(LOC, deps, patterns)` : Estimer la complexité en fonction du nombre de lignes, des dépendances et des modèles

- **RECOVERY** : 
  - `resume(last_stable_point)` : Reprendre à partir du dernier point stable
