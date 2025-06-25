// scripts/objectiveManager.test.js
// Tests unitaires pour ObjectiveManager (Phase 1)

const ObjectiveManager = require('./objectiveManager');

test('define and validate objectives', () => {
  const om = new ObjectiveManager();
  const objs = [
    { name: 'Cartographie', description: 'Cartographie exhaustive des dépendances' },
    { name: 'DocGen', description: 'Génération automatique de documentation' }
  ];
  om.defineObjectives(objs);
  expect(om.validateObjectives()).toBe(true);
});
