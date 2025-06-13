# EMAIL SENDER 1 – Augment Guidelines

*Version 2025-05-15 — à conserver dans `/docs/README_EMAIL_SENDER_1.md`*

---

## 1. Architecture du projet

### 1.1 Composants principaux

- **n8n workflows** : Automatisation des processus d'envoi d'emails et gestion des réponses
- **MCP (Model Context Protocol)** : Serveurs pour fournir du contexte aux modèles IA
- **Scripts PowerShell/Python** : Utilitaires et intégrations
- **Notion + Google Calendar** : Sources de données (contacts, disponibilités)
- **OpenRouter/DeepSeek** : Services IA pour personnalisation des messages

### 1.2 Structure des dossiers

```plaintext
/src/n8n/workflows/       → Workflows n8n actifs (*.json)
/src/n8n/workflows/archive → Versions archivées
/src/mcp/servers/         → Serveurs MCP (filesystem, github, gcp)
/projet/guides/           → Documentation méthodologique
/projet/roadmaps/         → Roadmap et planification
/projet/config/           → Fichiers de configuration
/development/scripts/     → Scripts d'automatisation et modes
/docs/guides/augment/     → Guides spécifiques à Augment
```plaintext
---

## 2. Workflows n8n principaux

- **Email Sender - Phase 1** : Prospection initiale
- **Email Sender - Phase 2** : Suivi des propositions
- **Email Sender - Phase 3** : Traitement des réponses
- **Email Sender - Config** : Configuration centralisée (templates, calendriers)

### 2.1 Pattern de workflow recommandé

```plaintext
+---------+      +----------------+      +-------+      +---------+      +----------------+
|  CRON   | ---> | Read Contacts  | ---> |  IF   | ---> |  Send   | ---> | Update Status  |
| (Sched) |      | (Notion/GCal)  |      | Filter|      | Email 1 |      | (e.g., Contacted)|
+---------+      +----------------+      +-------+      +---------+      +----------------+
                                                                               |
                                                                               V
+---------+      +----------------+      +-------+      +---------+      +----------------+
|  Wait   | <--- | Update Status  | <--- |  Send   | <--- |  IF   | <--- | Read Status    |
| (Delay) |      | (e.g., FollowUp)|      | Email 2 |      | NoReply?|      | (Check Reply)  |
+---------+      +----------------+      +---------+      +-------+      +----------------+
     |
     V
  (End or Loop)
```plaintext
Ce pattern `Trigger -> Read -> Filter -> Act -> Update -> Wait -> Re-check -> Conditional Act -> Update` est fondamental pour les workflows d'automatisation d'emails.

---

## 3. Modes opérationnels

| Mode | Fonction | Utilisation |
|------|----------|-------------|
| **GRAN** | Décomposition des tâches complexes | `Invoke-AugmentMode -Mode GRAN -FilePath "path/to/roadmap.md" -TaskIdentifier "1.2.3"` |
| **DEV-R** | Implémentation des tâches roadmap | Développement séquentiel des sous-tâches |
| **ARCHI** | Conception et modélisation | Diagrammes, contrats d'interface, chemins critiques |
| **DEBUG** | Résolution de bugs | Isolation et correction d'anomalies |
| **TEST** | Tests automatisés | Maximisation de la couverture de test |
| **OPTI** | Optimisation des performances | Réduction de complexité, parallélisation |
| **REVIEW** | Vérification de qualité | Standards SOLID, KISS, DRY |
| **PREDIC** | Analyse prédictive | Anticipation des performances et anomalies |
| **C-BREAK** | Résolution de dépendances circulaires | Détection et correction des cycles |

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

- Serveurs contextuels pour améliorer les réponses IA
- Intégration avec GitHub Actions

### 5.3 Optimisation des performances

- Parallélisation des traitements
- Mise en cache prédictive

### 5.4 Amélioration de l'UX

- Interface de configuration simplifiée
- Tableaux de bord de suivi

---

## 6. Standards techniques

- **Golang 1.21+** comme environnement principal (10-1000x plus rapide que PowerShell/Python)
- **PowerShell 7 + Python 3.11** pour scripts d'intégration et compatibilité legacy
- **TypeScript** pour les composants n8n personnalisés
- **UTF-8** pour tous les fichiers (avec BOM pour PowerShell)
- **Tests unitaires** avec Go testing framework, Pester (PS) et pytest (Python)
- **Documentation** : minimum 20% du code
- **Complexité cyclomatique** < 10

