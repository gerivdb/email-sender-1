/**
 * Configuration pour les tests Jest
 * Ce fichier est exécuté avant chaque test
 */

// Définir l'environnement de test
process.env.NODE_ENV = 'test';

// Mock pour document
global.document = {
  createElement: jest.fn(() => ({
    className: '',
    id: '',
    textContent: '',
    type: '',
    value: '',
    checked: false,
    required: false,
    addEventListener: jest.fn(),
    appendChild: jest.fn(),
    querySelectorAll: jest.fn(() => []),
    removeChild: jest.fn(),
    htmlFor: ''
  })),
  getElementById: jest.fn(() => ({
    className: '',
    id: '',
    textContent: '',
    appendChild: jest.fn(),
    parentNode: {
      id: 'test-container'
    },
    innerHTML: ''
  })),
  addEventListener: jest.fn(),
  dispatchEvent: jest.fn(),
  body: {
    appendChild: jest.fn(() => {}),
    removeChild: jest.fn(() => {})
  }
};

// Mock pour CustomEvent
global.CustomEvent = class CustomEvent {
  constructor(name, options = {}) {
    this.name = name;
    this.detail = options.detail || {};
  }
};

// Mock pour localStorage
global.localStorage = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn()
};

// Mock pour console
global.console = {
  ...console,
  log: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn()
};
