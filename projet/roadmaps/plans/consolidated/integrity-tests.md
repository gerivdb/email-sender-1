# Scénarios de tests d’intégrité et de validation – Migration Roadmap

## Objectif

Valider l’intégrité des données migrées et la cohérence de la synchronisation Markdown ↔ Qdrant.

## Scénarios

- Vérifier que chaque plan migré possède un identifiant unique, un titre, des objectifs, des sections et des métadonnées.
- Vérifier la présence et la validité des embeddings pour chaque roadmap.
- Vérifier la cohérence du mapping des champs entre Markdown et Qdrant.
- Vérifier la traçabilité des opérations (logs, backups, rapports).
- Vérifier la réussite de la synchronisation bidirectionnelle (priorité Markdown puis Qdrant).
- Vérifier la génération des artefacts critiques (roadmaps.json, backups, rapports).
- Vérifier la couverture des tests unitaires (>90%).

## Validation

- Exécution automatisée via CI/CD.
- Reporting des résultats dans `migration-report.md`.
- Badge de couverture généré automatiquement.
