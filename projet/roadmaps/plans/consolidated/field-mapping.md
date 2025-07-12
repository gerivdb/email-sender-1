# Mapping des champs Markdown ↔ Qdrant

Ce document spécifie le mapping des champs entre les fichiers Markdown et le schéma Qdrant, ainsi que la logique de synchronisation bidirectionnelle.

## Mapping des champs

| Markdown                | Qdrant         | Description                                 |
|-------------------------|---------------|---------------------------------------------|
| Titre                   | title         | Titre du plan                               |
| Objectifs               | objectives    | Objectifs du plan                           |
| Sections principales    | sections      | Contenu structuré                           |
| Métadonnées             | metadata      | Auteurs, date, version                      |
| Liens vers artefacts    | links         | Liens vers scripts, outils, rapports        |
| Tags (ajoutés)          | tags          | Mots-clés pour la recherche                 |
| Embeddings (calculés)   | embeddings    | Vecteurs pour la recherche sémantique       |

## Synchronisation bidirectionnelle

- Les modifications dans Markdown sont propagées vers Qdrant via le script Go de synchronisation.
- Les mises à jour dans Qdrant (ex : tags, embeddings) sont réinjectées dans les fichiers Markdown lors de la synchronisation inverse.
- Les conflits sont gérés par priorité : source Markdown, puis Qdrant, avec log des opérations.

## Validation

- Tests automatisés sur la cohérence des champs synchronisés.
- Revue technique croisée.
