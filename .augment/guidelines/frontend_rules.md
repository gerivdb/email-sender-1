# Règles de développement Frontend

Ce document définit les standards et bonnes pratiques pour le développement frontend dans le projet.

## Principes généraux

- **Séparation des préoccupations** : Séparer clairement HTML, CSS et JavaScript
- **Composants atomiques** : Utiliser une approche de conception par composants
- **Optimisation GPU** : Privilégier les propriétés CSS optimisées pour le GPU
- **Séparation business/présentation** : Maintenir une séparation claire entre logique métier et présentation

## Structure des composants

```
component/
  ├── Component.js       # Logique du composant
  ├── Component.css      # Styles spécifiques au composant
  ├── Component.test.js  # Tests unitaires
  └── index.js           # Point d'entrée (export)
```

## Conventions de nommage

- **Composants** : PascalCase (ex: `UserProfile`)
- **Fichiers JS** : PascalCase pour les composants, camelCase pour les utilitaires
- **Fichiers CSS** : Même nom que le composant associé
- **Classes CSS** : kebab-case (ex: `user-profile-container`)

## Optimisation des performances

- Utiliser la lazy-loading pour les composants lourds
- Minimiser les re-renders avec React.memo, useMemo et useCallback
- Optimiser les images (WebP, compression, dimensions appropriées)
- Implémenter le code-splitting pour réduire la taille des bundles

## Accessibilité

- Utiliser des éléments sémantiques HTML5
- Ajouter des attributs ARIA appropriés
- Assurer un contraste suffisant pour le texte
- Supporter la navigation au clavier

## Tests

- Écrire des tests unitaires pour chaque composant
- Implémenter des tests d'intégration pour les flux utilisateur critiques
- Viser une couverture de code d'au moins 80%

## Outils recommandés

- ESLint avec la configuration du projet
- Prettier pour le formatage du code
- Storybook pour la documentation des composants
- Lighthouse pour l'analyse des performances

## Ressources

- [Guide de style Airbnb pour React](https://github.com/airbnb/javascript/tree/master/react)
- [Documentation React](https://reactjs.org/projet/documentation/getting-started.html)
- [MDN Web projet/documentation](https://developer.mozilla.org/fr/)
