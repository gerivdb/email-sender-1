# README Technique - Phase 1 Doc-Manager Fusion & Code-Graph RAG

## Description

Cette phase pose les fondations de l’intégration entre le Doc-Manager dynamique (Go) et les extensions Code-Graph RAG (Node.js, Python).

## Livrables principaux

- Orchestrator (Go) : core/docmanager/orchestrator.go (+ tests)
- ObjectiveManager (Node.js) : scripts/objectiveManager.js (+ tests)
- DocGen (Python) : scripts/docgen.py (+ tests)
- Documentation des objectifs : docs/technical/OBJECTIVES.md
- Scripts de test : Go (`go test`), Node.js (`npm test`), Python (`pytest` ou `python -m unittest`)
- Conventions et structure de dépôt respectées

## Validation

- Tous les tests unitaires passent
- Les objectifs sont définis et validés dans chaque langage
- La documentation initiale est générée et accessible

## Prochaines étapes

- Extraction et parsing multi-langages (Phase 2)
- Génération de graphes et visualisation (Phase 3)
- Automatisation et synchronisation documentaire (Phase 4+)

Voir aussi : OBJECTIVES.md, plan-dev-v66-fusion-doc-manager-extensions-hybride.md
