# EMAIL SENDER 1 – Guidelines
*Version 2025-05-15 — à conserver dans `/docs/README_EMAIL_SENDER_1.md`*

---

## 1. Architecture du projet

### 1.1 Composants principaux
- **Go (Golang)** : Langage privilégié pour tous les serveurs, outils système et API (remplace Python/PowerShell dès que possible)
- **n8n workflows** : Automatisation des processus d'envoi d'emails et gestion des réponses
- **MCP (Model Context Protocol)** : Serveurs pour fournir du contexte aux modèles IA (Go prioritaire)
- **Scripts PowerShell/Python** : Utilitaires et intégrations (usage secondaire, transition progressive vers Go)
- **Notion + Google Calendar** : Sources de données (contacts, disponibilités)
- **OpenRouter/DeepSeek** : Services IA pour personnalisation des messages

### 1.2 Structure des dossiers
```
/src/go/                   → Code Go principal (API, serveurs, outils)
/src/n8n/workflows/        → Workflows n8n actifs (*.json)
/src/n8n/workflows/archive → Versions archivées
/src/mcp/servers/          → Serveurs MCP (Go prioritaire, legacy: python, ps1)
/projet/guides/            → Documentation méthodologique
/projet/roadmaps/          → Roadmap et planification
/projet/config/            → Fichiers de configuration
/development/scripts/      → Scripts d'automatisation et modes
/docs/guides/augment/      → Guides spécifiques à Augment
```

---

## 2. Workflows n8n principaux

- **Email Sender - Phase 1** : Prospection initiale
- **Email Sender - Phase 2** : Suivi des propositions
- **Email Sender - Phase 3** : Traitement des réponses
- **Email Sender - Config** : Configuration centralisée (templates, calendriers)

---

## 3. Modes opérationnels

| Mode      | Fonction                              | Utilisation |
|-----------|---------------------------------------|-------------|
| **GRAN**  | Décomposition des tâches complexes    | `Invoke-AugmentMode -Mode GRAN -FilePath "path/to/roadmap.md" -TaskIdentifier "1.2.3"` |
| **DEV-R** | Implémentation des tâches roadmap     | Développement séquentiel des sous-tâches |
| **ARCHI** | Conception et modélisation           | Diagrammes, contrats d'interface, chemins critiques |
| **DEBUG** | Résolution de bugs                   | Isolation et correction d'anomalies |
| **TEST**  | Tests automatisés                    | Maximisation de la couverture de test |
| **OPTI**  | Optimisation des performances        | Réduction de complexité, parallélisation |
| **REVIEW**| Vérification de qualité              | Standards SOLID, KISS, DRY |
| **PREDIC**| Analyse prédictive                   | Anticipation des performances et anomalies |
| **C-BREAK**| Résolution de dépendances circulaires| Détection et correction des cycles |

---

## 4. Intégrations principales

### 4.1 Notion
- Base de données LOT1 (contacts programmateurs)
- Suivi des disponibilités des membres
- Gestion des lieux et salles de concert

### 4.2 Google Calendar
- Calendrier BOOKING1 pour la gestion des disponibilités
- Synchronisation avec Notion

### 4.3 Gmail
- Templates d'emails personnalisés
- Suivi des réponses automatisé

### 4.4 OpenRouter/DeepSeek
- Personnalisation des messages par IA
- Analyse des réponses

---

## 5. Axes de développement prioritaires

### 5.1 Automatisation complète du workflow de booking
- Prospection initiale → Suivi → Confirmation → Post-concert

### 5.2 Intégration MCP avancée
- Serveurs contextuels pour améliorer les réponses IA (Go prioritaire)
- Intégration avec GitHub Actions

### 5.3 Optimisation des performances
- Parallélisation des traitements (Go routines privilégiées)
- Mise en cache prédictive

### 5.4 Amélioration de l'UX
- Interface de configuration simplifiée
- Tableaux de bord de suivi

---

## 6. Standards techniques

- **Go 1.22+** comme langage système principal (API, serveurs, outils)
- **PowerShell 7 + Python 3.11** pour scripts secondaires/legacy
- **TypeScript** pour les composants n8n personnalisés
- **UTF-8** pour tous les fichiers (avec BOM pour PowerShell)
- **Tests unitaires** avec Go test, Pester (PS), pytest (Python)
- **Documentation** : minimum 20% du code
- **Complexité cyclomatique** < 10

---

## 7. Méthodologie de développement

### 7.1 Cycle par tâche
1. **Analyze** : Décomposition et estimation
2. **Learn** : Recherche de patterns existants
3. **Explore** : Prototypage de solutions (ToT)
4. **Reason** : Boucle ReAct (analyser→exécuter→ajuster)
5. **Code** : Implémentation fonctionnelle (≤ 5KB)
6. **Progress** : Avancement séquentiel sans confirmation
7. **Adapt** : Ajustement de la granularité selon complexité
8. **Segment** : Division des tâches complexes

### 7.2 Gestion des inputs volumineux
- Segmentation automatique si > 5KB
- Compression (suppression commentaires/espaces)
- Implémentation incrémentale fonction par fonction

---

## 8. Intégration avec Augment

### 8.1 Module PowerShell
```powershell
# Importer le module
Import-Module AugmentIntegration

# Initialiser l'intégration
Initialize-AugmentIntegration -StartServers

# Exécuter un mode spécifique
Invoke-AugmentMode -Mode GRAN -FilePath "docs/plans/plan.md" -TaskIdentifier "1.2.3" -UpdateMemories
```

### 8.2 Gestion des Memories
- Mise à jour après chaque changement de mode
- Optimisation pour réduire la taille des contextes
- Segmentation intelligente des inputs volumineux

---

## 9. GitHub Actions

- Notification par email des actions GitHub
- Vérification automatique des standards de code
- Déploiement automatisé des workflows n8n

---

## 10. Ressources et documentation

- `/docs/guides/augment/` : Guides d'utilisation d'Augment
- `/projet/guides/methodologies/` : Documentation des modes opérationnels
- `/projet/mcp/docs/` : Documentation MCP
- `/projet/config/requirements.txt` : Dépendances du projet

---

> **Règle d'or** : *Granularité adaptative, tests systématiques, documentation claire*.
> Pour toute question, utiliser le mode approprié et progresser par étapes incrémentielles.