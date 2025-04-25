# Analyse de Sentiment

## Introduction

L'analyse de sentiment visualise l'évolution du sentiment dans les entrées du journal au fil du temps. Elle permet d'identifier les tendances émotionnelles et les changements de ton dans le journal.

## Contenu de la documentation

- [Fonctionnalités](./features.md) - Fonctionnalités de l'analyse de sentiment
- [Utilisation](./usage.md) - Comment utiliser l'analyse de sentiment
- [Métriques](./metrics.md) - Explication des métriques de sentiment
- [API](./api.md) - Documentation de l'API utilisée par l'analyse de sentiment
- [Implémentation](./implementation.md) - Détails techniques de l'implémentation

## Aperçu

L'analyse de sentiment offre deux vues principales:

1. **Évolution du sentiment**: Visualise l'évolution de la polarité (positif/négatif) et de la subjectivité (objectif/subjectif) au fil du temps
2. **Analyse par section**: Compare le sentiment entre différentes sections des entrées (Introduction, Développement, Conclusion, etc.)

Ces visualisations sont accompagnées de statistiques sur le sentiment moyen et les tendances récentes.

## Métriques clés

L'analyse de sentiment utilise deux métriques principales:

- **Polarité**: Mesure si le texte est positif (valeurs positives) ou négatif (valeurs négatives)
- **Subjectivité**: Mesure si le texte est objectif (valeurs proches de 0) ou subjectif (valeurs proches de 1)

## Prérequis

- Un navigateur moderne avec JavaScript activé
- Une collection d'entrées de journal avec suffisamment de contenu pour l'analyse
