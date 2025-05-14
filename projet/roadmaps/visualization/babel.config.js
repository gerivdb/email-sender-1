/**
 * Configuration Babel pour les tests Jest
 */

export default {
  presets: [
    [
      '@babel/preset-env',
      {
        targets: {
          node: 'current'
        },
        modules: 'auto'
      }
    ]
  ]
};
