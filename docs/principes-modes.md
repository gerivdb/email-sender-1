# Principes DRY / KISS / SOLID par mode

## Introduction
Présentation des principes fondamentaux appliqués à chaque mode du projet.

## Mode Code
- DRY : Factoriser les fonctions utilitaires, éviter la duplication des validations d’entrée.
  *Exemple : centraliser la logique de vérification des permissions dans un module partagé.*
- KISS : Privilégier des scripts simples, des workflows clairs et des interfaces épurées.
  *Exemple : une commande CLI unique pour lancer tous les tests.*
- SOLID : Respecter la séparation des responsabilités (ex : chaque fichier gère une seule fonctionnalité), favoriser l’extension via modules.
  *Exemple : interface IRunner pour l’exécution, implémentations spécifiques par type de test.*

## Mode Architect
- DRY : Réutiliser les schémas d’architecture, mutualiser les modèles de documentation.
  *Exemple : template YAML Roo pour tous les managers.*
- KISS : Modéliser des architectures compréhensibles, limiter les couches inutiles.
  *Exemple : diagramme mermaid synthétique pour la vue d’ensemble.*
- SOLID : Modulariser les composants, chaque manager a une responsabilité claire.
  *Exemple : PipelineManager orchestre, ErrorManager centralise la gestion des erreurs.*

## Mode Debug
- DRY : Centraliser les routines de log et de gestion d’erreur.
  *Exemple : fonction unique pour le masquage des données sensibles.*
- KISS : Utiliser des messages d’erreur explicites, limiter la complexité des traces.
  *Exemple : format JSON standard pour les logs.*
- SOLID : Séparer la détection, la gestion et la résolution des erreurs.
  *Exemple : ErrorManager traite, DebugManager analyse.*

## Mode Orchestrator
- DRY : Mutualiser les workflows, réutiliser les scénarios d’enchaînement.
  *Exemple : workflow orchestré pour audit sécurité et migration.*
- KISS : Orchestration lisible, transitions explicites entre modes.
  *Exemple : matrice de workflow avec étapes claires.*
- SOLID : Chaque mode spécialisé reste indépendant, Orchestrator gère la coordination.
  *Exemple : Orchestrator délègue à Debug, Code, Architect selon la tâche.*

## Mode Ask
- DRY : Centraliser les réponses types, mutualiser les modèles d’explication.
  *Exemple : base de connaissances partagée pour les questions récurrentes.*
- KISS : Réponses courtes, claires, illustrées par des exemples.
  *Exemple : FAQ synthétique pour chaque module.*
- SOLID : Séparer la documentation, l’explication et la suggestion.
  *Exemple : AskManager propose, DocManager documente.*

## Conclusion
L’application rigoureuse des principes DRY, KISS et SOLID dans chaque mode garantit la robustesse, la maintenabilité et la traçabilité du projet.
Pour chaque nouveau module ou workflow, vérifier la conformité à ces principes et documenter les exemples concrets.