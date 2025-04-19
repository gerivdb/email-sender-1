# Visualisations Avancées

## Introduction

Le système de journal de bord RAG inclut plusieurs visualisations avancées qui permettent d'explorer et d'analyser les données du journal de manière interactive. Ces visualisations utilisent D3.js pour créer des représentations graphiques riches et interactives.

## Nuage de Mots Interactif

### Description

Le nuage de mots interactif affiche les termes les plus fréquents dans les entrées du journal, avec une taille proportionnelle à leur fréquence. Cette visualisation permet d'identifier rapidement les sujets principaux abordés dans le journal.

### Fonctionnalités

- **Interactivité**: Cliquez sur un mot pour voir les détails et les entrées associées
- **Filtrage**: Filtrez par période, tags, catégorie, et plus encore
- **Analyse d'évolution**: Visualisez l'évolution de la fréquence des termes au fil du temps
- **Recherche contextuelle**: Trouvez les entrées contenant un terme spécifique avec le contexte

### Utilisation

1. Accédez à la page d'analyse du journal
2. Sélectionnez "Nuage de mots" dans les visualisations disponibles
3. Utilisez les contrôles en haut pour ajuster la période et le nombre de mots
4. Cliquez sur "Filtres avancés" pour accéder à des options de filtrage supplémentaires
5. Cliquez sur un mot pour voir ses détails et les entrées associées

### Options de configuration

