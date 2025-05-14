/**
 * Mock pour le module Cytoscape
 */

// Fonction factory pour créer une instance Cytoscape
const cytoscape = jest.fn(() => ({
  elements: jest.fn(() => ({
    nodes: jest.fn(() => []),
    edges: jest.fn(() => [])
  })),
  style: jest.fn(() => ({})),
  selector: jest.fn(() => ({})),
  update: jest.fn(),
  on: jest.fn(),
  container: jest.fn(() => ({})),
  zoom: jest.fn(() => 1),
  add: jest.fn(),
  remove: jest.fn(),
  fit: jest.fn(),
  center: jest.fn(),
  filter: jest.fn(() => []),
  toArray: jest.fn(() => [])
}));

// Ajouter des méthodes statiques
cytoscape.use = jest.fn();

// Exporter le module
module.exports = cytoscape;
