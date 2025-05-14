/**
 * Configuration Jest pour les tests du moteur de rendu avec layout automatique
 */

export default {
  // Répertoire racine
  rootDir: '.',

  // Environnement de test
  testEnvironment: 'jsdom',

  // Motifs de fichiers de test
  testMatch: [
    '**/tests/**/*.test.js'
  ],

  // Transformations
  transform: {
    '^.+\\.js$': 'babel-jest'
  },

  // Configuration de Babel
  transformIgnorePatterns: [
    '/node_modules/'
  ],

  // Couverture de code
  collectCoverage: true,
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    '**/*.js',
    '!**/node_modules/**',
    '!**/tests/**',
    '!**/coverage/**',
    '!**/jest.config.js'
  ],

  // Rapports de couverture
  coverageReporters: ['text', 'lcov', 'html', 'json-summary'],

  // Répertoire pour les rapports de couverture
  coverageDirectory: 'coverage',

  // Seuils de couverture désactivés pour le débogage
  // coverageThreshold: {
  //   global: {
  //     branches: 3,
  //     functions: 3,
  //     lines: 3,
  //     statements: 3
  //   }
  // },

  // Modules ES
  moduleFileExtensions: ['js', 'json'],

  // Configuration pour les modules ES et mocks pour les modules externes
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
    '^cytoscape$': '<rootDir>/tests/mocks/cytoscape.mock.js',
    '^cytoscape-cose-bilkent$': '<rootDir>/tests/mocks/cytoscape-cose-bilkent.mock.js',
    '^cytoscape-dagre$': '<rootDir>/tests/mocks/cytoscape-dagre.mock.js',
    '^cytoscape-klay$': '<rootDir>/tests/mocks/cytoscape-klay.mock.js',
    '^cytoscape-popper$': '<rootDir>/tests/mocks/cytoscape-popper.mock.js',
    '^tippy.js$': '<rootDir>/tests/mocks/tippy.mock.js',
    '^tippy.js/dist/tippy.css$': '<rootDir>/tests/mocks/empty.css.mock.js'
  },

  // Verbose
  verbose: true
};
