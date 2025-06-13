# Error Manager - Gestionnaire d'erreurs avancé

*Version 1.0 - 2025-06-04*

Le gestionnaire d'erreurs avancé est un système complet de gestion des erreurs en Go natif pour le projet EMAIL SENDER 1. Il offre journalisation structurée, catalogage intelligent, analyse algorithmique des patterns d'erreurs, et persistance via PostgreSQL et Qdrant.

## 🎯 Objectifs

- **Robustesse** : Améliorer la robustesse du système en prévenant la récurrence des erreurs
- **Mémoire persistante** : Conserver un historique des erreurs pour l'analyse et l'apprentissage
- **Intégration** : S'intégrer parfaitement avec les gestionnaires existants
- **Analyse** : Fournir des insights algorithmiques sur les patterns d'erreurs

## ✨ Fonctionnalités

### 📝 Journalisation structurée

- **Zap** : Journalisation haute performance avec sortie JSON
- **Enrichissement** : Stack traces, métadonnées contextuelles
- **Niveaux** : DEBUG, INFO, WARNING, ERROR, CRITICAL

### 📊 Catalogage intelligent

- **ErrorEntry** : Structure standardisée avec UUID, timestamp, module, sévérité
- **Validation** : Contrôle d'intégrité des données d'erreur
- **Catégorisation** : Classification automatique par module et code

### 🗄️ Persistance dual-store

- **PostgreSQL** : Stockage relationnel pour requêtes SQL complexes
- **Qdrant** : Recherche vectorielle pour similarité sémantique
- **Docker** : Conteneurisation complète

### 🔍 Analyse algorithmique

- **Patterns** : Détection des erreurs récurrentes
- **Corrélations** : Analyse temporelle entre modules
- **Rapports** : Génération automatisée JSON/HTML
- **Recommandations** : Suggestions algorithmiques

### 🔗 Intégration système

- **Integrated Manager** : Centralisation via hooks
- **Gestionnaires** : Propagation entre tous les managers
- **APIs** : Interface Go native et exports

## 📁 Structure du projet

```plaintext
error-manager/
├── README.md                    # Ce fichier

├── go.mod                      # Dépendances Go

├── go.sum                      # Checksums des dépendances

├── docs/                       # Documentation complète

│   ├── api/                    # Documentation API

│   ├── architecture/           # Diagrammes d'architecture

│   └── guides/                 # Guides utilisateur

├── storage/                    # Couche de persistance

│   ├── postgres.go            # Intégration PostgreSQL

│   ├── qdrant.go              # Intégration Qdrant

│   └── sql/                   # Schémas SQL

├── reports/                   # Rapports générés

├── *.go                      # Code source principal

└── *_test.go                 # Tests unitaires

```plaintext
## 🚀 Démarrage rapide

### Prérequis

- Go 1.22+
- Docker et Docker Compose
- PostgreSQL 15+ (conteneurisé)
- Qdrant (conteneurisé)

### Installation

```bash
# Cloner le dépôt (si nécessaire)

cd development/managers/error-manager

# Installer les dépendances

go mod tidy

# Construire le gestionnaire

go build .

# Lancer les tests

go test -v ./...
```plaintext
### Configuration Docker

```bash
# Démarrer les services de base

docker-compose up -d postgres qdrant

# Vérifier le statut

docker-compose ps
```plaintext
### Utilisation basique

```go
package main

import (
    "time"
    errormanager "error-manager"
)

func main() {
    // Créer une entrée d'erreur
    entry := errormanager.ErrorEntry{
        ID:             "uuid-here",
        Timestamp:      time.Now(),
        Message:        "Une erreur de test",
        Module:         "example-module",
        ErrorCode:      "EX001",
        ManagerContext: "contexte de test",
        Severity:       "ERROR",
    }
    
    // Valider l'entrée
    if err := errormanager.ValidateErrorEntry(entry); err != nil {
        panic(err)
    }
    
    // Cataloguer l'erreur
    errormanager.CatalogError(entry)
}
```plaintext
## 📚 Documentation

- **[API Documentation](docs/api/README.md)** : Documentation complète des APIs
- **[Architecture](docs/architecture/README.md)** : Diagrammes et conception
- **[User Guide](docs/guides/user-guide.md)** : Guide d'utilisation
- **[Developer Guide](docs/guides/developer-guide.md)** : Guide développeur
- **[Integration Guide](docs/guides/integration-guide.md)** : Intégration avec autres managers

## 🧪 Tests

Le gestionnaire d'erreurs dispose d'une suite de tests complète :

```bash
# Tests unitaires

go test -v

# Tests avec couverture

go test -cover

# Tests de performance

go test -bench=.

# Tests d'intégration (nécessite Docker)

go test -tags=integration
```plaintext
## 🏗️ Architecture

Le gestionnaire suit les principes **SOLID** et **DRY** avec une architecture modulaire :

- **Logger** : Couche de journalisation avec Zap
- **Catalog** : Catalogage et validation des erreurs  
- **Storage** : Abstraction pour PostgreSQL et Qdrant
- **Analyzer** : Analyse des patterns et génération de rapports
- **Integration** : Hooks avec integrated-manager

## 🔧 Configuration

La configuration se fait via des variables d'environnement ou fichiers JSON :

```json
{
  "database": {
    "postgres_url": "postgresql://user:pass@localhost:5432/errors",
    "qdrant_url": "http://localhost:6333"
  },
  "logging": {
    "level": "INFO",
    "output": "json",
    "file": "logs/error-manager.log"
  },
  "analysis": {
    "pattern_detection": true,
    "report_generation": true,
    "correlation_analysis": true
  }
}
```plaintext
## 🤝 Contribution

Pour contribuer au gestionnaire d'erreurs :

1. Suivre les standards Go (gofmt, golint)
2. Écrire des tests pour toute nouvelle fonctionnalité
3. Documenter les APIs publiques
4. Respecter l'architecture existante

## 📄 License

Ce projet fait partie du système EMAIL SENDER 1 et suit la même licence.

## 🆘 Support

Pour obtenir de l'aide :

- **Documentation** : Consulter `/docs/`
- **Issues** : Créer une issue dans le dépôt
- **Tests** : Vérifier les exemples dans `*_test.go`

---

*Gestionnaire d'erreurs avancé - EMAIL SENDER 1 - 2025*