- **Période**: Filtrez les données par période (Tout, Aujourd'hui, Cette semaine, Ce mois, Ce trimestre, Cette année)
- **Nombre de mots**: Ajustez le nombre de mots affichés (50, 100, 200)
- **Filtres avancés**:
  - Tags: Filtrez par tags spécifiques
  - Catégorie: Filtrez par catégorie
  - Recherche: Filtrez par terme de recherche
  - Plage de dates: Filtrez par dates spécifiques
  - Limite: Ajustez le nombre maximum d'éléments
  - Tri: Triez par date, pertinence ou ordre alphabétique

### Détails techniques

Le nuage de mots utilise la bibliothèque d3-cloud pour le placement des mots et D3.js pour l'interactivité. Les données sont récupérées via l'API `/api/analysis/word-cloud` avec les paramètres de filtrage appropriés.

## Analyse de Sentiment

### Description

L'analyse de sentiment visualise l'évolution du sentiment dans les entrées du journal au fil du temps. Elle permet d'identifier les tendances émotionnelles et les changements de ton dans le journal.

### Fonctionnalités

- **Évolution du sentiment**: Visualisez l'évolution de la polarité et de la subjectivité au fil du temps
- **Analyse par section**: Comparez le sentiment entre différentes sections des entrées
- **Statistiques de sentiment**: Consultez des statistiques sur le sentiment moyen et les tendances récentes
- **Filtrage avancé**: Filtrez les données par période, tags, catégorie, et plus encore

### Utilisation

1. Accédez à la page d'analyse du journal
2. Sélectionnez "Analyse de sentiment" dans les visualisations disponibles
3. Basculez entre les vues "Évolution" et "Sections" pour différentes perspectives
4. Utilisez les filtres avancés pour affiner les données affichées

### Vues disponibles

- **Évolution**: Affiche l'évolution de la polarité (positif/négatif) et de la subjectivité (objectif/subjectif) au fil du temps
- **Sections**: Affiche le sentiment moyen par section des entrées (Introduction, Développement, Conclusion, etc.)

### Détails techniques

L'analyse de sentiment utilise D3.js pour les visualisations et récupère les données via les API `/api/analysis/sentiment/evolution` et `/api/analysis/sentiment/sections`.

## Tendances des Sujets

### Description

La visualisation des tendances des sujets montre l'évolution des sujets principaux identifiés dans le journal au fil du temps. Elle permet de suivre l'émergence, la croissance et le déclin de différents sujets.

### Fonctionnalités

- **Évolution des sujets**: Visualisez l'évolution de la prévalence des sujets au fil du temps
- **Détails des sujets**: Consultez les mots clés associés à chaque sujet
- **Entrées associées**: Trouvez les entrées les plus représentatives de chaque sujet
- **Filtrage avancé**: Filtrez les données par période, tags, catégorie, et plus encore

### Utilisation

1. Accédez à la page d'analyse du journal
2. Sélectionnez "Tendances des sujets" dans les visualisations disponibles
3. Sélectionnez un sujet dans la liste pour voir son évolution et les entrées associées
4. Utilisez les filtres pour affiner les données affichées

### Options de configuration

- **Période**: Filtrez les données par période (Tout, 6 derniers mois, Cette année)
- **Filtres avancés**: Similaires aux filtres du nuage de mots

### Détails techniques

La visualisation des tendances des sujets utilise D3.js pour les graphiques et récupère les données via l'API `/api/analysis/topics/trends`.

## Évolution des Tags

### Description

La visualisation de l'évolution des tags montre comment l'utilisation des tags a évolué au fil du temps. Elle permet d'identifier les tendances dans la catégorisation des entrées.

### Fonctionnalités

- **Évolution des tags**: Visualisez l'évolution de l'utilisation des tags au fil du temps
- **Comparaison de tags**: Comparez l'utilisation de différents tags
- **Co-occurrence**: Identifiez les tags qui apparaissent souvent ensemble
- **Filtrage avancé**: Filtrez les données par période, tags spécifiques, et plus encore

### Utilisation

1. Accédez à la page d'analyse du journal
2. Sélectionnez "Évolution des tags" dans les visualisations disponibles
3. Sélectionnez les tags à comparer dans la liste
4. Utilisez les filtres pour affiner les données affichées

### Options de visualisation

- **Graphique linéaire**: Affiche l'évolution de l'utilisation des tags au fil du temps
- **Graphique à barres**: Compare l'utilisation des tags pour une période donnée
- **Graphique de co-occurrence**: Montre quels tags apparaissent souvent ensemble

### Détails techniques

La visualisation de l'évolution des tags utilise D3.js pour les graphiques et récupère les données via l'API `/api/analysis/tags/evolution`.

## Intégration des Visualisations

Les visualisations sont intégrées dans l'interface utilisateur du journal de bord et peuvent être accédées via la page d'analyse. Elles partagent un système de filtrage commun qui permet de filtrer les données de manière cohérente à travers les différentes visualisations.

### Composants communs

- **Filtres avancés**: Un panneau de filtrage commun à toutes les visualisations
- **Animations et transitions**: Des animations fluides pour les changements d'état et les transitions entre les vues
- **Exportation**: Des options pour exporter les visualisations en format PNG, SVG ou PDF

## Personnalisation des Visualisations

Les visualisations peuvent être personnalisées via les options de configuration disponibles dans l'interface utilisateur. Les utilisateurs avancés peuvent également personnaliser les visualisations en modifiant les fichiers de configuration ou en créant des plugins.

### Options de personnalisation

- **Thèmes**: Changez l'apparence des visualisations avec différents thèmes
- **Couleurs**: Personnalisez les palettes de couleurs utilisées dans les visualisations
- **Dimensions**: Ajustez la taille des visualisations
- **Interactivité**: Configurez les comportements interactifs des visualisations

## Exemples d'utilisation

### Identifier les tendances dans le journal

1. Utilisez le nuage de mots pour identifier les termes les plus fréquents
2. Utilisez l'analyse de sentiment pour voir comment le ton a évolué au fil du temps
3. Utilisez les tendances des sujets pour identifier les sujets émergents
4. Utilisez l'évolution des tags pour voir comment la catégorisation a évolué

### Analyser une période spécifique

1. Utilisez les filtres de date pour sélectionner la période d'intérêt
2. Comparez les visualisations avant et après la période
3. Identifiez les changements significatifs dans les sujets, le sentiment ou les tags

### Explorer un sujet spécifique

1. Utilisez les filtres de recherche pour trouver les entrées liées au sujet
2. Utilisez le nuage de mots pour identifier les termes associés
3. Utilisez l'analyse de sentiment pour comprendre le ton des entrées sur ce sujet
4. Utilisez les tendances des sujets pour voir comment le sujet a évolué au fil du temps
