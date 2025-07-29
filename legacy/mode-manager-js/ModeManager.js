// Implémentation minimale pour passage des tests Jest

class ModeManager {
  constructor() {
    this.currentMode = 'lecture';
    this.history = [];
    this.configs = {
      lecture: {},
      edition: {},
    };
  }

  switchMode(targetMode) {
    this.history.push({ from: this.currentMode, to: targetMode });
    this.currentMode = targetMode;
  }

  getCurrentMode() {
    return this.currentMode;
  }

  getModeConfig(mode) {
    return this.configs[mode] || {};
  }

  updateModeConfig(mode, config) {
    this.configs[mode] = { ...this.configs[mode], ...config };
  }

  getTransitionHistory() {
    return this.history;
  }
}

module.exports = ModeManager;