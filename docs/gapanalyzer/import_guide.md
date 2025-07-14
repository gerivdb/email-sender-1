# Guide des bonnes pratiques d’import – Gapanalyzer

## Objectif

Ce guide présente les bonnes pratiques pour gérer les imports dans le projet Gapanalyzer, suite à la correction des imports cassés.

## Bonnes pratiques

- Utiliser des chemins d’import relatifs cohérents
- Centraliser la gestion des dépendances
- Vérifier la compatibilité des modules avant import
- Documenter toute modification d’import dans le rapport dédié

## Procédure de correction

1. Identifier les imports cassés via l’outil d’audit
2. Appliquer les corrections recommandées
3. Générer le rapport de correction ([`import_fix_report.md`](./import_fix_report.md))
4. Mettre à jour la documentation technique

## Ressources

- Rapport de correction : [`import_fix_report.md`](./import_fix_report.md)
- Diagramme Mermaid : voir README

## Remédiation des imports cycliques

La détection et la suppression des imports cycliques dans le projet sont automatisées via le script PowerShell `_templates/script-automation/new/detect_cyclic_imports.ps1`.  
Ce script analyse tous les fichiers Go et génère un rapport dans `cmd/gapanalyzer/import_fix_report.md`.

**Étapes :**
1. Exécuter le script pour identifier les imports cycliques.
2. Corriger les imports selon le rapport.
3. Vérifier la traçabilité via le rapport généré.

La structure métier a été refactorisée pour séparer la logique dans `core/gapanalyzer`, permettant une modularisation et une maintenance facilitée.
