// tests/mode-manager.test.js
// Squelette de test Jest pour ModeManager

const ModeManager = require('../src/ModeManager'); // Adapter le chemin si nécessaire

describe('ModeManager', () => {
  let modeManager;

  beforeEach(() => {
    modeManager = new ModeManager();
  });

  test('devrait initialiser avec le mode par défaut', () => {
    expect(modeManager.getCurrentMode()).toBeDefined();
  });

  test('devrait changer de mode', () => {
    const initialMode = modeManager.getCurrentMode();
    modeManager.switchMode('autreMode');
    expect(modeManager.getCurrentMode()).not.toBe(initialMode);
  });

  test('devrait retourner la configuration du mode', () => {
    const config = modeManager.getModeConfig('default');
    expect(config).toBeDefined();
  });

  test('devrait mettre à jour la configuration du mode', () => {
    const newConfig = { option: true };
    modeManager.updateModeConfig('default', newConfig);
    expect(modeManager.getModeConfig('default')).toEqual(expect.objectContaining(newConfig));
  });

  test('devrait gérer les transitions de mode', () => {
    modeManager.switchMode('mode1');
    modeManager.switchMode('mode2');
    const history = modeManager.getTransitionHistory();
    expect(Array.isArray(history)).toBe(true);
    expect(history.length).toBeGreaterThanOrEqual(2);
  });
});