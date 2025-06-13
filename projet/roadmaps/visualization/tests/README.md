# Tests pour le Moteur de Rendu avec Layout Automatique

Ce dossier contient les tests pour le moteur de rendu avec layout automatique pour la visualisation en carte de métro.

## Structure des Tests

Les tests sont organisés en plusieurs fichiers :

- `MetroMapLayoutEngine.test.js` : Tests unitaires pour le moteur de layout automatique
- `MetroMapInteractiveRenderer.test.js` : Tests unitaires pour le système de rendu graphique interactif
- `MetroMapFilters.test.js` : Tests unitaires pour le module de filtrage
- `MetroMapCustomizer.test.js` : Tests unitaires pour le module de personnalisation
- `integration.test.js` : Tests d'intégration pour vérifier l'interaction entre les différents modules

## Exécution des Tests

### Prérequis

Avant d'exécuter les tests, assurez-vous d'avoir installé les dépendances nécessaires :

```bash
npm install
```plaintext
### Exécuter tous les tests

Pour exécuter tous les tests :

```bash
npm test
```plaintext
### Exécuter les tests unitaires

Pour exécuter uniquement les tests unitaires :

```bash
npm run test:unit
```plaintext
### Exécuter les tests d'intégration

Pour exécuter uniquement les tests d'intégration :

```bash
npm run test:integration
```plaintext
### Exécuter les tests avec surveillance

Pour exécuter les tests en mode surveillance (les tests sont réexécutés automatiquement lorsque les fichiers sont modifiés) :

```bash
npm run test:watch
```plaintext
### Générer un rapport de couverture

Pour générer un rapport de couverture de code :

```bash
npm run test:coverage
```plaintext
Le rapport de couverture sera généré dans le dossier `coverage`.

## Mocks

Les tests utilisent des mocks pour simuler le comportement de Cytoscape et d'autres dépendances externes. Ces mocks sont définis dans chaque fichier de test.

## Configuration

La configuration de Jest se trouve dans le fichier `jest.config.js` à la racine du projet. La configuration de Babel se trouve dans le fichier `babel.config.js`.

## Bonnes Pratiques

- Chaque test doit être indépendant des autres tests
- Utilisez des mocks pour simuler les dépendances externes
- Testez les cas limites et les cas d'erreur
- Maintenez une couverture de code élevée (au moins 80%)
- Écrivez des tests lisibles et maintenables

## Dépannage

Si vous rencontrez des problèmes lors de l'exécution des tests, voici quelques solutions possibles :

- Vérifiez que toutes les dépendances sont installées : `npm install`
- Vérifiez que la configuration de Jest est correcte : `jest.config.js`
- Vérifiez que la configuration de Babel est correcte : `babel.config.js`
- Essayez de nettoyer le cache de Jest : `npx jest --clearCache`
- Vérifiez que les mocks sont correctement configurés

## Ressources

- [Documentation Jest](https://jestjs.io/docs/getting-started)
- [Documentation Babel](https://babeljs.io/docs/en/)
- [Documentation Cytoscape](https://js.cytoscape.org/)
