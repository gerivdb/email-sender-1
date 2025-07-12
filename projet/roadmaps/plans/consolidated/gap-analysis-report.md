# Rapport d’écart – Migration Markdown → Qdrant

Ce rapport analyse les différences entre la structure des fichiers Markdown inventoriés et le schéma cible Qdrant pour la migration.

## Schéma cible Qdrant (extrait)

- id : identifiant unique
- title : titre du plan
- objectives : objectifs
- sections : contenu structuré
- metadata : auteurs, date, version
- links : liens vers scripts/artefacts
- tags : mots-clés
- embeddings : vecteurs pour la recherche sémantique

## Écarts identifiés

- Certains plans ne contiennent pas de métadonnées complètes (auteurs, date, version).
- Les sections principales sont parfois non structurées ou dispersées.
- Les liens vers scripts/artefacts sont absents ou non standardisés.
- Les tags et embeddings ne sont pas présents dans les fichiers Markdown.
- Les objectifs sont parfois mélangés avec la description ou non explicités.
- La granularité des sections varie fortement d’un plan à l’autre.
- Les champs spécifiques (ex : workflow, visualisation, synchronisation) sont hétérogènes.

## Recommandations

- Ajouter un bloc de métadonnées standardisé en tête de chaque plan.
- Structurer les sections principales : Objectifs, Workflow, Synchronisation, Visualisation, Tests, Documentation.
- Uniformiser les liens vers scripts/artefacts (format Markdown ou JSON).
- Ajouter des tags et préparer l’intégration des embeddings.
- Expliciter les objectifs dans une section dédiée.
- Harmoniser la granularité des sections pour faciliter la vectorisation.
