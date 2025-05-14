/**
 * Mock pour tippy.js
 */

// Fonction tippy
const tippy = jest.fn(() => ({
  setContent: jest.fn(),
  setProps: jest.fn(),
  show: jest.fn(),
  hide: jest.fn(),
  destroy: jest.fn()
}));

// Ajouter des méthodes statiques
tippy.setDefaultProps = jest.fn();

// Exporter le module
module.exports = tippy;
