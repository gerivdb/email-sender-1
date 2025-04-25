# Projet Email Sender pour n8n

## Architecture MCP avec Proxy Unifié

### Fonctionnalités
- Bascule automatique entre Augment et Cline
- Monitoring temps réel via WebSocket
- API REST pour le contrôle manuel

### Configuration
```json
{
  "port": 4000,
  "services": {
    "augment": {
      "url": "http://localhost:3000",
      "healthCheck": "/api/health"
    },
    "cline": {
      "url": "http://localhost:5000",
      "healthCheck": "/health"
    }
  }
}
```

### Tests Automatisés

#### Test d'intégration
```javascript
const axios = require('axios');

async function testProxy() {
  // 1. Vérifier l'état initial
  const status = await axios.get('http://localhost:4000/status');

  // 2. Tester la bascule
  await axios.post('http://localhost:4000/switch', {
    service: 'augment'
  });

  // 3. Vérifier le proxy
  const health = await axios.get('http://localhost:4000/proxy/api/health');
  console.log('Health check:', health.data);
}

testProxy().catch(console.error);
```

#### Lancer les tests
```bash
cd scripts/node
npm install mocha chai
npm test
```

### Structure du projet
[... contenu existant sur la structure ...]

### Guidelines
Voir les fichiers dans le répertoire [docs/guides/](docs/guides/) pour les bonnes pratiques de développement, notamment :
- [User Guidelines](docs/guides/user_guidelines.md) - Directives utilisateur et méthodologie de développement
- [Python Best Practices](docs/guides/python_best_practices.md) - Bonnes pratiques pour le développement Python
- [PowerShell Best Practices](docs/guides/powershell_best_practices.md) - Bonnes pratiques pour les scripts PowerShell
