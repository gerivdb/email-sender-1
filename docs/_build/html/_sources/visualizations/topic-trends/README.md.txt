# Tendances des Sujets

## Introduction

La visualisation des tendances des sujets montre l'évolution des sujets principaux identifiés dans le journal au fil du temps. Elle permet de suivre l'émergence, la croissance et le déclin de différents sujets.

## Contenu de la documentation

- [Fonctionnalités](./features.md) - Fonctionnalités de la visualisation des tendances des sujets
- [Utilisation](./usage.md) - Comment utiliser la visualisation des tendances des sujets
- [Modélisation des sujets](./topic-modeling.md) - Explication de la modélisation des sujets
- [API](./api.md) - Documentation de l'API utilisée par la visualisation
- [Implémentation](./implementation.md) - Détails techniques de l'implémentation

## Aperçu

La visualisation des tendances des sujets offre une vue d'ensemble des sujets principaux identifiés dans le journal et de leur évolution au fil du temps. Elle permet de:

- Identifier les sujets principaux dans le journal
- Suivre l'évolution de ces sujets au fil du temps
- Découvrir les mots clés associés à chaque sujet
- Explorer les entrées les plus représentatives de chaque sujet

## Fonctionnement

La visualisation utilise des techniques de modélisation de sujets (topic modeling) comme LDA (Latent Dirichlet Allocation) ou BERTopic pour identifier automatiquement les sujets dans le journal. Ces sujets sont ensuite visualisés sous forme de graphiques montrant leur évolution au fil du temps.

## Prérequis

- Un navigateur moderne avec JavaScript activé
- Une collection d'entrées de journal avec suffisamment de contenu pour l'analyse
- Des entrées datées pour permettre l'analyse temporelle
