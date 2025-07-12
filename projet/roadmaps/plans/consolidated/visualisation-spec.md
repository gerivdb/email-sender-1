# Spécification – Visualisation et Navigation Roadmap

## Objectif

Permettre la visualisation interactive et la navigation des roadmaps migrées, via CLI, TUI et HTML, en exploitant le modèle de données agrégé.

## Convention

- Utilisation du fichier `roadmaps.json` comme source unique.
- Navigation CLI : commandes pour lister, filtrer, afficher les roadmaps.
- TUI : interface textuelle interactive pour explorer les sections, métadonnées, liens.
- HTML : rendu dynamique des roadmaps, recherche, visualisation des liens et embeddings.

## Exemple CLI

```
roadmap-cli list
roadmap-cli show plan-dev-v25-meta-roadmap-sync-updated
roadmap-cli search "vectorisation"
```

## Exemple TUI

- Affichage des roadmaps sous forme de liste interactive.
- Sélection d’un plan pour afficher ses sections et métadonnées.

## Exemple HTML

- Page web générée à partir de `roadmaps.json`
- Recherche par tags, visualisation des embeddings, liens vers artefacts.

## Validation

- Tests automatisés sur la navigation et la cohérence des données affichées.
- Feedback utilisateur intégré dans le workflow CI/CD.
