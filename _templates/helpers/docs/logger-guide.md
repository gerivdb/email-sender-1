# Documentation du Système de Logging pour Templates Hygen

## Table des matières

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Utilisation](#utilisation)
5. [Bonnes pratiques](#bonnes-pratiques)
6. [Compatibilité cross-platform](#compatibilité-cross-platform)
7. [Dépannage](#dépannage)
8. [Tests](#tests)

## Introduction

Le système de logging est un module central pour tous les templates Hygen. Il fournit :
- Gestion unifiée des logs avec différents niveaux de verbosité
- Support des emojis avec fallbacks pour Windows
- Coloration syntaxique intégrée
- Compatibilité cross-platform

## Installation

```javascript
const { createLogger } = require('../../helpers/logger-helper.js');

const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});
```

## Configuration

### Options disponibles

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| verbosity | string | 'info' | Niveau de log ('debug', 'info', 'warn', 'error') |
| useEmoji | boolean | true | Activer/désactiver les emojis |
| platform | string | auto | Forcer une plateforme spécifique |
| prefix | string | '' | Préfixe pour les messages |

### Niveaux de verbosité

- **debug** : Informations détaillées pour le développement
- **info** : Messages d'information standard
- **warn** : Avertissements non critiques
- **error** : Erreurs critiques bloquantes

## Utilisation

### Exemple de base
```javascript
logger.info('Démarrage du processus');
logger.debug('Variable data:', data);
logger.warn('Configuration manquante');
logger.error('Erreur critique:', error);
```

### Validation dans les prompts
```javascript
{
  type: 'input',
  name: 'name',
  message: "Nom du script:",
  validate: input => {
    if (!input) {
      logger.warn('Le nom est requis');
      return 'Le nom est requis';
    }
    logger.debug('Nom validé:', input);
    return true;
  }
}
```

## Bonnes pratiques

1. **Niveaux appropriés**
   - debug : Pour le développement
   - info : Pour le suivi normal
   - warn : Pour les situations non optimales
   - error : Pour les erreurs bloquantes

2. **Messages clairs**
   - Inclure le contexte nécessaire
   - Être concis mais descriptif
   - Utiliser les verbes au présent

3. **Utilisation des emojis**
   - Choisir des emojis pertinents
   - Prévoir des fallbacks textuels
   - Tester sur différentes plateformes

## Compatibilité cross-platform

### Windows
- Fallbacks automatiques pour les emojis
- Support des chemins Windows
- Gestion des encodages

### Unix/Linux
- Support complet des emojis
- Chemins compatibles POSIX
- Couleurs natives du terminal

### Exemples de fallbacks
```javascript
// Windows
logger.info('[i] Message'); // Sans emoji
// Unix
logger.info('ℹ️ Message'); // Avec emoji
```

## Dépannage

### Problèmes courants

1. **Emojis mal affichés**
   - Solution : `useEmoji: false`
   - Alternative : Utiliser les fallbacks textuels

2. **Messages manquants**
   - Vérifier le niveau de verbosité
   - Contrôler la configuration du logger

3. **Problèmes d'encodage**
   - Utiliser UTF-8
   - Vérifier la configuration du terminal

## Tests

### Tests unitaires
```javascript
// test-logger-cross-platform.js
const logger = createLogger({...});
// Voir les exemples de tests dans /test
```

### Tests manuels recommandés
1. Vérification des niveaux de log
2. Test des emojis sur différentes plateformes
3. Validation des messages de couleur
4. Tests de performance

## Support et maintenance

### Mise à jour
- Vérifier régulièrement les mises à jour
- Tester après chaque mise à jour
- Maintenir la documentation à jour

### Contact
Pour toute question ou problème :
1. Consulter les tests
2. Vérifier la documentation
3. Ouvrir une issue sur le dépôt

## Exemples complets

### Template standard
```javascript
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ verbosity: 'info' });

module.exports = {
  prompt: async ({ prompter }) => {
    try {
      logger.info('Démarrage de la génération');
      // ... code ...
      logger.info('Génération terminée');
    } catch (error) {
      logger.error('Erreur:', error);
      throw error;
    }
  }
};
```

### Gestion avancée
```javascript
const logger = createLogger({ 
  verbosity: 'debug',
  useEmoji: true,
  prefix: '[Template]'
});

// Logs avec contexte
logger.debug('Context:', { data, options });
logger.info('Processing:', file.name);
logger.warn('Missing:', ['config.json', '.env']);
logger.error('Failed:', error.message, error.stack);
```