---

## 7. Méthodologie de développement

### 7.1 Cycle par tâche avec Framework Golang

1. **Analyze** : Décomposition et estimation avec métriques automatisées
2. **Learn** : Recherche de patterns existants dans templates Go
3. **Explore** : Prototypage avec code generation (ToT)
4. **Reason** : Boucle ReAct avec validation fail-fast
5. **Code** : Implémentation Golang haute performance (≤ 5KB par composant)
6. **Progress** : Avancement séquentiel avec pipeline automatisé
7. **Adapt** : Ajustement de la granularité selon complexité
8. **Segment** : Division des tâches complexes avec codegen

### 7.2 Gestion des inputs volumineux

- Segmentation automatique si > 5KB avec streaming Go
- Compression haute performance (suppression commentaires/espaces)
- Implémentation incrémentale fonction par fonction avec génération de templates

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
```plaintext
### 8.2 Gestion des Memories

- Mise à jour après chaque changement de mode
- Optimisation pour réduire la taille des contextes
- Segmentation intelligente des inputs volumineux

---

## 9. RAG System & Framework d'automatisation

### 9.1 Framework 7 Time-Saving Methods

Le projet utilise un framework d'automatisation Golang haute performance implémentant 7 méthodes pour maximiser l'efficacité:

1. **Fail-Fast Validation** (+72h immediate, +24h/month)
   - Validation précoce des entrées et configurations
   - Détection rapide des erreurs avant exécution

2. **Mock-First Strategy** (+24h immediate, +18h/month)
   - Développement avec interfaces mockées
   - Tests parallèles sans dépendances externes

3. **Contract-First Development** (+22h immediate, +12h/month)
   - Définition d'APIs avant implémentation
   - Génération automatique de code et documentation

4. **Inverted TDD** (+24h immediate, +42h/month)
   - Tests d'intégration avant tests unitaires
   - Couverture fonctionnelle complète

5. **Code Generation Framework** (+36h immediate)
   - Génération automatique de composants RAG
   - Templates configurables pour CLI et services

6. **Metrics-Driven Development** (+20h/month ongoing)
   - Métriques en temps réel
   - Optimisation basée sur les données

7. **Pipeline-as-Code** (+40h immediate)
   - Automatisation CI/CD complète
   - Infrastructure reproductible

### 9.2 Codegen CLI

```bash
# Générer un service RAG complet

./cmd/codegen/codegen -type service -output ./generated/rag-service/

# Générer une CLI avec commandes

./cmd/codegen/codegen -type cli -output ./generated/cli/

# Générer des composants spécifiques

./cmd/codegen/codegen -type component -spec embedding -output ./generated/
```plaintext
### 9.3 ROI du Framework

- **Économies immédiates** : 218h (soit $18,530 en valeur)
- **Économies annuelles** : 1,392h (soit $118,320 en valeur)
- **Performance** : 10-1000x plus rapide que PowerShell/Python
- **Maintenabilité** : Code généré conforme aux standards Go

---

## 10. Décisions architecturales importantes

### 9.1 Multi-Instance vs. Multi-Tenant

#### Multi-Instance

- Chaque client a sa propre instance isolée
- **Avantages** : Sécurité accrue, simplicité, mises à jour indépendantes
- **Inconvénients** : Coûts plus élevés, onboarding plus complexe
- **Recommandé si** : Données sensibles, configurations très différentes par client

#### Multi-Tenant

- Base de données partagée avec séparation logique des données
- **Avantages** : Moins cher à scaler, déploiement unique
- **Inconvénients** : Plus complexe, webhooks n8n doivent être génériques
- **Recommandé si** : Plateforme SaaS, nombreux clients avec configurations similaires

### 9.2 Sécurisation des secrets

- Stockage sécurisé des clés API et webhooks
- Utilisation d'une couche intermédiaire pour masquer les webhooks n8n
- Configuration centralisée dans Email Sender - Config

---

## 10. Ressources et documentation

- `/docs/guides/augment/` : Guides d'utilisation d'Augment
- `/projet/guides/methodologies/` : Documentation des modes opérationnels
- `/projet/guides/n8n/` : Guides d'utilisation de n8n
- `/projet/guides/architecture/` : Décisions architecturales
- `/projet/config/requirements.txt` : Dépendances du projet

---

> **Règle d'or** : *Granularité adaptative, tests systématiques, documentation claire*.
> Pour toute question, utiliser le mode approprié et progresser par étapes incrémentielles.
