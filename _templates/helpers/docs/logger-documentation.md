# Système de Logging pour Templates Hygen

## Vue d'ensemble
Le système de logging est un module centralisé qui fournit des fonctionnalités de logging cohérentes et cross-platform pour tous les templates Hygen.

## Fonctionnalités principales

### Niveaux de verbosité
- `debug`: Messages détaillés pour le développement
- `info`: Informations générales sur le processus
- `warn`: Avertissements non critiques
- `error`: Erreurs critiques

### Support des emojis
- Détection automatique de la plateforme
- Fallback pour les plateformes sans support emoji
- Configuration via `useEmoji: boolean`

## Utilisation

```javascript
const { createLogger } = require('../../helpers/logger-helper.js');

// Création d'une instance de logger
const logger = createLogger({
  verbosity: 'info',  // 'debug' | 'info' | 'warn' | 'error'
  useEmoji: true      // true | false
});

// Utilisation
logger.debug('Message de debug');
logger.info('Information importante');
logger.warn('Attention !');
logger.error('Erreur critique');
```

## Configuration avancée

### Options de configuration
```javascript
{
  verbosity: 'info',     // Niveau de verbosité par défaut
  useEmoji: true,        // Activation des emojis
  prefix: 'MyTemplate:'  // Préfixe personnalisé pour les messages
}
```

### Fallbacks pour les emojis
- Windows : Caractères ASCII alternatifs
- Autres plateformes : Emojis Unicode complets

## Bonnes pratiques

1. **Niveaux de log appropriés**
   - `debug`: Pour les détails d'implémentation
   - `info`: Pour le suivi du processus
   - `warn`: Pour les situations non optimales
   - `error`: Pour les erreurs bloquantes

2. **Messages clairs et concis**
   - Inclure le contexte pertinent
   - Éviter les messages trop verbeux
   - Utiliser une ponctuation cohérente

3. **Gestion cross-platform**
   - Toujours tester sur Windows et Unix
   - Vérifier le rendu des emojis
   - Utiliser les fallbacks appropriés

## Intégration dans les templates

### Template de base
```javascript
const { createLogger } = require('../../helpers/logger-helper.js');

module.exports = {
  prompt: async ({ prompter, args }) => {
    const logger = createLogger({ verbosity: 'info' });
    
    try {
      // Votre code ici
      logger.info('Traitement en cours...');
    } catch (error) {
      logger.error('Une erreur est survenue:', error);
    }
  }
};
```

## Dépannage

### Problèmes courants

1. **Emojis mal affichés**
   - Vérifier la configuration du terminal
   - Utiliser `useEmoji: false` si nécessaire

2. **Messages manquants**
   - Vérifier le niveau de verbosité
   - S'assurer que le niveau est approprié

3. **Performance**
   - Utiliser `debug` avec parcimonie
   - Éviter les logs excessifs

## Support

Pour tout problème ou suggestion :
1. Vérifier la documentation
2. Consulter les tests unitaires
3. Ouvrir une issue sur le dépôt
