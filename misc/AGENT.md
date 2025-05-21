# Directives pour les agents - Email-Sender-1

> Ce document contient les instructions essentielles pour les agents IA opérant dans ce dépôt. Il est complémentaire aux informations détaillées présentes dans `.augment/context/` et `.cline/`.

## Commandes de build/test
- Exécuter tous les tests: `node src/n8n/nodes/tests/run-all-tests.js`
- Exécuter un test spécifique: `node src/n8n/nodes/tests/test-mcp-nodes.js` ou `node src/n8n/nodes/tests/test-scenarios.js`
- Tests PowerShell: `Install-Module -Name Pester -Force -SkipPublisherCheck` puis exécuter `./path/to/test.ps1`

## Architecture du projet
- **n8n workflows**: Processus d'automatisation d'emails dans `/src/n8n/workflows/`
- **MCP (Model Context Protocol)**: Serveurs contextuels IA dans `/src/mcp/servers/`
- **Intégrations**: Notion, Google Calendar, Gmail, OpenRouter/DeepSeek
- **Workflows clés**: Email Sender Phases 1-3 (prospection, suivi, traitement des réponses)

## Modes opérationnels
| Mode | Fonction | 
|------|----------|
| **GRAN** | Décomposition des tâches complexes |
| **DEV-R** | Implémentation des tâches roadmap |
| **TEST** | Tests automatisés et couverture |
| **DEBUG** | Résolution de bugs |
| **OPTI** | Optimisation des performances |

## Standards de code
- **Environnement**: PowerShell 7 + Python 3.11, TypeScript pour composants n8n
- **Encodage**: UTF-8 pour tous les fichiers (avec BOM pour PowerShell)
- **Conventions de nommage**: 
  - PowerShell: PascalCase pour fonctions (Verbe-Nom), camelCase pour variables
  - JavaScript: camelCase pour variables/fonctions, PascalCase pour classes
  - Python: snake_case pour fonctions/variables, PascalCase pour classes
- **Documentation**: Minimum 20% du code, documenter intention et logique
- **Complexité**: Complexité cyclomatique < 10
- **Gestion d'erreurs**: Utiliser exceptions/erreurs spécifiques, logger avec contexte
- **Organisation**: Structure modulaire avec séparation claire des responsabilités
- **Principes**: SOLID, DRY, KISS, YAGNI
- **Limites**: Max 500 lignes par fichier, max 5KB par unité fonctionnelle

## Méthodologie de développement
- **ANALYZE**: Décomposer et estimer les tâches
- **LEARN**: Rechercher les patterns existants
- **CODE**: Implémenter en unités fonctionnelles ≤5KB
- **TEST**: Tests systématiques avec haute couverture
- **ADAPT**: Ajuster la granularité selon la complexité

## Méthodologie de tests (P1-P4)

### Phase 1 (P1): Tests Basiques
- Validation des paramètres et comportement nominal
- Tests unitaires simples sans dépendances
- Vérification des types de retour et valeurs par défaut

### Phase 2 (P2): Tests de Robustesse
- Tests des cas limites et valeurs extrêmes
- Validation avec entrées nulles/vides
- Tests de performances sous charge normale

### Phase 3 (P3): Tests d'Exceptions
- Vérification de la gestion des erreurs
- Tests de récupération après échec
- Validation des messages d'erreur

### Phase 4 (P4): Tests Avancés
- Tests de performance sous charge élevée
- Validation de la concurrence et du parallélisme
- Tests d'intégration et de stress

## Dépendances
- n8n-nodes-mcp==0.1.14
- @suekou/mcp-notion-server==1.1.1
- python-dotenv==1.0.0
- requests==2.31.0