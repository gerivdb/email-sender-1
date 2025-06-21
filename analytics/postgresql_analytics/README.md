# PostgreSQL Analytics - Documentation

Ce dossier contient les scripts SQL pour l'intégration de l'analytics documentaire dans PostgreSQL, conformément au plan 4.4.2 :

- `001_create_schema_documentation_analytics.sql` : création du schéma `documentation_analytics`.
- `002_create_tables_managers_documents.sql` : création des tables `managers` et `documents`.
- `003_functions_plpgsql.sql` : fonctions avancées PL/pgSQL pour l'analytics.
- `004_materialized_views_dashboard.sql` : vues matérialisées pour le dashboard analytique.

## Utilisation

1. Exécutez les scripts dans l'ordre pour initialiser l'analytics documentaire.
2. Vérifiez la cohérence des données et la présence des artefacts dans le schéma `documentation_analytics`.
3. Les fonctions et vues sont prêtes à être utilisées pour des requêtes analytiques et des dashboards.

## Tests

Des tests unitaires et d'intégration peuvent être ajoutés dans ce dossier pour valider chaque artefact SQL.
